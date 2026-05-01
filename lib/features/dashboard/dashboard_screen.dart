import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/loit_categories.dart';
import '../../core/theme/loit_colors.dart';
import '../../core/theme/loit_radius.dart';
import '../../core/theme/loit_spacing.dart';
import '../../core/theme/loit_typography.dart';
import '../../shared/providers/auth_providers.dart';
import '../../shared/providers/budgets_provider.dart';
import '../../shared/providers/selected_month_provider.dart';
import '../../shared/providers/transactions_provider.dart';
import '../../shared/widgets/budget_alert_banner.dart';
import '../../shared/widgets/connectivity_banner.dart';
import '../../shared/widgets/loit_budget_row.dart';
import '../../shared/widgets/loit_month_app_bar.dart';
import '../../shared/widgets/loit_fab_stack.dart';
import '../../shared/widgets/loit_group_label.dart';
import '../../shared/widgets/loit_stat_triple.dart';
import '../../shared/widgets/loit_tx_row.dart';
import '../../shared/widgets/receipt_expiry_banner.dart';

/// LOIT Home / Dashboard.
///
/// Layout per design system (Home artboard, `screens-home-tx.jsx`):
///   1. Month app bar (chevrons + label + actions)
///   2. Stat triple (Income / Expenses / Total)
///   3. Hero summary band (day-of-month + MTD amount + goal bar)
///   4. Budgets group + edge-to-edge category rows
///   5. Recent group + edge-to-edge tx rows
///   6. FAB stack (scan + add) above bottom tab bar
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txns = ref.watch(transactionsProvider);
    final profile = ref.watch(userProfileProvider).value;
    final budgetStatuses = ref.watch(budgetStatusesProvider);
    final month = ref.watch(selectedMonthProvider);
    final c = context.loitColors;
    final now = DateTime.now();
    final isCurrentMonth = now.year == month.year && now.month == month.month;
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final dayOfMonth = isCurrentMonth ? now.day : daysInMonth;
    final overBudgetCount = budgetStatuses.where((s) => s.isOver).length;
    final onTrackCount = budgetStatuses.where((s) => !s.isOver).length;
    final isLateMonth = dayOfMonth / daysInMonth >= 0.75;
    final isDense = isLateMonth && overBudgetCount > 0;

    return Scaffold(
      backgroundColor: c.canvas,
      appBar: LoitMonthAppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.search, size: 20),
            tooltip: 'Search',
            onPressed: () => context.push('/transactions?focus=search'),
          ),
          IconButton(
            icon: const Icon(Icons.tune, size: 20),
            tooltip: 'Filter',
            onPressed: () {},
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(transactionsProvider.notifier).refresh(),
        child: txns.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (items) {
            final summary = _MonthSummary.fromTxns(items, month);
            final currency = profile?.homeCurrency ?? 'IDR';
            final today = DateTime(now.year, now.month, now.day);
            final todays = isCurrentMonth
                ? items.where((t) => !t.createdAt.isBefore(today)).toList()
                : <Txn>[];
            return CustomScrollView(
              slivers: [
                const SliverToBoxAdapter(child: ConnectivityBanner()),
                SliverToBoxAdapter(
                  child: LoitStatTriple(
                    stats: [
                      LoitStat(
                        label: 'Income',
                        amount: _fmt(summary.income, currency),
                        color: c.info,
                      ),
                      LoitStat(
                        label: 'Expenses',
                        amount: _fmt(summary.expenses, currency),
                        color: c.danger,
                      ),
                      LoitStat(
                        label: 'Total',
                        amount: _fmt(summary.income - summary.expenses, currency),
                      ),
                    ],
                  ),
                ),
                if (isDense) ...[
                  SliverToBoxAdapter(
                    child: _DenseAlertPill(
                      message:
                          '$overBudgetCount budgets over. Day $dayOfMonth of $daysInMonth.',
                      onTap: () => context.push('/budgets'),
                    ),
                  ),
                  const SliverToBoxAdapter(
                    child: LoitGroupLabel(label: 'Quick stats'),
                  ),
                  SliverToBoxAdapter(
                    child: Container(
                      color: c.surface,
                      child: Column(
                        children: [
                          _QuickStatRow(
                            label: 'Budgets',
                            value: '$onTrackCount of ${budgetStatuses.length} on track',
                            valueColor: c.success,
                          ),
                          _QuickStatRow(
                            label: 'Over budget',
                            value: '$overBudgetCount',
                            valueColor: c.danger,
                          ),
                          _QuickStatRow(
                            label: 'Spent MTD',
                            value: _fmt(summary.expenses, currency),
                            valueColor: c.contentPrimary,
                          ),
                          _QuickStatRow(
                            label: 'Transactions',
                            value: '${items.length}',
                            valueColor: c.info,
                            showDivider: false,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: LoitGroupLabel(label: 'Today')),
                  if (todays.isEmpty)
                    SliverToBoxAdapter(
                      child: Container(
                        color: c.surface,
                        padding: const EdgeInsets.all(LoitSpacing.s4),
                        child: Text(
                          'No transactions yet today.',
                          style: LoitTypography.bodyM
                              .copyWith(color: c.contentTertiary),
                        ),
                      ),
                    )
                  else
                    SliverList.builder(
                      itemCount: todays.length,
                      itemBuilder: (_, i) {
                        final t = todays[i];
                        return LoitTxRow(
                          merchant: t.merchant ?? t.category ?? 'Transaction',
                          categoryKey: t.category,
                          subtitle: _txSubtitle(t),
                          amount: _fmt(t.amount, t.currency),
                          showDivider: i != todays.length - 1,
                          onTap: () {},
                        );
                      },
                    ),
                ] else ...[
                  SliverToBoxAdapter(
                    child: _HeroSummary(
                      dayOfMonth: dayOfMonth,
                      daysInMonth: daysInMonth,
                      spentLabel: _fmt(summary.expenses, currency),
                      goalLabel:
                          'Goal: ${_fmt(_estimatedGoal(summary), currency)}',
                      progress: _goalProgress(summary),
                    ),
                  ),
                  const SliverToBoxAdapter(child: BudgetAlertBanner()),
                  const SliverToBoxAdapter(child: ReceiptExpiryBanner()),
                  if (items.isEmpty)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: _EmptyState(),
                    )
                  else ...[
                    if (budgetStatuses.isNotEmpty) ...[
                      const SliverToBoxAdapter(
                        child: LoitGroupLabel(label: 'Budgets'),
                      ),
                      SliverToBoxAdapter(
                        child: Container(
                          color: c.surface,
                          child: Column(
                            children: _topBudgetRows(
                              context: context,
                              statuses: budgetStatuses,
                              currency: currency,
                            ),
                          ),
                        ),
                      ),
                    ],
                    const SliverToBoxAdapter(
                      child: LoitGroupLabel(label: 'Recent'),
                    ),
                    SliverList.builder(
                      itemCount: items.length,
                      itemBuilder: (_, i) {
                        final t = items[i];
                        return LoitTxRow(
                          merchant: t.merchant ?? t.category ?? 'Transaction',
                          categoryKey: t.category,
                          subtitle: _txSubtitle(t),
                          amount: _fmt(t.amount, t.currency),
                          showDivider: i != items.length - 1,
                          onTap: () {},
                        );
                      },
                    ),
                  ],
                ],
                const SliverToBoxAdapter(child: SizedBox(height: 120)),
              ],
            );
          },
        ),
      ),
      floatingActionButton: LoitFabStack(
        onPrimary: () => context.push('/transactions/new'),
        onSecondary: () => context.push('/scan'),
        primaryTooltip: 'Add expense',
        secondaryTooltip: 'Scan receipt',
        primaryIcon: Icons.add,
        secondaryIcon: Icons.document_scanner_outlined,
      ),
    );
  }

  String _fmt(double v, String currency) {
    final fmt = NumberFormat.simpleCurrency(name: currency, decimalDigits: 0);
    return fmt.format(v);
  }

  double _estimatedGoal(_MonthSummary s) =>
      s.expenses == 0 ? 6200000 : (s.expenses / 0.68).roundToDouble();

  double _goalProgress(_MonthSummary s) {
    final goal = _estimatedGoal(s);
    if (goal == 0) return 0;
    return (s.expenses / goal).clamp(0, 1).toDouble();
  }

  String _txSubtitle(Txn t) {
    final when = DateFormat.MMMd().add_jm().format(t.createdAt.toLocal());
    final tags = <String>[
      if (t.aiParsed) 'AI',
      if (t.isManualFallback) 'Manual',
    ];
    return tags.isEmpty ? when : '$when · ${tags.join(' · ')}';
  }
}

