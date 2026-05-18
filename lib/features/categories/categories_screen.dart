import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/loit_colors.dart';
import '../../core/theme/loit_radius.dart';
import '../../core/theme/loit_spacing.dart';
import '../../core/theme/loit_typography.dart';
import '../../l10n/l10n_x.dart';
import '../../shared/providers/user_categories_provider.dart';
import '../../shared/widgets/loit_category_avatar.dart';
import '../../shared/widgets/loit_group_label.dart';

class CategoriesScreen extends ConsumerStatefulWidget {
  const CategoriesScreen({super.key});

  @override
  ConsumerState<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends ConsumerState<CategoriesScreen> {
  final _dismissed = <String>{};

  @override
  Widget build(BuildContext context) {
    final c = context.loitColors;
    final l = context.l10n;
    final catsAsync = ref.watch(userCategoriesProvider);

    return Scaffold(
      backgroundColor: c.canvas,
      appBar: AppBar(
        title: Text(l.catScreenTitle),
        backgroundColor: c.canvas,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(userCategoriesProvider);
          await ref.read(userCategoriesProvider.future);
        },
        child: catsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (cats) {
          final visible = cats
              .where((c) => c.isPersonal && !_dismissed.contains(c.id))
              .toList();
          if (visible.isEmpty) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [_EmptyCategoriesState()],
            );
          }

          final personalExpense =
              visible.where((cat) => cat.isExpense).toList();
          final personalIncome =
              visible.where((cat) => cat.isIncome).toList();

          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              if (personalExpense.isNotEmpty) ...[
                LoitGroupLabel(
                  label: l.catScreenPersonalExpense,
                  trailing: _CountBadge(count: personalExpense.length),
                ),
                _RowGroup(
                  cats: personalExpense,
                  onEdit: (cat) =>
                      context.push('/categories/${cat.id}/edit', extra: cat),
                  onDelete: _confirmDelete,
                  canManage: true,
                ),
              ],
              if (personalIncome.isNotEmpty) ...[
                LoitGroupLabel(
                  label: l.catScreenPersonalIncome,
                  trailing: _CountBadge(count: personalIncome.length),
                ),
                _RowGroup(
                  cats: personalIncome,
                  onEdit: (cat) =>
                      context.push('/categories/${cat.id}/edit', extra: cat),
                  onDelete: _confirmDelete,
                  canManage: true,
                ),
              ],
              const SizedBox(height: 80),
            ],
          );
        },
      ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/categories/new'),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<bool> _confirmDelete(UserCategory cat) async {
    if (!mounted) return false;
    final c = context.loitColors;
    final l = context.l10n;
    return await showDialog<bool>(
          context: context,
          useRootNavigator: false,
          builder: (dialogCtx) => AlertDialog(
            title: Text(l.catScreenDeleteTitle(cat.name)),
            content: Text(
              l.catScreenDeleteBody,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx, false),
                child: Text(l.catScreenCancel),
              ),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: c.danger),
                onPressed: () => Navigator.pop(dialogCtx, true),
                child: Text(l.catScreenDelete),
              ),
            ],
          ),
        ) ??
        false;
  }
}

class _RowGroup extends ConsumerWidget {
  const _RowGroup({
    required this.cats,
    required this.canManage,
    this.onEdit,
    this.onDelete,
  });
  final List<UserCategory> cats;
  final bool canManage;
  final void Function(UserCategory)? onEdit;
  final Future<bool> Function(UserCategory)? onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.loitColors;
    return Container(
      color: c.surface,
      child: Column(
        children: [
          for (var i = 0; i < cats.length; i++)
            _row(context, ref, cats[i], i != cats.length - 1),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, WidgetRef ref, UserCategory cat,
      bool showDivider) {
    final tap = (canManage && onEdit != null) ? () => onEdit!(cat) : null;
    final row = _CategoryRow(cat: cat, showDivider: showDivider, onTap: tap);
    if (!canManage || onDelete == null) return row;
    final c = context.loitColors;
    return Dismissible(
      key: ValueKey(cat.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async => onDelete!(cat),
      onDismissed: (_) {
        ref.read(userCategoriesProvider.notifier).delete(cat.id);
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: c.danger,
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      child: row,
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.cat,
    required this.showDivider,
    required this.onTap,
  });

  final UserCategory cat;
  final bool showDivider;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.loitColors;
    final l = context.l10n;
    final readOnly = onTap == null;
    final row = InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: LoitSpacing.s5,
          vertical: LoitSpacing.s4,
        ),
        child: Row(
          children: [
            LoitCategoryAvatar(categoryKey: cat.key, size: 36),
            const SizedBox(width: LoitSpacing.s4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cat.name,
                    style: LoitTypography.bodyM.copyWith(
                      color: c.contentPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (readOnly && cat.isRoom)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        l.catScreenInherited,
                        style: LoitTypography.bodyS
                            .copyWith(color: c.contentTertiary),
                      ),
                    ),
                ],
              ),
            ),
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: cat.tintColor,
                shape: BoxShape.circle,
                border: Border.all(color: c.borderSubtle),
              ),
            ),
            const SizedBox(width: LoitSpacing.s3),
            if (!readOnly)
              Icon(Icons.chevron_right, size: 16, color: c.contentTertiary)
            else
              Icon(Icons.lock_outline, size: 14, color: c.contentTertiary),
          ],
        ),
      ),
    );

    if (!showDivider) return row;
    return Column(
      children: [
        row,
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

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final c = context.loitColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: c.muted,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$count',
        style: LoitTypography.labelS.copyWith(color: c.contentSecondary),
      ),
    );
  }
}

class _EmptyCategoriesState extends StatelessWidget {
  const _EmptyCategoriesState();

  @override
  Widget build(BuildContext context) {
    final c = context.loitColors;
    final l = context.l10n;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(LoitSpacing.s6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: c.muted,
                borderRadius: LoitRadius.brM,
              ),
              alignment: Alignment.center,
              child: Icon(Icons.category_outlined,
                  size: 26, color: c.contentSecondary),
            ),
            const SizedBox(height: LoitSpacing.s4),
            Text(
              l.catScreenNoCategories,
              style: LoitTypography.titleM
                  .copyWith(color: c.contentPrimary, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              l.catScreenEmptyBody,
              textAlign: TextAlign.center,
              style: LoitTypography.bodyS.copyWith(color: c.contentSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
