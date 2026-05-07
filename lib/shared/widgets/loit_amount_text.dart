import 'package:flutter/material.dart';

import '../../core/theme/loit_colors.dart';
import '../../core/theme/loit_palette_aliases.dart';
import '../../core/theme/loit_typography.dart';
import '../utils/amount_input.dart';

enum LoitAmountVariant { hero, large, defaultSize, inline }

/// Amount display with tabular numerals.
///
/// Two ways to use:
///
/// * Pre-formatted string (legacy): `LoitAmountText('Rp 12.000')`.
/// * Money helper (preferred): `LoitAmountText.money(amount: 10, currency: 'USD')`.
///   Optionally pass `convertedAmount`/`convertedCurrency` to render a
///   secondary `≈` line (e.g. converted home/room currency), and `isStale`
///   to flag rates served from a stale FX cache.
class LoitAmountText extends StatelessWidget {
  const LoitAmountText(
    this.value, {
    super.key,
    this.variant = LoitAmountVariant.defaultSize,
    this.color,
    this.isIncome,
    this.maxLines = 1,
    this.secondary,
    this.isStale = false,
  });

  /// Renders amount in [currency], plus an optional `≈` secondary line in
  /// [convertedCurrency]. The widget itself is synchronous — callers compute
  /// converted values upstream (typically via `currencyServiceProvider`).
  factory LoitAmountText.money({
    Key? key,
    required double amount,
    required String currency,
    LoitAmountVariant variant = LoitAmountVariant.defaultSize,
    Color? color,
    bool? isIncome,
    int maxLines = 1,
    double? convertedAmount,
    String? convertedCurrency,
    bool isStale = false,
    bool showSign = false,
  }) {
    final primary = formatMoney(amount, currency, showSign: showSign);
    final secondary = (convertedAmount != null &&
            convertedCurrency != null &&
            convertedCurrency != currency)
        ? '≈ ${formatMoney(convertedAmount, convertedCurrency)}'
        : null;
    return LoitAmountText(
      primary,
      key: key,
      variant: variant,
      color: color,
      isIncome: isIncome,
      maxLines: maxLines,
      secondary: secondary,
      isStale: isStale,
    );
  }

  final String value;
  final LoitAmountVariant variant;
  final Color? color;

  /// When set, uses income/expense alias colors. Overridden by [color].
  final bool? isIncome;
  final int maxLines;

  /// Optional secondary line (e.g. converted-currency approximation).
  final String? secondary;

  /// When true, an `≈ stale` chip is shown next to the primary value.
  final bool isStale;

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

    final primaryText = Text(
      value,
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
      style: base.copyWith(color: resolved),
    );

    if (secondary == null && !isStale) return primaryText;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            primaryText,
            if (isStale) ...[
              const SizedBox(width: 6),
              Icon(Icons.schedule, size: 14, color: c.contentTertiary),
            ],
          ],
        ),
        if (secondary != null)
          Text(
            secondary!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: LoitTypography.bodyS.copyWith(color: c.contentTertiary),
          ),
      ],
    );
  }
}
