import 'package:flutter/material.dart';

import '../../core/theme/loit_colors.dart';
import '../../core/theme/loit_spacing.dart';
import '../../core/theme/loit_typography.dart';

/// Section header: small uppercase eyebrow on the canvas, with optional
/// trailing action (e.g. "See all").
class LoitGroupLabel extends StatelessWidget {
  const LoitGroupLabel({
    super.key,
    required this.label,
    this.trailing,
  });

  final String label;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final c = context.loitColors;
    return Container(
      color: c.canvas,
      padding: const EdgeInsets.fromLTRB(
        LoitSpacing.s5,
        LoitSpacing.s5,
        LoitSpacing.s5,
        LoitSpacing.s2,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label.toUpperCase(),
              style: LoitTypography.labelS.copyWith(
                color: c.contentSecondary,
                letterSpacing: 0.8,
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
