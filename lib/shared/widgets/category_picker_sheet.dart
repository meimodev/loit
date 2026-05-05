import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/loit_colors.dart';
import '../../core/theme/loit_radius.dart';
import '../../core/theme/loit_spacing.dart';
import '../../core/theme/loit_typography.dart';
import '../../shared/providers/user_categories_provider.dart';
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

class _CategoryPickerSheet extends ConsumerStatefulWidget {
  const _CategoryPickerSheet({this.selectedKey, this.isIncome = false});

  final String? selectedKey;
  final bool isIncome;

  @override
  ConsumerState<_CategoryPickerSheet> createState() =>
      _CategoryPickerSheetState();
}

class _CategoryPickerSheetState extends ConsumerState<_CategoryPickerSheet> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.loitColors;
    final cats = ref.watch(widget.isIncome
        ? incomeCategoriesProvider
        : expenseCategoriesProvider);
    final filtered = _query.isEmpty
        ? cats
        : cats
            .where((cat) =>
                cat.name.toLowerCase().contains(_query.toLowerCase()) ||
                cat.key.toLowerCase().contains(_query.toLowerCase()))
            .toList();

    return LoitSheet(
      title: widget.isIncome ? 'Income category' : 'Category',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              hintText: 'Search categories…',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _query.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() => _query = '');
                      },
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: LoitSpacing.s3,
                vertical: LoitSpacing.s2,
              ),
              border: OutlineInputBorder(
                borderRadius: LoitRadius.brM,
                borderSide: BorderSide(color: c.borderSubtle),
              ),
            ),
            onChanged: (v) => setState(() => _query = v),
          ),
          const SizedBox(height: LoitSpacing.s4),
          if (filtered.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: LoitSpacing.s6),
              child: Text(
                'No categories found',
                textAlign: TextAlign.center,
                style: LoitTypography.bodyM
                    .copyWith(color: c.contentTertiary),
              ),
            )
          else
            for (final cat in filtered)
              InkWell(
                borderRadius: LoitRadius.brM,
                onTap: () => Navigator.of(context).pop(cat.key),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: LoitSpacing.s3,
                    horizontal: LoitSpacing.s2,
                  ),
                  child: Row(
                    children: [
                      LoitCategoryAvatar(categoryKey: cat.key, size: 36),
                      const SizedBox(width: LoitSpacing.s4),
                      Expanded(
                        child: Text(
                          cat.name,
                          style: LoitTypography.bodyL
                              .copyWith(color: c.contentPrimary),
                        ),
                      ),
                      if (cat.key == widget.selectedKey)
                        Icon(Icons.check_rounded,
                            color: c.brand, size: 22),
                    ],
                  ),
                ),
              ),
        ],
      ),
    );
  }
}
