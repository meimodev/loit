import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/config/pricing_constants.dart';
import '../../core/services/analytics_service.dart';
import '../../core/services/dummy_payment_service.dart';
import '../../core/services/scanner_service.dart';
import '../../core/theme/loit_colors.dart';
import '../../core/theme/loit_radius.dart';
import '../../core/theme/loit_spacing.dart';
import '../../core/theme/loit_typography.dart';
import '../../shared/providers/auth_providers.dart';
import '../../shared/providers/services_providers.dart';
import '../../shared/widgets/loit_banner.dart';
import '../../shared/widgets/loit_button.dart';
import '../../shared/widgets/loit_sheet.dart';
import '../paywall/paywall_screen.dart';

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
  const ScannerScreen({super.key});

  @override
  ConsumerState<ScannerScreen> createState() => _ScannerScreenState();
}

enum _ScanPhase { capture, processing, error }

class _ScannerScreenState extends ConsumerState<ScannerScreen> {
  final _picker = ImagePicker();
  _ScanPhase _phase = _ScanPhase.capture;
  String? _errorKind;
  File? _lastFile;

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
    await Analytics.scanStarted();

    final profile = ref.read(userProfileProvider).value;
    final isDemo = profile != null && !profile.hasUsedDemoScan;

    final scanner = ref.read(scannerServiceProvider);
    final compressed = await scanner.compressToFile(file);
    final result = await scanner.scanReceipt(compressed, isDemo: isDemo);

    if (!mounted) return;

    switch (result.errorType) {
      case null:
        final data = Map<String, dynamic>.from(result.parsedData ?? {});
        data['_ai_parsed'] = true;
        data['_image_path'] = compressed.path;
        context.pushReplacement('/transactions/new', extra: data);
        break;
      case ScanErrorType.aiFailure:
        await Analytics.scanFailed('ai_failure');
        final data = Map<String, dynamic>.from(result.partialFields ?? {});
        data['_manual_fallback'] = true;
        data['_image_path'] = compressed.path;
        if (!mounted) return;
        context.pushReplacement('/transactions/new', extra: data);
        break;
      case ScanErrorType.quotaExceeded:
        await Analytics.scanFailed('quota_exceeded');
        await Analytics.scanTopupPromptShown();
        if (!mounted) return;
        setState(() => _phase = _ScanPhase.capture);
        await _showQuotaSheet();
        break;
      case ScanErrorType.connectionError:
        await Analytics.scanFailed('connection_error');
        setState(() {
          _errorKind = 'connection';
          _phase = _ScanPhase.error;
        });
        break;
      case ScanErrorType.serverError:
        await Analytics.scanFailed('server_error');
        setState(() {
          _errorKind = 'server';
          _phase = _ScanPhase.error;
        });
        break;
    }
  }

  Future<void> _showQuotaSheet() async {
    await showLoitSheet<void>(
      context,
      builder: (_) => LoitSheet(
        title: 'Scan limit reached',
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
          onCamera: () => _pickAndScan(ImageSource.camera),
          onGallery: () => _pickAndScan(ImageSource.gallery),
          onClose: () => context.pop(),
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
  });
  final VoidCallback onCamera;
  final VoidCallback onGallery;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0C0B),
      body: SafeArea(
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
                        'RECEIPT',
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
              bottom: 220,
              left: 30,
              right: 30,
              child: const _FrameGuide(),
            ),
            // Bottom controls
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  LoitSpacing.s5,
                  LoitSpacing.s5,
                  LoitSpacing.s5,
                  LoitSpacing.s6,
                ),
                child: Row(
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
              ),
            ),
          ],
        ),
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
        const Center(
          child: Text(
            'Align receipt within frame',
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
    return Scaffold(
      backgroundColor: c.canvas,
      appBar: AppBar(
        title: const Text('Reading receipt'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {},
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(LoitSpacing.s5),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _ReceiptSkeleton(controller: _ctrl),
            const SizedBox(height: LoitSpacing.s6),
            Text(
              'Reading your receipt…',
              style: LoitTypography.titleM.copyWith(color: c.contentPrimary),
            ),
            const SizedBox(height: LoitSpacing.s2),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 260),
              child: Text(
                "Usually takes about 2 seconds. We're extracting merchant, total, and items.",
                textAlign: TextAlign.center,
                style: LoitTypography.bodyS.copyWith(color: c.contentSecondary),
              ),
            ),
            const SizedBox(height: LoitSpacing.s5),
            _IndeterminateBar(controller: _ctrl),
          ],
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
    final isOffline = kind == 'connection';
    final title = isOffline ? "You're offline" : 'Scan service unavailable';
    final body = isOffline
        ? "We couldn't reach the scan service. Check connection and retry."
        : 'Scan service temporarily unavailable. Try again in a moment.';
    return Scaffold(
      backgroundColor: c.canvas,
      appBar: AppBar(title: const Text('Scan receipt')),
      body: Padding(
        padding: const EdgeInsets.all(LoitSpacing.s5),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            LoitBanner(
              kind: isOffline ? LoitBannerKind.warning : LoitBannerKind.error,
              title: title,
              body: body,
            ),
            const SizedBox(height: LoitSpacing.s5),
            LoitButton.primary(
              label: 'Retry',
              icon: Icons.refresh,
              onPressed: onRetry,
              fullWidth: true,
            ),
            const SizedBox(height: LoitSpacing.s2),
            LoitButton.tertiary(
              label: 'Cancel',
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
                ? 'You have used your monthly scan quota.'
                : "Used all ${profile.scanQuota ?? '∞'} scans on "
                    "${profile.tier.toUpperCase()} this month.",
            textAlign: TextAlign.center,
            style: LoitTypography.bodyM.copyWith(color: c.contentSecondary),
          ),
          const SizedBox(height: LoitSpacing.s5),
          if (canTopUp) ...[
            LoitButton.primary(
              label: 'Top up · 10 scans for Rp19,000',
              onPressed: () {
                Navigator.of(context).pop();
                onTopUp();
              },
              fullWidth: true,
            ),
            const SizedBox(height: LoitSpacing.s2),
          ],
          LoitButton.secondary(
            label: 'Upgrade to Pro — unlimited scans',
            onPressed: () {
              Navigator.of(context).pop();
              showPaywallSheet(context, feature: 'more_scan_quota');
            },
            fullWidth: true,
          ),
          const SizedBox(height: LoitSpacing.s2),
          LoitButton.tertiary(
            label: 'Not now',
            onPressed: () => Navigator.of(context).pop(),
            fullWidth: true,
          ),
        ],
      ),
    );
  }
}
