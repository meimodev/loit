import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../core/theme/loit_colors.dart';
import '../../core/theme/loit_motion.dart';
import '../../core/theme/loit_typography.dart';
import '../../l10n/l10n_x.dart';

/// Compact sparkline of daily values. Used by Dashboard insights preview and
/// Reports Overview tab.
class LoitMiniLineChart extends StatelessWidget {
  const LoitMiniLineChart({
    super.key,
    required this.values,
    this.height = 90,
    this.emptyLabel,
    this.formatValue,
  });

  final List<double> values;
  final double height;
  final String? emptyLabel;
  final String Function(double value)? formatValue;

  @override
  Widget build(BuildContext context) {
    final c = context.loitColors;
    if (values.isEmpty || values.every((v) => v == 0)) {
      return SizedBox(
        height: height,
        child: Center(
          child: Text(
            emptyLabel ?? context.l10n.chartNoSpendYet,
            style: LoitTypography.bodyS.copyWith(color: c.contentTertiary),
          ),
        ),
      );
    }
    final spots = <FlSpot>[
      for (var i = 0; i < values.length; i++) FlSpot(i.toDouble(), values[i]),
    ];
    final maxY = values.fold<double>(0, (s, v) => v > s ? v : s) * 1.15 + 1;
    final reduce = MediaQuery.of(context).disableAnimations;
    return SizedBox(
      height: height,
      child: LineChart(
        duration: reduce ? Duration.zero : LoitMotion.entrance,
        curve: LoitMotion.easeOutQuart,
        LineChartData(
          minY: 0,
          maxY: maxY,
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          gridData: const FlGridData(show: false),
          lineTouchData: LineTouchData(
            handleBuiltInTouches: true,
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => c.contentPrimary,
              tooltipRoundedRadius: 8,
              tooltipPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 6,
              ),
              getTooltipItems: (spots) => spots
                  .map(
                    (s) => LineTooltipItem(
                      formatValue?.call(s.y) ?? s.y.toStringAsFixed(0),
                      LoitTypography.labelS.copyWith(
                        color: c.canvas,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
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
      ),
    );
  }
}
