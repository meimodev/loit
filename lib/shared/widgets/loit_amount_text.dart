import 'package:flutter/material.dart';

import '../../core/theme/loit_colors.dart';
import '../../core/theme/loit_palette_aliases.dart';
import '../../core/theme/loit_typography.dart';

enum LoitAmountVariant { hero, large, defaultSize, inline }

/// Amount display with tabular numerals. Use for any monetary value to keep
/// columns aligned across rows.
class LoitAmountText extends StatelessWidget {
  const LoitAmountText(
    this.value, {
    super.key,
    this.variant = LoitAmountVariant.defaultSize,
    this.color,
    this.isIncome,
    this.maxLines = 1,
  });

  final String value;
  final LoitAmountVariant variant;
  final Color? color;

  /// When set, uses income/expense alias colors. Overridden by [color].
  final bool? isIncome;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final c = context.loitColors;
    final base = switch (variant) {
      LoitAmountVariant.hero => LoitTypography.amountHero,
      LoitAmountVariant.large => LoitTypography.amountLarge,
      LoitAmountVariant.defaultSize => LoitTypography.amountDefault,
      LoitAmountVariant.inline => LoitTypography.amountDefault.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
    };

    final resolved = color ??
        (isIncome == null
            ? c.contentPrimary
            : (isIncome!
                ? LoitStatusAliases.income(c)
                : LoitStatusAliases.expense(c)));

    return Text(
      value,
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
      style: base.copyWith(color: resolved),
    );
  }
}
