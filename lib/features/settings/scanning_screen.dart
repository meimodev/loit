import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/config/pricing_constants.dart';
import '../../core/services/dummy_payment_service.dart';
import '../../core/services/payment_service.dart';
import '../../core/theme/loit_colors.dart';
import '../../core/theme/loit_typography.dart';
import '../../l10n/l10n_x.dart';
import '../../shared/providers/auth_providers.dart';
import '../../shared/providers/preferences_provider.dart';
import '../../shared/providers/services_providers.dart';
import '../../shared/widgets/loit_button.dart';
import '../../shared/widgets/loit_progress_bar.dart';
import '../paywall/feature_gate.dart';
import '_widgets.dart';

/// Settings → Scanning. Surfaces account scan info (plan, monthly usage,
/// reset date), wires a direct-purchase top-up CTA (consumable, all tiers),
/// and keeps scanner-v2 user preferences below.
class ScanningScreen extends ConsumerStatefulWidget {
  const ScanningScreen({super.key});

  @override
  ConsumerState<ScanningScreen> createState() => _ScanningScreenState();
}

class _ScanningScreenState extends ConsumerState<ScanningScreen> {
  bool _busy = false;
  PaymentProductDetails? _topUpDetails;
  StreamSubscription<PurchaseUpdate>? _purchaseSub;

  @override
  void initState() {
    super.initState();
    final pay = ref.read(paymentServiceProvider);
    _purchaseSub = pay.purchaseUpdates.listen(_onPurchaseUpdate);
    _loadTopUpDetails();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final pay = ref.read(paymentServiceProvider);
    if (pay is DummyPaymentService) pay.bindContext(context);
  }

  @override
  void dispose() {
    final pay = ref.read(paymentServiceProvider);
    if (pay is DummyPaymentService) pay.unbindContext(context);
    _purchaseSub?.cancel();
    super.dispose();
  }

  Future<void> _loadTopUpDetails() async {
    final pay = ref.read(paymentServiceProvider);
    try {
      final d = await pay.getProductDetails(PricingConstants.skuScanTopUp);
      if (!mounted) return;
      setState(() => _topUpDetails = d);
    } catch (_) {/* fallback to constant */}
  }

