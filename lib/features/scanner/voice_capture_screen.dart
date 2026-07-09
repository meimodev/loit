import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

import '../../core/config/pricing_constants.dart';
import '../../core/services/dummy_payment_service.dart';
import '../../core/services/log_service.dart';
import '../../core/services/scanner_service.dart';
import '../../core/theme/loit_colors.dart';
import '../../core/theme/loit_motion.dart';
import '../../core/theme/loit_spacing.dart';
import '../../core/theme/loit_typography.dart';
import '../../shared/providers/accounts_provider.dart';
import '../../shared/providers/room_accounts_provider.dart';
import '../../shared/providers/room_providers.dart';
import '../../shared/providers/services_providers.dart';
import '../../shared/providers/transactions_provider.dart';
import '../../shared/widgets/loit_animations.dart';
import '../../shared/widgets/loit_button.dart';
import '../paywall/scan_topup_sheet.dart';
import '../../l10n/l10n_x.dart';

/// In-app voice Capture (ADR-0022). Hold the mic to record, release to send.
/// The clip is uploaded to `parse-voice` (transcribe + parse, AI Credit gated),
/// audio is discarded server-side, and the parsed transaction lands in the
/// transaction form for review — the same prefill path scan uses on fallback.
class VoiceCaptureScreen extends ConsumerStatefulWidget {
  const VoiceCaptureScreen({super.key, this.roomId});

  /// When set, the voice transaction is scoped to this room (categories +
  /// accounts), mirroring `/scan?roomId=`.
  final String? roomId;

  @override
  ConsumerState<VoiceCaptureScreen> createState() => _VoiceCaptureScreenState();
}

enum _VoicePhase { idle, recording, processing, error, roomNotFound, permissionDenied }

