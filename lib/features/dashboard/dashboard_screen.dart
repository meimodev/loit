import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/loit_colors.dart';
import '../../core/theme/loit_elevation.dart';
import '../../core/theme/loit_radius.dart';
import '../../core/theme/loit_spacing.dart';
import '../../core/theme/loit_typography.dart';
import '../../shared/providers/accounts_provider.dart';
import '../../shared/providers/auth_providers.dart';
import '../../shared/providers/budgets_provider.dart';
import '../../shared/providers/selected_month_provider.dart';
import '../../shared/providers/transactions_provider.dart';
import '../../shared/providers/user_categories_provider.dart';
import '../../shared/utils/amount_input.dart';
import '../../shared/widgets/budget_alert_banner.dart';
import '../../shared/widgets/loit_budget_row.dart';
import '../../shared/widgets/loit_group_label.dart';
import '../../shared/widgets/loit_mini_line_chart.dart';
import '../../shared/widgets/loit_stat_triple.dart';
import '../../shared/widgets/receipt_expiry_banner.dart';

/// LOIT Home / Dashboard.
///
/// Layout:
///   1. LOIT title bar with profile avatar
///   2. Net worth strip (Assets / Liabilities / Net Worth)
///   3. Accounts horizontal scroll
///   4. Hero summary band (day-of-month + MTD amount + goal bar)
///   5. Budget alerts and receipt expiry banners
///   6. Budgets group + edge-to-edge category rows
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txns = ref.watch(transactionsProvider);
    final profile = ref.watch(userProfileProvider).value;
    final budgetStatuses = ref.watch(budgetStatusesProvider);
    final month = ref.watch(selectedMonthProvider);
    final accounts = ref.watch(activeAccountsProvider);
    final balances = ref.watch(accountBalancesProvider);
    final totalAssets = ref.watch(totalAssetsProvider);
    final totalLiabilities = ref.watch(totalLiabilitiesProvider);
    final netWorth = ref.watch(netWorthProvider);
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
      appBar: AppBar(
        title: const Text('LOIT'),
        backgroundColor: c.canvas,
        scrolledUnderElevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: LoitSpacing.s4),
            child: GestureDetector(
              onTap: () => context.push('/settings/profile'),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: c.brand,
                child: Text(
                  _avatarInitial(profile),
                  style: LoitTypography.labelS.copyWith(color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(transactionsProvider.notifier).refresh(),
        child: txns.when(
          skipLoadingOnReload: true,
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (items) {
            final summary = _MonthSummary.fromTxns(items, month);
            final currency = profile?.homeCurrency ?? 'IDR';
            final byDay = _spendByDay(items, month);
            final activeDays = byDay.where((v) => v > 0).length;
            final avgDay = activeDays == 0
                ? 0.0
                : byDay.reduce((a, b) => a + b) / activeDays;
            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: _ReportsPreviewCard(
                    byDay: byDay,
                    avgDay: avgDay,
                    mtdSpend: summary.expenses,
                    currency: currency,
                    onTap: () => context.push('/reports'),
                  ),
                ),
                // Net worth strip
                SliverToBoxAdapter(
                  child: LoitStatTriple(
                    stats: [
                      LoitStat(
                        label: 'Assets',
                        amount: _fmt(totalAssets, currency),
                        color: c.success,
                      ),
                      LoitStat(
                        label: 'Liabilities',
                        amount: _fmt(totalLiabilities, currency),
                        color: c.danger,
                      ),
                      LoitStat(
                        label: 'Net worth',
                        amount: _fmt(netWorth, currency),
                        color: netWorth >= 0 ? c.success : c.danger,
                      ),
                    ],
                  ),
                ),
                // Accounts list
                if (accounts.isEmpty)
                  SliverToBoxAdapter(
                    child: _AddFirstAccountBanner(
                      onTap: () => context.push('/accounts/new'),
                    ),
                  )
                else ...[
                  const SliverToBoxAdapter(
                    child: LoitGroupLabel(label: 'Accounts'),
                  ),
                  SliverToBoxAdapter(
                    child: Container(
                      color: c.surface,
                      child: Column(
                        children: [
                          for (var i = 0; i < accounts.length; i++)
                            _AccountRow(
                              account: accounts[i],
                              balance: balances[accounts[i].id] ?? 0,
                              currency: currency,
                              showDivider: true,
                              onTap: () => context.push(
                                '/accounts/${accounts[i].id}/edit',
                                extra: accounts[i],
                              ),
                            ),
                          _AccountRow.add(
                            onTap: () => context.push('/accounts/new'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
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
                ] else ...[
                  const SliverToBoxAdapter(child: BudgetAlertBanner()),
                  const SliverToBoxAdapter(child: ReceiptExpiryBanner()),
                  const SliverToBoxAdapter(
                    child: LoitGroupLabel(label: 'Budgets'),
                  ),
                  SliverToBoxAdapter(
                    child: Container(
                      color: c.surface,
                      child: Column(
                        children: [
                          ..._topBudgetRows(
                            context: context,
                            ref: ref,
                            statuses: budgetStatuses,
                            currency: currency,
                          ),
                          _AddBudgetRow(
                            onTap: () => context.push('/budgets/new'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: _ManageCategoriesCard(
                      onTap: () => context.push('/categories'),
                    ),
                  ),
                ],
                const SliverToBoxAdapter(child: SizedBox(height: 80)),
              ],
            );
          },
        ),
      ),
    );
  }
  String _fmt(double v, String currency) => formatMoney(v, currency);

  String _avatarInitial(UserProfile? profile) {
    if (profile != null && profile.name.isNotEmpty) {
      return profile.name[0].toUpperCase();
    }
    if (profile != null && profile.email.isNotEmpty) {
      return profile.email[0].toUpperCase();
    }
    return '?';
  }
}

List<double> _spendByDay(List<Txn> txns, DateTime month) {
  final days = DateTime(month.year, month.month + 1, 0).day;
  final out = List<double>.filled(days, 0);
  final monthStart = DateTime(month.year, month.month, 1);
  final monthEnd = DateTime(month.year, month.month + 1, 1);
  for (final t in txns) {
    if (t.isTransfer || t.isIncome) continue;
    if (t.createdAt.isBefore(monthStart)) continue;
    if (!t.createdAt.isBefore(monthEnd)) continue;
    final v = (t.amountHome ?? t.amount).abs();
    final d = t.createdAt.day;
    if (d >= 1 && d <= days) out[d - 1] += v;
  }
  return out;
}

class _ReportsPreviewCard extends StatelessWidget {
  const _ReportsPreviewCard({
    required this.byDay,
    required this.avgDay,
    required this.mtdSpend,
    required this.currency,
    required this.onTap,
  });

  final List<double> byDay;
  final double avgDay;
  final double mtdSpend;
  final String currency;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.loitColors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        LoitSpacing.s4,
        LoitSpacing.s5,
        LoitSpacing.s4,
        LoitSpacing.s4,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: LoitRadius.brM,
        child: InkWell(
          onTap: onTap,
          borderRadius: LoitRadius.brM,
          child: Container(
            padding: const EdgeInsets.all(LoitSpacing.s5),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: LoitRadius.brM,
              border: Border.all(
                color: c.brand.withValues(alpha: 0.4),
                width: 1.2,
              ),
              boxShadow: LoitElevation.e2,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'INSIGHTS',
                      style: LoitTypography.labelS.copyWith(
                        color: c.contentSecondary,
                        letterSpacing: 0.4,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: LoitSpacing.s4,
                        vertical: LoitSpacing.s2,
                      ),
                      decoration: BoxDecoration(
                        color: LoitPalette.teal800,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'See report →',
                        style: LoitTypography.labelS.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.4,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: LoitSpacing.s3),
                Text(
                  'Spending this month',
                  style: LoitTypography.titleM.copyWith(
                    color: c.contentPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: LoitSpacing.s4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _PreviewMetric(
                      label: 'AVG/DAY',
                      value: formatMoney(avgDay, currency),
                      align: TextAlign.left,
                    ),
                    _PreviewMetric(
                      label: 'MTD',
                      value: formatMoney(mtdSpend, currency),
                      align: TextAlign.right,
                    ),
                  ],
                ),
                const SizedBox(height: LoitSpacing.s4),
                LoitMiniLineChart(
                  values: byDay,
                  height: 80,
                  formatValue: (v) => formatMoney(v, currency),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PreviewMetric extends StatelessWidget {
  const _PreviewMetric({
    required this.label,
    required this.value,
    required this.align,
  });
  final String label;
  final String value;
  final TextAlign align;

  @override
  Widget build(BuildContext context) {
    final c = context.loitColors;
    final cross = align == TextAlign.right
        ? CrossAxisAlignment.end
        : CrossAxisAlignment.start;
    return Column(
      crossAxisAlignment: cross,
      children: [
        Text(
          label,
          style: LoitTypography.labelS.copyWith(
            color: c.contentSecondary,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: LoitTypography.bodyM.copyWith(
            color: c.contentPrimary,
            fontWeight: FontWeight.w600,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

class _ManageCategoriesCard extends StatelessWidget {
  const _ManageCategoriesCard({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.loitColors;
    return InkWell(
      onTap: onTap,
      borderRadius: LoitRadius.brM,
      child: Container(
        margin: const EdgeInsets.fromLTRB(
          LoitSpacing.s4,
          LoitSpacing.s3,
          LoitSpacing.s4,
          LoitSpacing.s2,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: LoitSpacing.s4,
          vertical: LoitSpacing.s4,
        ),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: LoitRadius.brM,
          border: Border.all(color: c.borderSubtle),
        ),
        child: Row(
          children: [
            Icon(Icons.category_outlined, size: 20, color: c.brand),
            const SizedBox(width: LoitSpacing.s3),
            Expanded(
              child: Text(
                'Manage categories',
                style: LoitTypography.bodyM.copyWith(
                  color: c.brand,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(Icons.chevron_right, size: 16, color: c.contentTertiary),
          ],
        ),
      ),
    );
  }
}

/// Top-3 budget rows by spend ratio (over-budget first, then approaching).
List<Widget> _topBudgetRows({
  required BuildContext context,
  required WidgetRef ref,
  required List<BudgetStatus> statuses,
  required String currency,
}) {
  final sorted = [...statuses]..sort((a, b) => b.ratio.compareTo(a.ratio));
  final picked = sorted.take(3).toList();
  return [
    for (var i = 0; i < picked.length; i++)
      LoitBudgetRow(
        label: ref.watch(categoryLabelProvider(
            CategoryLabelKey(key: picked[i].budget.category))),
        categoryKey: picked[i].budget.category,
        percent: (picked[i].ratio * 100).round(),
        subtitle:
            '${formatMoney(picked[i].spent, currency)} of ${formatMoney(picked[i].budget.monthlyLimit, currency)}',
        showDivider: true,
        onTap: () =>
            GoRouter.of(context).push('/budgets/${picked[i].budget.id}'),
      ),
  ];
}

class _AddBudgetRow extends StatelessWidget {
  const _AddBudgetRow({required this.onTap});
  final VoidCallback onTap;

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
        child: Row(
          children: [
            Icon(Icons.add, size: 18, color: c.brand),
            const SizedBox(width: LoitSpacing.s3),
            Text(
              'Add budget',
              style: LoitTypography.bodyM.copyWith(color: c.brand),
            ),
          ],
        ),
      ),
    );
  }
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
      if (t.isTransfer) continue;
      if (t.createdAt.isBefore(monthStart)) continue;
      if (!t.createdAt.isBefore(monthEnd)) continue;
      final v = t.amountHome ?? t.amount;
      if (t.isIncome) {
        income += v.abs();
      } else {
        expenses += v.abs();
      }
    }
    return _MonthSummary(income: income, expenses: expenses);
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

class _AddFirstAccountBanner extends StatelessWidget {
  const _AddFirstAccountBanner({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.loitColors;
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(
          LoitSpacing.s4,
          LoitSpacing.s3,
          LoitSpacing.s4,
          LoitSpacing.s3,
        ),
        padding: const EdgeInsets.all(LoitSpacing.s4),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: LoitRadius.brM,
          border: Border.all(color: c.borderSubtle),
        ),
        child: Row(
          children: [
            Icon(Icons.account_balance_wallet_outlined,
                size: 20, color: c.brand),
            const SizedBox(width: LoitSpacing.s3),
            Expanded(
              child: Text(
                'Add your first account to start tracking balances.',
                style:
                    LoitTypography.bodyS.copyWith(color: c.contentSecondary),
              ),
            ),
            Icon(Icons.chevron_right, size: 16, color: c.contentTertiary),
          ],
        ),
      ),
    );
  }
}

class _AccountRow extends StatelessWidget {
  const _AccountRow({
    required this.account,
    required this.balance,
    required this.currency,
    required this.onTap,
    this.showDivider = true,
  })  : isAdd = false;

  const _AccountRow.add({required this.onTap})
      : account = null,
        balance = 0,
        currency = '',
        showDivider = false,
        isAdd = true;

  final Account? account;
  final double balance;
  final String currency;
  final VoidCallback onTap;
  final bool showDivider;
  final bool isAdd;

  @override
  Widget build(BuildContext context) {
    final c = context.loitColors;
    final divider = showDivider
        ? Border(bottom: BorderSide(color: c.borderSubtle, width: 1))
        : null;

    if (isAdd) {
      return InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: LoitSpacing.s4,
            vertical: LoitSpacing.s3,
          ),
          decoration: BoxDecoration(border: divider),
          child: Row(
            children: [
              Icon(Icons.add, size: 18, color: c.brand),
              const SizedBox(width: LoitSpacing.s3),
              Text(
                'Add account',
                style: LoitTypography.bodyM.copyWith(color: c.brand),
              ),
            ],
          ),
        ),
      );
    }

    final a = account!;
    final isAsset = a.kind == AccountKind.asset;
    final iconColor = isAsset ? c.success : c.danger;
    final amountColor = balance < 0 ? c.danger : c.success;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: LoitSpacing.s4,
          vertical: LoitSpacing.s3,
        ),
        decoration: BoxDecoration(border: divider),
        child: Row(
          children: [
            Icon(
              isAsset
                  ? Icons.account_balance_wallet_outlined
                  : Icons.credit_card_outlined,
              size: 18,
              color: iconColor,
            ),
            const SizedBox(width: LoitSpacing.s3),
            Expanded(
              child: Text(
                a.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: LoitTypography.bodyM.copyWith(color: c.contentPrimary),
              ),
            ),
            Text(
              formatMoney(balance, currency),
              style: LoitTypography.bodyM.copyWith(
                color: amountColor,
                fontWeight: FontWeight.w600,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
