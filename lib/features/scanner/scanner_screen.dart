import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/config/pricing_constants.dart';
import '../../core/services/analytics_service.dart';
import '../../core/services/dummy_payment_service.dart';
import '../../core/services/interaction_log_service.dart';
import '../../core/services/log_service.dart';
import '../../core/services/scanner_service.dart';
import '../../core/theme/loit_colors.dart';
import '../../core/theme/loit_radius.dart';
import '../../core/theme/loit_spacing.dart';
import '../../core/theme/loit_typography.dart';
import '../../shared/providers/accounts_provider.dart';
import '../../shared/providers/auth_providers.dart';
import '../../shared/providers/room_providers.dart';
import '../../shared/providers/services_providers.dart';
import '../../shared/providers/preferences_provider.dart';
import '../../shared/providers/user_categories_provider.dart';
import 'scan_review_screen.dart';
import '../../shared/utils/invite_token.dart';
import '../../shared/widgets/loit_banner.dart';
import '../../shared/widgets/loit_button.dart';
import '../../shared/widgets/loit_sheet.dart';
import '../paywall/paywall_screen.dart';
import '../../l10n/l10n_x.dart';

/// LOIT scanner flow.
///
/// Single screen with state machine:
///   - capture (dark camera viewport with frame guide)
///   - processing (shimmer skeleton + progress)
///   - error (retry / cancel)
///
/// Confirm step routes to `/transactions/new` (Phase 2 C form).
/// Success surfaces via form's save snackbar.
class ScannerScreen extends ConsumerStatefulWidget {
  const ScannerScreen({super.key, this.roomId});

  /// When non-null, scanner is locked to a specific room: the toggle is
  /// preselected to Rooms and disabled, and the post-scan room picker
  /// is bypassed.
  final String? roomId;

  @override
  ConsumerState<ScannerScreen> createState() => _ScannerScreenState();
}

enum _ScanPhase { capture, processing, error }

class _ScannerScreenState extends ConsumerState<ScannerScreen> {
  static const _tag = 'ScannerScreen';
  final _picker = ImagePicker();
  _ScanPhase _phase = _ScanPhase.capture;
  String? _errorKind;
  File? _lastFile;

  CameraController? _camCtrl;
  bool _camReady = false;

  /// When true, scanned receipt is routed to a room. The user picks which
  /// room after the scan completes (rooms vary, can't pre-select reliably).
  bool _useRoom = false;