/// Top-3 budget rows by spend ratio (over-budget first, then approaching).
List<Widget> _topBudgetRows({
  required BuildContext context,
  required List<BudgetStatus> statuses,
  required String currency,
}) {
  final fmt = NumberFormat.simpleCurrency(name: currency, decimalDigits: 0);
  final sorted = [...statuses]..sort((a, b) => b.ratio.compareTo(a.ratio));
  final picked = sorted.take(3).toList();
  return [
    for (var i = 0; i < picked.length; i++)
      LoitBudgetRow(
        label: LoitCategories.resolve(picked[i].budget.category).label,
        categoryKey: picked[i].budget.category,
        percent: (picked[i].ratio * 100).round(),
        subtitle:
            '${fmt.format(picked[i].spent)} of ${fmt.format(picked[i].budget.monthlyLimit)}',
        showDivider: i != picked.length - 1,
        onTap: () =>
            GoRouter.of(context).push('/budgets/${picked[i].budget.id}'),
      ),
  ];
}

class _MonthSummary {
  const _MonthSummary({required this.income, required this.expenses});
  final double income;
  final double expenses;

  factory _MonthSummary.fromTxns(List<Txn> items, DateTime month) {
    final monthStart = DateTime(month.year, month.month, 1);
    final monthEnd = DateTime(month.year, month.month + 1, 1);
    var income = 0.0;
    var expenses = 0.0;
    for (final t in items) {
      if (t.createdAt.isBefore(monthStart)) continue;
      if (!t.createdAt.isBefore(monthEnd)) continue;
      final v = t.amountHome ?? t.amount;
      if (v < 0) {
        income += -v;
      } else {
        expenses += v;
      }
    }
    return _MonthSummary(income: income, expenses: expenses);
  }
}

