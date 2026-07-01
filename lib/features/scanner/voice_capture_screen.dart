import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../../core/config/pricing_constants.dart';
import '../../core/services/dummy_payment_service.dart';
import '../../core/services/log_service.dart';
import '../../core/services/scanner_service.dart';
import '../../core/theme/loit_colors.dart';
import '../../core/theme/loit_spacing.dart';
import '../../core/theme/loit_typography.dart';
import '../../shared/providers/accounts_provider.dart';
import '../../shared/providers/room_accounts_provider.dart';
import '../../shared/providers/room_providers.dart';
import '../../shared/providers/services_providers.dart';
import '../../shared/providers/transactions_provider.dart';
import '../../shared/widgets/loit_button.dart';
import '../../shared/widgets/loit_sheet.dart';
import '../../l10n/l10n_x.dart';
import '../transactions/notes_breakdown.dart';

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

enum _VoicePhase { idle, recording, processing, error, roomNotFound }

class _VoiceCaptureScreenState extends ConsumerState<VoiceCaptureScreen> {
  static const _tag = 'VoiceCaptureScreen';
  static const _maxDuration = Duration(seconds: 60);
  static const _minMillis = 800; // too-short release → discard, no charge

  final _recorder = AudioRecorder();
  _VoicePhase _phase = _VoicePhase.idle;
  String? _transcript; // what was heard, shown on a failed parse
  String? _notFoundRoom; // room named in speech but not a member (parity)
  DateTime? _startedAt;
  double _amplitude = 0; // 0..1 normalized
  int _elapsed = 0; // seconds

  Timer? _ticker;
  StreamSubscription<Amplitude>? _ampSub;

