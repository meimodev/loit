import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/loit_colors.dart';
import '../../core/theme/loit_radius.dart';
import '../../core/theme/loit_spacing.dart';
import '../../core/theme/loit_typography.dart';
import '../../shared/providers/budgets_provider.dart';
import '../../shared/providers/home_currency_provider.dart';
import '../../shared/providers/user_categories_provider.dart';
import '../../shared/providers/transactions_provider.dart';
import '../../shared/utils/amount_input.dart';
import '../../shared/widgets/loit_group_label.dart';
import '../../shared/widgets/loit_tx_row.dart';

class BudgetDetailScreen extends ConsumerWidget {
  const BudgetDetailScreen({super.key, required this.budgetId});

  final String budgetId;

  String _dayLabel(Budget b) {
    final now = DateTime.now();
    final start = b.windowStart(now);
    final dayInCycle =
        now.difference(DateTime(start.year, start.month, start.day)).inDays + 1;
    return 'Day $dayInCycle / ${b.cycleDays(now)}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.loitColors;
    final statuses = ref.watch(budgetStatusesProvider);
    final status = statuses.where((s) => s.budget.id == budgetId).firstOrNull;
    final txs = ref.watch(transactionsProvider).value ?? const [];

    if (status == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Budget not found')),
      );
    }
    final b = status.budget;
    final style = ref.watch(categoryStyleProvider(b.category));
    final catLabel = ref.watch(
        categoryLabelProvider(CategoryLabelKey(key: b.category)));
    final pct = (status.ratio * 100).round();
    final over = status.isOver;
    final overAmt = (status.spent - b.monthlyLimit).clamp(0, double.infinity).toDouble();

    final currency = ref.watch(homeCurrencyProvider);
    String fmt(double v) => formatMoney(v, currency);
    final contributing = txs
        .where((t) => t.category == b.category)
        .toList()
      ..sort((a, c) => c.createdAt.compareTo(a.createdAt));
    final top5 = contributing.take(5).toList();
    final df = DateFormat.MMMd();

    return Scaffold(
      backgroundColor: c.canvas,
      appBar: AppBar(
        leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop()),
        actions: [IconButton(icon: const Icon(Icons.more_vert), onPressed: () {})],
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            decoration: BoxDecoration(
              color: c.surface,
              border: Border(bottom: BorderSide(color: c.borderSubtle)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: style.tint.withValues(alpha: 0.14),
                        borderRadius: LoitRadius.brS,
                      ),
                      child:
                          Icon(style.icon, color: style.tint, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${catLabel.toUpperCase()} · ${b.period.label.toUpperCase()}',
                            style: LoitTypography.bodyS.copyWith(
                              color: c.contentSecondary,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.4,
                            )),
                        const SizedBox(height: 2),
                        Text.rich(
                          TextSpan(
                            style: LoitTypography.titleL.copyWith(
                              color: c.contentPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                            children: [
                              TextSpan(text: fmt(status.spent)),
                              TextSpan(
                                text: ' / ${fmt(b.monthlyLimit)}',
                                style: LoitTypography.bodyM.copyWith(
                                  color: c.contentSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: status.ratio.clamp(0, 1).toDouble(),
                    minHeight: 5,
                    backgroundColor: c.muted,
                    color: over ? c.danger : style.tint,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      over
                          ? '$pct% — ${fmt(overAmt)} over'
                          : '$pct% used',
                      style: LoitTypography.bodyS.copyWith(
                        color: over ? c.danger : c.contentSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(_dayLabel(b),
                        style: LoitTypography.bodyS
                            .copyWith(color: c.contentSecondary)),
                  ],
                ),
              ],
            ),
          ),
          if (top5.isNotEmpty) const LoitGroupLabel(label: 'CONTRIBUTING · TOP 5'),
          ...top5.map((t) => LoitTxRow(
                title: t.notes ?? '',
                categoryKey: t.category,
                subtitle: df.format(t.createdAt),
                amount: fmt(t.amount),
                onTap: t.id == null
                    ? null
                    : () => context.push('/transactions/${t.id}'),
              )),
          Padding(
            padding: const EdgeInsets.fromLTRB(
                LoitSpacing.s5, LoitSpacing.s6, LoitSpacing.s5, LoitSpacing.s4),
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                foregroundColor: c.danger,
                side: BorderSide(color: c.danger),
              ),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Delete budget?'),
                    content: Text(
                      'This permanently deletes the $catLabel budget. Transactions are kept. This cannot be undone.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        style: TextButton.styleFrom(foregroundColor: c.danger),
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );
                if (confirm != true) return;
                if (!context.mounted) return;
                try {
                  await ref.read(budgetsProvider.notifier).delete(b.id);
                  if (!context.mounted) return;
                  context.pop();
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Delete failed: $e')),
                  );
                }
              },
              child: const Text('Delete budget'),
            ),
          ),
          const SizedBox(height: LoitSpacing.s10),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(LoitSpacing.s4),
        decoration: BoxDecoration(
          color: c.surface,
          border: Border(top: BorderSide(color: c.borderSubtle)),
        ),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: OutlinedButton(
                    onPressed: () =>
                        context.push('/budgets/${b.id}/edit', extra: b),
                    child: const Text('Edit limit'),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: FilledButton(
                    onPressed: () {},
                    child: const Text('Roll over'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
