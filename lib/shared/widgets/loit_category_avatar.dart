import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/loit_radius.dart';
import '../../shared/providers/user_categories_provider.dart';

/// Circular tinted icon bubble for a category.
/// Background is the category tint at 12% (light) or 20% (dark).
class LoitCategoryAvatar extends ConsumerWidget {
  const LoitCategoryAvatar({
    super.key,
    required this.categoryKey,
    this.size = 36,
    this.iconSize,
  });

  final String? categoryKey;
  final double size;
  final double? iconSize;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final style = ref.watch(categoryStyleProvider(categoryKey));
    final bg = style.tint.withValues(alpha: isDark ? 0.20 : 0.12);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: LoitRadius.brFull,
      ),
      alignment: Alignment.center,
      child: Icon(style.icon, color: style.tint, size: iconSize ?? size * 0.5),
    );
  }
}
