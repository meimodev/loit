import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/config/pricing_constants.dart';
import '../../core/services/analytics_service.dart';
import '../../core/services/dummy_payment_service.dart';
import '../../core/services/interaction_log_service.dart';
import '../../core/services/payment_service.dart';
import '../../shared/providers/auth_providers.dart';
import '../../shared/providers/services_providers.dart';

enum _BillingPeriod { monthly, annual }

/// Paywall screen shown when a gated feature is tapped.
///
/// Drives Google Play Billing through [PaymentService] (RevenueCat under
/// the hood). The actual entitlement flip happens server-side when the
/// `revenuecat-webhook` Edge Function processes the matching RC event.
class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({super.key, required this.feature});

  /// The feature that triggered the paywall (e.g. 'unlimited_budgets').
  final String feature;

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  bool _busy = false;
  bool _analyticsTracked = false;
  _BillingPeriod _period = _BillingPeriod.annual;
  StreamSubscription<PurchaseUpdate>? _purchaseSub;

  @override
  void initState() {
    super.initState();
    final pay = ref.read(paymentServiceProvider);
    _purchaseSub = pay.purchaseUpdates.listen(_onPurchaseUpdate);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Stub payment service needs a [BuildContext] to show its
    // "Pretend Pay" dialog. Real RevenueCat impl ignores this call.
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

  Future<void> _purchaseSubscription(String productId) async {
    setState(() => _busy = true);
    try {
      final pay = ref.read(paymentServiceProvider);
      final result = await pay.purchaseSubscription(productId);
      if (!mounted) return;
      // Success/restored/pending snacks come from _onPurchaseUpdate listener
      // (single source of truth). Only show terminal-fail/cancel here since
      // those don't emit through the CustomerInfo stream.
      if (result.status == PurchaseStatus.cancelled) {
        _showSnack('Purchase cancelled.');
      } else if (result.status == PurchaseStatus.failed) {
        _showSnack(result.message ?? 'Purchase failed.');
      } else if (result.isTerminalSuccess) {
        ref.invalidate(userProfileProvider);
      }
    } catch (e) {
      if (!mounted) return;
      _showSnack('Could not start purchase: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _purchaseTopUp(String productId) async {
    final profile = ref.read(userProfileProvider).value;
    // Top-ups are Free-tier only. Pro/Team have unlimited scans.
    assert(profile?.canPurchaseScanTopUp ?? false,
        'Top-up flow reached for non-free tier');
    if (profile?.canPurchaseScanTopUp != true) return;
    setState(() => _busy = true);
    try {
      final pay = ref.read(paymentServiceProvider);
      final result = await pay.purchaseOneTime(productId);
      if (!mounted) return;
      if (result.status == PurchaseStatus.cancelled) {
        _showSnack('Purchase cancelled.');
      } else if (result.status == PurchaseStatus.failed) {
        _showSnack(result.message ?? 'Purchase failed.');
      } else if (result.isTerminalSuccess) {
        ref.invalidate(userProfileProvider);
      }
    } catch (e) {
      if (!mounted) return;
      _showSnack('Could not start purchase: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _restorePurchases() async {
    setState(() => _busy = true);
    try {
      await ref.read(paymentServiceProvider).restorePurchases();
      if (!mounted) return;
      _showSnack('Restoring purchases…');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _onPurchaseUpdate(PurchaseUpdate u) {
    if (!mounted) return;
    final msg = switch (u.status) {
      PurchaseStatus.purchased => 'Purchase complete. Unlocking…',
      PurchaseStatus.restored => 'Purchase restored.',
      PurchaseStatus.pending => 'Purchase pending. Waiting for confirmation…',
      PurchaseStatus.cancelled => 'Purchase cancelled.',
      PurchaseStatus.failed => u.message ?? 'Purchase failed.',
    };
    InteractionLog.info(
      action: 'payment_purchase_update',
      screen: 'paywall',
      message: msg,
      metadata: {'product': u.productId, 'status': u.status.name},
    );
    _showSnack(msg);
    if (u.status == PurchaseStatus.purchased ||
        u.status == PurchaseStatus.restored) {
      Analytics.subscriptionStarted(_inferTier(u.productId));
      // RC fires `purchased` on local CustomerInfo, but our DB `users.tier`
      // flip lands a beat later via the revenuecat-webhook. Poll profile
      // until tier reflects entitlement (or timeout) so the UI doesn't
      // settle on a stale `free` row.
      _pollProfileUntilTierMatches(_inferTier(u.productId));
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
      } catch (_) {/* retry */}
      if (!mounted) return;
      await Future.delayed(interval);
      if (!mounted) return;
    }
    if (mounted) setState(() => _busy = false);
  }

  String _inferTier(String sku) {
    if (sku.contains('team')) return 'team';
    if (sku.contains('pro')) return 'pro';
    return 'free';
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(userProfileProvider).value;
    final isPro = profile?.tier == 'pro' || profile?.tier == 'team';
    final cs = Theme.of(context).colorScheme;
    final canBuyTopUp = profile?.canPurchaseScanTopUp ?? true;

    return Scaffold(
      appBar: AppBar(title: const Text('Upgrade to Pro')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Icon(Icons.workspace_premium, size: 64, color: cs.primary),
          const SizedBox(height: 16),
          Text(
            isPro ? 'You are on Pro' : 'Unlock all features',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          if (!isPro)
            Text(
              'Remove limits and get the most out of LOIT.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          const SizedBox(height: 24),
          if (!isPro) _BillingPeriodToggle(
            value: _period,
            onChanged: (p) => setState(() => _period = p),
          ),
          const SizedBox(height: 16),
          const _FeatureRow(
            icon: Icons.all_inclusive,
            title: 'Unlimited budgets',
            subtitle: 'Free: 3 categories',
          ),
          const _FeatureRow(
            icon: Icons.document_scanner,
            title: 'Unlimited scans',
            subtitle: 'Free: 8 scans / month',
          ),
          const _FeatureRow(
            icon: Icons.currency_exchange,
            title: 'Real-time FX rates',
            subtitle: 'Free: daily rates',
          ),
          const _FeatureRow(
            icon: Icons.download,
            title: 'CSV & PDF export',
            subtitle: 'Free: not available',
          ),
          const _FeatureRow(
            icon: Icons.history,
            title: 'Full transaction history',
            subtitle: 'Free: 3 months',
          ),
          const _FeatureRow(
            icon: Icons.receipt_long,
            title: 'Receipt image storage',
            subtitle: 'Free: not available',
          ),
          const _FeatureRow(
            icon: Icons.repeat,
            title: 'Recurring bills',
            subtitle: 'Free: not available',
          ),
          const SizedBox(height: 24),
          if (!isPro) ..._buildPurchaseButtons(),
          if (isPro)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'You have access to all Pro features.',
                textAlign: TextAlign.center,
                style: TextStyle(color: cs.onPrimaryContainer),
              ),
            ),
          const SizedBox(height: 16),
          // Scan top-up is Free-tier only. Pro / Team get unlimited scans.
          if (canBuyTopUp) ...[
            const Divider(),
            const SizedBox(height: 8),
            Text('One-time add-ons',
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: _busy
                  ? null
                  : () => _purchaseTopUp(PricingConstants.skuScanTopUp),
              child: Text(
                  '+10 scans · ${_formatIdr(PricingConstants.scanTopUpIdr)}'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: _busy
                  ? null
                  : () => _purchaseTopUp(PricingConstants.skuStorageExt),
              child: Text(
                  'Extend receipt storage · 6 months · ${_formatIdr(PricingConstants.storageExtensionIdr)}'),
            ),
          ],
          const SizedBox(height: 24),
          Center(
            child: TextButton(
              onPressed: _busy ? null : _restorePurchases,
              child: const Text('Restore purchases'),
            ),
          ),
          Center(
            child: Text(
              'Payments processed securely via Google Play.',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'iOS version coming soon.',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildPurchaseButtons() {
    final isAnnual = _period == _BillingPeriod.annual;
    final proSku = isAnnual
        ? PricingConstants.skuProAnnual
        : PricingConstants.skuProMonthly;
    final teamSku = isAnnual
        ? PricingConstants.skuTeamAnnual
        : PricingConstants.skuTeamMonthly;
    final proPrice = isAnnual
        ? PricingConstants.proAnnualIdr
        : PricingConstants.proMonthlyIdr;
    final teamPrice = isAnnual
        ? PricingConstants.teamAnnualIdr
        : PricingConstants.teamMonthlyIdr;
    final periodLabel = isAnnual ? '/yr' : '/mo';
    return [
      FilledButton(
        onPressed: _busy ? null : () => _purchaseSubscription(proSku),
        child: _busy
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text('Pro — ${_formatIdr(proPrice)}$periodLabel'),
      ),
      const SizedBox(height: 12),
      OutlinedButton(
        onPressed: _busy ? null : () => _purchaseSubscription(teamSku),
        child: Text('Team — ${_formatIdr(teamPrice)}$periodLabel'),
      ),
      if (isAnnual) ...[
        const SizedBox(height: 8),
        Center(
          child: Text(
            '4 months free · Save 33%',
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Center(
          child: Text(
            // Show per-month equivalent for the annual price.
            'Pro ≈ ${_formatIdr(PricingConstants.proAnnualIdr ~/ 12)}/mo · '
            'Team ≈ ${_formatIdr(PricingConstants.teamAnnualIdr ~/ 12)}/mo',
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ),
      ],
    ];
  }
}

class _BillingPeriodToggle extends StatelessWidget {
  const _BillingPeriodToggle({required this.value, required this.onChanged});
  final _BillingPeriod value;
  final ValueChanged<_BillingPeriod> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<_BillingPeriod>(
      segments: const [
        ButtonSegment(
          value: _BillingPeriod.monthly,
          label: Text('Monthly'),
        ),
        ButtonSegment(
          value: _BillingPeriod.annual,
          label: Text('Annual · 4 months free'),
        ),
      ],
      selected: {value},
      onSelectionChanged: (s) => onChanged(s.first),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleSmall),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          Icon(Icons.check_circle,
              color: Theme.of(context).colorScheme.primary, size: 20),
        ],
      ),
    );
  }
}

String _formatIdr(int amount) {
  final fmt = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp',
    decimalDigits: 0,
  );
  return fmt.format(amount);
}

/// Helper to show paywall from anywhere.
void showPaywallSheet(BuildContext context, {required String feature}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      builder: (_, controller) => PaywallScreen(feature: feature),
    ),
  );
}
