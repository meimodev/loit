import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/loit_colors.dart';
import '../../core/theme/loit_spacing.dart';
import '../../core/theme/loit_typography.dart';
import '../../l10n/l10n_x.dart';
import '../../shared/providers/auth_providers.dart';
import '../../shared/utils/locale_date_format.dart';
import '../../shared/widgets/loit_button.dart';
import '../settings/_widgets.dart';

class ManageSubscriptionScreen extends ConsumerWidget {
  const ManageSubscriptionScreen({super.key});

  Future<void> _openPlay() async {
    final uri = Uri.parse(
        'https://play.google.com/store/account/subscriptions?package=id.activid.loit');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  String _planLabel(String tier) => switch (tier) {
        'pro' => 'PRO',
        'lite' => 'LITE',
        _ => 'FREE',
      };

  String _planBody(BuildContext context, String tier) {
    final l = context.l10n;
    return switch (tier) {
      'pro' => l.billingPaidBody,
      'lite' => l.billingLiteBody,
      _ => l.billingFreeBody,
    };
  }

  List<String> _benefits(BuildContext context, String tier) {
    final l = context.l10n;
    return switch (tier) {
      'pro' => [l.billingProBenefit1, l.billingProBenefit2, l.billingProBenefit3],
      'lite' => [
          l.billingLiteBenefit1,
          l.billingLiteBenefit2,
          l.billingLiteBenefit3,
        ],
      _ => [l.billingFreeBenefit1, l.billingFreeBenefit2, l.billingFreeBenefit3],
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.loitColors;
    final l10n = context.l10n;
    final profile = ref.watch(userProfileProvider).value;
    final tier = profile?.tier ?? 'free';
    final isPaid = tier == 'pro' || tier == 'lite';
    final isPro = tier == 'pro';
    final benefits = _benefits(context, tier);

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
                  _planLabel(tier),
                  style: LoitTypography.titleL.copyWith(
                    color: isPaid ? Colors.white : c.contentPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 26,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _planBody(context, tier),
                  style: LoitTypography.bodyM.copyWith(
                    color: isPaid
                        ? Colors.white.withValues(alpha: 0.9)
                        : c.contentSecondary,
                  ),
                ),
                if (isPaid && profile?.tierExpiresAt != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    l10n.billingPlanEndsOn(
                      yMMMd(context).format(profile!.tierExpiresAt!),
                    ),
                    style: LoitTypography.bodyS.copyWith(
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: Text(
              l10n.billingPlanBenefits,
              style: LoitTypography.labelS.copyWith(
                color: c.contentSecondary,
                letterSpacing: 0.8,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.symmetric(
              horizontal: LoitSpacing.s4,
              vertical: LoitSpacing.s3,
            ),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: c.borderSubtle),
            ),
            child: Column(
              children: [
                for (final b in benefits)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.check, size: 18, color: c.success),
                        const SizedBox(width: LoitSpacing.s3),
                        Expanded(
                          child: Text(b, style: LoitTypography.bodyM),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          if (!isPro)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: LoitButton.primary(
                label: l10n.billingUpgradeCta,
                size: LoitButtonSize.l,
                fullWidth: true,
                onPressed: () => context.push('/paywall', extra: 'manage'),
              ),
            ),
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
