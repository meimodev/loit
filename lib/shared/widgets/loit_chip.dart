import 'package:flutter/material.dart';

import '../../core/theme/loit_colors.dart';
import '../../core/theme/loit_radius.dart';
import '../../core/theme/loit_spacing.dart';
import '../../core/theme/loit_typography.dart';

enum LoitChipVariant { defaultChip, selected, outline }

/// Pill chip used for filters, tags. 32pt high.
class LoitChip extends StatelessWidget {
  const LoitChip({
    super.key,
    required this.label,
    this.selected = false,
    this.variant = LoitChipVariant.defaultChip,
    this.leading,
    this.onTap,
    this.onDismiss,
  });

  final String label;
  final bool selected;
  final LoitChipVariant variant;
  final IconData? leading;
  final VoidCallback? onTap;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    final c = context.loitColors;
    final isSelected = selected || variant == LoitChipVariant.selected;
    final isOutline = variant == LoitChipVariant.outline && !isSelected;

    final bg = isSelected
        ? c.brand
        : isOutline
            ? Colors.transparent
            : c.muted;
    final fg = isSelected ? c.contentInverse : c.contentPrimary;
    final border = isOutline ? Border.all(color: c.borderDefault) : null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: LoitRadius.brFull,
        child: Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: LoitSpacing.s4),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: LoitRadius.brFull,
            border: border,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (leading != null) ...[
                Icon(leading, size: 14, color: fg),
                const SizedBox(width: 4),
              ],
              Text(label,
                  style: LoitTypography.labelM.copyWith(color: fg)),
              if (onDismiss != null) ...[
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: onDismiss,
                  child: Icon(Icons.close, size: 12, color: fg.withValues(alpha: 0.75)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