  Future<void> _buyTopUp() async {
    setState(() => _busy = true);
    try {
      final pay = ref.read(paymentServiceProvider);
      final result =
          await pay.purchaseOneTime(PricingConstants.skuScanTopUp);
      if (!mounted) return;
      if (result.status == PurchaseStatus.cancelled) {
        _showSnack(context.l10n.paywallPurchaseCancelled);
      } else if (result.status == PurchaseStatus.failed) {
        _showSnack(result.message ?? context.l10n.paywallPurchaseFailed);
      }
    } catch (e) {
      if (!mounted) return;
      _showSnack(context.l10n.paywallPurchaseStartError(e.toString()));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _onPurchaseUpdate(PurchaseUpdate u) {
    if (!mounted) return;
    if (u.productId != PricingConstants.skuScanTopUp) return;
    final l10n = context.l10n;
    if (u.status == PurchaseStatus.purchased ||
        u.status == PurchaseStatus.restored) {
      _showSnack(l10n.scanInfoTopUpSuccess);
      ref.invalidate(userProfileProvider);
    } else if (u.status == PurchaseStatus.failed) {
      _showSnack(u.message ?? l10n.paywallPurchaseFailed);
    } else if (u.status == PurchaseStatus.cancelled) {
      _showSnack(l10n.paywallPurchaseCancelled);
    }
    if (u.status != PurchaseStatus.pending) {
      setState(() => _busy = false);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  String get _topUpPrice =>
      _topUpDetails?.priceString ??
      _formatIdr(PricingConstants.scanTopUpIdr);

  @override
  Widget build(BuildContext context) {
    final c = context.loitColors;
    final l = context.l10n;
    final profile = ref.watch(userProfileProvider).value;
    final flags = ref.watch(featureGateProvider).value ??
        FeatureFlags.forTier(profile?.tier ?? 'free');
    final prefs =
        ref.watch(preferencesProvider).value ?? const AppPreferences();
    final notifier = ref.read(preferencesProvider.notifier);

    return Scaffold(
      backgroundColor: c.canvas,
      appBar: AppBar(
        title: Text(l.scanSettingsSection),
        backgroundColor: c.canvas,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(userProfileProvider);
          ref.invalidate(featureGateProvider);
          ref.invalidate(preferencesProvider);
          await _loadTopUpDetails();
          await ref.read(userProfileProvider.future);
        },
        child: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SettingsGroup(label: l.scanInfoPlanSection, children: [
            SettingsRow(
              label: (profile?.tier ?? 'free').toUpperCase(),
              value: flags.hasUnlimitedScans
                  ? l.scanInfoUsageUnlimited
                  : l.scanInfoTierBenefit(flags.scanLimitPerMonth ?? 0),
              onTap: () => context.push('/paywall?feature=scanning'),
            ),
          ]),
          SettingsGroup(label: l.scanInfoUsageSection, children: [
            _UsageCard(
              used: profile?.scansUsedThisMonth ?? 0,
              total: profile?.scanQuota ?? flags.scanLimitPerMonth,
              bonus: profile?.scanTopupBonusThisMonth ?? 0,
              resetDate: _nextResetDate(),
            ),
            SettingsRow(
              label: l.scanInfoRecentLink,
              onTap: () => context.push('/receipts'),
            ),
          ]),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
            child: Text(
              l.scanInfoTopUpSection.toUpperCase(),
              style: LoitTypography.labelS.copyWith(
                color: c.contentSecondary,
                letterSpacing: 0.8,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
            child: LoitButton.primary(
              label: l.scanInfoTopUpCta(_topUpPrice),
              size: LoitButtonSize.l,
              fullWidth: true,
              loading: _busy,
              onPressed: _busy ? null : _buyTopUp,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
            child: Text(
              l.scanInfoTopUpHelper,
              style: LoitTypography.bodyS.copyWith(color: c.contentTertiary),
            ),
          ),
          SettingsGroup(label: l.scanInfoPrefsSection, children: [
            SettingsToggleRow(
              label: l.scanSettingsAutoConfirm,
              helper: null,
              value: prefs.scanAutoConfirm,
              onChanged: (v) =>
                  notifier.setBool(PrefKeys.scanAutoConfirm, v),
            ),
          ]),
        ],
      ),
      ),
    );
  }
}

class _UsageCard extends StatelessWidget {
  const _UsageCard({
    required this.used,
    required this.total,
    required this.bonus,
    required this.resetDate,
  });

  final int used;
  final int? total;
  final int bonus;
  final DateTime resetDate;

  @override
  Widget build(BuildContext context) {
    final c = context.loitColors;
    final l = context.l10n;
    final unlimited = total == null;
    final pct = unlimited || total! == 0
        ? 0
        : ((used / total!) * 100).round();
    final dateFmt =
        DateFormat.yMMMMd(Localizations.localeOf(context).toLanguageTag());

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(bottom: BorderSide(color: c.borderSubtle, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            unlimited
                ? l.scanInfoUsageUnlimited
                : l.scanInfoUsage(used, total!),
            style: LoitTypography.titleM.copyWith(
              color: c.contentPrimary,
              fontWeight: FontWeight.w600,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          if (bonus > 0) ...[
            const SizedBox(height: 2),
            Text(
              l.scanInfoBonusBreakdown(bonus),
              style:
                  LoitTypography.bodyS.copyWith(color: c.brand),
            ),
          ],
          if (!unlimited) ...[
            const SizedBox(height: 10),
            LoitProgressBar(percent: pct),
          ],
          const SizedBox(height: 8),
          Text(
            l.scanInfoResetsOn(dateFmt.format(resetDate)),
            style: LoitTypography.bodyS.copyWith(color: c.contentSecondary),
          ),
        ],
      ),
    );
  }
}

DateTime _nextResetDate() {
  final now = DateTime.now();
  return DateTime(now.year, now.month + 1, 1);
}

String _formatIdr(int amount) {
  final fmt = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );
  return fmt.format(amount).trim();
}
