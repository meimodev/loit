import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/config/pricing_constants.dart';
import '../../core/services/analytics_service.dart';
import '../../core/services/dummy_payment_service.dart';
import '../../core/services/interaction_log_service.dart';
import '../../core/services/payment_service.dart';
import '../../core/theme/loit_colors.dart';
import '../../core/theme/loit_motion.dart';
import '../../core/theme/loit_typography.dart';
import '../../l10n/l10n_x.dart';
import '../../shared/providers/auth_providers.dart';
import '../../shared/providers/services_providers.dart';
import '../../shared/widgets/loit_animations.dart';
import '../../shared/widgets/loit_button.dart';

enum _Plan { free, liteMonthly, liteAnnual, proMonthly, proAnnual }

class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({super.key, required this.feature});

  final String feature;

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  bool _busy = false;
  bool _analyticsTracked = false;
  _Plan _selected = _Plan.proAnnual;
  StreamSubscription<PurchaseUpdate>? _purchaseSub;
  final Map<String, PaymentProductDetails> _details = {};

  @override
  void initState() {
    super.initState();
    final pay = ref.read(paymentServiceProvider);
    _purchaseSub = pay.purchaseUpdates.listen(_onPurchaseUpdate);
    _loadProductDetails();
  }

  Future<void> _loadProductDetails() async {
    final pay = ref.read(paymentServiceProvider);
    const skus = [
      PricingConstants.skuLiteMonthly,
      PricingConstants.skuLiteAnnual,
      PricingConstants.skuProMonthly,
      PricingConstants.skuProAnnual,
    ];
    final results = await Future.wait(
      skus.map((s) => pay.getProductDetails(s).catchError((_) => null)),
    );
    if (!mounted) return;
    setState(() {
      for (var i = 0; i < skus.length; i++) {
        final d = results[i];
        if (d != null) _details[skus[i]] = d;
      }
    });
  }

  String _priceFor(String sku, int fallbackIdr) =>
      _details[sku]?.priceString ?? _formatIdr(fallbackIdr);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final pay = ref.read(paymentServiceProvider);
    if (pay is DummyPaymentService) pay.bindContext(context);
    if (!_analyticsTracked) {
      _analyticsTracked = true;
      Analytics.paywallSeen(widget.feature);
    }
  }

  @override
  void dispose() {
    final pay = ref.read(paymentServiceProvider);
    if (pay is DummyPaymentService) pay.unbindContext(context);
    _purchaseSub?.cancel();
    super.dispose();
  }

  String? get _selectedSku => switch (_selected) {
        _Plan.proAnnual => PricingConstants.skuProAnnual,
        _Plan.proMonthly => PricingConstants.skuProMonthly,
        _Plan.liteAnnual => PricingConstants.skuLiteAnnual,
        _Plan.liteMonthly => PricingConstants.skuLiteMonthly,
        _Plan.free => null,
      };

  Future<void> _continue() async {
    final sku = _selectedSku;
    if (sku == null) {
      if (context.mounted) context.pop();
      return;
    }
    setState(() => _busy = true);
    try {
      final pay = ref.read(paymentServiceProvider);
      final result = await pay.purchaseSubscription(sku);
      if (!mounted) return;
      if (result.status == PurchaseStatus.cancelled) {
        _showSnack(context.l10n.paywallPurchaseCancelled);
      } else if (result.status == PurchaseStatus.failed) {
        _showSnack(result.message ?? context.l10n.paywallPurchaseFailed);
      } else if (result.isTerminalSuccess) {
        ref.invalidate(userProfileProvider);
      }
    } catch (e) {
      if (!mounted) return;
      _showSnack(context.l10n.paywallPurchaseStartError(e.toString()));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _restorePurchases() async {
    setState(() => _busy = true);
    try {
      await ref.read(paymentServiceProvider).restorePurchases();
      if (!mounted) return;
      _showSnack(context.l10n.paywallRestoring);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _onPurchaseUpdate(PurchaseUpdate u) {
    if (!mounted) return;
    final l10n = context.l10n;
    final msg = switch (u.status) {
      PurchaseStatus.purchased => l10n.paywallPurchaseComplete,
      PurchaseStatus.restored => l10n.paywallPurchaseRestored,
      PurchaseStatus.pending => l10n.paywallPurchasePending,
      PurchaseStatus.cancelled => l10n.paywallPurchaseCancelled,
      PurchaseStatus.failed => u.message ?? l10n.paywallPurchaseFailed,
    };
    InteractionLog.info(
      action: 'payment_purchase_update',
      screen: 'paywall',
      message: msg,
      metadata: {'product': u.productId, 'status': u.status.name},
    );
    if (u.status == PurchaseStatus.purchased ||
        u.status == PurchaseStatus.restored) {
      Analytics.subscriptionStarted(_inferTier(u.productId));
      _pollProfileUntilTierMatches(_inferTier(u.productId));
    } else {
      _showSnack(msg);
    }
    if (u.status == PurchaseStatus.cancelled ||
        u.status == PurchaseStatus.failed) {
      setState(() => _busy = false);
    }
  }

  Future<void> _pollProfileUntilTierMatches(String expectedTier) async {
    if (expectedTier == 'free') {
      if (mounted) setState(() => _busy = false);
      return;
    }
    const maxAttempts = 8;
    const interval = Duration(milliseconds: 1500);
    for (var i = 0; i < maxAttempts; i++) {
      ref.invalidate(userProfileProvider);
      try {
        final profile = await ref.read(userProfileProvider.future);
        if (profile?.tier == expectedTier) break;
      } catch (_) {}
      if (!mounted) return;
      await Future.delayed(interval);
      if (!mounted) return;
    }
    if (!mounted) return;
    setState(() => _busy = false);
    if (context.mounted) context.go('/pro/success');
  }

  String _inferTier(String sku) {
    if (sku.contains('pro')) return 'pro';
    if (sku.contains('lite')) return 'lite';
    return 'free';
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  String _ctaLabel() {
    final l10n = context.l10n;
    switch (_selected) {
      case _Plan.free:
        return l10n.paywallCtaFree;
      case _Plan.proAnnual:
        return l10n.paywallCtaProAnnual(_priceFor(
            PricingConstants.skuProAnnual, PricingConstants.proAnnualIdr));
      case _Plan.proMonthly:
        return l10n.paywallCtaProMonthly(_priceFor(
            PricingConstants.skuProMonthly, PricingConstants.proMonthlyIdr));
      case _Plan.liteAnnual:
        return l10n.paywallCtaLiteAnnual(_priceFor(
            PricingConstants.skuLiteAnnual, PricingConstants.liteAnnualIdr));
      case _Plan.liteMonthly:
        return l10n.paywallCtaLiteMonthly(_priceFor(
            PricingConstants.skuLiteMonthly, PricingConstants.liteMonthlyIdr));
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.loitColors;
    final l10n = context.l10n;
    final profile = ref.watch(userProfileProvider).value;
    final isPro = profile?.tier == 'pro';

    return Scaffold(
      backgroundColor: c.canvas,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Row(
                children: [
                  const Spacer(),
                  TextButton(
                    onPressed: () => context.canPop()
                        ? context.pop()
                        : context.go('/'),
                    child: Text(
                      l10n.scanNotNow,
                      style: LoitTypography.bodyM.copyWith(
                        color: c.contentSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LoitScaleIn(
                    from: 0.6,
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [c.brand, c.accent],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.workspace_premium,
                          size: 24, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
              child: Align(
                alignment: Alignment.centerLeft,
                child: LoitFadeSlideIn(
                  delay: const Duration(milliseconds: 80),
                  child: Text(
                    isPro ? l10n.paywallHeroPro : l10n.paywallHero,
                    style: LoitTypography.titleL.copyWith(
                      color: c.contentPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 24,
                      height: 30 / 24,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  if (isPro)
                    _ProActiveCard(profile: profile)
                  else ...[
                    _PlanCard(
                      entranceIndex: 0,
                      title: l10n.paywallFree,
                      price: 'Rp 0',
                      period: '/mo',
                      features: l10n.paywallFreeFeatures,
                      selected: _selected == _Plan.free,
                      onTap: () => setState(() => _selected = _Plan.free),
                    ),
                    _PlanCard(
                      entranceIndex: 1,
                      title:
                          '${l10n.paywallLite} · ${l10n.paywallPlanMonthly}',
                      price: _priceFor(PricingConstants.skuLiteMonthly,
                          PricingConstants.liteMonthlyIdr),
                      period: '/mo',
                      features: l10n.paywallLiteMonthlyFeatures,
                      selected: _selected == _Plan.liteMonthly,
                      onTap: () =>
                          setState(() => _selected = _Plan.liteMonthly),
                    ),
                    _PlanCard(
                      entranceIndex: 2,
                      title:
                          '${l10n.paywallLite} · ${l10n.paywallPlanYearly}',
                      price: _priceFor(PricingConstants.skuLiteAnnual,
                          PricingConstants.liteAnnualIdr),
                      period: '/yr',
                      features: l10n.paywallLiteAnnualFeatures,
                      selected: _selected == _Plan.liteAnnual,
                      onTap: () =>
                          setState(() => _selected = _Plan.liteAnnual),
                    ),
                    _PlanCard(
                      entranceIndex: 3,
                      title: '${l10n.paywallPro} · ${l10n.paywallPlanMonthly}',
                      price: _priceFor(PricingConstants.skuProMonthly,
                          PricingConstants.proMonthlyIdr),
                      period: '/mo',
                      features: l10n.paywallProMonthlyFeatures,
                      selected: _selected == _Plan.proMonthly,
                      onTap: () =>
                          setState(() => _selected = _Plan.proMonthly),
                    ),
                    _PlanCard(
                      entranceIndex: 4,
                      title: '${l10n.paywallPro} · ${l10n.paywallPlanYearly}',
                      price: _priceFor(PricingConstants.skuProAnnual,
                          PricingConstants.proAnnualIdr),
                      period: '/yr',
                      features: l10n.paywallProAnnualFeatures,
                      selected: _selected == _Plan.proAnnual,
                      recommended: true,
                      bestValueLabel: l10n.paywallBestValue,
                      onTap: () =>
                          setState(() => _selected = _Plan.proAnnual),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Center(
                    child: TextButton(
                      onPressed: _busy ? null : _restorePurchases,
                      child: Text(l10n.restorePurchases,
                          style: LoitTypography.bodyS.copyWith(
                            color: c.brand,
                            fontWeight: FontWeight.w600,
                          )),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
              decoration: BoxDecoration(
                color: c.surface,
                border: Border(
                  top: BorderSide(color: c.borderSubtle, width: 1),
                ),
              ),
              child: Column(
                children: [
                  AnimatedSwitcher(
                    duration: LoitMotion.short,
                    switchInCurve: LoitMotion.easeOutQuart,
                    switchOutCurve: LoitMotion.easeOutQuart,
                    transitionBuilder: (child, anim) => FadeTransition(
                      opacity: anim,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.15),
                          end: Offset.zero,
                        ).animate(anim),
                        child: child,
                      ),
                    ),
                    child: LoitButton.primary(
                      key: ValueKey(isPro
                          ? 'cta-pro-all-set'
                          : 'cta-${_selected.name}'),
                      label: isPro ? l10n.paywallCtaAllSet : _ctaLabel(),
                      size: LoitButtonSize.l,
                      fullWidth: true,
                      loading: _busy,
                      onPressed: _busy || isPro ? null : _continue,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.paymentGooglePlayOnly,
                    style: LoitTypography.bodyS
                        .copyWith(color: c.contentTertiary),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.title,
    required this.price,
    required this.period,
    required this.features,
    required this.selected,
    required this.onTap,
    this.recommended = false,
    this.bestValueLabel,
    this.entranceIndex = 0,
  });

  final String title;
  final String price;
  final String period;
  final String features;
  final bool selected;
  final bool recommended;
  final String? bestValueLabel;
  final VoidCallback onTap;
  final int entranceIndex;

  @override
  Widget build(BuildContext context) {
    final c = context.loitColors;
    final borderColor = selected ? c.brand : c.borderSubtle;
    final borderWidth = selected ? 2.0 : 1.0;
    final card = Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          LoitTapScale(
            scale: 0.985,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(12),
              child: AnimatedScale(
                scale: selected ? 1.012 : 1.0,
                duration: LoitMotion.short,
                curve: LoitMotion.easeOutQuart,
                child: AnimatedContainer(
                  duration: LoitMotion.short,
                  curve: LoitMotion.easeOutQuart,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: c.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderColor, width: borderWidth),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(title,
                                style: LoitTypography.titleM.copyWith(
                                  color: c.contentPrimary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                )),
                          ),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(price,
                                  style: LoitTypography.titleL.copyWith(
                                    color: c.contentPrimary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 18,
                                    fontFeatures: const [
                                      FontFeature.tabularFigures()
                                    ],
                                  )),
                              Text(period,
                                  style: LoitTypography.bodyS
                                      .copyWith(color: c.contentSecondary)),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(features,
                          style: LoitTypography.bodyS.copyWith(
                            color: c.contentSecondary,
                            height: 17 / 12,
                          )),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (recommended)
            Positioned(
              top: -10,
              left: 14,
              child: LoitGentlePulse(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: c.brand,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    bestValueLabel ?? 'BEST VALUE',
                    style: LoitTypography.labelS.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
    return LoitFadeSlideIn(
      delay: LoitMotion.staggerStep * entranceIndex +
          const Duration(milliseconds: 140),
      child: card,
    );
  }
}

class _ProActiveCard extends StatelessWidget {
  const _ProActiveCard({required this.profile});
  final UserProfile? profile;

  @override
  Widget build(BuildContext context) {
    final c = context.loitColors;
    final tier = profile?.tier.toUpperCase() ?? 'PRO';
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.successSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.brand.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          LoitScaleIn(
            from: 0.4,
            duration: LoitMotion.emphasized,
            child: Icon(Icons.check_circle, color: c.brand, size: 22),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: LoitFadeSlideIn(
              delay: const Duration(milliseconds: 120),
              child: Text(
                context.l10n.paywallTierActive(tier),
                style: LoitTypography.bodyM.copyWith(
                  color: c.contentPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _formatIdr(int amount) {
  final fmt = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );
  return fmt.format(amount).trim();
}

void showPaywallSheet(BuildContext context, {required String feature}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.92,
      maxChildSize: 0.96,
      builder: (_, controller) => PaywallScreen(feature: feature),
    ),
  );
}