class _VoiceCaptureScreenState extends ConsumerState<VoiceCaptureScreen>
    with WidgetsBindingObserver {
  static const _tag = 'VoiceCaptureScreen';
  static const _maxDuration = Duration(seconds: 60);
  static const _minMillis = 800; // too-short release → discard, no charge

  final _recorder = AudioRecorder();
  _VoicePhase _phase = _VoicePhase.idle;
  bool _permanentlyDenied = false; // OS won't re-prompt → deep-link to settings
  String? _transcript; // what was heard, shown on a failed parse
  String? _notFoundRoom; // room named in speech but not a member (parity)
  DateTime? _startedAt;
  double _amplitude = 0; // 0..1 normalized
  int _elapsed = 0; // seconds

  Timer? _ticker;
  StreamSubscription<Amplitude>? _ampSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _requestMic();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.cancel();
    _ampSub?.cancel();
    _recorder.dispose();
    super.dispose();
  }

  /// Mic permission is requested on load (ADR-0022 UX amendment) rather than on
  /// first record press: this screen's sole purpose is voice, so arriving here
  /// is already the intent. `_phase` stays idle (the mic backdrop sits behind
  /// the OS dialog); denial flips to a dedicated view before any interaction.
  Future<void> _requestMic() async {
    final status = await Permission.microphone.request();
    if (!mounted || status.isGranted) return;
    setState(() {
      _phase = _VoicePhase.permissionDenied;
      _permanentlyDenied = status.isPermanentlyDenied || status.isRestricted;
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Returning from Settings (or foregrounding after a mid-session grant/
    // revoke): re-check and recover to the record UI without a tap.
    if (state != AppLifecycleState.resumed) return;
    if (_phase != _VoicePhase.permissionDenied) return;
    Permission.microphone.status.then((s) {
      if (!mounted || !s.isGranted) return;
      setState(() => _phase = _VoicePhase.idle);
    });
  }

  /// Denied-view button: re-request while still askable; once permanently
  /// denied the OS suppresses the dialog, so deep-link to app settings instead.
  Future<void> _onMicAction() async {
    if (_permanentlyDenied) {
      await openAppSettings();
    } else {
      await _requestMic();
    }
  }

  Future<void> _start() async {
    if (_phase == _VoicePhase.processing) return;
    final dir = await getTemporaryDirectory();
    final path =
        '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
    await _recorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc),
      path: path,
    );
    _startedAt = DateTime.now();
    _ampSub = _recorder
        .onAmplitudeChanged(const Duration(milliseconds: 150))
        .listen((a) {
          // dBFS (~ -45 silence .. 0 loud) → 0..1 for the pulse ring.
          final norm = ((a.current + 45) / 45).clamp(0.0, 1.0);
          if (mounted) setState(() => _amplitude = norm);
        });
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _elapsed++);
      if (_elapsed >= _maxDuration.inSeconds) _stopAndSend();
    });
    if (mounted) {
      setState(() {
        _phase = _VoicePhase.recording;
        _elapsed = 0;
      });
    }
  }

  Future<void> _stopAndSend() async {
    _ticker?.cancel();
    await _ampSub?.cancel();
    _ampSub = null;
    final started = _startedAt;
    final path = await _recorder.stop();
    final tooShort =
        started == null ||
        DateTime.now().difference(started).inMilliseconds < _minMillis;
    if (tooShort || path == null) {
      if (mounted) {
        setState(() => _phase = _VoicePhase.idle);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.l10n.voiceTooShort)));
      }
      return;
    }
    if (mounted) setState(() => _phase = _VoicePhase.processing);
    await _send(path);
  }

  Future<void> _cancel() async {
    _ticker?.cancel();
    await _ampSub?.cancel();
    _ampSub = null;
    if (await _recorder.isRecording()) await _recorder.stop();
    if (mounted) setState(() => _phase = _VoicePhase.idle);
  }

  Future<void> _send(String path) async {
    final screenRoomId = widget.roomId;

    // Full context now lives server-side (ADR-0022 amendment): parse-voice uses
    // loadUserContext and resolves the destination room itself, so the client
    // no longer ships scoped categories/accounts. `roomId` is only the default
    // destination when speech names no room.
    final scanner = ref.read(scannerServiceProvider);
    final result = await scanner.transcribeAndParse(
      File(path),
      roomId: screenRoomId,
    );
    if (!mounted) return;

    switch (result.errorType) {
      case null:
        final parsed = Map<String, dynamic>.from(result.parsedData ?? {});
        // Server-resolved destination (speech wins; else the screen room).
        final destRoomId = parsed['destination_room_id'] as String?;
        final destRoomName = parsed['destination_room'] as String?;
        final routedBySpeech = parsed['routed_by_speech'] == true;
        // Room captures default to the Room pool (ADR-0023): resolve against the
        // room's Room accounts first (a Room-account movement), and fall back to
        // a personal account (Out-of-pocket) only when the room has none —
        // mirroring scan_review_screen. Personal captures use personal accounts.
        List<Account> accountList = destRoomId != null
            ? await ref.read(roomAccountsProvider(destRoomId).future)
            : (ref.read(accountsProvider).value ?? const <Account>[]);
        if (destRoomId != null && accountList.isEmpty) {
          accountList = ref.read(accountsProvider).value ?? const <Account>[];
        }
        if (!mounted) return; // room-accounts fetch above is an async gap
        // High trust (ADR-0022): same predicate as scan auto-confirm, minus the
        // autoConfirmEnabled toggle. Commit straight to a Transaction iff the
        // account also resolves; otherwise fall through to the review form.
        final highTrust =
            result.confidenceBucket == ConfidenceBucket.high &&
            !result.reconciliationWarning &&
            !result.totalComputed;
        final accountId = highTrust
            ? (_accountIdFromName(parsed['account'] as String?, accountList) ??
                  _firstActiveAccountId(accountList))
            : null;
        if (highTrust && accountId != null) {
          await _commit(
            parsed,
            accountId,
            destRoomId,
            routedRoomName: routedBySpeech ? destRoomName : null,
          );
        } else {
          if (destRoomId != null) parsed['_room_id'] = destRoomId;
          if (routedBySpeech && destRoomName != null) {
            parsed['_routed_room'] = destRoomName;
          }
          parsed['_source'] = 'voice';
          parsed['_ai_parsed'] = true;
          Log.i(
            _tag,
            'Voice parse → form (trust=${result.confidenceBucket.name}, room=$destRoomId)',
          );
          context.pushReplacement('/transactions/new', extra: parsed);
        }
        break;
      case ScanErrorType.aiFailure:
        // Best-effort: keep whatever was recovered, else manual fallback.
        final data = Map<String, dynamic>.from(result.partialFields ?? {});
        if (screenRoomId != null) data['_room_id'] = screenRoomId;
        final totalRaw = data['total'];
        final totalNum = totalRaw is num
            ? totalRaw.toDouble()
            : double.tryParse('${totalRaw ?? ''}');
        final hasItems =
            data['items'] is List && (data['items'] as List).isNotEmpty;
        if ((totalNum != null && totalNum > 0) || hasItems) {
          data['_source'] = 'voice';
          data['_ai_parsed'] = true;
        } else {
          data['_manual_fallback'] = true;
          data['_source'] = 'manual';
        }
        context.pushReplacement('/transactions/new', extra: data);
        break;
      case ScanErrorType.quotaExceeded:
        setState(() => _phase = _VoicePhase.idle);
        await _showQuotaSheet();
        break;
      case ScanErrorType.roomNotFound:
        // Parity with the bot: a room was addressed that the user isn't in.
        setState(() {
          _notFoundRoom = result.notFoundRoom;
          _transcript = result.transcript;
          _phase = _VoicePhase.roomNotFound;
        });
        break;
      case ScanErrorType.notATransaction:
        setState(() {
          _transcript = result.transcript;
          _phase = _VoicePhase.error;
        });
        break;
      case ScanErrorType.connectionError:
      default:
        setState(() => _phase = _VoicePhase.error);
    }
  }

  String? _accountIdFromName(String? name, List<Account> accounts) {
    if (name == null) return null;
    for (final a in accounts) {
      if (a.archivedAt != null) continue;
      if (a.name.toLowerCase() == name.toLowerCase()) return a.id;
    }
    return null;
  }

  String? _firstActiveAccountId(List<Account> accounts) {
    for (final a in accounts) {
      if (a.archivedAt == null) return a.id;
    }
    return null;
  }

  /// High-trust direct commit. Mirrors `scan_review_screen._save`: merchant,
  /// note, and items persist structured (ADR-0025), then `addTransaction`. On
  /// success land on the detail screen with the context-aware list underneath,
  /// so back reveals where the row lives. `date` is intentionally omitted — the
  /// table has no date column; `created_at` carries the timestamp.
  Future<void> _commit(
    Map<String, dynamic> p,
    String accountId,
    String? roomId, {
    String? routedRoomName,
  }) async {
    // Structured storage (ADR-0025): merchant / note / items each land in
    // their own column — the AI's structure is persisted as-is.
    final merchant = (p['merchant'] as String?)?.trim() ?? '';
    final currency = (p['currency'] as String?) ?? 'IDR';
    final rawNotes = (p['notes'] as String?)?.trim();

    try {
      final insertedId = await ref
          .read(transactionsProvider.notifier)
          .addTransaction({
            'type': p['type'] ?? 'expense',
            'amount': p['total'],
            'currency': currency,
            if (merchant.isNotEmpty) 'merchant': merchant,
            if (rawNotes != null && rawNotes.isNotEmpty) 'notes': rawNotes,
            'category': p['category'] ?? 'other',
            'account_id': accountId,
            'ai_parsed': true,
            'source': 'voice',
            'created_at': DateTime.now().toUtc().toIso8601String(),
            if (roomId != null) 'room_id': roomId,
            if (p['items'] != null) 'items': p['items'],
          }, requireOnline: roomId != null);
      if (!mounted) return;
      Log.i(_tag, 'Voice high-trust commit id=$insertedId');
      // Capture before navigation replaces this screen's context.
      final messenger = ScaffoldMessenger.of(context);
      final l = context.l10n;
      if (insertedId == null) {
        // Personal offline race: row queued, no id to open detail with.
        context.go('/transactions');
        return;
      }
      if (roomId != null) {
        context.go('/rooms/$roomId?highlight=$insertedId');
        context.push('/rooms/$roomId/transactions/$insertedId');
      } else {
        context.go('/transactions?highlight=$insertedId');
        context.push('/transactions/$insertedId');
      }
      // Speech re-routed this to a room (ADR-0022 amendment): warn, with Undo,
      // since a High-trust capture skips the review form.
      if (routedRoomName != null) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(l.voiceSavedToRoom(routedRoomName)),
            action: SnackBarAction(
              label: l.undo,
              onPressed: () => ref
                  .read(transactionsProvider.notifier)
                  .deleteTransaction(insertedId, requireOnline: roomId != null),
            ),
          ),
        );
      }
    } catch (e, st) {
      Log.e(_tag, 'Voice commit failed', error: e, stack: st);
      if (!mounted) return;
      // Room (requireOnline) offline, or insert error → review in the form.
      if (roomId != null) p['_room_id'] = roomId;
      p['_source'] = 'voice';
      p['_ai_parsed'] = true;
      context.pushReplacement('/transactions/new', extra: p);
    }
  }

  Future<void> _showQuotaSheet() async {
    await showScanTopUpSheet(context, onTopUp: () async {
      if (!mounted) return;
      final pay = ref.read(paymentServiceProvider);
      if (pay is DummyPaymentService) pay.bindContext(context);
      try {
        await pay.purchaseOneTime(PricingConstants.skuScanTopUp);
      } catch (_) {}
    });
  }

  // Collapses idle+recording into one key so the record orb animates in place
  // rather than the whole control re-fading when a hold begins.
  String get _phaseGroup => switch (_phase) {
    _VoicePhase.idle || _VoicePhase.recording => 'record',
    _VoicePhase.processing => 'processing',
    _VoicePhase.error => 'error',
    _VoicePhase.roomNotFound => 'roomNotFound',
    _VoicePhase.permissionDenied => 'denied',
  };

  List<Widget> _deniedContent(BuildContext context) {
    final c = context.loitColors;
    final l = context.l10n;
    return [
      Text(
        l.voiceMicTitle,
        textAlign: TextAlign.center,
        style: LoitTypography.titleM.copyWith(color: c.contentInverse),
      ),
      const SizedBox(height: LoitSpacing.s2),
      Text(
        l.voiceMicDenied,
        textAlign: TextAlign.center,
        style: LoitTypography.bodyM.copyWith(
          color: c.contentInverse.withValues(alpha: 0.7),
        ),
      ),
    ];
  }

  List<Widget> _roomNotFoundContent(BuildContext context) {
    final c = context.loitColors;
    final l = context.l10n;
    final room = _notFoundRoom ?? '';
    final rooms = (ref.watch(activeRoomsProvider).value ?? const [])
        .map((r) => r['name'] as String? ?? '')
        .where((n) => n.isNotEmpty)
        .toList();
    final heard = _transcript?.trim();
    return [
      Text(
        rooms.isEmpty
            ? l.voiceRoomNotFoundNoRooms(room)
            : l.voiceRoomNotFound(room),
        textAlign: TextAlign.center,
        style: LoitTypography.bodyM.copyWith(color: c.contentInverse),
      ),
      if (rooms.isNotEmpty) ...[
        const SizedBox(height: LoitSpacing.s3),
        Text(
          l.voiceYourRooms(rooms.join(', ')),
          textAlign: TextAlign.center,
          style: LoitTypography.bodyS.copyWith(
            color: c.contentInverse.withValues(alpha: 0.7),
          ),
        ),
      ],
      if (heard != null && heard.isNotEmpty) ...[
        const SizedBox(height: LoitSpacing.s5),
        Text(
          '"$heard"',
          textAlign: TextAlign.center,
          style: LoitTypography.bodyM.copyWith(
            color: c.contentInverse,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    ];
  }

  List<Widget> _errorContent(BuildContext context) {
    final c = context.loitColors;
    final l = context.l10n;
    final heard = _transcript?.trim();
    return [
      Text(
        l.voiceError,
        textAlign: TextAlign.center,
        style: LoitTypography.bodyM.copyWith(color: c.contentInverse),
      ),
      if (heard != null && heard.isNotEmpty) ...[
        const SizedBox(height: LoitSpacing.s5),
        Text(
          l.voiceHeard,
          style: LoitTypography.labelS.copyWith(
            color: c.contentInverse.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: LoitSpacing.s2),
        Text(
          '"$heard"',
          textAlign: TextAlign.center,
          style: LoitTypography.bodyM.copyWith(
            color: c.contentInverse,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    ];
  }

  @override
  Widget build(BuildContext context) {
    final c = context.loitColors;
    final l = context.l10n;
    return Scaffold(
      backgroundColor: c.inverse,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: c.contentInverse,
        elevation: 0,
        title: Text(l.voiceTitle),
      ),
      body: SafeArea(
        // Phases cross-fade instead of snapping. idle+recording share one
        // subtree key so pressing record animates the orb, not the whole view.
        child: Center(
          child: AnimatedSwitcher(
            duration: LoitMotion.base,
            switchInCurve: LoitMotion.easeOutQuint,
            switchOutCurve: LoitMotion.easeOutQuart,
            child: KeyedSubtree(
              key: ValueKey(_phaseGroup),
              child: switch (_phase) {
                _VoicePhase.permissionDenied => _MessageView(
                  icon: Icons.mic_off_rounded,
                  buttonLabel: _permanentlyDenied
                      ? l.voiceMicOpenSettings
                      : l.voiceMicGrant,
                  onPressed: _onMicAction,
                  children: _deniedContent(context),
                ),
                _VoicePhase.processing => _Processing(label: l.voiceProcessing),
                _VoicePhase.roomNotFound => _MessageView(
                  icon: Icons.meeting_room_outlined,
                  buttonLabel: MaterialLocalizations.of(context).okButtonLabel,
                  onPressed: () => setState(() => _phase = _VoicePhase.idle),
                  children: _roomNotFoundContent(context),
                ),
                _VoicePhase.error => _MessageView(
                  icon: Icons.error_outline,
                  buttonLabel: MaterialLocalizations.of(context).okButtonLabel,
                  onPressed: () => setState(() => _phase = _VoicePhase.idle),
                  children: _errorContent(context),
                ),
                _ => _RecordControl(
                  recording: _phase == _VoicePhase.recording,
                  amplitude: _amplitude,
                  elapsed: _elapsed,
                  hint: _phase == _VoicePhase.recording
                      ? l.voiceRecording
                      : l.voiceHint,
                  onStart: _start,
                  onStop: _stopAndSend,
                  onCancel: _cancel,
                ),
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _RecordControl extends StatelessWidget {
  const _RecordControl({
    required this.recording,
    required this.amplitude,
    required this.elapsed,
    required this.hint,
    required this.onStart,
    required this.onStop,
    required this.onCancel,
  });

  final bool recording;
  final double amplitude;
  final int elapsed;
  final String hint;
  final VoidCallback onStart;
  final VoidCallback onStop;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final c = context.loitColors;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Timer slot is always reserved so the orb never jumps when a hold
        // starts — the digits just fade in. Tabular figures hold the width
        // steady as the seconds tick (DESIGN: the Tabular Money Rule).
        SizedBox(
          height: 48,
          child: AnimatedOpacity(
            opacity: recording ? 1 : 0,
            duration: LoitMotion.short,
            curve: LoitMotion.easeOutQuart,
            child: Text(
              '0:${elapsed.toString().padLeft(2, '0')}',
              style: LoitTypography.displayM.copyWith(
                color: c.contentInverse,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ),
        // Tight to the orb, generous below it: rhythm, not monotone padding.
        const SizedBox(height: LoitSpacing.s7),
        GestureDetector(
          onLongPressStart: (_) => onStart(),
          onLongPressEnd: (_) => onStop(),
          onLongPressCancel: onCancel,
          // Fixed box holds the largest halo/ring so nothing reflows as the
          // orb breathes or reacts to the voice.
          child: SizedBox(
            width: 240,
            height: 240,
            child: Center(
              child: _MicOrb(recording: recording, amplitude: amplitude),
            ),
          ),
        ),
        const SizedBox(height: LoitSpacing.s8),
        AnimatedSwitcher(
          duration: LoitMotion.short,
          child: Text(
            hint,
            key: ValueKey(hint),
            textAlign: TextAlign.center,
            style: LoitTypography.bodyM.copyWith(
              color: c.contentInverse.withValues(alpha: 0.7),
            ),
          ),
        ),
        // Rotating spoken example — teaches that a capture can name a room and
        // trail a note (ADR-0022). Idle only; while recording the hint owns the
        // slot and a changing example would compete with the live orb.
        if (!recording) ...[
          const SizedBox(height: LoitSpacing.s4),
          const _RotatingExample(),
        ],
      ],
    );
  }
}

/// Cycles through a few example utterances under the record hint so the user
/// sees what voice can do (room routing + notes). Fades between them every
/// [_interval]; under reduce-motion it holds the first example, no timer.
class _RotatingExample extends StatefulWidget {
  const _RotatingExample();

  @override
  State<_RotatingExample> createState() => _RotatingExampleState();
}

class _RotatingExampleState extends State<_RotatingExample> {
  static const _interval = Duration(milliseconds: 2500);
  Timer? _timer;
  int _index = 0;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.loitColors;
    final l = context.l10n;
    final examples = [l.voiceExample1, l.voiceExample2, l.voiceExample3];
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    // Start (or stop) cycling based on the current reduce-motion setting —
    // build runs on the setting flipping mid-session, so reconcile here.
    if (reduceMotion) {
      _timer?.cancel();
      _timer = null;
    } else {
      _timer ??= Timer.periodic(_interval, (_) {
        if (mounted) setState(() => _index = (_index + 1) % examples.length);
      });
    }

    final text = Text(
      examples[_index % examples.length],
      key: ValueKey(_index),
      textAlign: TextAlign.center,
      style: LoitTypography.bodyS.copyWith(
        color: c.contentInverse.withValues(alpha: 0.55),
        fontStyle: FontStyle.italic,
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: LoitSpacing.s6),
      child: reduceMotion
          ? text
          : AnimatedSwitcher(duration: LoitMotion.base, child: text),
    );
  }
}

/// The capture hero. At rest it breathes with a slow expanding halo — the same
/// living quality as the Scan FAB — to invite the hold. While recording, a ring
/// tracks the mic amplitude so the user sees their voice land.
class _MicOrb extends StatefulWidget {
  const _MicOrb({required this.recording, required this.amplitude});

  final bool recording;
  final double amplitude;

  @override
  State<_MicOrb> createState() => _MicOrbState();
}

class _MicOrbState extends State<_MicOrb> with SingleTickerProviderStateMixin {
  late final AnimationController _idle = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..repeat();

  @override
  void dispose() {
    _idle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.loitColors;
    final core = Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: c.brand,
        boxShadow: [
          BoxShadow(
            color: c.brand.withValues(alpha: 0.4),
            blurRadius: 28,
            spreadRadius: widget.recording ? 6 : 2,
          ),
        ],
      ),
      child: Icon(
        widget.recording ? Icons.mic : Icons.mic_none_rounded,
        color: Colors.white,
        size: 40,
      ),
    );

    if (widget.recording) {
      final ring = 150.0 + widget.amplitude * 78;
      return Stack(
        alignment: Alignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            curve: LoitMotion.easeOutQuart,
            width: ring,
            height: ring,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: c.brand.withValues(alpha: 0.14 + widget.amplitude * 0.12),
            ),
          ),
          core,
        ],
      );
    }

    if (MediaQuery.of(context).disableAnimations) return core;

    return AnimatedBuilder(
      animation: _idle,
      builder: (_, __) {
        final t = _idle.value;
        final breathe = 1 + 0.03 * math.sin(t * 2 * math.pi);
        final halo = 96 + 96 * Curves.easeOut.transform(t);
        return Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: halo,
              height: halo,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: c.brand.withValues(alpha: (1 - t) * 0.16),
              ),
            ),
            Transform.scale(scale: breathe, child: core),
          ],
        );
      },
    );
  }
}

/// Shared scaffold for the three terminal states — permission denied, room not
/// found, parse error. Each is an icon, a middle block, and a single action;
/// the icon scales in and the button trails it so the state lands with intent
/// rather than snapping into place. (Permission denied: a dead mic-hold UI on a
/// single-purpose screen would be dishonest, so we show this instead.)
class _MessageView extends StatelessWidget {
  const _MessageView({
    required this.icon,
    required this.children,
    required this.buttonLabel,
    required this.onPressed,
  });

  final IconData icon;
  final List<Widget> children;
  final String buttonLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final c = context.loitColors;
    return Padding(
      padding: const EdgeInsets.all(LoitSpacing.s6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          LoitScaleIn(
            from: 0.8,
            child: Icon(
              icon,
              color: c.contentInverse.withValues(alpha: 0.7),
              size: 48,
            ),
          ),
          const SizedBox(height: LoitSpacing.s5),
          ...children,
          const SizedBox(height: LoitSpacing.s7),
          LoitFadeSlideIn(
            delay: const Duration(milliseconds: 120),
            child: LoitButton.primary(label: buttonLabel, onPressed: onPressed),
          ),
        ],
      ),
    );
  }
}

class _Processing extends StatelessWidget {
  const _Processing({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.loitColors;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircularProgressIndicator(color: c.brand),
        const SizedBox(height: LoitSpacing.s5),
        Text(
          label,
          style: LoitTypography.bodyM.copyWith(color: c.contentInverse),
        ),
      ],
    );
  }
}

