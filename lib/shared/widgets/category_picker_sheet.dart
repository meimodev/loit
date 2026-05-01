import 'package:flutter/material.dart';

import '../../core/theme/loit_categories.dart';
import '../../core/theme/loit_colors.dart';
import '../../core/theme/loit_radius.dart';
import '../../core/theme/loit_spacing.dart';
import '../../core/theme/loit_typography.dart';
import 'loit_category_avatar.dart';
import 'loit_sheet.dart';

/// Bottom sheet for picking a category. Returns the selected key.
/// When [isIncome] is true, only income categories are shown; otherwise expense.
Future<String?> pickLoitCategory(
  BuildContext context, {
  String? selectedKey,
  bool isIncome = false,
}) {
  return showLoitSheet<String>(
    context,
    builder: (_) => _CategoryPickerSheet(
      selectedKey: selectedKey,
      isIncome: isIncome,
    ),
  );
}

class _CategoryPickerSheet extends StatelessWidget {
  const _CategoryPickerSheet({this.selectedKey, this.isIncome = false});

  final String? selectedKey;
  final bool isIncome;

  @override
  Widget build(BuildContext context) {
    final c = context.loitColors;
    final keys =
        isIncome ? LoitCategories.incomeKeys : LoitCategories.expenseKeys;
    return LoitSheet(
      title: isIncome ? 'Income category' : 'Category',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final key in keys) ...[
            InkWell(
              borderRadius: LoitRadius.brM,
              onTap: () => Navigator.of(context).pop(key),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: LoitSpacing.s3,
                  horizontal: LoitSpacing.s2,
                ),
                child: Row(
                  children: [
                    LoitCategoryAvatar(categoryKey: key, size: 36),
                    const SizedBox(width: LoitSpacing.s4),
                    Expanded(
                      child: Text(
                        LoitCategories.byKey[key]!.label,
                        style: LoitTypography.bodyL
                            .copyWith(color: c.contentPrimary),
                      ),
                    ),
                    if (key == selectedKey)
                      Icon(Icons.check_rounded, color: c.brand, size: 22),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
