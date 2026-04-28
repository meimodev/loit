import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/services/analytics_service.dart';
import '../../core/services/scanner_service.dart';
import '../../core/config/pricing_constants.dart';
import '../../core/services/dummy_payment_service.dart';
import '../paywall/paywall_screen.dart';
import '../../shared/providers/auth_providers.dart';
import '../../shared/providers/services_providers.dart';

/// Orchestrates the AI scanner flow.
///
/// 1. Picks a photo (camera or gallery).
/// 2. Calls [ScannerService.scanReceipt].
/// 3. Dispatches to the correct screen per [ScanErrorType]:
///    - success → confirm form pre-filled with parsed data
///    - aiFailure (422) → manual-entry form pre-filled with partial_fields
///    - quotaExceeded (402) → quota sheet
///    - connectionError / serverError → retry screen
class ScannerScreen extends ConsumerStatefulWidget {
  const ScannerScreen({super.key});

  @override
  ConsumerState<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends ConsumerState<ScannerScreen> {
  final _picker = ImagePicker();
  bool _busy = false;
  String? _lastError;
  File? _lastFile;

  Future<void> _pickAndScan(ImageSource source) async {
    final x = await _picker.pickImage(source: source, imageQuality: 95);
    if (x == null) return;
    final file = File(x.path);
    await _scan(file);
  }

  Future<void> _scan(File file) async {
    setState(() {
      _busy = true;
      _lastError = null;
      _lastFile = file;
    });
    await Analytics.scanStarted();

    final profile = ref.read(userProfileProvider).value;
    final isDemo = profile != null && !profile.hasUsedDemoScan;

    final scanner = ref.read(scannerServiceProvider);
    final compressed = await scanner.compressToFile(file);
    final result = await scanner.scanReceipt(compressed, isDemo: isDemo);

    if (!mounted) return;
    setState(() => _busy = false);

    switch (result.errorType) {
      case null:
        // success
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
        await _showQuotaSheet();
        break;
      case ScanErrorType.connectionError:
        await Analytics.scanFailed('connection_error');
        setState(() => _lastError = 'connection');
        break;
      case ScanErrorType.serverError:
        await Analytics.scanFailed('server_error');
        setState(() => _lastError = 'server');
        break;
    }
  }

  Future<void> _showQuotaSheet() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _QuotaExceededSheet(onTopUp: _handleTopUp),
    );
  }

  Future<void> _handleTopUp() async {
    // Sheet has already popped. Bind dummy service to the still-mounted
    // scanner page context so the "Pretend Pay" dialog has a host.
    if (!mounted) return;
    final pay = ref.read(paymentServiceProvider);
    if (pay is DummyPaymentService) pay.bindContext(context);
    try {
      await pay.purchaseOneTime(PricingConstants.skuScanTopUp);
    } catch (_) {
      // PurchaseUpdate stream surfaces failures.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan receipt')),
      body: _busy
          ? const _ScanningView()
          : _lastError != null
              ? _RetryView(
                  kind: _lastError!,
                  onRetry: _lastFile == null ? null : () => _scan(_lastFile!),
                  onCancel: () => context.pop(),
                )
              : _PickerView(
                  onCamera: () => _pickAndScan(ImageSource.camera),
                  onGallery: () => _pickAndScan(ImageSource.gallery),
                ),
    );
  }
}

class _PickerView extends StatelessWidget {
  const _PickerView({required this.onCamera, required this.onGallery});
  final VoidCallback onCamera;
  final VoidCallback onGallery;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text('Scan a receipt',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            const Text('We will extract the merchant, amount, and category.',
                textAlign: TextAlign.center),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: onCamera,
              icon: const Icon(Icons.camera_alt),
              label: const Text('Take photo'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onGallery,
              icon: const Icon(Icons.photo_library),
              label: const Text('Choose from gallery'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScanningView extends StatelessWidget {
  const _ScanningView();
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Reading your receipt…'),
        ],
      ),
    );
  }
}

class _RetryView extends StatelessWidget {
  const _RetryView({required this.kind, this.onRetry, required this.onCancel});
  final String kind; // 'connection' | 'server'
  final VoidCallback? onRetry;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final title = kind == 'connection'
        ? "You're offline"
        : "Scan service is unavailable";
    final body = kind == 'connection'
        ? "We couldn't reach the scan service. Check your connection and try again."
        : "The scan service is temporarily unavailable. Please try again in a moment.";
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              kind == 'connection' ? Icons.wifi_off : Icons.cloud_off,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(title, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(body, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
            TextButton(onPressed: onCancel, child: const Text('Cancel')),
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
    final profile = ref.watch(userProfileProvider).value;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        8,
        24,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(Icons.lock_outline,
              size: 48, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 12),
          Text(
            'Scan limit reached',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            profile == null
                ? 'You have used your monthly scan quota.'
                : "You've used all ${profile.scanQuota ?? '∞'} scans in your "
                    "${profile.tier.toUpperCase()} plan this month.",
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          // Top-up is Free-tier only. Pro/Team get unlimited scans and
          // should never reach this sheet — but guard anyway.
          if (profile?.canPurchaseScanTopUp ?? true)
            FilledButton(
              onPressed: () {
                // Pop sheet first so the "Pretend Pay" dialog hosts on the
                // scanner page context (still mounted) instead of the
                // about-to-be-disposed sheet context.
                Navigator.of(context).pop();
                onTopUp();
              },
              child: const Text('Top up · 10 scans for Rp19,000'),
            ),
          if (profile?.canPurchaseScanTopUp ?? true)
            const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () {
              Navigator.of(context).pop();
              showPaywallSheet(context, feature: 'more_scan_quota');
            },
            child: const Text('Upgrade to Pro — unlimited scans'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Not now'),
          ),
        ],
      ),
    );
  }
}
