import 'package:flutter/material.dart';

import '../../core/theme/loit_colors.dart';
import '../../core/theme/loit_motion.dart';
import '../../core/theme/loit_spacing.dart';
import '../../core/theme/loit_typography.dart';

/// App bar with a centered tappable month label and a row of trailing
/// icon actions. Mirrors `AppBarMonth` in the design prototype.
class LoitAppBarMonth extends StatelessWidget implements PreferredSizeWidget {
  const LoitAppBarMonth({
    super.key,
    required this.label,
    this.onPrev,
    this.onNext,
    this.actions = const [],
    this.leading,
    this.direction = 0,
  });

  final String label;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;
  final List<Widget> actions;
  final Widget? leading;

  /// +1 forward (next), -1 back (prev), 0 fade-only (initial / jump).
  final int direction;

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    final c = context.loitColors;
    final topInset = MediaQuery.paddingOf(context).top;
    return Container(
      height: 56 + topInset,
      color: c.canvas,
      padding: EdgeInsets.only(
        top: topInset,
        left: LoitSpacing.s4,
        right: LoitSpacing.s4,
      ),
      child: Row(
        children: [
          if (leading != null) leading!,
          IconButton(
            icon: const Icon(Icons.chevron_left, size: 22),
            onPressed: onPrev,
            color: c.contentSecondary,
          ),
          Expanded(
            child: Center(
              child: _AnimatedMonthLabel(
                label: label,
                direction: direction,
                color: c.contentPrimary,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, size: 22),
            onPressed: onNext,
            color: c.contentSecondary,
          ),
          ...actions,
        ],
      ),
    );
  }
}

class _AnimatedMonthLabel extends StatelessWidget {
  const _AnimatedMonthLabel({
    required this.label,
    required this.direction,
    required this.color,
  });

  final String label;
  final int direction;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final style = LoitTypography.titleM.copyWith(
      color: color,
      letterSpacing: -0.1,
    );
    if (reduce || direction == 0) {
      return AnimatedSwitcher(
        duration: reduce ? Duration.zero : LoitMotion.short,
        switchInCurve: LoitMotion.easeOutExpo,
        child: Text(label, key: ValueKey(label), style: style),
      );
    }
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 260),
      reverseDuration: const Duration(milliseconds: 180),
      switchInCurve: LoitMotion.easeOutExpo,
      switchOutCurve: LoitMotion.easeOutExpo,
      layoutBuilder: (current, prev) => Stack(
        alignment: Alignment.center,
        children: [...prev, if (current != null) current],
      ),
      transitionBuilder: (child, anim) {
        final key = child.key;
        final isIncoming = key is ValueKey<String> && key.value == label;
        final dx = isIncoming ? direction * 0.35 : -direction * 0.35;
        return ClipRect(
          child: SlideTransition(
            position: Tween<Offset>(
              begin: Offset(dx, 0),
              end: Offset.zero,
            ).animate(anim),
            child: child,
          ),
        );
      },
      child: Text(label, key: ValueKey<String>(label), style: style),
    );
  }
}