  // QR detection state. ML Kit scanner runs on the camera image stream in
  // parallel with the shutter capture path. Only LOIT room-invite QR codes
  // surface UI; everything else is silently ignored.
  late final BarcodeScanner _barcodeScanner =
      BarcodeScanner(formats: [BarcodeFormat.qrCode]);
  bool _qrStreamRunning = false;
  bool _capturing = false;
  bool _joinSheetOpen = false;
  String? _lastSeenInviteToken;
  DateTime _lastSeenInviteAt = DateTime.fromMillisecondsSinceEpoch(0);
  DateTime _lastBarcodeProcessAt = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void initState() {
    super.initState();
    if (widget.roomId != null) _useRoom = true;
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        Log.w(_tag, 'No cameras available');
        return;
      }
      final back = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      // NV21 on Android lets ML Kit consume image-stream frames directly.
      // takePicture() still returns JPEG regardless of this flag.
      final ctrl = CameraController(back, ResolutionPreset.high,
          enableAudio: false,
          imageFormatGroup: Platform.isAndroid
              ? ImageFormatGroup.nv21
              : ImageFormatGroup.bgra8888);
      await ctrl.initialize();
      if (!mounted) {
        await ctrl.dispose();
        return;
      }
      setState(() {
        _camCtrl = ctrl;
        _camReady = true;
      });
      Log.i(_tag, 'Camera ready: ${back.name}');
      await _startQrStream();
    } catch (e, st) {
      Log.e(_tag, 'Camera init failed', error: e, stack: st);
    }
  }

  Future<void> _startQrStream() async {
    if (_qrStreamRunning || _camCtrl == null) return;
    try {
      await _camCtrl!.startImageStream(_onCameraImage);
      _qrStreamRunning = true;
      Log.d(_tag, 'QR image stream started');
    } catch (e) {
      Log.w(_tag, 'startImageStream failed', error: e);
    }
  }

  Future<void> _stopQrStream() async {
    if (!_qrStreamRunning || _camCtrl == null) return;
    try {
      await _camCtrl!.stopImageStream();
    } catch (_) {}
    _qrStreamRunning = false;
  }

  /// ML Kit frame callback. Throttled to ~3 fps. Only LOIT invite QR codes
  /// trigger UI; non-invite payloads are dropped.
  Future<void> _onCameraImage(CameraImage image) async {
    if (!mounted || _capturing || _joinSheetOpen) return;
    final now = DateTime.now();
    if (now.difference(_lastBarcodeProcessAt).inMilliseconds < 300) return;
    _lastBarcodeProcessAt = now;

    final input = _toInputImage(image);
    if (input == null) return;
    try {
      final barcodes = await _barcodeScanner.processImage(input);
      for (final b in barcodes) {
        final raw = b.rawValue;
        if (raw == null || raw.isEmpty) continue;
        if (!isLoitInviteUrl(raw)) continue;
        final token = extractInviteToken(raw);
        if (token == null || token.isEmpty) continue;
        // Debounce same payload after dismissal so a held-up QR doesn't
        // re-prompt on every frame.
        if (token == _lastSeenInviteToken &&
            now.difference(_lastSeenInviteAt).inSeconds < 5) {
          continue;
        }
        _lastSeenInviteToken = token;
        _lastSeenInviteAt = now;
        if (!mounted) return;
        _joinSheetOpen = true;
        await _stopQrStream();
        await _showJoinSheet(token);
        _joinSheetOpen = false;
        if (mounted && _phase == _ScanPhase.capture) {
          await _startQrStream();
        }
        return;
      }
    } catch (e) {
      // Frame conversion or ML Kit error — drop and continue.
    }
  }

  InputImage? _toInputImage(CameraImage image) {
    if (_camCtrl == null) return null;
    final WriteBuffer buf = WriteBuffer();
    for (final plane in image.planes) {
      buf.putUint8List(plane.bytes);
    }
    final bytes = buf.done().buffer.asUint8List();
    final size = Size(image.width.toDouble(), image.height.toDouble());
    final sensor = _camCtrl!.description.sensorOrientation;
    final rotation = InputImageRotationValue.fromRawValue(sensor) ??
        InputImageRotation.rotation90deg;
    final format = InputImageFormatValue.fromRawValue(image.format.raw) ??
        (Platform.isAndroid
            ? InputImageFormat.nv21
            : InputImageFormat.bgra8888);
    return InputImage.fromBytes(
      bytes: bytes,
      metadata: InputImageMetadata(
        size: size,
        rotation: rotation,
        format: format,
        bytesPerRow: image.planes.first.bytesPerRow,
      ),
    );
  }

  Future<void> _showJoinSheet(String token) async {
    await showLoitSheet<void>(
      context,
      builder: (sheetCtx) => _InviteJoinSheet(
        token: token,
        onJoin: () => _acceptInvite(sheetCtx, token),
        onCancel: () => Navigator.of(sheetCtx).pop(),
      ),
    );
  }

  Future<void> _acceptInvite(BuildContext sheetCtx, String token) async {
    final l = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    final sheetNav = Navigator.of(sheetCtx);
    try {
      final roomId =
          await ref.read(roomServiceProvider).acceptInvite(token);
      Analytics.roomJoined();
      InteractionLog.success(
        action: 'room_joined',
        screen: 'scanner_qr',
        message: '$roomId',
      );
      ref.invalidate(myRoomsProvider);
      ref.invalidate(pendingInvitesProvider);
      ref.invalidate(userCategoriesProvider);
      if (roomId != null) ref.invalidate(roomDetailProvider(roomId));
      if (!mounted) return;
      if (sheetNav.canPop()) sheetNav.pop();
      if (roomId != null) {
        router.pushReplacement('/rooms/$roomId');
      } else {
        messenger.showSnackBar(
          SnackBar(content: Text(l.scanInviteInvalid)),
        );
      }
    } catch (e) {
      InteractionLog.error(
        action: 'room_join',
        screen: 'scanner_qr',
        message: '$e',
      );
      if (!mounted) return;
      if (sheetNav.canPop()) sheetNav.pop();
      messenger.showSnackBar(
        SnackBar(content: Text(l.scanCouldNotJoinRoom(e.toString()))),
      );
    }
  }

  @override
  void dispose() {
    _stopQrStream();
    _barcodeScanner.close();
    _camCtrl?.dispose();
    super.dispose();
  }

  Future<void> _captureFromCamera() async {
    _capturing = true;
    await _stopQrStream();
    if (_camReady && _camCtrl != null) {
      try {
        Log.d(_tag, 'Taking picture via CameraController');
        final xfile = await _camCtrl!.takePicture();
        await _scan(File(xfile.path));
        return;
      } catch (e) {
        Log.w(_tag, 'CameraController capture failed, falling back to picker', error: e);
      } finally {
        _capturing = false;
      }
    }
    Log.d(_tag, 'Using image_picker fallback for camera capture');
    final x = await _picker.pickImage(source: ImageSource.camera, imageQuality: 95);
    if (x == null) return;
    await _scan(File(x.path));
  }

  Future<void> _pickAndScan(ImageSource source) async {
    final x = await _picker.pickImage(source: source, imageQuality: 95);
    if (x == null) return;
    await _scan(File(x.path));
  }

  Future<void> _scan(File file) async {
    setState(() {
      _phase = _ScanPhase.processing;
      _errorKind = null;
      _lastFile = file;
    });
    Log.i(_tag, 'Scan started: ${file.path}');
    await Analytics.scanStarted();

    // Step 2 — preprocess (1600px JPEG q85 grayscale).
    final preprocessor = ref.read(scanPreprocessorProvider);
    final pp = await preprocessor.process(file);
    await Analytics.scanPreprocessed(
      durationMs: pp.durationMs,
      origBytes: pp.origBytes,
      processedBytes: pp.bytes.length,
    );

    // Step 3 — quality gate (blur / brightness / aspect).
    final gate = ref.read(scanQualityGateProvider);
    final q = await gate.check(pp.bytes);
    if (!q.ok) {
      if (!mounted) return;
      await Analytics.scanQualityGateFailed(q.reasonKey);
      setState(() {
        _errorKind = 'quality_${q.reasonKey}';
        _phase = _ScanPhase.error;
      });
      return;
    }

    // Step 4 — rate limit (10/60s) + client-side quota check.
    final limiter = ref.read(scanRateLimiterProvider);
    if (!await limiter.tryConsume()) {
      if (!mounted) return;
      await Analytics.scanFailed('rate_limited');
      setState(() {
        _errorKind = 'rate_limited';
        _phase = _ScanPhase.error;
      });
      return;
    }
    final profile = ref.read(userProfileProvider).value;
    final quota = profile?.scanQuota;
    final used = profile?.scansUsedThisMonth ?? 0;
    if (quota != null && used >= quota) {
      if (!mounted) return;
      await Analytics.scanFailed('quota_exceeded');
      await Analytics.scanTopupPromptShown();
      setState(() => _phase = _ScanPhase.capture);
      await _showQuotaSheet();
      return;
    }

    final compressed = pp.file;
    final scanner = ref.read(scannerServiceProvider);
    final userCats = ref.read(userCategoriesProvider).value ?? [];
    // Scope categories strictly to the active context: room scan → only that
    // room's categories; personal scan → personal only. Cross-context cats
    // are noise and would let the AI pick a label the txn can't actually use.
    final scopedCats = widget.roomId != null
        ? userCats.where((c) => c.roomId == widget.roomId).toList()
        : userCats.where((c) => c.isPersonal).toList();
    final catList = scopedCats
        .map((c) => {'key': c.key, 'name': c.name, 'kind': c.kind})
        .toList();
    final activeAccounts = (ref.read(accountsProvider).value ?? const [])
        .where((a) => a.archivedAt == null)
        .map((a) => a.name)
        .toList(growable: false);
    Log.d(_tag,
        'Sending to scan-receipt (cats=${catList.length}, accts=${activeAccounts.length}, roomScoped=${widget.roomId != null})');
    // Rough token estimate: image vision tokens scale ~ pixels/750; static
    // prompt + dynamic ~ 700 tokens. Good enough for PostHog histograms.
    await Analytics.scanApiCalled(
      imageBytes: pp.bytes.length,
      promptTokensEst: 700 + (1600 * 1600 ~/ 750),
    );
    final result = await scanner.scanReceipt(
      compressed,
      categories: catList.isNotEmpty ? catList : null,
      accountNames: activeAccounts.isNotEmpty ? activeAccounts : null,
    );

    if (!mounted) return;

    final bucket = bucketFor(result.confidence).name;
    await Analytics.scanApiReturned(
      isTransaction: result.errorType != ScanErrorType.notATransaction,
      transactionKind: result.parsedData?['transaction_kind'] as String?,
      confidenceBucket: bucket,
    );
    if (result.reconciliationWarning) {
      await Analytics.scanReconciliationWarning();
    }

    // Resolve room target. When scanner is locked to a room (opened from
    // RoomDetail), use that id directly — skip picker. Otherwise prompt.
    String? roomId;
    if (widget.roomId != null) {
      roomId = widget.roomId;
    } else if (_useRoom) {
      final picked = await _pickRoom();
      if (picked == null) {
        if (mounted) setState(() => _phase = _ScanPhase.capture);
        return;
      }
      roomId = picked;
    }

    switch (result.errorType) {
      case null:
        final data = Map<String, dynamic>.from(result.parsedData ?? {});
        if (!mounted) return;
        Log.i(_tag, 'Scan success → ScanReviewScreen');
        final prefs = ref.read(preferencesProvider).value;
        final reviewData = ScanReviewData(
          parsed: data,
          imagePath: compressed.path,
          confidence: result.confidence,
          roomId: roomId,
          reconciliationWarning: result.reconciliationWarning,
          totalComputed: result.totalComputed,
          autoConfirmEnabled: prefs?.scanAutoConfirm ?? true,
        );
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => ScanReviewScreen(scan: reviewData),
          ),
        );
        break;
      case ScanErrorType.aiFailure:
        final data = Map<String, dynamic>.from(result.partialFields ?? {});
        if (roomId != null) data['_room_id'] = roomId;
        // Raise bar: only show manual-fallback banner when nothing useful was
        // recovered. If total>0 or items present, treat as best-effort parse.
        final totalRaw = data['total'];
        final totalNum = totalRaw is num
            ? totalRaw.toDouble()
            : double.tryParse('${totalRaw ?? ''}');
        final hasItems = data['items'] is List &&
            (data['items'] as List).isNotEmpty;
        final hasUsable = (totalNum != null && totalNum > 0) || hasItems;
        if (hasUsable) {
          Log.w(_tag, 'AI partial parse → treat as ai_parsed');
          await Analytics.scanFailed('ai_failure_partial');
          data['_ai_parsed'] = true;
          data['_source'] = 'scanned';
        } else {
          Log.w(_tag, 'AI parse failure → manual fallback');
          await Analytics.scanFailed('ai_failure');
          data['_manual_fallback'] = true;
          data['_source'] = 'manual';
        }
        data['_image_path'] = compressed.path;
        if (!mounted) return;
        context.pushReplacement('/transactions/new', extra: data);
        break;
      case ScanErrorType.quotaExceeded:
        Log.w(_tag, 'Quota exceeded → showing top-up sheet');
        await Analytics.scanFailed('quota_exceeded');
        await Analytics.scanTopupPromptShown();
        if (!mounted) return;
        setState(() => _phase = _ScanPhase.capture);
        await _showQuotaSheet();
        break;
      case ScanErrorType.connectionError:
        Log.w(_tag, 'Connection error → error view');
        await Analytics.scanFailed('connection_error');
        setState(() {
          _errorKind = 'connection';
          _phase = _ScanPhase.error;
        });
        break;
      case ScanErrorType.serverError:
        Log.w(_tag, 'Server error → error view');
        await Analytics.scanFailed('server_error');
        setState(() {
          _errorKind = 'server';
          _phase = _ScanPhase.error;
        });
        break;
      case ScanErrorType.notATransaction:
        Log.w(_tag, 'Not a transaction: ${result.notATransactionReason}');
        await Analytics.scanFailed('not_a_transaction');
        setState(() {
          _errorKind = 'not_transaction';
          _phase = _ScanPhase.error;
        });
        break;
      case ScanErrorType.rateLimited:
        Log.w(_tag, 'Rate-limited');
        await Analytics.scanFailed('rate_limited');
        setState(() {
          _errorKind = 'rate_limited';
          _phase = _ScanPhase.error;
        });
        break;
      case ScanErrorType.qualityGate:
        Log.w(_tag, 'Quality gate failed: ${result.notATransactionReason}');
        await Analytics.scanFailed('quality_gate');
        setState(() {
          _errorKind = 'quality_${result.notATransactionReason ?? 'unknown'}';
          _phase = _ScanPhase.error;
        });
        break;
    }
  }

  /// Bottom sheet — list rooms, return selected room id or null on cancel.
  Future<String?> _pickRoom() async {
    final l = context.l10n;
    final rooms = await ref.read(myRoomsProvider.future);
    if (!mounted) return null;
    if (rooms.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.scanNoRooms)),
      );
      return null;
    }
    return showLoitSheet<String>(
      context,
      builder: (sheetCtx) => LoitSheet(
        title: l.scanSendToRoom,
        child: SafeArea(
          top: false,
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: rooms.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final r = rooms[i];
              final id = r['id'] as String;
              final name = (r['name'] as String?) ?? l.scanRoom;
              return ListTile(
                leading: const Icon(Icons.group_outlined),
                title: Text(name),
                onTap: () => Navigator.pop(sheetCtx, id),
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _showQuotaSheet() async {
    final l = context.l10n;
    await showLoitSheet<void>(
      context,
      builder: (_) => LoitSheet(
        title: l.scanLimitReached,
        child: _QuotaExceededSheet(onTopUp: _handleTopUp),
      ),
    );
  }

  Future<void> _handleTopUp() async {
    if (!mounted) return;
    final pay = ref.read(paymentServiceProvider);
    if (pay is DummyPaymentService) pay.bindContext(context);
    try {
      await pay.purchaseOneTime(PricingConstants.skuScanTopUp);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return switch (_phase) {
      _ScanPhase.capture => _CaptureView(
          onCamera: _captureFromCamera,
          onGallery: () => _pickAndScan(ImageSource.gallery),
          onClose: () => context.pop(),
          cameraController: _camReady ? _camCtrl : null,
          useRoom: _useRoom,
          lockedToRoom: widget.roomId != null,
          onUseRoomChanged: (v) => setState(() => _useRoom = v),
        ),
      _ScanPhase.processing => const _ProcessingView(),
      _ScanPhase.error => _ErrorView(
          kind: _errorKind!,
          onRetry: _lastFile == null ? null : () => _scan(_lastFile!),
          onCancel: () => setState(() => _phase = _ScanPhase.capture),
        ),
    };
  }
}

class _CaptureView extends StatelessWidget {
  const _CaptureView({
    required this.onCamera,
    required this.onGallery,
    required this.onClose,
    required this.useRoom,
    required this.onUseRoomChanged,
    this.lockedToRoom = false,
    this.cameraController,
  });
  final VoidCallback onCamera;
  final VoidCallback onGallery;
  final VoidCallback onClose;
  final bool useRoom;
  final ValueChanged<bool> onUseRoomChanged;
  final bool lockedToRoom;
  final CameraController? cameraController;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final size = MediaQuery.sizeOf(context);
    final isLandscape = size.width > size.height;
    final isBigScreen = size.shortestSide >= 600;
    // On phone portrait, fill the screen (cover) — natural fullscreen camera
    // UX. On landscape or tablet/large screens, letterbox so the preview
    // keeps its native aspect ratio with black bars on the sides.
    final previewFit =
        (isLandscape || isBigScreen) ? BoxFit.contain : BoxFit.cover;
    return Scaffold(
      backgroundColor: const Color(0xFF0A0C0B),
      body: Stack(
        children: [
          if (cameraController != null)
            SizedBox.expand(
              child: FittedBox(
                fit: previewFit,
                child: SizedBox(
                  width: cameraController!.value.previewSize!.height,
                  height: cameraController!.value.previewSize!.width,
                  child: CameraPreview(cameraController!),
                ),
              ),
            )
          else
            const SizedBox.expand(child: ColoredBox(color: Color(0xFF0A0C0B))),
          SafeArea(
            child: Stack(
              children: [
            // Top bar
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.all(LoitSpacing.s3),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _CircleButton(icon: Icons.close, onTap: onClose),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: LoitSpacing.s3,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xCC0F6E5C),
                        borderRadius: LoitRadius.brFull,
                      ),
                      child: Text(
                        l.scanReceipt,
                        style: LoitTypography.labelS.copyWith(
                          color: Colors.white,
                          letterSpacing: 0.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 36),
                  ],
                ),
              ),
            ),
            // Frame guide
            Positioned.fill(
              top: 80,
              bottom: 280,
              left: 30,
              right: 30,
              child: const _FrameGuide(),
            ),
            // Bottom controls (toggle above shutter row)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  LoitSpacing.s5,
                  LoitSpacing.s4,
                  LoitSpacing.s5,
                  LoitSpacing.s6,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _TargetToggle(
                      useRoom: useRoom,
                      onChanged: onUseRoomChanged,
                      locked: lockedToRoom,
                    ),
                    const SizedBox(height: LoitSpacing.s5),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _CircleButton(
                          icon: Icons.photo_library_outlined,
                          onTap: onGallery,
                          size: 48,
                          iconSize: 22,
                        ),
                        GestureDetector(
                          onTap: onCamera,
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.4),
                                width: 4,
                              ),
                            ),
                            child: Container(
                              margin: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        _CircleButton(
                          icon: Icons.edit_outlined,
                          onTap: () => onCamera,
                          size: 48,
                          iconSize: 22,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
          ),
        ],
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({
    required this.icon,
    required this.onTap,
    this.size = 36,
    this.iconSize = 20,
  });
  final IconData icon;
  final VoidCallback onTap;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black.withValues(alpha: 0.4),
        ),
        child: Icon(icon, size: iconSize, color: Colors.white),
      ),
    );
  }
}

