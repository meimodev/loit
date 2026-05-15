import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/loit_colors.dart';
import '../../core/theme/loit_typography.dart';
import '../../l10n/l10n_x.dart';
import '../../shared/providers/auth_providers.dart';
import '../../shared/providers/services_providers.dart';
import '../../shared/widgets/loit_button.dart';
import '../settings/_widgets.dart';

class ManageSubscriptionScreen extends ConsumerStatefulWidget {
  const ManageSubscriptionScreen({super.key});

  @override
  ConsumerState<ManageSubscriptionScreen> createState() =>
      _ManageSubscriptionScreenState();
}

class _ManageSubscriptionScreenState
    extends ConsumerState<ManageSubscriptionScreen> {
  bool _busy = false;

  Future<void> _openPlay() async {
    final uri = Uri.parse(
        'https://play.google.com/store/account/subscriptions?package=id.activid.loit');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _restore() async {
    setState(() => _busy = true);
    try {
      await ref.read(paymentServiceProvider).restorePurchases();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.paywallRestoring)),
      );
      ref.invalidate(userProfileProvider);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.loitColors;
    final l10n = context.l10n;
    final profile = ref.watch(userProfileProvider).value;
    final tier = profile?.tier ?? 'free';
    final isPaid = tier == 'pro' || tier == 'team';

    return Scaffold(
      backgroundColor: c.canvas,
      appBar: AppBar(
        title: Text(l10n.billingManageTitle),
        backgroundColor: c.canvas,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: isPaid
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [c.brand, c.accent],
                    )
                  : null,
              color: isPaid ? null : c.surface,
              borderRadius: BorderRadius.circular(14),
              border: isPaid ? null : Border.all(color: c.borderSubtle),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.billingManageCurrentPlan,
                  style: LoitTypography.labelS.copyWith(
                    color: isPaid
                        ? Colors.white.withValues(alpha: 0.85)
                        : c.contentSecondary,
                    letterSpacing: 0.8,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  tier.toUpperCase(),
                  style: LoitTypography.titleL.copyWith(
                    color: isPaid ? Colors.white : c.contentPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 26,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isPaid ? l10n.billingPaidBody : l10n.billingFreeBody,
                  style: LoitTypography.bodyM.copyWith(
                    color: isPaid
                        ? Colors.white.withValues(alpha: 0.9)
                        : c.contentSecondary,
                  ),
                ),
                if (profile?.nextReceiptExpiryAt != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    l10n.billingNextRenewal(profile!.nextReceiptExpiryAt!
                        .toLocal()
                        .toString()
                        .split(' ')
                        .first),
                    style: LoitTypography.bodyS.copyWith(
                      color: isPaid
                          ? Colors.white.withValues(alpha: 0.85)
                          : c.contentSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (!isPaid)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: LoitButton.primary(
                label: l10n.paywallTitle,
                size: LoitButtonSize.l,
                fullWidth: true,
                onPressed: () => context.push('/paywall', extra: 'manage'),
              ),
            ),
          SettingsGroup(label: l10n.billingGroupBilling, children: [
            SettingsRow(
              label: l10n.restorePurchases,
              onTap: _busy ? null : _restore,
            ),
          ]),
          if (isPaid)
            SettingsGroup(label: l10n.billingGroupManagePlay, children: [
              SettingsRow(
                label: l10n.billingChangePlan,
                onTap: _openPlay,
              ),
              SettingsRow(
                label: l10n.billingManageCancel,
                destructive: true,
                showChevron: false,
                onTap: _openPlay,
              ),
            ]),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Text(
              l10n.billingPlayFootnote,
              style: LoitTypography.bodyS
                  .copyWith(color: c.contentTertiary),
            ),
          ),
        ],
      ),
    );
  }
}
