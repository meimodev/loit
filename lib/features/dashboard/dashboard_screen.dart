import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/config/categories.dart';
import '../../shared/providers/auth_providers.dart';
import '../../shared/providers/transactions_provider.dart';
import '../../shared/widgets/budget_alert_banner.dart';
import '../../shared/widgets/receipt_expiry_banner.dart';

/// Home screen: month-to-date spend + recent transactions + FAB (manual/scan).
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txns = ref.watch(transactionsProvider);
    final profile = ref.watch(userProfileProvider).value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('LOIT'),
        actions: [
          if (profile != null)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(
                child: Chip(
                  label: Text(profile.tier.toUpperCase()),
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(transactionsProvider.notifier).refresh(),
        child: txns.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (items) => CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _MonthSummary(items: items, profile: profile)),
              const SliverToBoxAdapter(child: BudgetAlertBanner()),
              const SliverToBoxAdapter(child: ReceiptExpiryBanner()),
              if (items.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: _EmptyState(),
                )
              else
                SliverList.builder(
                  itemCount: items.length,
                  itemBuilder: (_, i) => _TxnTile(txn: items[i]),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 96)),
            ],
          ),
        ),
      ),
      floatingActionButton: _AddMenu(),
    );
  }
}

class _AddMenu extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        FloatingActionButton.small(
          heroTag: 'scan',
          onPressed: () => context.push('/scan'),
          tooltip: 'Scan receipt',
          child: const Icon(Icons.document_scanner_outlined),
        ),
        const SizedBox(height: 12),
        FloatingActionButton.extended(
          heroTag: 'add',
          onPressed: () => context.push('/transactions/new'),
          icon: const Icon(Icons.add),
          label: const Text('Add'),
        ),
      ],
    );
  }
}

class _MonthSummary extends StatelessWidget {
  const _MonthSummary({required this.items, this.profile});
  final List<Txn> items;
  final UserProfile? profile;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final total = items
        .where((t) => t.createdAt.isAfter(monthStart))
        .fold<double>(0, (s, t) => s + (t.amountHome ?? t.amount));
    final fmt = NumberFormat.simpleCurrency(name: profile?.homeCurrency ?? 'IDR');
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Month-to-date', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 6),
              Text(fmt.format(total),
                  style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 4),
              Text(
                '${items.where((t) => t.createdAt.isAfter(monthStart)).length} '
                'transactions',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (profile != null) ...[
                const SizedBox(height: 8),
                Text(
                  profile!.hasUnlimitedScans
                      ? 'Scans: Unlimited'
                      : 'Scans used: ${profile!.scansUsedThisMonth}/${profile!.scanQuota}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _TxnTile extends StatelessWidget {
  const _TxnTile({required this.txn});
  final Txn txn;

  @override
  Widget build(BuildContext context) {
    final amtFmt = NumberFormat.simpleCurrency(name: txn.currency);
    return ListTile(
      leading: CircleAvatar(child: Icon(Categories.iconFor(txn.category))),
      title: Text(txn.merchant ?? txn.category ?? 'Transaction'),
      subtitle: Text(
        '${txn.category ?? 'other'} · '
        '${DateFormat.yMMMd().add_jm().format(txn.createdAt.toLocal())}'
        '${txn.aiParsed ? ' · AI' : ''}'
        '${txn.isManualFallback ? ' · manual fallback' : ''}',
      ),
      trailing: Text(
        amtFmt.format(txn.amount),
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined,
              size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text('No transactions yet',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          const Text('Add one manually or scan a receipt'),
        ],
      ),
    );
  }
}
