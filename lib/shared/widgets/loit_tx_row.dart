import 'package:flutter/material.dart';

import '../../core/theme/loit_colors.dart';
import '../../core/theme/loit_palette_aliases.dart';
import '../../core/theme/loit_spacing.dart';
import '../../core/theme/loit_typography.dart';
import 'loit_category_avatar.dart';

/// Edge-to-edge transaction row.
/// 60pt min-height per design; bordered bottom unless last in group.
class LoitTxRow extends StatelessWidget {
  const LoitTxRow({
    super.key,
    required this.title,
    required this.amount,
    this.categoryKey,
    this.subtitle,
    this.isIncome = false,
    this.isTransfer = false,
    this.accountLabel,
    this.amountColor,
    this.showDivider = true,
    this.onTap,
    this.trailingBadge,
  });

  final String title;
  final String amount;
  final String? categoryKey;
  final String? subtitle;
  final bool isIncome;
  final bool isTransfer;
  final String? accountLabel;
  final Color? amountColor;
  final bool showDivider;
  final VoidCallback? onTap;
  final Widget? trailingBadge;

  @override
  Widget build(BuildContext context) {
    final c = context.loitColors;
    final colorAmount = amountColor ??
        (isTransfer
            ? c.contentSecondary
            : isIncome
                ? LoitStatusAliases.income(c)
                : LoitStatusAliases.expense(c));
    final effectiveSubtitle = accountLabel != null
        ? (subtitle != null ? '$subtitle · $accountLabel' : accountLabel)
        : subtitle;
    final row = Container(
      color: c.surface,
      padding: const EdgeInsets.symmetric(
        horizontal: LoitSpacing.s5,
        vertical: LoitSpacing.s4,
      ),
      child: Row(
        children: [
          isTransfer
              ? Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: c.contentSecondary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Icon(Icons.swap_horiz, size: 18, color: c.contentSecondary),
                )
              : LoitCategoryAvatar(categoryKey: categoryKey, size: 36),
          const SizedBox(width: LoitSpacing.s4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  softWrap: true,
                  style: LoitTypography.bodyM.copyWith(
                    color: c.contentPrimary,
                    fontWeight: FontWeight.w500,
                    height: 1.25,
                  ),
                ),
                if (effectiveSubtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    effectiveSubtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: LoitTypography.bodyS.copyWith(
                      color: c.contentTertiary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailingBadge != null) ...[
            trailingBadge!,
            const SizedBox(width: LoitSpacing.s3),
          ],
          Text(
            amount,
            style: LoitTypography.amountDefault.copyWith(color: colorAmount),
          ),
        ],
      ),
    );

    final inkRow = onTap == null
        ? row
        : Material(
            color: c.surface,
            child: InkWell(onTap: onTap, child: row),
          );

    if (!showDivider) return inkRow;
    return Column(
      children: [
        inkRow,
        Container(
          height: 1,
          color: c.borderSubtle,
          margin: const EdgeInsets.only(left: LoitSpacing.s5 + 36 + LoitSpacing.s4),
        ),
      ],
    );
  }
}
