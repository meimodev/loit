import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/categories.dart';
import '../../shared/providers/auth_providers.dart';
import '../paywall/feature_gate.dart';

class RecurringBill {
  final String id;
  final String? merchant;
  final double amount;
  final String currency;
  final String? category;
  final String frequency;
  final DateTime nextDueDate;
  final bool isActive;

  RecurringBill({
    required this.id,
    required this.merchant,
    required this.amount,
    required this.currency,
    required this.category,
    required this.frequency,
    required this.nextDueDate,
    required this.isActive,
  });

  factory RecurringBill.fromRow(Map<String, dynamic> r) => RecurringBill(
        id: r['id'] as String,
        merchant: r['merchant'] as String?,
        amount: (r['amount'] as num).toDouble(),
        currency: r['currency'] as String,
        category: r['category'] as String?,
        frequency: r['frequency'] as String,
        nextDueDate: DateTime.parse(r['next_due_date'] as String),
        isActive: r['is_active'] as bool? ?? true,
      );
}

final recurringBillsProvider =
    FutureProvider<List<RecurringBill>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  final rows = await Supabase.instance.client
      .from('recurring_bills')
      .select()
      .eq('user_id', user.id)
      .order('next_due_date');
  return (rows as List)
      .map((r) => RecurringBill.fromRow(r as Map<String, dynamic>))
      .toList();
});

class RecurringBillsScreen extends ConsumerWidget {
  const RecurringBillsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tier = ref.watch(userProfileProvider).value?.tier ?? 'free';
    final flags = FeatureFlags.forTier(tier);
    if (!flags.recurringBills) {
      return Scaffold(
        appBar: AppBar(title: const Text('Recurring bills')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_outline, size: 48),
                const SizedBox(height: 12),
                const Text('Recurring bills is a Pro feature.'),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () =>
                      context.push('/paywall', extra: 'recurring_bills'),
                  child: const Text('Upgrade'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final bills = ref.watch(recurringBillsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Recurring bills')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(context, ref, null),
        icon: const Icon(Icons.add),
        label: const Text('Add'),
      ),
      body: bills.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (items) {
          if (items.isEmpty) {
            return const Center(child: Text('No recurring bills yet.'));
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(recurringBillsProvider),
            child: ListView.builder(
              itemCount: items.length,
              itemBuilder: (_, i) {
                final b = items[i];
                final amt =
                    NumberFormat.simpleCurrency(name: b.currency).format(b.amount);
                return ListTile(
                  leading: CircleAvatar(
                    child: Icon(Categories.iconFor(b.category)),
                  ),
                  title: Text(b.merchant ?? b.category ?? 'Bill'),
                  subtitle: Text(
                    '${b.frequency} · next ${DateFormat.yMMMd().format(b.nextDueDate)}',
                  ),
                  trailing: Text(amt,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  onTap: () => _openEditor(context, ref, b),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Future<void> _openEditor(
      BuildContext context, WidgetRef ref, RecurringBill? bill) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _BillEditor(bill: bill),
    );
    ref.invalidate(recurringBillsProvider);
  }
}

class _BillEditor extends ConsumerStatefulWidget {
  const _BillEditor({this.bill});
  final RecurringBill? bill;

  @override
  ConsumerState<_BillEditor> createState() => _BillEditorState();
}

class _BillEditorState extends ConsumerState<_BillEditor> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _merchant;
  late final TextEditingController _amount;
  late String _currency;
  late String _category;
  late String _frequency;
  late DateTime _nextDue;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final b = widget.bill;
    _merchant = TextEditingController(text: b?.merchant ?? '');
    _amount = TextEditingController(text: b?.amount.toString() ?? '');
    _currency = b?.currency ?? 'IDR';
    _category = b?.category ?? 'other';
    _frequency = b?.frequency ?? 'monthly';
    _nextDue = b?.nextDueDate ?? DateTime.now().add(const Duration(days: 1));
  }

  @override
  void dispose() {
    _merchant.dispose();
    _amount.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      final user = ref.read(currentUserProvider);
      if (user == null) return;
      final payload = {
        'user_id': user.id,
        'merchant': _merchant.text.trim().isEmpty ? null : _merchant.text.trim(),
        'amount': double.parse(_amount.text.trim()),
        'currency': _currency,
        'category': _category,
        'frequency': _frequency,
        'next_due_date': _nextDue.toIso8601String().substring(0, 10),
        'is_active': true,
      };
      final supa = Supabase.instance.client;
      if (widget.bill == null) {
        await supa.from('recurring_bills').insert(payload);
      } else {
        await supa.from('recurring_bills').update(payload).eq('id', widget.bill!.id);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Save failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete() async {
    if (widget.bill == null) return;
    setState(() => _busy = true);
    try {
      await Supabase.instance.client
          .from('recurring_bills')
          .delete()
          .eq('id', widget.bill!.id);
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(widget.bill == null ? 'New recurring bill' : 'Edit bill',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              TextFormField(
                controller: _merchant,
                decoration: const InputDecoration(
                  labelText: 'Merchant',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _amount,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Amount',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Required';
                        final p = double.tryParse(v);
                        if (p == null || p <= 0) return 'Invalid';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _currency,
                      decoration: const InputDecoration(
                        labelText: 'Currency',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        for (final c in kCommonCurrencies)
                          DropdownMenuItem(value: c, child: Text(c)),
                      ],
                      onChanged: (v) => setState(() => _currency = v ?? 'IDR'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
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
                onChanged: (v) => setState(() => _category = v ?? 'other'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _frequency,
                decoration: const InputDecoration(
                  labelText: 'Frequency',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                  DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
                  DropdownMenuItem(value: 'yearly', child: Text('Yearly')),
                ],
                onChanged: (v) => setState(() => _frequency = v ?? 'monthly'),
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Next due date'),
                subtitle: Text(DateFormat.yMMMd().format(_nextDue)),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _nextDue,
                    firstDate: DateTime.now().subtract(const Duration(days: 1)),
                    lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                  );
                  if (picked != null) setState(() => _nextDue = picked);
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  if (widget.bill != null) ...[
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _busy ? null : _delete,
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Delete'),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: FilledButton(
                      onPressed: _busy ? null : _save,
                      child: _busy
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Save'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