  @override
  void dispose() {
    _ticker?.cancel();
    _ampSub?.cancel();
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    if (_phase == _VoicePhase.processing) return;
    if (!await _recorder.hasPermission()) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.voiceMicDenied)));
      return;
    }
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

  /// High-trust direct commit. Mirrors `scan_review_screen._save`: merchant +
  /// items fold into the notes breakdown (with the parser's raw `notes` as the
  /// fallback, since voice often has only that), then `addTransaction`. On
  /// success land on the detail screen with the context-aware list underneath,
  /// so back reveals where the row lives. `date` is intentionally omitted — the
  /// table has no date column; `created_at` carries the timestamp.
  Future<void> _commit(
    Map<String, dynamic> p,
    String accountId,
    String? roomId, {
    String? routedRoomName,
  }) async {
    final merchant = (p['merchant'] as String?)?.trim() ?? '';
    final itemsRaw = (p['items'] as List?) ?? const [];
    final breakdownItems = <NotesBreakdownItem>[
      for (final it in itemsRaw.whereType<Map>())
        NotesBreakdownItem(
          name: (it['name'] as String?) ?? '',
          qty: (it['qty'] as num?)?.toDouble(),
          unitPrice: (it['unit_price'] as num?)?.toDouble(),
          totalPrice: (it['total_price'] as num?)?.toDouble(),
        ),
    ];
    final currency = (p['currency'] as String?) ?? 'IDR';
    final breakdownText = (merchant.isEmpty && breakdownItems.isEmpty)
        ? null
        : formatBreakdown(
            NotesBreakdown(
              merchant: merchant,
              items: breakdownItems,
              total: (p['total'] as num?)?.toDouble(),
              currency: currency,
            ),
          ).trim();
    final rawNotes = (p['notes'] as String?)?.trim();
    final notesText = (breakdownText != null && breakdownText.isNotEmpty)
        ? breakdownText
        : (rawNotes != null && rawNotes.isNotEmpty ? rawNotes : null);

    try {
      final insertedId = await ref
          .read(transactionsProvider.notifier)
          .addTransaction({
            'type': p['type'] ?? 'expense',
            'amount': p['total'],
            'currency': currency,
            if (notesText != null && notesText.isNotEmpty) 'notes': notesText,
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

  // ponytail: small top-up sheet inlined rather than extracting scanner's
  // private _QuotaExceededSheet. Promote to a shared widget if a 3rd surface
  // needs it.
  Future<void> _showQuotaSheet() async {
    final l = context.l10n;
    await showLoitSheet<void>(
      context,
      builder: (sheetCtx) => LoitSheet(
        title: l.scanLimitReached,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(LoitSpacing.s4),
            child: LoitButton.primary(
              label: l.scanTopUpPrice,
              onPressed: () async {
                Navigator.pop(sheetCtx);
                final pay = ref.read(paymentServiceProvider);
                if (pay is DummyPaymentService) pay.bindContext(context);
                try {
                  await pay.purchaseOneTime(PricingConstants.skuScanTopUp);
                } catch (_) {}
              },
            ),
          ),
        ),
      ),
    );
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
        child: Center(
          child: switch (_phase) {
            _VoicePhase.processing => _Processing(label: l.voiceProcessing),
            _VoicePhase.roomNotFound => _RoomNotFoundView(
              room: _notFoundRoom ?? '',
              transcript: _transcript,
              rooms: (ref.watch(activeRoomsProvider).value ?? const [])
                  .map((r) => r['name'] as String? ?? '')
                  .where((n) => n.isNotEmpty)
                  .toList(),
              onRetry: () => setState(() => _phase = _VoicePhase.idle),
            ),
            _VoicePhase.error => _ErrorView(
              message: l.voiceError,
              transcript: _transcript,
              heardLabel: l.voiceHeard,
              onRetry: () => setState(() => _phase = _VoicePhase.idle),
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
    final ringSize = 140.0 + (recording ? amplitude * 80 : 0);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (recording)
          Text(
            '0:${elapsed.toString().padLeft(2, '0')}',
            style: LoitTypography.displayM.copyWith(color: c.contentInverse),
          ),
        const SizedBox(height: LoitSpacing.s6),
        GestureDetector(
          onLongPressStart: (_) => onStart(),
          onLongPressEnd: (_) => onStop(),
          onLongPressCancel: onCancel,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            width: ringSize,
            height: ringSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: recording
                  ? c.brand.withValues(alpha: 0.18)
                  : c.muted.withValues(alpha: 0.12),
            ),
            child: Center(
              child: Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: c.brand,
                ),
                child: Icon(
                  recording ? Icons.mic : Icons.mic_none_rounded,
                  color: Colors.white,
                  size: 40,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: LoitSpacing.s6),
        Text(
          hint,
          textAlign: TextAlign.center,
          style: LoitTypography.bodyM.copyWith(
            color: c.contentInverse.withValues(alpha: 0.7),
          ),
        ),
      ],
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

/// Parity with the Telegram bot's room-not-found reply (ADR-0022 amendment):
/// the transcript addressed a room the user isn't a member of. Inform-only — no
/// "log as personal" escape, matching the bot 1:1.
class _RoomNotFoundView extends StatelessWidget {
  const _RoomNotFoundView({
    required this.room,
    required this.rooms,
    required this.onRetry,
    this.transcript,
  });
  final String room;
  final List<String> rooms;
  final String? transcript;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final c = context.loitColors;
    final l = context.l10n;
    final heard = transcript?.trim();
    return Padding(
      padding: const EdgeInsets.all(LoitSpacing.s6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.meeting_room_outlined,
            color: c.contentInverse.withValues(alpha: 0.7),
            size: 48,
          ),
          const SizedBox(height: LoitSpacing.s5),
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
          const SizedBox(height: LoitSpacing.s6),
          LoitButton.primary(
            label: MaterialLocalizations.of(context).okButtonLabel,
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({
    required this.message,
    required this.onRetry,
    required this.heardLabel,
    this.transcript,
  });
  final String message;
  final String heardLabel;
  final String? transcript;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final c = context.loitColors;
    final heard = transcript?.trim();
    return Padding(
      padding: const EdgeInsets.all(LoitSpacing.s6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline,
            color: c.contentInverse.withValues(alpha: 0.7),
            size: 48,
          ),
          const SizedBox(height: LoitSpacing.s5),
          Text(
            message,
            textAlign: TextAlign.center,
            style: LoitTypography.bodyM.copyWith(color: c.contentInverse),
          ),
          if (heard != null && heard.isNotEmpty) ...[
            const SizedBox(height: LoitSpacing.s5),
            Text(
              heardLabel,
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
          const SizedBox(height: LoitSpacing.s6),
          LoitButton.primary(
            label: MaterialLocalizations.of(context).okButtonLabel,
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}