class _HeroSummary extends StatelessWidget {
  const _HeroSummary({
    required this.dayOfMonth,
    required this.daysInMonth,
    required this.spentLabel,
    required this.goalLabel,
    required this.progress,
  });

  final int dayOfMonth;
  final int daysInMonth;
  final String spentLabel;
  final String goalLabel;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final c = context.loitColors;
    return Container(
      color: c.canvas,
      padding: const EdgeInsets.fromLTRB(
        LoitSpacing.s5,
        LoitSpacing.s4,
        LoitSpacing.s5,
        LoitSpacing.s3,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                'DAY $dayOfMonth · $daysInMonth',
                style: LoitTypography.labelS
                    .copyWith(color: c.contentSecondary, letterSpacing: 0.5),
              ),
              Text(
                goalLabel,
                style: LoitTypography.bodyS.copyWith(color: c.contentTertiary),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(spentLabel, style: LoitTypography.amountHero.copyWith(color: c.contentPrimary)),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: LoitRadius.brFull,
            child: Container(
              height: 5,
              color: c.muted,
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: progress,
                child: Container(color: c.brand),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DenseAlertPill extends StatelessWidget {
  const _DenseAlertPill({required this.message, this.onTap});
  final String message;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.loitColors;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: LoitSpacing.s4,
          vertical: LoitSpacing.s3,
        ),
        decoration: BoxDecoration(
          color: c.dangerSurface,
          border: Border(
            bottom: BorderSide(color: c.borderSubtle, width: 1),
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.warning_amber_rounded, size: 18, color: c.danger),
            const SizedBox(width: LoitSpacing.s2),
            Expanded(
              child: Text(
                message,
                style: LoitTypography.bodyS.copyWith(
                  color: c.danger,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(Icons.chevron_right, size: 16, color: c.danger),
          ],
        ),
      ),
    );
  }
}

class _QuickStatRow extends StatelessWidget {
  const _QuickStatRow({
    required this.label,
    required this.value,
    required this.valueColor,
    this.showDivider = true,
  });
  final String label;
  final String value;
  final Color valueColor;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final c = context.loitColors;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: LoitSpacing.s4,
        vertical: LoitSpacing.s3,
      ),
      decoration: BoxDecoration(
        border: showDivider
            ? Border(bottom: BorderSide(color: c.borderSubtle, width: 1))
            : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: LoitTypography.bodyM.copyWith(color: c.contentPrimary),
          ),
          Text(
            value,
            style: LoitTypography.bodyM.copyWith(
              color: valueColor,
              fontWeight: FontWeight.w600,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final c = context.loitColors;
    return Padding(
      padding: const EdgeInsets.all(LoitSpacing.s6),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              border: Border.all(color: c.borderDefault, style: BorderStyle.solid),
              borderRadius: LoitRadius.brL,
              color: c.surface,
            ),
            alignment: Alignment.center,
            child: Icon(Icons.receipt_long_outlined, size: 40, color: c.brand),
          ),
          const SizedBox(height: LoitSpacing.s5),
          Text(
            'Ready when you are',
            style: LoitTypography.titleM.copyWith(color: c.contentPrimary),
          ),
          const SizedBox(height: LoitSpacing.s2),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 260),
            child: Text(
              'Snap your first receipt or type in an expense — both take about five seconds.',
              textAlign: TextAlign.center,
              style: LoitTypography.bodyM.copyWith(color: c.contentSecondary),
            ),
          ),
          const SizedBox(height: LoitSpacing.s5),
          Wrap(
            spacing: LoitSpacing.s3,
            children: [
              FilledButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.camera_alt_outlined, size: 18),
                label: const Text('Scan'),
              ),
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add manually'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
