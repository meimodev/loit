import 'package:flutter/material.dart';

import '../../core/theme/loit_colors.dart';
import '../../core/theme/loit_radius.dart';

/// Budget progress bar. Color reflects spend ratio.
/// pct < 70 → success, 70..99 → warning, ≥100 → danger.
/// Over 100 paints a darker red overflow segment on the right.
class LoitProgressBar extends StatelessWidget {
  const LoitProgressBar({
    super.key,
    required this.percent,
    this.height = 8,
    this.fillColorOverride,
  });

  final int percent; // 0..200+
  final double height;

  /// Override the fill color (e.g. category tint). Status colors still take
  /// precedence at warning/danger thresholds.
  final Color? fillColorOverride;

  @override
  Widget build(BuildContext context) {
    final c = context.loitColors;
    final pct = percent.clamp(0, 200);
    final fill = pct >= 100
        ? c.danger
        : pct >= 70
            ? c.warning
            : (fillColorOverride ?? c.success);
    final base = pct.clamp(0, 100) / 100;
    final over = pct > 100 ? (pct - 100) / pct : 0.0;

    return ClipRRect(
      borderRadius: LoitRadius.brFull,
      child: Container(
        height: height,
        color: c.muted,
        child: Stack(
          children: [
            FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: base,
              child: Container(color: fill),
            ),
            if (over > 0)
              Align(
                alignment: Alignment.centerRight,
                child: FractionallySizedBox(
                  widthFactor: over,
                  child: Container(color: c.danger.withValues(alpha: 0.8)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
