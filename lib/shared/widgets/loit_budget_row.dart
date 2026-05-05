import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/loit_colors.dart';
import '../../core/theme/loit_radius.dart';
import '../../core/theme/loit_spacing.dart';
import '../../core/theme/loit_typography.dart';
import '../../shared/providers/user_categories_provider.dart';
import 'loit_category_avatar.dart';

/// Per-category budget row with progress bar.
class LoitBudgetRow extends ConsumerWidget {
  const LoitBudgetRow({
    super.key,
    required this.label,
    required this.percent,
    required this.subtitle,
    this.categoryKey,
    this.showDivider = true,
    this.onTap,
  });

  final String label;
  final int percent;
  final String subtitle;
  final String? categoryKey;
  final bool showDivider;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.loitColors;
    final style = ref.watch(categoryStyleProvider(categoryKey));
    final tint = style.tint;
    final isOver = percent > 100;
    final pctColor = isOver ? c.danger : c.contentPrimary;
    final fillColor = isOver ? c.danger : tint;

    final body = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: LoitSpacing.s5,
        vertical: LoitSpacing.s4,
      ),
      child: Row(
        children: [
          LoitCategoryAvatar(categoryKey: categoryKey, size: 36),
          const SizedBox(width: LoitSpacing.s4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        label,
                        style: LoitTypography.bodyM.copyWith(
                          color: c.contentPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Text(
                      '$percent%',
                      style: LoitTypography.amountDefault.copyWith(
                        color: pctColor,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: LoitRadius.brFull,
                  child: Container(
                    height: 4,
                    color: c.muted,
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: (percent.clamp(0, 100)) / 100,
                      child: Container(color: fillColor),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: LoitTypography.bodyS.copyWith(color: c.contentTertiary),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    final tappable = onTap == null
        ? Container(color: c.surface, child: body)
        : Material(
            color: c.surface,
            child: InkWell(onTap: onTap, child: body),
          );

    if (!showDivider) return tappable;
    return Column(
      children: [
        tappable,
        Container(
          height: 1,
          color: c.borderSubtle,
          margin: const EdgeInsets.only(
              left: LoitSpacing.s5 + 36 + LoitSpacing.s4),
        ),
      ],
    );
  }
}
