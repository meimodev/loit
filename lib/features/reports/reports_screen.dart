import 'package:fl_chart/fl_chart.dart';
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
import '../../shared/providers/transactions_provider.dart';
import '../../shared/widgets/loit_app_bar_month.dart';
import '../../shared/widgets/loit_group_label.dart';
import '../../shared/widgets/loit_stat_triple.dart';

/// LOIT Reports — G · Reports & Insights.
class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  int _tab = 0; // 0 Overview · 1 Categories · 2 Trend · 3 Insights · 4 Income

  @override
  Widget build(BuildContext context) {
    final c = context.loitColors;
    final txns = ref.watch(transactionsProvider).value ?? const [];
    final profile = ref.watch(userProfileProvider).value;
    final home = profile?.homeCurrency ?? 'IDR';
    final fmt = NumberFormat.simpleCurrency(name: home, decimalDigits: 0);

    final monthStart = _month;
    final monthEnd = DateTime(_month.year, _month.month + 1, 1);
    final monthTxns = txns
        .where((t) =>
            !t.createdAt.isBefore(monthStart) &&
            t.createdAt.isBefore(monthEnd))
        .toList();

    final income = monthTxns
        .where((t) => (t.amountHome ?? t.amount) < 0)
        .fold<double>(0, (s, t) => s + (t.amountHome ?? t.amount).abs());
    final expenses = monthTxns
        .where((t) => (t.amountHome ?? t.amount) >= 0)
        .fold<double>(0, (s, t) => s + (t.amountHome ?? t.amount));
    final net = income - expenses;

    return Scaffold(
      backgroundColor: c.canvas,
      appBar: LoitAppBarMonth(
        label: DateFormat.yMMM().format(_month),
        onPrev: () => setState(
            () => _month = DateTime(_month.year, _month.month - 1)),
        onNext: () => setState(
            () => _month = DateTime(_month.year, _month.month + 1)),
        actions: [
          IconButton(
            icon: const Icon(Icons.ios_share, size: 20),
            tooltip: 'Export',
            onPressed: () => context.push('/reports/export'),
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _ReportTabs(
              active: _tab,
              onTap: (i) => setState(() => _tab = i),
            ),
          ),
          SliverToBoxAdapter(
            child: LoitStatTriple(
              stats: [
                LoitStat(
                    label: 'Income',
                    amount: fmt.format(income),
                    color: c.info),
                LoitStat(
                    label: 'Expenses',
                    amount: fmt.format(expenses),
                    color: c.danger),
                LoitStat(
                  label: 'Net',
                  amount: fmt.format(net),
                  color: net >= 0 ? c.success : c.danger,
                ),
              ],
            ),
          ),
          ..._tabSlivers(context, txns, monthTxns, fmt, home),
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }

  List<Widget> _tabSlivers(
    BuildContext context,
    List<Txn> allTxns,
    List<Txn> monthTxns,
    NumberFormat fmt,
    String home,
  ) {
    switch (_tab) {
      case 1:
        return _categoriesSlivers(monthTxns, fmt);
      case 2:
        return _trendSlivers(allTxns, fmt);
      case 3:
        return _insightsSlivers(monthTxns, fmt);
      case 4:
        return _incomeSlivers(monthTxns, fmt);
      case 0:
      default:
        return _overviewSlivers(monthTxns, fmt);
    }
  }

  List<Widget> _incomeSlivers(List<Txn> monthTxns, NumberFormat fmt) {
    final cats = _incomeCategoryTotals(monthTxns).entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final total = cats.fold<double>(0, (s, e) => s + e.value);
    if (cats.isEmpty) {
      return const [
        SliverToBoxAdapter(
            child: _EmptyHint(text: 'No income recorded this month')),
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

  Map<String, double> _incomeCategoryTotals(List<Txn> txns) {
    final out = <String, double>{};
    for (final t in txns) {
      final v = t.amountHome ?? t.amount;
      if (v >= 0) continue;
      final k = t.category ?? 'income_other';
      out[k] = (out[k] ?? 0) + v.abs();
    }
    return out;
  }

  List<Widget> _overviewSlivers(List<Txn> monthTxns, NumberFormat fmt) {
    final c = context.loitColors;
    final byDay = _spendByDay(monthTxns, _month);
    final avgDay = byDay.isEmpty
        ? 0.0
        : byDay.reduce((a, b) => a + b) /
            byDay.where((v) => v > 0).length.clamp(1, byDay.length);
    final cats = _categoryTotals(monthTxns).entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final totalCats = cats.fold<double>(0, (s, e) => s + e.value);

    return [
      const SliverToBoxAdapter(child: LoitGroupLabel(label: 'Trend · this month')),
      SliverToBoxAdapter(
        child: Container(
          color: c.surface,
          padding: const EdgeInsets.fromLTRB(
              LoitSpacing.s4, LoitSpacing.s4, LoitSpacing.s4, LoitSpacing.s4),
          decoration:
              BoxDecoration(border: Border(bottom: BorderSide(color: c.borderSubtle))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _MetricCell(
                      label: 'AVG/DAY', value: fmt.format(avgDay), align: TextAlign.left),
                  _MetricCell(
                      label: 'DAYS',
                      value: '${byDay.where((v) => v > 0).length} / ${byDay.length}',
                      align: TextAlign.right),
                ],
              ),
              const SizedBox(height: LoitSpacing.s3),
              SizedBox(height: 90, child: _MiniLineChart(values: byDay)),
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
        const SliverToBoxAdapter(child: _EmptyHint(text: 'No spend this month'))
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

  List<Widget> _categoriesSlivers(List<Txn> monthTxns, NumberFormat fmt) {
    final cats = _categoryTotals(monthTxns).entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final total = cats.fold<double>(0, (s, e) => s + e.value);
    if (cats.isEmpty) {
      return const [
        SliverToBoxAdapter(child: _EmptyHint(text: 'No category data this month')),
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

  List<Widget> _trendSlivers(List<Txn> allTxns, NumberFormat fmt) {
    final c = context.loitColors;
    final now = DateTime.now();
    final months = List.generate(
        6, (i) => DateTime(now.year, now.month - (5 - i), 1));
    final totals = months.map((m) {
      final next = DateTime(m.year, m.month + 1, 1);
      return allTxns
          .where((t) =>
              !t.createdAt.isBefore(m) && t.createdAt.isBefore(next))
          .fold<double>(0, (s, t) {
        final v = t.amountHome ?? t.amount;
        return s + (v >= 0 ? v : 0);
      });
    }).toList();
    final maxY =
        (totals.fold<double>(0, (s, v) => v > s ? v : s)) * 1.2 + 1;

    return [
      const SliverToBoxAdapter(child: LoitGroupLabel(label: 'Last 6 months')),
      SliverToBoxAdapter(
        child: Container(
          color: c.surface,
          padding: const EdgeInsets.fromLTRB(
              LoitSpacing.s4, LoitSpacing.s4, LoitSpacing.s4, LoitSpacing.s4),
          decoration: BoxDecoration(
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
                            DateFormat.MMM().format(months[i]),
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
            color: c.surface,
            padding: const EdgeInsets.symmetric(
                horizontal: LoitSpacing.s4, vertical: LoitSpacing.s3),
            decoration: BoxDecoration(
              border: Border(
                  bottom: isLast
                      ? BorderSide.none
                      : BorderSide(color: c.borderSubtle)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    DateFormat.yMMMM().format(months[i]),
                    style: LoitTypography.bodyM
                        .copyWith(color: c.contentPrimary),
                  ),
                ),
                Text(
                  fmt.format(totals[i]),
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

  List<Widget> _insightsSlivers(List<Txn> monthTxns, NumberFormat fmt) {
    final c = context.loitColors;
    final cats = _categoryTotals(monthTxns).entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final cards = <_InsightCard>[];

    // Top category card
    if (cats.isNotEmpty) {
      final top = cats.first;
      final style = LoitCategories.resolve(top.key);
      cards.add(_InsightCard(
        title: '${style.label} leads spending',
        body:
            '${fmt.format(top.value)} this month — your biggest category.',
        color: style.tint,
        icon: style.icon,
      ));
    }

    // Recurring merchant card (≥3 visits this month)
    if (monthTxns.isNotEmpty) {
      final byMerchant = <String, int>{};
      final spendByMerchant = <String, double>{};
      for (final t in monthTxns) {
        final m = t.merchant ?? 'Unknown';
        byMerchant[m] = (byMerchant[m] ?? 0) + 1;
        final v = t.amountHome ?? t.amount;
        if (v > 0) spendByMerchant[m] = (spendByMerchant[m] ?? 0) + v;
      }
      final repeats = byMerchant.entries.where((e) => e.value >= 3).toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      if (repeats.isNotEmpty) {
        final r = repeats.first;
        cards.add(_InsightCard(
          title: '${r.key} · ${r.value} visits',
          body:
              'Most spent here: ${fmt.format(spendByMerchant[r.key] ?? 0)}. Consider a budget cap.',
          color: c.info,
          icon: Icons.repeat,
        ));
      }
    }

    // Potential subscriptions card: same merchant, exactly 1 hit this month, similar amount last month.
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
      return const [
        SliverToBoxAdapter(
            child: _EmptyHint(text: 'Insights appear once you have spend data')),
      ];
    }
    return [
      SliverToBoxAdapter(
        child: Container(
          color: c.surface,
          padding: const EdgeInsets.fromLTRB(LoitSpacing.s4,
              LoitSpacing.s4, LoitSpacing.s4, LoitSpacing.s4),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: c.borderSubtle)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('THIS MONTH',
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
    // Heuristic: merchants with exactly 1 hit this month, amount > 20k IDR-ish,
    // categorized as utilities/entertainment.
    const subCats = {'utilities', 'entertainment'};
    final byMerchant = <String, int>{};
    for (final t in monthTxns) {
      final m = t.merchant;
      if (m == null || m.isEmpty) continue;
      if (!subCats.contains(t.category)) continue;
      final v = t.amountHome ?? t.amount;
      if (v <= 0) continue;
      byMerchant[m] = (byMerchant[m] ?? 0) + 1;
    }
    return byMerchant.entries
        .where((e) => e.value == 1)
        .map((e) => e.key)
        .toList();
  }

  List<double> _spendByDay(List<Txn> txns, DateTime month) {
    final days = DateTime(month.year, month.month + 1, 0).day;
    final out = List<double>.filled(days, 0);
    for (final t in txns) {
      final v = t.amountHome ?? t.amount;
      if (v < 0) continue;
      final d = t.createdAt.day;
      if (d >= 1 && d <= days) out[d - 1] += v;
    }
    return out;
  }

  Map<String, double> _categoryTotals(List<Txn> txns) {
    final out = <String, double>{};
    for (final t in txns) {
      final v = t.amountHome ?? t.amount;
      if (v < 0) continue;
      final k = t.category ?? 'other';
      out[k] = (out[k] ?? 0) + v;
    }
    return out;
  }

}

class _ReportTabs extends StatelessWidget {
  const _ReportTabs({required this.active, required this.onTap});
  final int active;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.loitColors;
    const labels = ['Overview', 'Categories', 'Trend', 'Insights', 'Income'];
    return Container(
      color: c.canvas,
      padding: const EdgeInsets.fromLTRB(
        LoitSpacing.s5,
        LoitSpacing.s1,
        LoitSpacing.s5,
        LoitSpacing.s2,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (var i = 0; i < labels.length; i++) ...[
              _Pill(
                  label: labels[i],
                  active: i == active,
                  onTap: () => onTap(i)),
              if (i < labels.length - 1) const SizedBox(width: LoitSpacing.s2),
            ],
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill(
      {required this.label, required this.active, required this.onTap});
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
            horizontal: LoitSpacing.s3, vertical: LoitSpacing.s2),
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

class _MiniLineChart extends StatelessWidget {
  const _MiniLineChart({required this.values});
  final List<double> values;

  @override
  Widget build(BuildContext context) {
    final c = context.loitColors;
    if (values.isEmpty || values.every((v) => v == 0)) {
      return Center(
        child: Text('No spend yet',
            style: LoitTypography.bodyS.copyWith(color: c.contentTertiary)),
      );
    }
    final spots = <FlSpot>[];
    for (var i = 0; i < values.length; i++) {
      spots.add(FlSpot(i.toDouble(), values[i]));
    }
    final maxY = values.fold<double>(0, (s, v) => v > s ? v : s) * 1.15 + 1;
    return LineChart(
      LineChartData(
        minY: 0,
        maxY: maxY,
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        gridData: const FlGridData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: c.brand,
            barWidth: 2,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: c.brand.withValues(alpha: 0.15),
            ),
          ),
        ],
      ),
    );
  }
}

class _StackedBar extends StatelessWidget {
  const _StackedBar({required this.parts, required this.total});
  final List<MapEntry<String, double>> parts;
  final double total;

  @override
  Widget build(BuildContext context) {
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
                    Container(color: LoitCategories.resolve(e.key).tint),
              ),
          ],
        ),
      ),
    );
  }
}

class _CategoryLine extends StatelessWidget {
  const _CategoryLine({
    required this.entry,
    required this.total,
    required this.fmt,
    required this.isLast,
  });
  final MapEntry<String, double> entry;
  final double total;
  final NumberFormat fmt;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final c = context.loitColors;
    final style = LoitCategories.resolve(entry.key);
    final pct = total <= 0 ? 0 : ((entry.value / total) * 100).round();
    return Container(
      color: c.surface,
      padding: const EdgeInsets.symmetric(
          horizontal: LoitSpacing.s4, vertical: LoitSpacing.s3),
      decoration: BoxDecoration(
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
          Text(fmt.format(entry.value),
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
      color: c.surface,
      decoration: BoxDecoration(
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
                          const SizedBox(height: 8),
                          Text('See details →',
                              style: LoitTypography.bodyS.copyWith(
                                  color: c.brand,
                                  fontWeight: FontWeight.w600)),
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
      child: Text('BETA',
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
