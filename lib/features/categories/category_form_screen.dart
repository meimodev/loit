import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/loit_categories.dart';
import '../../core/theme/loit_colors.dart';
import '../../core/theme/loit_radius.dart';
import '../../core/theme/loit_spacing.dart';
import '../../core/theme/loit_typography.dart';
import '../../l10n/l10n_x.dart';
import '../../shared/providers/user_categories_provider.dart';
import '../../shared/widgets/loit_input.dart';

const _kCategoryPalette = [
  '#F2A85C', '#2F8F5E', '#3E7AC5', '#B15FC0', '#E06B8A',
  '#5A6160', '#C5443E', '#188268', '#9AA09E', '#D49A2B',
  '#4FA88B', '#6EAA92', '#8FB7A6', '#B7CF8C', '#3CA876',
];

class CategoryFormScreen extends ConsumerStatefulWidget {
  const CategoryFormScreen({super.key, this.category, this.roomId});
  final UserCategory? category;
  final String? roomId;

  @override
  ConsumerState<CategoryFormScreen> createState() =>
      _CategoryFormScreenState();
}

class _CategoryFormScreenState extends ConsumerState<CategoryFormScreen> {
  final _nameCtrl = TextEditingController();
  String _kind = 'expense';
  String _iconName = 'category_outlined';
  String _tint = '#9AA09E';
  bool _busy = false;
  String? _nameError;

  bool get _isRoom =>
      widget.category?.isRoom == true || widget.roomId != null;

  String? get _effectiveRoomId =>
      widget.category?.roomId ?? widget.roomId;

  @override
  void initState() {
    super.initState();
    final cat = widget.category;
    if (cat != null) {
      _nameCtrl.text = cat.name;
      _kind = cat.kind;
      _iconName = cat.iconName ?? 'category_outlined';
      _tint = cat.tint ?? '#9AA09E';
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  bool _validate() {
    final l = context.l10n;
    final name = _nameCtrl.text.trim();
    final err = name.isEmpty ? l.catFormNameRequired : null;
    setState(() => _nameError = err);
    return err == null;
  }

  String _generateKey(String name, String kind) {
    final slug = name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .trimChar('_');
    final prefix = kind == 'income' ? 'income_' : '';
    final roomId = _effectiveRoomId;
    if (roomId != null) {
      return 'room:$roomId:$prefix$slug';
    }
    return '$prefix$slug';
  }

  Future<void> _save() async {
    if (!_validate()) return;
    setState(() => _busy = true);
    try {
      final notifier = ref.read(userCategoriesProvider.notifier);
      final name = _nameCtrl.text.trim();
      if (widget.category == null) {
        final key = _generateKey(name, _kind);
        await notifier.create(
          key: key,
          name: name,
          kind: _kind,
          iconName: _iconName,
          tint: _tint,
          roomId: _effectiveRoomId,
        );
      } else {
        await notifier.updateCategory(
          id: widget.category!.id,
          name: name,
          kind: _kind,
          iconName: _iconName,
          tint: _tint,
        );
      }
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(context.l10n.catFormSaveFailed(e.toString()))));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete() async {
    final c = context.loitColors;
    final l = context.l10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l.catScreenDeleteTitle(widget.category!.name)),
        content: Text(
          l.catScreenDeleteBodyPermanent,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l.catScreenCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: c.danger),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l.catScreenDelete),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(userCategoriesProvider.notifier)
          .delete(widget.category!.id);
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l.catFormDeleteFailed(e.toString()))));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.loitColors;
    final l = context.l10n;
    final isEdit = widget.category != null;
    final tintColor = _parseColor(_tint);

    String title;
    if (_isRoom) {
      title = isEdit ? l.catFormEditRoomCategory : l.catFormNewRoomCategory;
    } else {
      title = isEdit ? l.catFormEditCategory : l.catFormNewCategory;
    }

    return Scaffold(
      backgroundColor: c.canvas,
      appBar: AppBar(
        title: Text(title),
        actions: [
          if (isEdit)
            IconButton(
              icon: Icon(Icons.delete_outline, color: c.danger),
              tooltip: l.catFormDelete,
              onPressed: _busy ? null : _delete,
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(LoitSpacing.s5),
        children: [
          LoitInput(
            controller: _nameCtrl,
            label: l.catFormName,
            placeholder: l.catFormNamePlaceholder,
            error: _nameError,
          ),
          const SizedBox(height: LoitSpacing.s5),
          Text(
            l.catFormType,
            style: LoitTypography.bodyM.copyWith(
              color: c.contentPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: [
              ButtonSegment(value: 'expense', label: Text(l.catFormExpense)),
              ButtonSegment(value: 'income', label: Text(l.catFormIncome)),
            ],
            selected: {_kind},
            onSelectionChanged: (v) => setState(() => _kind = v.first),
          ),
          const SizedBox(height: LoitSpacing.s5),
          Text(
            l.catFormColor,
            style: LoitTypography.bodyM.copyWith(
              color: c.contentPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final hex in _kCategoryPalette)
                GestureDetector(
                  onTap: () => setState(() => _tint = hex),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: _parseColor(hex),
                      shape: BoxShape.circle,
                      border: _tint == hex
                          ? Border.all(color: c.contentPrimary, width: 2)
                          : null,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: LoitSpacing.s5),
          Text(
            l.catFormIcon,
            style: LoitTypography.bodyM.copyWith(
              color: c.contentPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 200,
            child: GridView.builder(
              shrinkWrap: true,
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 6,
                mainAxisSpacing: 4,
                crossAxisSpacing: 4,
              ),
              itemCount: LoitCategories.commonIconNames.length,
              itemBuilder: (_, i) {
                final name = LoitCategories.commonIconNames[i];
                final icon = LoitCategories.iconFromName(name)!;
                final selected = name == _iconName;
                return InkWell(
                  borderRadius: LoitRadius.brS,
                  onTap: () => setState(() => _iconName = name),
                  child: Container(
                    decoration: BoxDecoration(
                      color: selected
                          ? tintColor.withValues(alpha: 0.14)
                          : null,
                      borderRadius: LoitRadius.brS,
                      border: selected
                          ? Border.all(color: tintColor, width: 1.5)
                          : null,
                    ),
                    child: Icon(icon,
                        size: 22,
                        color: selected ? tintColor : c.contentSecondary),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: LoitSpacing.s7),
          FilledButton(
            style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52)),
            onPressed: _busy ? null : _save,
            child: _busy
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(isEdit ? l.catFormSaveChanges : l.catFormCreateCategory),
          ),
        ],
      ),
    );
  }
}

Color _parseColor(String hex) {
  final h = hex.replaceFirst('#', '');
  return Color(int.parse('FF$h', radix: 16));
}

extension on String {
  String trimChar(String ch) {
    var s = this;
    while (s.startsWith(ch)) {
      s = s.substring(1);
    }
    while (s.endsWith(ch)) {
      s = s.substring(0, s.length - 1);
    }
    return s;
  }
}
