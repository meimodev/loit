import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../shared/utils/locale_date_format.dart';

import '../../core/theme/loit_colors.dart';
import '../../core/theme/loit_radius.dart';
import '../../core/theme/loit_spacing.dart';
import '../../core/theme/loit_typography.dart';
import '../../l10n/l10n_x.dart';
import '../../shared/providers/auth_providers.dart';
import '../../shared/providers/transactions_provider.dart';
import '../../shared/providers/user_categories_provider.dart';
import '../../shared/utils/amount_input.dart';
import '../../shared/widgets/loit_app_bar_month.dart';
import '../../shared/widgets/loit_group_label.dart';
import '../../shared/widgets/loit_mini_line_chart.dart';
import '../../shared/widgets/loit_stat_triple.dart';

/// LOIT Reports — G · Reports & Insights.
///
/// When [roomId] is provided, scopes the report to transactions made inside
/// that room (any member, subject to RLS). Otherwise shows the user's global
/// transactions.
class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key, this.roomId});

  final String? roomId;

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen>
    with SingleTickerProviderStateMixin {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.loitColors;
    final l10n = context.l10n;
    final roomId = widget.roomId;
    final txns = roomId != null
        ? (ref.watch(roomTransactionsProvider(roomId)).value ?? const [])
        : (ref.watch(transactionsProvider).value ?? const []);
    final profile = ref.watch(userProfileProvider).value;
    final home = profile?.homeCurrency ?? 'IDR';
    String fmt(double v) => formatMoney(v, home);

    final monthStart = _month;
    final monthEnd = DateTime(_month.year, _month.month + 1, 1);
    final monthTxns = txns
        .where((t) =>
            !t.createdAt.isBefore(monthStart) &&
            t.createdAt.isBefore(monthEnd))
        .toList();

    final income = monthTxns
        .where((t) => !t.isTransfer && t.isIncome)
        .fold<double>(0, (s, t) => s + t.absAmountIn(home));
    final expenses = monthTxns
        .where((t) => !t.isTransfer && !t.isIncome)
        .fold<double>(0, (s, t) => s + t.absAmountIn(home));
    final net = income - expenses;

    return Scaffold(
      backgroundColor: c.canvas,
      appBar: LoitAppBarMonth(
        label: yMMM(context).format(_month),
        leading: Navigator.of(context).canPop()
            ? IconButton(
                icon: const Icon(Icons.arrow_back, size: 22),
                onPressed: () => context.pop(),
                color: c.contentSecondary,
              )
            : null,
        onPrev: () => setState(
            () => _month = DateTime(_month.year, _month.month - 1)),
        onNext: () => setState(
            () => _month = DateTime(_month.year, _month.month + 1)),
        actions: [
          IconButton(
            icon: const Icon(Icons.ios_share, size: 20),
            tooltip: l10n.exportScreenTitle,
            onPressed: () => context.push(
              roomId != null
                  ? '/rooms/$roomId/reports/export'
                  : '/reports/export',
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          LoitStatTriple(
            stats: [
              LoitStat(
                  label: l10n.reportsScreenIncome,
                  amount: fmt(income),
                  color: c.info),
              LoitStat(
                  label: l10n.reportsScreenExpenses,
                  amount: fmt(expenses),
                  color: c.danger),
              LoitStat(
                label: l10n.reportsScreenNet,
                amount: fmt(net),
                color: net >= 0 ? c.success : c.danger,
              ),
            ],
          ),
          Container(
            decoration: BoxDecoration(
              color: c.canvas,
              border: Border(bottom: BorderSide(color: c.borderSubtle)),
            ),
            child: TabBar(
              controller: _tabController,
              isScrollable: false,
              labelColor: c.brand,
              unselectedLabelColor: c.contentSecondary,
              indicatorColor: c.brand,
              indicatorWeight: 2.5,
              indicatorSize: TabBarIndicatorSize.tab,
              labelPadding: EdgeInsets.zero,
              labelStyle:
                  LoitTypography.bodyS.copyWith(fontWeight: FontWeight.w700),
              unselectedLabelStyle:
                  LoitTypography.bodyS.copyWith(fontWeight: FontWeight.w600),
              tabs: const [
                Tab(text: 'Overview'),
                Tab(text: 'Categories'),
                Tab(text: 'Trend'),
                Tab(text: 'Insights'),
                Tab(text: 'Income'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _tabScroll(_overviewSlivers(monthTxns, fmt, home)),
                _tabScroll(_categoriesSlivers(monthTxns, fmt, home)),
                _tabScroll(_trendSlivers(txns, fmt, home)),
                _tabScroll(_insightsSlivers(monthTxns, fmt, home)),
                _tabScroll(_incomeSlivers(monthTxns, fmt, home)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabScroll(List<Widget> slivers) {
    return CustomScrollView(
      key: PageStorageKey(slivers.hashCode),
      slivers: [
        ...slivers,
        const SliverToBoxAdapter(child: SizedBox(height: 80)),
      ],
    );
  }

  List<Widget> _incomeSlivers(List<Txn> monthTxns, String Function(double) fmt, String home) {
    final l10n = context.l10n;
    final cats = _incomeCategoryTotals(monthTxns, home).entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final total = cats.fold<double>(0, (s, e) => s + e.value);
    if (cats.isEmpty) {
      return [
        SliverToBoxAdapter(
            child: _EmptyHint(text: l10n.reportsScreenNoData)),
      ];
    }
    return [
      const SliverToBoxAdapter(
          child: LoitGroupLabel(label: 'Income by source')),
      SliverList.builder(
        itemCount: cats.length,
        itemBuilder: (_, i) => _CategoryLine(
          entry: cats[i],
          total: total,
          fmt: fmt,
          isLast: i == cats.length - 1,
        ),
      ),
    ];
  }

  Map<String, double> _incomeCategoryTotals(List<Txn> txns, String home) {
    final out = <String, double>{};
    for (final t in txns) {
      if (t.isTransfer || !t.isIncome) continue;
      final v = t.absAmountIn(home);
      final k = t.category ?? 'income_other';
      out[k] = (out[k] ?? 0) + v;
    }
    return out;
  }

  List<Widget> _overviewSlivers(List<Txn> monthTxns, String Function(double) fmt, String home) {
    final c = context.loitColors;
    final l10n = context.l10n;
    final byDay = _spendByDay(monthTxns, _month, home);
    final avgDay = byDay.isEmpty
        ? 0.0
        : byDay.reduce((a, b) => a + b) /
            byDay.where((v) => v > 0).length.clamp(1, byDay.length);
    final cats = _categoryTotals(monthTxns, home).entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final totalCats = cats.fold<double>(0, (s, e) => s + e.value);

    return [
      const SliverToBoxAdapter(child: LoitGroupLabel(label: 'Trend · this month')),
      SliverToBoxAdapter(
        child: Container(
          padding: const EdgeInsets.fromLTRB(
              LoitSpacing.s4, LoitSpacing.s4, LoitSpacing.s4, LoitSpacing.s4),
          decoration: BoxDecoration(
              color: c.surface,
              border: Border(bottom: BorderSide(color: c.borderSubtle))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _MetricCell(
                      label: 'AVG/DAY', value: fmt(avgDay), align: TextAlign.left),
                  _MetricCell(
                      label: 'DAYS',
                      value: '${byDay.where((v) => v > 0).length} / ${byDay.length}',
                      align: TextAlign.right),
                ],
              ),
              const SizedBox(height: LoitSpacing.s3),
              LoitMiniLineChart(
                values: byDay,
                formatValue: (v) => fmt(v),
              ),
            ],
          ),
        ),
      ),
      const SliverToBoxAdapter(child: LoitGroupLabel(label: 'By category')),
      SliverToBoxAdapter(
        child: Container(
          color: c.surface,
          padding: const EdgeInsets.fromLTRB(
              LoitSpacing.s4, LoitSpacing.s3, LoitSpacing.s4, LoitSpacing.s2),
          child: _StackedBar(parts: cats, total: totalCats),
        ),
      ),
      if (cats.isEmpty)
        SliverToBoxAdapter(child: _EmptyHint(text: l10n.reportsScreenNoData))
      else
        SliverList.builder(
          itemCount: cats.length,
          itemBuilder: (_, i) => _CategoryLine(
            entry: cats[i],
            total: totalCats,
            fmt: fmt,
            isLast: i == cats.length - 1,
          ),
        ),
    ];
  }

  List<Widget> _categoriesSlivers(List<Txn> monthTxns, String Function(double) fmt, String home) {
    final l10n = context.l10n;
    final cats = _categoryTotals(monthTxns, home).entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final total = cats.fold<double>(0, (s, e) => s + e.value);
    if (cats.isEmpty) {
      return [
        SliverToBoxAdapter(child: _EmptyHint(text: l10n.reportsScreenNoData)),
      ];
    }
    return [
      const SliverToBoxAdapter(
          child: LoitGroupLabel(label: 'All categories')),
      SliverList.builder(
        itemCount: cats.length,
        itemBuilder: (_, i) => _CategoryLine(
          entry: cats[i],
          total: total,
          fmt: fmt,
          isLast: i == cats.length - 1,
        ),
      ),
    ];
  }

  List<Widget> _trendSlivers(List<Txn> allTxns, String Function(double) fmt, String home) {
    final c = context.loitColors;
    final mmm = MMM(context);
    final now = DateTime.now();
    final months = List.generate(
        6, (i) => DateTime(now.year, now.month - (5 - i), 1));
    final totals = months.map((m) {
      final next = DateTime(m.year, m.month + 1, 1);
      return allTxns
          .where((t) =>
              !t.createdAt.isBefore(m) && t.createdAt.isBefore(next))
          .where((t) => !t.isTransfer && !t.isIncome)
          .fold<double>(
              0, (s, t) => s + t.absAmountIn(home));
    }).toList();
    final maxY =
        (totals.fold<double>(0, (s, v) => v > s ? v : s)) * 1.2 + 1;

    return [
      const SliverToBoxAdapter(child: LoitGroupLabel(label: 'Last 6 months')),
      SliverToBoxAdapter(
        child: Container(
          padding: const EdgeInsets.fromLTRB(
              LoitSpacing.s4, LoitSpacing.s4, LoitSpacing.s4, LoitSpacing.s4),
          decoration: BoxDecoration(
              color: c.surface,
              border: Border(bottom: BorderSide(color: c.borderSubtle))),
          child: SizedBox(
            height: 220,
            child: BarChart(
              BarChartData(
                maxY: maxY,
                alignment: BarChartAlignment.spaceAround,
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, _) {
                        final i = value.toInt();
                        if (i < 0 || i >= months.length) {
                          return const SizedBox();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            mmm.format(months[i]),
                            style: LoitTypography.bodyS
                                .copyWith(color: c.contentTertiary),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                gridData: const FlGridData(show: false),
                barGroups: [
                  for (var i = 0; i < totals.length; i++)
                    BarChartGroupData(x: i, barRods: [
                      BarChartRodData(
                        toY: totals[i],
                        color: i == totals.length - 1 ? c.brand : c.muted,
                        width: 28,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4)),
                      ),
                    ]),
                ],
              ),
            ),
          ),
        ),
      ),
      const SliverToBoxAdapter(child: LoitGroupLabel(label: 'Totals')),
      SliverList.builder(
        itemCount: months.length,
        itemBuilder: (_, i) {
          final isLast = i == months.length - 1;
          return Container(
            padding: const EdgeInsets.symmetric(
                horizontal: LoitSpacing.s4, vertical: LoitSpacing.s3),
            decoration: BoxDecoration(
              color: c.surface,
              border: Border(
                  bottom: isLast
                      ? BorderSide.none
                      : BorderSide(color: c.borderSubtle)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    yMMMM(context).format(months[i]),
                    style: LoitTypography.bodyM
                        .copyWith(color: c.contentPrimary),
                  ),
                ),
                Text(
                  fmt(totals[i]),
                  style: LoitTypography.bodyM.copyWith(
                    color: c.contentPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    ];
  }

  List<Widget> _insightsSlivers(List<Txn> monthTxns, String Function(double) fmt, String home) {
    final c = context.loitColors;
    final l10n = context.l10n;
    final cats = _categoryTotals(monthTxns, home).entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final cards = <_InsightCard>[];

    if (cats.isNotEmpty) {
      final top = cats.first;
      final style = ref.watch(categoryStyleProvider(top.key));
      cards.add(_InsightCard(
        title: '${style.label} leads spending',
        body:
            '${fmt(top.value)} this month — your biggest category.',
        color: style.tint,
        icon: style.icon,
      ));
    }

    if (monthTxns.isNotEmpty) {
      final byMerchant = <String, int>{};
      final spendByMerchant = <String, double>{};
      for (final t in monthTxns) {
        final raw = (t.notes ?? '').trim();
        final m = raw.isEmpty ? 'Unknown' : raw.split('\n').first;
        byMerchant[m] = (byMerchant[m] ?? 0) + 1;
        if (!t.isTransfer && !t.isIncome) {
          spendByMerchant[m] =
              (spendByMerchant[m] ?? 0) + t.absAmountIn(home);
        }
      }
      final repeats = byMerchant.entries.where((e) => e.value >= 3).toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      if (repeats.isNotEmpty) {
        final r = repeats.first;
        cards.add(_InsightCard(
          title: '${r.key} · ${r.value} visits',
          body:
              'Most spent here: ${fmt(spendByMerchant[r.key] ?? 0)}. Consider a budget cap.',
          color: c.info,
          icon: Icons.repeat,
        ));
      }
    }

    final subs = _detectSubscriptions(monthTxns);
    if (subs.isNotEmpty) {
      cards.add(_InsightCard(
        title: '${subs.length} recurring subscription${subs.length == 1 ? '' : 's'}',
        body: '${subs.take(3).join(', ')}. Tap to review.',
        color: const Color(0xFFD49A2B),
        icon: Icons.power,
      ));
    }

    if (cards.isEmpty) {
      return [
        SliverToBoxAdapter(
            child: _EmptyHint(text: l10n.reportsScreenEmptyBody)),
      ];
    }
    return [
      SliverToBoxAdapter(
        child: Container(
          padding: const EdgeInsets.fromLTRB(LoitSpacing.s4,
              LoitSpacing.s4, LoitSpacing.s4, LoitSpacing.s4),
          decoration: BoxDecoration(
            color: c.surface,
            border: Border(bottom: BorderSide(color: c.borderSubtle)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.reportsThisMonth,
                  style: LoitTypography.labelS.copyWith(
                      color: c.contentSecondary, letterSpacing: 0.4)),
              const SizedBox(height: 4),
              Text(
                cards.length >= 3
                    ? "You're spending evenly across categories — your most balanced month yet."
                    : "Your spend pattern is forming — keep going.",
                style: LoitTypography.titleM.copyWith(
                    color: c.contentPrimary, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
      SliverToBoxAdapter(
        child: LoitGroupLabel(
          label: 'Insights · ${cards.length}',
          trailing: _BetaChip(),
        ),
      ),
      SliverList.builder(
        itemCount: cards.length,
        itemBuilder: (_, i) => cards[i],
      ),
    ];
  }

  List<String> _detectSubscriptions(List<Txn> monthTxns) {
    const subCats = {'utilities', 'entertainment'};
    final byMerchant = <String, int>{};
    for (final t in monthTxns) {
      final raw = (t.notes ?? '').trim();
      if (raw.isEmpty) continue;
      final m = raw.split('\n').first;
      if (!subCats.contains(t.category)) continue;
      if (t.isTransfer || t.isIncome) continue;
      byMerchant[m] = (byMerchant[m] ?? 0) + 1;
    }
    return byMerchant.entries
        .where((e) => e.value == 1)
        .map((e) => e.key)
        .toList();
  }

  List<double> _spendByDay(List<Txn> txns, DateTime month, String home) {
    final days = DateTime(month.year, month.month + 1, 0).day;
    final out = List<double>.filled(days, 0);
    for (final t in txns) {
      if (t.isTransfer || t.isIncome) continue;
      final v = t.absAmountIn(home);
      final d = t.createdAt.day;
      if (d >= 1 && d <= days) out[d - 1] += v;
    }
    return out;
  }

  Map<String, double> _categoryTotals(List<Txn> txns, String home) {
    final out = <String, double>{};
    for (final t in txns) {
      if (t.isTransfer || t.isIncome) continue;
      final v = t.absAmountIn(home);
      final k = t.category ?? 'other';
      out[k] = (out[k] ?? 0) + v;
    }
    return out;
  }

}

class _MetricCell extends StatelessWidget {
  const _MetricCell(
      {required this.label, required this.value, required this.align});
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
        Text(label.toUpperCase(),
            style: LoitTypography.labelS.copyWith(
                color: c.contentSecondary, letterSpacing: 0.4)),
        const SizedBox(height: 2),
        Text(value,
            style: LoitTypography.titleM.copyWith(
                color: c.contentPrimary, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _StackedBar extends ConsumerWidget {
  const _StackedBar({super.key, required this.parts, required this.total});
  final List<MapEntry<String, double>> parts;
  final double total;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.loitColors;
    if (parts.isEmpty || total <= 0) {
      return Container(
        height: 14,
        decoration: BoxDecoration(
            color: c.muted, borderRadius: BorderRadius.circular(6)),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: SizedBox(
        height: 14,
        child: Row(
          children: [
            for (final e in parts)
              Expanded(
                flex: ((e.value / total) * 1000).round().clamp(1, 1000),
                child:
                    Container(color: ref.watch(categoryStyleProvider(e.key)).tint),
              ),
          ],
        ),
      ),
    );
  }
}

class _CategoryLine extends ConsumerWidget {
  const _CategoryLine({
    super.key,
    required this.entry,
    required this.total,
    required this.fmt,
    required this.isLast,
  });
  final MapEntry<String, double> entry;
  final double total;
  final String Function(double) fmt;
  final bool isLast;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.loitColors;
    final style = ref.watch(categoryStyleProvider(entry.key));
    final pct = total <= 0 ? 0 : ((entry.value / total) * 100).round();
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: LoitSpacing.s4, vertical: LoitSpacing.s3),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(
          bottom: isLast
              ? BorderSide.none
              : BorderSide(color: c.borderSubtle),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: style.tint,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: LoitSpacing.s3),
          Expanded(
            child: Text(style.label,
                style: LoitTypography.bodyM
                    .copyWith(color: c.contentPrimary)),
          ),
          Text(fmt(entry.value),
              style: LoitTypography.bodyM.copyWith(
                  color: c.contentPrimary, fontWeight: FontWeight.w600)),
          const SizedBox(width: LoitSpacing.s3),
          SizedBox(
            width: 40,
            child: Text('$pct%',
                textAlign: TextAlign.right,
                style: LoitTypography.bodyS
                    .copyWith(color: c.contentTertiary)),
          ),
        ],
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({
    required this.title,
    required this.body,
    required this.color,
    required this.icon,
  });
  final String title;
  final String body;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final c = context.loitColors;
    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(bottom: BorderSide(color: c.borderSubtle)),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 3, color: color),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: LoitSpacing.s4, vertical: LoitSpacing.s4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.14),
                        borderRadius: LoitRadius.brS,
                      ),
                      child: Icon(icon, color: color, size: 16),
                    ),
                    const SizedBox(width: LoitSpacing.s3),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title,
                              style: LoitTypography.bodyM.copyWith(
                                  color: c.contentPrimary,
                                  fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          Text(body,
                              style: LoitTypography.bodyS
                                  .copyWith(color: c.contentSecondary)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BetaChip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = context.loitColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFE6F4F0),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(context.l10n.reportsBeta,
          style: LoitTypography.labelS.copyWith(
              color: c.brand, letterSpacing: 0.4, fontWeight: FontWeight.w700)),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.loitColors;
    return Container(
      color: c.surface,
      padding: const EdgeInsets.all(LoitSpacing.s5),
      child: Center(
        child: Text(text,
            style: LoitTypography.bodyM
                .copyWith(color: c.contentTertiary)),
      ),
    );
  }
}