class _FrameGuide extends StatelessWidget {
  const _FrameGuide();

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.85),
              width: 2,
            ),
            borderRadius: LoitRadius.brL,
          ),
        ),
        for (final corner in _corners) Positioned(
          top: corner.top,
          bottom: corner.bottom,
          left: corner.left,
          right: corner.right,
          child: CustomPaint(
            size: const Size(24, 24),
            painter: _CornerPainter(
              tl: corner.tl, tr: corner.tr, bl: corner.bl, br: corner.br,
            ),
          ),
        ),
        Center(
          child: Text(
            l.scanAlignHint,
            style: TextStyle(
              color: Color(0xD9FFFFFF),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _Corner {
  const _Corner({this.top, this.bottom, this.left, this.right,
    this.tl = false, this.tr = false, this.bl = false, this.br = false});
  final double? top, bottom, left, right;
  final bool tl, tr, bl, br;
}

const _corners = [
  _Corner(top: -2, left: -2, tl: true),
  _Corner(top: -2, right: -2, tr: true),
  _Corner(bottom: -2, left: -2, bl: true),
  _Corner(bottom: -2, right: -2, br: true),
];

class _TargetToggle extends StatelessWidget {
  const _TargetToggle({
    required this.useRoom,
    required this.onChanged,
    this.locked = false,
  });
  final bool useRoom;
  final ValueChanged<bool> onChanged;

  /// When true, the toggle is fixed to Rooms — Personal is greyed out and
  /// not tappable. Used when scanner is opened from a room context.
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: LoitRadius.brFull,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.18),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(5),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _segment(
              icon: Icons.person_outline,
              label: l.scanPersonal,
              selected: !useRoom,
              disabled: locked,
              onTap: locked ? null : () => onChanged(false)),
          _segment(
              icon: Icons.group_outlined,
              label: l.scanRooms,
              selected: useRoom,
              disabled: false,
              onTap: locked ? null : () => onChanged(true)),
        ],
      ),
    );
  }

  Widget _segment({
    required IconData icon,
    required String label,
    required bool selected,
    required bool disabled,
    required VoidCallback? onTap,
  }) {
    final fg = disabled
        ? Colors.white.withValues(alpha: 0.35)
        : (selected ? Colors.black : Colors.white);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: selected
            ? (disabled
                ? Colors.white.withValues(alpha: 0.25)
                : Colors.white)
            : Colors.transparent,
        borderRadius: LoitRadius.brFull,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: LoitRadius.brFull,
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: LoitSpacing.s5, vertical: LoitSpacing.s3),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 20, color: fg),
                const SizedBox(width: LoitSpacing.s2),
                Text(
                  label,
                  style: LoitTypography.bodyM.copyWith(
                    color: fg,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  _CornerPainter({required this.tl, required this.tr, required this.bl, required this.br});
  final bool tl, tr, bl, br;
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = const Color(0xFFF5BC6D)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;
    if (tl || tr) canvas.drawLine(const Offset(0, 0), Offset(size.width, 0), p);
    if (bl || br) canvas.drawLine(Offset(0, size.height), Offset(size.width, size.height), p);
    if (tl || bl) canvas.drawLine(const Offset(0, 0), Offset(0, size.height), p);
    if (tr || br) canvas.drawLine(Offset(size.width, 0), Offset(size.width, size.height), p);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ProcessingView extends StatefulWidget {
  const _ProcessingView();
  @override
  State<_ProcessingView> createState() => _ProcessingViewState();
}

class _ProcessingViewState extends State<_ProcessingView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.loitColors;
    final l = context.l10n;
    return Scaffold(
      backgroundColor: c.canvas,
      appBar: AppBar(
        title: Text(l.scanReadingTitle),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {},
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(LoitSpacing.s5),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ReceiptSkeleton(controller: _ctrl),
              const SizedBox(height: LoitSpacing.s6),
              Text(
                l.scanReadingBody,
                style: LoitTypography.titleM.copyWith(color: c.contentPrimary),
              ),
              const SizedBox(height: LoitSpacing.s2),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 260),
                child: Text(
                  l.scanReadingSubtitle,
                  textAlign: TextAlign.center,
                  style: LoitTypography.bodyS.copyWith(color: c.contentSecondary),
                ),
              ),
              const SizedBox(height: LoitSpacing.s5),
              _IndeterminateBar(controller: _ctrl),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReceiptSkeleton extends StatelessWidget {
  const _ReceiptSkeleton({required this.controller});
  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    final c = context.loitColors;
    return Container(
      width: 160,
      height: 220,
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: LoitRadius.brM,
        border: Border.all(color: c.borderDefault),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            offset: const Offset(0, 4),
            blurRadius: 12,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: LoitRadius.brM,
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(LoitSpacing.s3),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SkelLine(width: 100, height: 8, color: c.muted),
                  const SizedBox(height: 8),
                  _SkelLine(width: 70, height: 6, color: c.muted),
                  const SizedBox(height: 14),
                  for (final w in [60.0, 80.0, 70.0, 90.0, 50.0]) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _SkelLine(width: w, height: 5, color: c.muted),
                        _SkelLine(width: 24, height: 5, color: c.muted),
                      ],
                    ),
                    const SizedBox(height: 6),
                  ],
                ],
              ),
            ),
            AnimatedBuilder(
              animation: controller,
              builder: (_, __) => Positioned(
                top: controller.value * 220 - 6,
                left: 0,
                right: 0,
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        c.brand,
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SkelLine extends StatelessWidget {
  const _SkelLine({required this.width, required this.height, required this.color});
  final double width;
  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
    );
  }
}

