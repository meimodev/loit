import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/config/categories.dart';
import '../../shared/providers/room_providers.dart';

class RoomBudgetsScreen extends ConsumerWidget {
  const RoomBudgetsScreen({super.key, required this.roomId});
  final String roomId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgets = ref.watch(roomBudgetsProvider(roomId));
    final room = ref.watch(roomDetailProvider(roomId));
    final currency =
        room.when(
          data: (r) => r['base_currency'] as String? ?? 'IDR',
          loading: () => 'IDR',
          error: (_, __) => 'IDR',
        );

    return Scaffold(
      appBar: AppBar(title: const Text('Room Budgets')),
      body: budgets.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (list) => list.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.savings_outlined,
                        size: 64, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    Text('No budgets set',
                        style: Theme.of(context).textTheme.titleMedium),
                  ],
                ),
              )
            : ListView.builder(
                itemCount: list.length,
                itemBuilder: (_, i) {
                  final b = list[i];
                  final fmt = NumberFormat.simpleCurrency(
                    name: b['currency'] as String? ?? currency,
                  );
                  return ListTile(
                    leading: CircleAvatar(
                      child: Icon(
                          Categories.iconFor(b['category'] as String?)),
                    ),
                    title: Text(b['category'] as String? ?? 'Budget'),
                    trailing: Text(
                      fmt.format(
                          (b['budget_limit'] as num?)?.toDouble() ?? 0),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () =>
            _showAddBudget(context, ref, roomId, currency),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddBudget(
    BuildContext context,
    WidgetRef ref,
    String roomId,
    String currency,
  ) {
    String category = 'dining';
    final amountCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Add Budget'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: category,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
                items: [
                  for (final c in Categories.all)
                    DropdownMenuItem(value: c, child: Text(c)),
                ],
                onChanged: (v) =>
                    setDialogState(() => category = v ?? 'dining'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amountCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
                decoration: InputDecoration(
                  labelText: 'Budget limit ($currency)',
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final amount = double.tryParse(amountCtrl.text.trim());
                if (amount == null || amount <= 0) return;
                await ref.read(roomServiceProvider).upsertRoomBudget(
                      roomId: roomId,
                      category: category,
                      budgetLimit: amount,
                      currency: currency,
                    );
                ref.invalidate(roomBudgetsProvider(roomId));
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
