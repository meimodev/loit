import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/config/categories.dart';
import '../../core/services/analytics_service.dart';
import '../../core/services/interaction_log_service.dart';
import '../paywall/paywall_screen.dart';
import '../../shared/providers/auth_providers.dart';
import '../../shared/providers/budgets_provider.dart';

/// Budgets list + create/edit flow. Enforces Free-tier 3-budget cap.
class BudgetsScreen extends ConsumerWidget {
  const BudgetsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgets = ref.watch(budgetsProvider);
    final statuses = ref.watch(budgetStatusesProvider);
    final profile = ref.watch(userProfileProvider).value;

    return Scaffold(
      appBar: AppBar(title: const Text('Budgets')),
      body: budgets.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (items) {
          if (items.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'No budgets yet. Tap + to add one per category.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: statuses.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) => _BudgetCard(
              status: statuses[i],
              homeCurrency: profile?.homeCurrency ?? 'IDR',
              onEdit: () =>
                  _openSheet(context, ref, existing: statuses[i].budget),
              onDelete: () => ref
                  .read(budgetsProvider.notifier)
                  .delete(statuses[i].budget.id),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          final count = budgets.value?.length ?? 0;
          final cap = profile?.budgetLimit ?? 3;
          if (count >= cap) {
            showPaywallSheet(context, feature: 'unlimited_budgets');
            return;
          }
          _openSheet(context, ref);
        },
        icon: const Icon(Icons.add),
        label: const Text('Add budget'),
      ),
    );
  }

  void _openSheet(BuildContext context, WidgetRef ref, {Budget? existing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _BudgetFormSheet(existing: existing),
    );
  }
}

class _BudgetCard extends StatelessWidget {
  const _BudgetCard({
    required this.status,
    required this.homeCurrency,
    required this.onEdit,
    required this.onDelete,
  });

  final BudgetStatus status;
  final String homeCurrency;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.simpleCurrency(name: homeCurrency);
    final color = status.isOver
        ? Theme.of(context).colorScheme.error
        : status.isNearLimit
        ? Colors.amber.shade700
        : Theme.of(context).colorScheme.primary;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Categories.iconFor(status.budget.category)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    status.budget.category,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton(onPressed: onEdit, icon: const Icon(Icons.edit)),
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: status.ratio.clamp(0.0, 1.0),
              color: color,
              minHeight: 8,
              // ignore: deprecated_member_use
              backgroundColor: color.withOpacity(0.15),
            ),
            const SizedBox(height: 6),
            Text(
              '${fmt.format(status.spent)} / ${fmt.format(status.budget.monthlyLimit)}'
              '  ·  ${(status.ratio * 100).toStringAsFixed(0)}%',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _BudgetFormSheet extends ConsumerStatefulWidget {
  const _BudgetFormSheet({this.existing});
  final Budget? existing;

  @override
  ConsumerState<_BudgetFormSheet> createState() => _BudgetFormSheetState();
}

class _BudgetFormSheetState extends ConsumerState<_BudgetFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late String _category;
  final _limit = TextEditingController();
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _category = widget.existing?.category ?? 'dining';
    if (widget.existing != null) {
      _limit.text = widget.existing!.monthlyLimit.toString();
    }
  }

  @override
  void dispose() {
    _limit.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(budgetsProvider.notifier)
          .upsert(
            category: _category,
            monthlyLimit: double.parse(_limit.text),
            id: widget.existing?.id,
          );
      if (widget.existing == null) await Analytics.budgetCreated();
      InteractionLog.success(
        action: widget.existing == null ? 'budget_created' : 'budget_updated',
        screen: 'budgets',
        message: 'Category: $_category, limit: ${_limit.text}',
      );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      InteractionLog.error(
        action: 'budget_save',
        screen: 'budgets',
        message: '$e',
        metadata: {'category': _category, 'limit': _limit.text},
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Save failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        8,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.existing == null ? 'New budget' : 'Edit budget',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _category,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
              items: [
                for (final c in Categories.all)
                  DropdownMenuItem(value: c, child: Text(c)),
              ],
              onChanged: widget.existing == null
                  ? (v) => setState(() => _category = v ?? 'dining')
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _limit,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              decoration: const InputDecoration(
                labelText: 'Monthly limit',
                border: OutlineInputBorder(),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Required';
                final parsed = double.tryParse(v);
                if (parsed == null || parsed <= 0) return 'Invalid';
                return null;
              },
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _busy ? null : _save,
              child: _busy
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
