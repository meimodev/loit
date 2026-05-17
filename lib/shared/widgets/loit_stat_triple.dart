import 'package:flutter/material.dart';

import '../../core/theme/loit_colors.dart';
import '../../core/theme/loit_motion.dart';
import '../../core/theme/loit_spacing.dart';
import '../../core/theme/loit_typography.dart';
import 'loit_animations.dart';

/// Three-up summary band: Income / Expenses / Total.
/// Sits directly under the month app bar on Home and Reports.
class LoitStatTriple extends StatelessWidget {
  const LoitStatTriple({super.key, required this.stats});

  final List<LoitStat> stats;

  @override
  Widget build(BuildContext context) {
    final c = context.loitColors;
    return Container(
      color: c.canvas,
      padding: const EdgeInsets.fromLTRB(
        LoitSpacing.s5,
        LoitSpacing.s2,
        LoitSpacing.s5,
        LoitSpacing.s4,
      ),
      child: Row(
        children: [
          for (var i = 0; i < stats.length; i++) ...[
            Expanded(
              child: LoitFadeSlideIn(
                delay: LoitMotion.staggerStep * i,
                child: _StatCell(stat: stats[i]),
              ),
            ),
            if (i < stats.length - 1)
              Container(
                width: 1,
                height: 28,
                color: c.borderSubtle,
                margin: const EdgeInsets.symmetric(horizontal: LoitSpacing.s3),
              ),
          ],
        ],
      ),
    );
  }
}

class LoitStat {
  const LoitStat({required this.label, required this.amount, this.color});
  final String label;
  final String amount;
  final Color? color;
}

class _StatCell extends StatelessWidget {
  const _StatCell({required this.stat});
  final LoitStat stat;

  @override
  Widget build(BuildContext context) {
    final c = context.loitColors;
    final color = stat.color ?? c.contentPrimary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          stat.label.toUpperCase(),
          style: LoitTypography.labelS.copyWith(
            color: c.contentTertiary,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 4),
        AnimatedDefaultTextStyle(
          duration: LoitMotion.emphasized,
          curve: LoitMotion.easeOutQuart,
          style: LoitTypography.amountDefault.copyWith(color: color),
          child: AnimatedSwitcher(
            duration: LoitMotion.base,
            switchInCurve: LoitMotion.easeOutQuart,
            switchOutCurve: LoitMotion.easeOutQuart,
            transitionBuilder: (child, anim) {
              final offset = Tween<Offset>(
                begin: const Offset(0, 0.25),
                end: Offset.zero,
              ).animate(anim);
              return FadeTransition(
                opacity: anim,
                child: SlideTransition(position: offset, child: child),
              );
            },
            layoutBuilder: (current, previous) => Stack(
              alignment: Alignment.center,
              children: [...previous, if (current != null) current],
            ),
            child: Text(stat.amount, key: ValueKey(stat.amount)),
          ),
        ),
      ],
    );
  }
}
