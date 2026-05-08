import 'package:flutter/material.dart';

import '../../core/theme/loit_colors.dart';
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
  });

  final String label;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;
  final List<Widget> actions;
  final Widget? leading;

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
              child: Text(
                label,
                style: LoitTypography.titleM.copyWith(
                  color: c.contentPrimary,
                  letterSpacing: -0.1,
                ),
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
