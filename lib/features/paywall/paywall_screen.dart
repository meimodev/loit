import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/analytics_service.dart';
import '../../core/services/interaction_log_service.dart';
import '../../core/services/midtrans_service.dart';
import '../../shared/providers/auth_providers.dart';

/// Paywall screen shown when a gated feature is tapped.
///
/// Fires `Analytics.paywallSeen(feature)` on build. Shows Pro benefits
/// and an upgrade button that hands off to Midtrans Snap.
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_analyticsTracked) {
      _analyticsTracked = true;
      Analytics.paywallSeen(widget.feature);
    }
  }

  Future<void> _upgrade(String productKey) async {
    setState(() => _busy = true);
    try {
      final result = await MidtransService.instance.startCheckout(
        context: context,
        productKey: productKey,
      );
      if (!mounted) return;

      final msg = switch (result.status) {
        MidtransCheckoutStatus.succeeded =>
          'Payment received. Unlocking Pro…',
        MidtransCheckoutStatus.pending =>
          "Payment pending. We'll upgrade you as soon as it settles.",
        MidtransCheckoutStatus.failed => 'Payment failed. Please try again.',
        MidtransCheckoutStatus.cancelled => 'Payment cancelled.',
        MidtransCheckoutStatus.unknown =>
          'Payment status unknown. Check back in a minute.',
      };
      final statusStr = result.status.name;
      InteractionLog.info(
        action: 'payment_checkout',
        screen: 'paywall',
        message: msg,
        metadata: {'product': productKey, 'status': statusStr},
      );

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(msg)));

      if (result.status == MidtransCheckoutStatus.succeeded) {
        await Analytics.subscriptionStarted('pro');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(userProfileProvider).value;
    final isPro = profile?.tier == 'pro' || profile?.tier == 'team';
    final cs = Theme.of(context).colorScheme;

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
          const SizedBox(height: 32),
          _FeatureRow(
            icon: Icons.all_inclusive,
            title: 'Unlimited budgets',
            subtitle: 'Free: 3 categories',
          ),
          _FeatureRow(
            icon: Icons.document_scanner,
            title: '50 scans / month',
            subtitle: 'Free: 8 scans',
          ),
          _FeatureRow(
            icon: Icons.currency_exchange,
            title: 'Real-time FX rates',
            subtitle: 'Free: daily rates',
          ),
          _FeatureRow(
            icon: Icons.download,
            title: 'CSV & PDF export',
            subtitle: 'Free: not available',
          ),
          _FeatureRow(
            icon: Icons.history,
            title: 'Full transaction history',
            subtitle: 'Free: 3 months',
          ),
          _FeatureRow(
            icon: Icons.receipt_long,
            title: 'Receipt image storage',
            subtitle: 'Free: not available',
          ),
          const SizedBox(height: 32),
          if (!isPro) ...[
            FilledButton(
              onPressed: _busy ? null : () => _upgrade('pro_monthly'),
              child: _busy
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Upgrade to Pro — Monthly'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _busy ? null : () => _upgrade('pro_annual'),
              child: const Text('Upgrade to Pro — Annual (Save 17%)'),
            ),
          ],
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
        ],
      ),
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
                Text(title,
                    style: Theme.of(context).textTheme.titleSmall),
                Text(subtitle,
                    style: Theme.of(context).textTheme.bodySmall),
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
