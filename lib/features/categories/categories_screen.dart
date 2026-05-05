import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/loit_colors.dart';
import '../../core/theme/loit_radius.dart';
import '../../core/theme/loit_spacing.dart';
import '../../core/theme/loit_typography.dart';
import '../../shared/providers/user_categories_provider.dart';
import '../../shared/widgets/loit_category_avatar.dart';
import '../../shared/widgets/loit_group_label.dart';

class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.loitColors;
    final catsAsync = ref.watch(userCategoriesProvider);

    return Scaffold(
      backgroundColor: c.canvas,
      appBar: AppBar(
        title: const Text('Categories'),
        backgroundColor: c.canvas,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: catsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (cats) {
          final expense = cats.where((cat) => cat.isExpense).toList();
          final income = cats.where((cat) => cat.isIncome).toList();

          if (cats.isEmpty) return const _EmptyCategoriesState();

          return ListView(
            children: [
              if (expense.isNotEmpty) ...[
                LoitGroupLabel(
                  label: 'Expense',
                  trailing: _CountBadge(count: expense.length),
                ),
                Container(
                  color: c.surface,
                  child: Column(
                    children: [
                      for (var i = 0; i < expense.length; i++)
                        _dismissibleRow(
                          context: context,
                          ref: ref,
                          cat: expense[i],
                          showDivider: i != expense.length - 1,
                        ),
                    ],
                  ),
                ),
              ],
              if (income.isNotEmpty) ...[
                LoitGroupLabel(
                  label: 'Income',
                  trailing: _CountBadge(count: income.length),
                ),
                Container(
                  color: c.surface,
                  child: Column(
                    children: [
                      for (var i = 0; i < income.length; i++)
                        _dismissibleRow(
                          context: context,
                          ref: ref,
                          cat: income[i],
                          showDivider: i != income.length - 1,
                        ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 80),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/categories/new'),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _dismissibleRow({
    required BuildContext context,
    required WidgetRef ref,
    required UserCategory cat,
    required bool showDivider,
  }) {
    final c = context.loitColors;
    return Dismissible(
      key: ValueKey(cat.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        return await showDialog<bool>(
              context: context,
              builder: (_) => AlertDialog(
                title: Text('Delete "${cat.name}"?'),
                content: const Text(
                  'Transactions or budgets with this category key will fall back to "Other".',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                  FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: c.danger),
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Delete'),
                  ),
                ],
              ),
            ) ??
            false;
      },
      onDismissed: (_) {
        ref.read(userCategoriesProvider.notifier).delete(cat.id);
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: c.danger,
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      child: _CategoryRow(
        cat: cat,
        showDivider: showDivider,
        onTap: () =>
            context.push('/categories/${cat.id}/edit', extra: cat),
      ),
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
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.loitColors;
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
              child: Text(
                cat.name,
                style: LoitTypography.bodyM.copyWith(
                  color: c.contentPrimary,
                  fontWeight: FontWeight.w500,
                ),
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
            Icon(Icons.chevron_right, size: 16, color: c.contentTertiary),
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
              'No categories yet',
              style: LoitTypography.titleM
                  .copyWith(color: c.contentPrimary, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              'Tap "Add category" to create your first one.',
              textAlign: TextAlign.center,
              style: LoitTypography.bodyS.copyWith(color: c.contentSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
