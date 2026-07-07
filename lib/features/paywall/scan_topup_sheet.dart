import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/loit_colors.dart';
import '../../core/theme/loit_spacing.dart';
import '../../core/theme/loit_typography.dart';
import '../../l10n/l10n_x.dart';
import '../../shared/providers/auth_providers.dart';
import '../../shared/widgets/loit_button.dart';
import '../../shared/widgets/loit_sheet.dart';
import 'paywall_screen.dart';

/// Shared AI-Credit top-up sheet. Surfaced when a Capture (scanner, in-app
/// voice) or the Laporan Realisasi report (export) is blocked or nudged by low
/// credits. [onTopUp] runs the consumable purchase (`skuScanTopUp`); the caller
/// owns the payment-service call and any post-purchase refresh so this widget
/// stays surface-agnostic.
///
// ponytail: promoted from scanner's private _QuotaExceededSheet once export
// became the 3rd caller. Callers pass onTopUp rather than reimplementing.
Future<void> showScanTopUpSheet(
  BuildContext context, {
  required Future<void> Function() onTopUp,
}) {
  final l = context.l10n;
  return showLoitSheet<void>(
    context,
    builder: (_) => LoitSheet(
      title: l.scanLimitReached,
      child: ScanTopUpSheet(onTopUp: onTopUp),
    ),
  );
}

class ScanTopUpSheet extends ConsumerWidget {
  const ScanTopUpSheet({super.key, required this.onTopUp});
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
                : l.scanUsedAllScans(
                    '${profile.scanQuota ?? '0'}', profile.tier.toUpperCase()),
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
