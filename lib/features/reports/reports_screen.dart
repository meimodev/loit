import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/config/categories.dart';
import '../../shared/providers/auth_providers.dart';
import '../../shared/providers/transactions_provider.dart';

/// 3-month spending report: bar chart + per-category breakdown.
class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txns = ref.watch(transactionsProvider).value ?? const [];
    final profile = ref.watch(userProfileProvider).value;
    final home = profile?.homeCurrency ?? 'IDR';
    final fmt = NumberFormat.simpleCurrency(name: home);

    final now = DateTime.now();
    final months = List.generate(3, (i) {
      final d = DateTime(now.year, now.month - (2 - i), 1);
      return d;
    });

    final monthTotals = <double>[];
    for (final m in months) {
      final next = DateTime(m.year, m.month + 1, 1);
      final total = txns
          .where((t) =>
              t.createdAt.isAfter(m) && t.createdAt.isBefore(next))
          .fold<double>(0, (s, t) => s + (t.amountHome ?? t.amount));
      monthTotals.add(total);
    }

    final categoryTotals = <String, double>{};
    final monthStart = months.first;
    for (final t in txns) {
      if (t.createdAt.isBefore(monthStart)) continue;
      final key = t.category ?? 'other';
      categoryTotals[key] =
          (categoryTotals[key] ?? 0) + (t.amountHome ?? t.amount);
    }
    final sortedCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      appBar: AppBar(title: const Text('Reports')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Last 3 months', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          SizedBox(
            height: 220,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, _) {
                        final i = value.toInt();
                        if (i < 0 || i >= months.length) return const SizedBox();
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(DateFormat.MMM().format(months[i])),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                gridData: const FlGridData(show: false),
                barGroups: [
                  for (var i = 0; i < monthTotals.length; i++)
                    BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: monthTotals[i],
                          color: Theme.of(context).colorScheme.primary,
                          width: 32,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text('By category (3 mo)',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (sortedCategories.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: Text('No data yet')),
            )
          else
            for (final e in sortedCategories)
              ListTile(
                dense: true,
                leading: Icon(Categories.iconFor(e.key)),
                title: Text(e.key),
                trailing: Text(fmt.format(e.value)),
              ),
        ],
      ),
    );
  }
}
