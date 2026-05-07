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
/// Personal + inherited room categories are listed together, grouped
/// by source. When [activeRoomId] is set, that room's categories
/// surface first and render unprefixed; other rooms' categories show
/// prefixed with the room name so users can disambiguate.
Future<String?> pickLoitCategory(
  BuildContext context, {
  String? selectedKey,
  bool isIncome = false,
  String? activeRoomId,
}) {
  return showLoitSheet<String>(
    context,
    builder: (_) => _CategoryPickerSheet(
      selectedKey: selectedKey,
      isIncome: isIncome,
      activeRoomId: activeRoomId,
    ),
  );
}

class _CategoryPickerSheet extends ConsumerStatefulWidget {
  const _CategoryPickerSheet({
    this.selectedKey,
    this.isIncome = false,
    this.activeRoomId,
  });

  final String? selectedKey;
  final bool isIncome;
  final String? activeRoomId;

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

  bool _matches(UserCategory cat) {
    if (_query.isEmpty) return true;
    final q = _query.toLowerCase();
    final raw = cat.name.toLowerCase();
    final display =
        cat.displayLabel(activeRoomId: widget.activeRoomId).toLowerCase();
    final key = cat.key.toLowerCase();
    return raw.contains(q) || display.contains(q) || key.contains(q);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.loitColors;
    final all = ref.watch(widget.isIncome
        ? allIncomeCategoriesProvider
        : allExpenseCategoriesProvider);

    final activeRoomCats = <UserCategory>[];
    final personalCats = <UserCategory>[];
    final otherRoomCats = <Map<String, dynamic>>[];
    final otherRoomBuckets = <String, List<UserCategory>>{};

    for (final cat in all) {
      if (!_matches(cat)) continue;
      if (cat.isPersonal) {
        personalCats.add(cat);
      } else if (cat.roomId == widget.activeRoomId &&
          widget.activeRoomId != null) {
        activeRoomCats.add(cat);
      } else {
        final id = cat.roomId ?? '';
        otherRoomBuckets.putIfAbsent(id, () => []).add(cat);
      }
    }
    otherRoomBuckets.forEach((id, list) {
      otherRoomCats.add({
        'roomId': id,
        'roomName': list.first.roomName ?? 'Room',
        'cats': list,
      });
    });
    otherRoomCats.sort((a, b) =>
        (a['roomName'] as String).compareTo(b['roomName'] as String));

    final empty = activeRoomCats.isEmpty &&
        personalCats.isEmpty &&
        otherRoomCats.isEmpty;

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
          if (empty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: LoitSpacing.s6),
              child: Text(
                'No categories found',
                textAlign: TextAlign.center,
                style: LoitTypography.bodyM
                    .copyWith(color: c.contentTertiary),
              ),
            )
          else ...[
            if (activeRoomCats.isNotEmpty) ...[
              _sectionHeader(c, 'This room'),
              for (final cat in activeRoomCats) _row(cat, c),
              const SizedBox(height: LoitSpacing.s2),
            ],
            if (personalCats.isNotEmpty) ...[
              _sectionHeader(c, 'Personal'),
              for (final cat in personalCats) _row(cat, c),
              const SizedBox(height: LoitSpacing.s2),
            ],
            for (final group in otherRoomCats) ...[
              _sectionHeader(c, group['roomName'] as String),
              for (final cat in group['cats'] as List<UserCategory>)
                _row(cat, c),
              const SizedBox(height: LoitSpacing.s2),
            ],
          ],
        ],
      ),
    );
  }

  Widget _sectionHeader(LoitColors c, String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          LoitSpacing.s2, LoitSpacing.s2, LoitSpacing.s2, 6),
      child: Text(
        label.toUpperCase(),
        style: LoitTypography.labelS
            .copyWith(color: c.contentSecondary, letterSpacing: 0.5),
      ),
    );
  }

  Widget _row(UserCategory cat, LoitColors c) {
    final label = cat.displayLabel(activeRoomId: widget.activeRoomId);
    return InkWell(
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
                label,
                style:
                    LoitTypography.bodyL.copyWith(color: c.contentPrimary),
              ),
            ),
            if (cat.key == widget.selectedKey)
              Icon(Icons.check_rounded, color: c.brand, size: 22),
          ],
        ),
      ),
    );
  }
}
