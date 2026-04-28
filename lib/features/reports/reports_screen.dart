import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/config/categories.dart';
import '../../core/services/analytics_service.dart';
import '../../shared/providers/auth_providers.dart';
import '../../shared/providers/transactions_provider.dart';
import '../paywall/feature_gate.dart';
import 'export_service.dart';

/// 3-month spending report: bar chart + per-category breakdown.
class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txns = ref.watch(transactionsProvider).value ?? const [];
    final profile = ref.watch(userProfileProvider).value;
    final home = profile?.homeCurrency ?? 'IDR';
    final fmt = NumberFormat.simpleCurrency(name: home);
    final flags = FeatureFlags.forTier(profile?.tier ?? 'free');

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
      appBar: AppBar(
        title: const Text('Reports'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.ios_share),
            tooltip: 'Export',
            onSelected: (v) => _handleExport(context, ref, v, txns, home, flags),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'csv', child: Text('Export CSV')),
              PopupMenuItem(value: 'pdf', child: Text('Export PDF')),
            ],
          ),
        ],
      ),
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

  Future<void> _handleExport(
    BuildContext context,
    WidgetRef ref,
    String kind,
    List<Txn> txns,
    String home,
    FeatureFlags flags,
  ) async {
    final isPdf = kind == 'pdf';
    final allowed = isPdf ? flags.pdfExport : flags.csvExport;
    if (!allowed) {
      await Analytics.paywallSeen('export');
      if (context.mounted) context.push('/paywall', extra: 'export');
      return;
    }
    if (txns.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('No transactions to export')));
      return;
    }

    DateTimeRange? range;
    if (isPdf) {
      final earliest = txns
          .map((t) => t.createdAt)
          .reduce((a, b) => a.isBefore(b) ? a : b);
      final spanMonths = _monthsBetween(earliest, DateTime.now());
      if (spanMonths > ExportService.maxPdfMonths) {
        range = await showDateRangePicker(
          context: context,
          firstDate: earliest,
          lastDate: DateTime.now(),
          helpText: 'PDF limit: 12 months',
        );
        if (range == null) return;
        if (_monthsBetween(range.start, range.end) >
            ExportService.maxPdfMonths) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Range exceeds 12 months — pick a smaller range'),
              ),
            );
          }
          return;
        }
      }
    }

    final filtered = range == null
        ? txns
        : txns
            .where((t) =>
                !t.createdAt.isBefore(range!.start) &&
                !t.createdAt.isAfter(range.end))
            .toList();

    try {
      final svc = ExportService();
      final file = isPdf
          ? await svc.exportPdf(
              filtered,
              home,
              filtered.fold<double>(
                  0, (s, t) => s + (t.amountHome ?? t.amount)),
            )
          : await svc.exportCsv(filtered);
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: isPdf ? 'LOIT report' : 'LOIT export',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Export failed: $e')));
      }
    }
  }

  int _monthsBetween(DateTime a, DateTime b) {
    return (b.year - a.year) * 12 + (b.month - a.month);
  }
}
