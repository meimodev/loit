import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/loit_colors.dart';
import '../../core/theme/loit_elevation.dart';
import '../../core/theme/loit_motion.dart';
import '../../core/theme/loit_radius.dart';
import '../../core/theme/loit_spacing.dart';
import '../../core/theme/loit_typography.dart';
import '../../l10n/l10n_x.dart';
import '../../shared/providers/accounts_provider.dart';
import '../../shared/providers/auth_providers.dart';
import '../../shared/providers/budgets_provider.dart';
import '../../shared/providers/selected_month_provider.dart';
import '../../shared/providers/transactions_provider.dart';
import '../../shared/providers/user_categories_provider.dart';
import '../../shared/utils/amount_input.dart';
import '../../shared/widgets/budget_alert_banner.dart';
import '../../shared/widgets/loit_budget_row.dart';
import '../../shared/widgets/loit_category_avatar.dart';
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
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entrance;
  bool _entranceStarted = false;

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(
      vsync: this,
      duration: LoitMotion.entrance + LoitMotion.staggerStep * 5,
    );
  }

  void _maybeStartEntrance() {
    if (_entranceStarted) return;
    _entranceStarted = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _entrance.forward();
    });
  }

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.disableAnimationsOf(context);
    final txns = ref.watch(transactionsProvider);
    final profile = ref.watch(userProfileProvider).value;
    final budgetStatuses = ref.watch(budgetStatusesProvider);
    final month = ref.watch(selectedMonthProvider);
    final accounts = ref.watch(activeAccountsProvider);
    final balances = ref.watch(accountBalancesProvider);
    final nativeBalances = ref.watch(accountNativeBalancesProvider);
    final totalAssets = ref.watch(totalAssetsProvider);
    final totalLiabilities = ref.watch(totalLiabilitiesProvider);
    final netWorth = ref.watch(netWorthProvider);
    final c = context.loitColors;
    final l = context.l10n;
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
            child: _PressScale(
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
            _maybeStartEntrance();
            final currency = profile?.homeCurrency ?? 'IDR';
            final summary = _MonthSummary.fromTxns(items, month, currency);
            final byDay = _spendByDay(items, month, currency);
            final activeDays = byDay.where((v) => v > 0).length;
            final avgDay = activeDays == 0
                ? 0.0
                : byDay.reduce((a, b) => a + b) / activeDays;
            final monthStart = DateTime(month.year, month.month, 1);
            final monthEnd = DateTime(month.year, month.month + 1, 1);
            final hasMonthTxn = items.any((t) =>
                !t.createdAt.isBefore(monthStart) &&
                t.createdAt.isBefore(monthEnd));
            Widget fadeUpSliver(int index, Widget child) {
              return SliverToBoxAdapter(
                child: _FadeUp(
                  controller: _entrance,
                  index: index,
                  reduced: reduced,
                  child: child,
                ),
              );
            }

            return CustomScrollView(
              slivers: [
                fadeUpSliver(
                  0,
                  hasMonthTxn
                      ? _ReportsPreviewCard(
                          byDay: byDay,
                          avgDay: avgDay,
                          mtdSpend: summary.expenses,
                          currency: currency,
                          onTap: () => context.push('/reports'),
                        )
                      : _PastReportsCard(
                          onTap: () => context.push('/reports'),
                        ),
                ),
                // Net worth strip
                fadeUpSliver(
                  1,
                  LoitStatTriple(
                    stats: [
                      LoitStat(
                        label: l.dashboardAssets,
                        amount: _fmt(totalAssets, currency),
                        color: c.success,
                      ),
                      LoitStat(
                        label: l.dashboardLiabilities,
                        amount: _fmt(totalLiabilities, currency),
                        color: c.danger,
                      ),
                      LoitStat(
                        label: l.dashboardNetWorth,
                        amount: _fmt(netWorth, currency),
                        color: netWorth >= 0 ? c.success : c.danger,
                      ),
                    ],
                  ),
                ),
                // Accounts list
                if (accounts.isEmpty)
                  fadeUpSliver(
                    2,
                    _AddFirstAccountBanner(
                      onTap: () => context.push('/accounts/new'),
                    ),
                  )
                else ...[
                  fadeUpSliver(2, LoitGroupLabel(label: l.dashboardAccounts)),
                  fadeUpSliver(
                    3,
                    Container(
                      color: c.surface,
                      child: Column(
                        children: [
                          for (var i = 0; i < accounts.length; i++)
                            _AccountRow(
                              account: accounts[i],
                              balance: nativeBalances[accounts[i].id] ?? 0,
                              homeBalance: balances[accounts[i].id] ?? 0,
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
                  fadeUpSliver(
                    4,
                    _DenseAlertPill(
                      message: l.dashboardBudgetsOver(
                          overBudgetCount, dayOfMonth, daysInMonth),
                      onTap: () => context.push('/budgets'),
                    ),
                  ),
                  fadeUpSliver(4, LoitGroupLabel(label: l.dashboardQuickStats)),
                  fadeUpSliver(
                    5,
                    Container(
                      color: c.surface,
                      child: Column(
                        children: [
                          _QuickStatRow(
                            label: l.dashboardBudgets,
                            value: l.dashboardOnTrack(
                                onTrackCount, budgetStatuses.length),
                            valueColor: c.success,
                          ),
                          _QuickStatRow(
                            label: l.dashboardOverBudget,
                            value: '$overBudgetCount',
                            valueColor: c.danger,
                          ),
                          _QuickStatRow(
                            label: l.dashboardSpentMtd,
                            value: _fmt(summary.expenses, currency),
                            valueColor: c.contentPrimary,
                          ),
                          _QuickStatRow(
                            label: l.dashboardTransactions,
                            value: '${items.length}',
                            valueColor: c.info,
                            showDivider: false,
                          ),
                        ],
                      ),
                    ),
                  ),
                ] else ...[
                  fadeUpSliver(4, const BudgetAlertBanner()),
                  fadeUpSliver(4, const ReceiptExpiryBanner()),
                  fadeUpSliver(4, LoitGroupLabel(label: l.dashboardBudgets)),
                  fadeUpSliver(
                    5,
                    Container(
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
                  fadeUpSliver(
                    5,
                    LoitGroupLabel(label: l.dashboardCategories),
                  ),
                  fadeUpSliver(
                    5,
                    Consumer(
                      builder: (context, ref, _) {
                        final cats =
                            ref.watch(userCategoriesProvider).value ??
                                const <UserCategory>[];
                        final personal =
                            cats.where((c) => c.isPersonal).toList()
                              ..sort((a, b) =>
                                  a.sortOrder.compareTo(b.sortOrder));
                        final picked = personal.take(3).toList();
                        return Container(
                          color: c.surface,
                          child: Column(
                            children: [
                              for (var i = 0; i < picked.length; i++)
                                _CategoryRow(
                                  category: picked[i],
                                  onTap: () => context.push(
                                    '/categories/${picked[i].id}/edit',
                                    extra: picked[i],
                                  ),
                                ),
                              _SeeAllCategoriesRow(
                                onTap: () => context.push('/categories'),
                              ),
                            ],
                          ),
                        );
                      },
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

List<double> _spendByDay(List<Txn> txns, DateTime month, String home) {
  final days = DateTime(month.year, month.month + 1, 0).day;
  final out = List<double>.filled(days, 0);
  final monthStart = DateTime(month.year, month.month, 1);
  final monthEnd = DateTime(month.year, month.month + 1, 1);
  for (final t in txns) {
    if (t.isTransfer || t.isIncome) continue;
    if (t.createdAt.isBefore(monthStart)) continue;
    if (!t.createdAt.isBefore(monthEnd)) continue;
    final v = t.absAmountIn(home);
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
    final l = context.l10n;
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
                      l.dashboardInsights,
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
                        l.dashboardSeeReport,
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
                  l.dashboardSpendingThisMonth,
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
                      label: l.dashboardAvgPerDay,
                      value: formatMoney(avgDay, currency),
                      align: TextAlign.left,
                    ),
                    _PreviewMetric(
                      label: l.dashboardMtd,
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

class _PastReportsCard extends StatelessWidget {
  const _PastReportsCard({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.loitColors;
    final l = context.l10n;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        LoitSpacing.s4,
        LoitSpacing.s5,
        LoitSpacing.s4,
        LoitSpacing.s2,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: LoitRadius.brM,
        child: InkWell(
          onTap: onTap,
          borderRadius: LoitRadius.brM,
          child: Container(
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
                Icon(Icons.insights_outlined, size: 20, color: c.brand),
                const SizedBox(width: LoitSpacing.s3),
                Expanded(
                  child: Text(
                    l.dashboardSeePastReports,
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

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({required this.category, required this.onTap});
  final UserCategory category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.loitColors;
    final l = context.l10n;
    final kindLabel = category.isIncome ? l.dashboardIncome : l.dashboardExpense;
    return Material(
      color: c.surface,
      child: InkWell(
        onTap: onTap,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: LoitSpacing.s5,
                vertical: LoitSpacing.s4,
              ),
              child: Row(
                children: [
                  LoitCategoryAvatar(categoryKey: category.key, size: 36),
                  const SizedBox(width: LoitSpacing.s4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          category.name,
                          style: LoitTypography.bodyM.copyWith(
                            color: c.contentPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          kindLabel,
                          style: LoitTypography.bodyS.copyWith(
                            color: c.contentTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, size: 16, color: c.contentTertiary),
                ],
              ),
            ),
            Container(
              height: 1,
              color: c.borderSubtle,
              margin: const EdgeInsets.only(
                  left: LoitSpacing.s5 + 36 + LoitSpacing.s4),
            ),
          ],
        ),
      ),
    );
  }
}

class _SeeAllCategoriesRow extends StatelessWidget {
  const _SeeAllCategoriesRow({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.loitColors;
    final l = context.l10n;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: LoitSpacing.s4,
          vertical: LoitSpacing.s3,
        ),
        child: Row(
          children: [
            Icon(Icons.category_outlined, size: 18, color: c.brand),
            const SizedBox(width: LoitSpacing.s3),
            Expanded(
              child: Text(
                l.dashboardSeeAllCategories,
                style: LoitTypography.bodyM.copyWith(color: c.brand),
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
  final l = context.l10n;
  final sorted = [...statuses]..sort((a, b) => b.ratio.compareTo(a.ratio));
  final picked = sorted.take(3).toList();
  return [
    for (var i = 0; i < picked.length; i++)
      LoitBudgetRow(
        label: ref.watch(categoryLabelProvider(
            CategoryLabelKey(key: picked[i].budget.category))),
        categoryKey: picked[i].budget.category,
        percent: (picked[i].ratio * 100).round(),
        subtitle: l.dashboardOfPattern(
            formatMoney(picked[i].spent, currency),
            formatMoney(picked[i].monthlyLimit, currency)),
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
    final l = context.l10n;
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
              l.dashboardAddBudget,
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

  factory _MonthSummary.fromTxns(List<Txn> items, DateTime month, String home) {
    final monthStart = DateTime(month.year, month.month, 1);
    final monthEnd = DateTime(month.year, month.month + 1, 1);
    var income = 0.0;
    var expenses = 0.0;
    for (final t in items) {
      if (t.isTransfer) continue;
      if (t.createdAt.isBefore(monthStart)) continue;
      if (!t.createdAt.isBefore(monthEnd)) continue;
      final v = t.absAmountIn(home);
      if (t.isIncome) {
        income += v;
      } else {
        expenses += v;
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
    final l = context.l10n;
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
                l.dashboardAddFirstAccount,
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
    required this.homeBalance,
    required this.currency,
    required this.onTap,
    this.showDivider = true,
  })  : isAdd = false;

  const _AccountRow.add({required this.onTap})
      : account = null,
        balance = 0,
        homeBalance = 0,
        currency = '',
        showDivider = false,
        isAdd = true;

  final Account? account;
  final double balance;
  final double homeBalance;
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
      final l = context.l10n;
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
                l.dashboardAddAccount,
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
    final showHomeSub = a.currency != currency;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: LoitSpacing.s4,
          vertical: LoitSpacing.s3,
        ),
        decoration: BoxDecoration(border: divider),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  formatMoney(balance, a.currency),
                  style: LoitTypography.bodyM.copyWith(
                    color: amountColor,
                    fontWeight: FontWeight.w600,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                if (showHomeSub) ...[
                  const SizedBox(height: 2),
                  Text(
                    '≈ ${formatMoney(homeBalance, currency)}',
                    style: LoitTypography.labelS.copyWith(
                      color: c.contentSecondary,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Stagger entrance: fade + slide-up driven by a shared controller.
/// Each section gets a slight delay based on [index]. Skipped under
/// reduced-motion.
class _FadeUp extends StatelessWidget {
  const _FadeUp({
    required this.controller,
    required this.index,
    required this.reduced,
    required this.child,
  });

  final AnimationController controller;
  final int index;
  final bool reduced;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (reduced) return child;
    const span = 0.65;
    final start = (index * 0.10).clamp(0.0, 1 - span);
    final end = (start + span).clamp(0.0, 1.0);
    final curved = CurvedAnimation(
      parent: controller,
      curve: Interval(start, end, curve: LoitMotion.easeOutQuint),
    );
    return AnimatedBuilder(
      animation: curved,
      builder: (_, c) {
        final v = curved.value;
        return Opacity(
          opacity: v,
          child: Transform.translate(
            offset: Offset(0, (1 - v) * 14),
            child: c,
          ),
        );
      },
      child: child,
    );
  }
}

/// Tap-down scale feedback. Drops to 0.94 on press, springs back via
/// easeOutQuart. Used for circular avatars and small targets where
/// InkWell ripple is too heavy.
class _PressScale extends StatefulWidget {
  const _PressScale({required this.child, required this.onTap});

  final Widget child;
  final VoidCallback onTap;

  @override
  State<_PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<_PressScale> {
  bool _down = false;

  void _setDown(bool v) {
    if (_down != v) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.disableAnimationsOf(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _setDown(true),
      onTapUp: (_) => _setDown(false),
      onTapCancel: () => _setDown(false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: (!reduced && _down) ? 0.94 : 1.0,
        duration: LoitMotion.instant,
        curve: LoitMotion.easeOutQuart,
        child: widget.child,
      ),
    );
  }
}