class _IndeterminateBar extends StatelessWidget {
  const _IndeterminateBar({required this.controller});
  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    final c = context.loitColors;
    return SizedBox(
      width: 200,
      height: 6,
      child: ClipRRect(
        borderRadius: LoitRadius.brFull,
        child: Stack(
          children: [
            Container(color: c.muted),
            AnimatedBuilder(
              animation: controller,
              builder: (_, __) => FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: 0.4,
                child: Transform.translate(
                  offset: Offset(controller.value * 300 - 80, 0),
                  child: Container(color: c.brand),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.kind, this.onRetry, required this.onCancel});
  final String kind;
  final VoidCallback? onRetry;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final c = context.loitColors;
    final l = context.l10n;
    final isOffline = kind == 'connection';
    final isNotTransaction = kind == 'not_transaction';
    final String title;
    final String body;
    final LoitBannerKind bannerKind;
    if (isNotTransaction) {
      title = l.scanNotTransaction;
      body = l.scanNotTransactionBody;
      bannerKind = LoitBannerKind.warning;
    } else if (isOffline) {
      title = l.scanOfflineTitle;
      body = l.scanOfflineBody;
      bannerKind = LoitBannerKind.warning;
    } else {
      title = l.scanUnavailableTitle;
      body = l.scanUnavailableBody;
      bannerKind = LoitBannerKind.error;
    }
    return Scaffold(
      backgroundColor: c.canvas,
      appBar: AppBar(title: Text(l.scanReceiptTitle)),
      body: Padding(
        padding: const EdgeInsets.all(LoitSpacing.s5),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            LoitBanner(
              kind: bannerKind,
              title: title,
              body: body,
            ),
            const SizedBox(height: LoitSpacing.s5),
            // Retrying the same image won't help when it isn't a transaction
            // doc — only offer "Take another photo" which returns to capture.
            LoitButton.primary(
              label: isNotTransaction ? l.scanTakeAnother : l.scanRetry,
              icon: isNotTransaction ? Icons.camera_alt : Icons.refresh,
              onPressed: isNotTransaction ? onCancel : onRetry,
              fullWidth: true,
            ),
            const SizedBox(height: LoitSpacing.s2),
            LoitButton.tertiary(
              label: l.scanCancel,
              onPressed: onCancel,
              fullWidth: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _QuotaExceededSheet extends ConsumerWidget {
  const _QuotaExceededSheet({required this.onTopUp});
  final Future<void> Function() onTopUp;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.loitColors;
    final l = context.l10n;
    final profile = ref.watch(userProfileProvider).value;
    final canTopUp = profile?.canPurchaseScanTopUp ?? true;
    return Padding(
      padding: const EdgeInsets.all(LoitSpacing.s5),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(Icons.lock_outline, size: 48, color: c.brand),
          const SizedBox(height: LoitSpacing.s3),
          Text(
            profile == null
                ? l.scanQuotaDefault
                : l.scanUsedAllScans('${profile.scanQuota ?? '0'}', profile.tier.toUpperCase()),
            textAlign: TextAlign.center,
            style: LoitTypography.bodyM.copyWith(color: c.contentSecondary),
          ),
          const SizedBox(height: LoitSpacing.s5),
          if (canTopUp) ...[
            LoitButton.primary(
              label: l.scanTopUp,
              onPressed: () {
                Navigator.of(context).pop();
                onTopUp();
              },
              fullWidth: true,
            ),
            const SizedBox(height: LoitSpacing.s2),
          ],
          LoitButton.secondary(
            label: l.scanUpgrade,
            onPressed: () {
              Navigator.of(context).pop();
              showPaywallSheet(context, feature: 'more_scan_quota');
            },
            fullWidth: true,
          ),
          const SizedBox(height: LoitSpacing.s2),
          LoitButton.tertiary(
            label: l.scanNotNow,
            onPressed: () => Navigator.of(context).pop(),
            fullWidth: true,
          ),
        ],
      ),
    );
  }
}

class _InviteJoinSheet extends StatefulWidget {
  const _InviteJoinSheet({
    required this.token,
    required this.onJoin,
    required this.onCancel,
  });

  final String token;
  final Future<void> Function() onJoin;
  final VoidCallback onCancel;

  @override
  State<_InviteJoinSheet> createState() => _InviteJoinSheetState();
}

class _InviteJoinSheetState extends State<_InviteJoinSheet> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final c = context.loitColors;
    final l = context.l10n;
    return LoitSheet(
      title: l.scanJoinRoomTitle,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(LoitSpacing.s4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l.scanJoinRoomBody,
                style: LoitTypography.bodyM.copyWith(color: c.contentSecondary),
              ),
              const SizedBox(height: LoitSpacing.s4),
              LoitButton.primary(
                label: _busy ? l.scanJoining : l.scanJoinRoom,
                fullWidth: true,
                onPressed: _busy
                    ? null
                    : () async {
                        setState(() => _busy = true);
                        await widget.onJoin();
                        if (mounted) setState(() => _busy = false);
                      },
              ),
              const SizedBox(height: LoitSpacing.s2),
              LoitButton.tertiary(
                label: l.scanCancel,
                fullWidth: true,
                onPressed: _busy ? null : widget.onCancel,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
