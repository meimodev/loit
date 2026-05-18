import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../shared/utils/locale_date_format.dart';

import '../../core/theme/loit_colors.dart';
import '../../core/theme/loit_spacing.dart';
import '../../core/theme/loit_typography.dart';
import '../../l10n/l10n_x.dart';
import '../../shared/providers/auth_providers.dart';
import '../../shared/providers/budgets_provider.dart';
import '../../shared/providers/transactions_provider.dart';
import '../../shared/providers/user_categories_provider.dart';
import '../../shared/utils/amount_input.dart';
import '../../shared/widgets/loit_app_bar_month.dart';
import '../../shared/widgets/loit_budget_row.dart';
import '../../shared/widgets/loit_empty_state.dart';
import '../../shared/widgets/loit_fab_stack.dart';
import '../../shared/widgets/loit_group_label.dart';
import '../../shared/widgets/loit_stat_triple.dart';
import '../paywall/paywall_screen.dart';

class BudgetsScreen extends ConsumerStatefulWidget {
  const BudgetsScreen({super.key});

  @override
  ConsumerState<BudgetsScreen> createState() => _BudgetsScreenState();
}

class _BudgetsScreenState extends ConsumerState<BudgetsScreen> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  int _periodTab = 0;

  @override
  Widget build(BuildContext context) {
    final c = context.loitColors;
    final l = context.l10n;
    final budgets = ref.watch(budgetsProvider);
    final statuses = ref.watch(budgetStatusesProvider);
    final profile = ref.watch(userProfileProvider).value;
    final currency = profile?.homeCurrency ?? 'IDR';
    String fmt(double v) => formatMoney(v, currency);
    final monthLabel = yMMM(context).format(_month);

    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final dayOfMonth = now.day;

    final totalLimit = statuses.fold<double>(
      0,
      (s, b) => s + b.monthlyLimit,
    );
    final totalSpent = statuses.fold<double>(0, (s, b) => s + b.spent);
    final left = (totalLimit - totalSpent).clamp(0, double.infinity).toDouble();

    final overCount = statuses.where((s) => s.isOver).length;
    final paceLabel = _paceLabel(
      spent: totalSpent,
      limit: totalLimit,
      dayOfMonth: dayOfMonth,
      daysInMonth: daysInMonth,
      overCount: overCount,
    );

    return Scaffold(
      backgroundColor: c.canvas,
      appBar: LoitAppBarMonth(
        label: monthLabel,
        onPrev: () =>
            setState(() => _month = DateTime(_month.year, _month.month - 1)),
        onNext: () =>
            setState(() => _month = DateTime(_month.year, _month.month + 1)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, size: 20),
            tooltip: l.budgetsScreenNewBudget,
            onPressed: () => _addBudget(),
          ),
          IconButton(
            icon: const Icon(Icons.tune, size: 20),
            tooltip: l.budgetsScreenFilter,
            onPressed: () {},
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(budgetsProvider);
          ref.invalidate(transactionsProvider);
          ref.invalidate(userProfileProvider);
          await ref.read(budgetsProvider.future);
        },
        child: budgets.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (items) {
          return CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: _PeriodTabs(
                  active: _periodTab,
                  onTap: (i) => setState(() => _periodTab = i),
                ),
              ),
              SliverToBoxAdapter(
                child: LoitStatTriple(
                  stats: [
                    LoitStat(
                      label: l.budgetsScreenLimit,
                      amount: fmt(totalLimit),
                      color: c.info,
                    ),
                    LoitStat(
                      label: l.budgetsScreenSpent,
                      amount: fmt(totalSpent),
                      color: c.danger,
                    ),
                    LoitStat(
                      label: l.budgetsScreenLeft,
                      amount: fmt(left),
                      color: c.brand,
                    ),
                  ],
                ),
              ),
              if (items.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: LoitEmptyState(
                      icon: Icons.savings_outlined,
                      title: l.budgetsScreenNoBudgets,
                      body: l.budgetsScreenEmptyBody,
                      primaryCta: l.budgetsScreenNewBudget,
                      onPrimaryCta: _addBudget,
                    ),
                  ),
                )
              else ...[
                SliverToBoxAdapter(
                  child: LoitGroupLabel(
                    label: l.budgetsScreenCategories,
                    trailing: Text(
                      paceLabel,
                      style: LoitTypography.bodyS.copyWith(
                        color: c.contentTertiary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                SliverList.builder(
                  itemCount: statuses.length,
                  itemBuilder: (_, i) {
                    final s = statuses[i];
                    final pct = (s.ratio * 100).round();
                    final overAmt = s.spent - s.monthlyLimit;
                    final subtitleParts = [
                      l.dashboardOfPattern(
                          fmt(s.spent), fmt(s.monthlyLimit)),
                      if (s.isOver) l.budgetDetailOverBudget(pct, fmt(overAmt)),
                    ];
                    return LoitBudgetRow(
                      label: ref.watch(categoryLabelProvider(
                          CategoryLabelKey(key: s.budget.category))),
                      categoryKey: s.budget.category,
                      percent: pct,
                      subtitle: subtitleParts.join(' · '),
                      showDivider: i != statuses.length - 1,
                      onTap: () => context.push('/budgets/${s.budget.id}'),
                    );
                  },
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 120)),
              ],
            ],
          );
        },
      ),
      ),
      floatingActionButton: LoitFabStack(
        primaryIcon: Icons.add,
        primaryTooltip: l.budgetsScreenNewBudget,
        onPrimary: _addBudget,
      ),
    );
  }

  void _addBudget() {
    final budgets = ref.read(budgetsProvider).value ?? const [];
    final cap = ref.read(userProfileProvider).value?.budgetLimit ?? 3;
    if (budgets.length >= cap) {
      showPaywallSheet(context, feature: 'unlimited_budgets');
      return;
    }
    context.push('/budgets/new');
  }

  String _paceLabel({
    required double spent,
    required double limit,
    required int dayOfMonth,
    required int daysInMonth,
    required int overCount,
  }) {
    final l = context.l10n;
    if (limit <= 0) return l.budgetsScreenNoLimits;
    if (overCount > 0) {
      return l.budgetsScreenDayOver(dayOfMonth, daysInMonth, overCount);
    }
    final expected = limit * (dayOfMonth / daysInMonth);
    final onPace = spent <= expected;
    return onPace
        ? l.budgetsScreenOnPace(dayOfMonth, daysInMonth)
        : l.budgetsScreenOverPace(dayOfMonth, daysInMonth);
  }
}

class _PeriodTabs extends StatelessWidget {
  const _PeriodTabs({required this.active, required this.onTap});

  final int active;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.loitColors;
    final l = context.l10n;
    final labels = [l.budgetsScreenMonthly, l.budgetsScreenWeekly, l.budgetsScreenCustom];
    return Container(
      color: c.canvas,
      padding: const EdgeInsets.fromLTRB(
        LoitSpacing.s5,
        LoitSpacing.s1,
        LoitSpacing.s5,
        LoitSpacing.s2,
      ),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++) ...[
            _TabChip(
              label: labels[i],
              active: i == active,
              onTap: () => onTap(i),
            ),
            if (i < labels.length - 1) const SizedBox(width: LoitSpacing.s2),
          ],
        ],
      ),
    );
  }
}

class _TabChip extends StatelessWidget {
  const _TabChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.loitColors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: LoitSpacing.s4,
          vertical: LoitSpacing.s2,
        ),
        decoration: BoxDecoration(
          color: active ? c.brand : c.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: active ? c.brand : c.borderSubtle),
        ),
        child: Text(
          label,
          style: LoitTypography.bodyS.copyWith(
            color: active ? Colors.white : c.contentSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
