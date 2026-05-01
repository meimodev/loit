import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_providers.dart';
import 'transactions_provider.dart';

class Budget {
  final String id;
  final String category;
  final double monthlyLimit;

  const Budget({
    required this.id,
    required this.category,
    required this.monthlyLimit,
  });

  factory Budget.fromRow(Map<String, dynamic> r) => Budget(
        id: r['id'] as String,
        category: r['category'] as String,
        monthlyLimit: ((r['monthly_limit'] as num?) ?? 0).toDouble(),
      );
}

class BudgetStatus {
  final Budget budget;
  final double spent;
  double get ratio => budget.monthlyLimit <= 0 ? 0 : spent / budget.monthlyLimit;
  bool get isOver => ratio >= 1.0;
  bool get isNearLimit => ratio >= 0.8 && !isOver;
  const BudgetStatus({required this.budget, required this.spent});
}

class BudgetsNotifier extends AsyncNotifier<List<Budget>> {
  @override
  Future<List<Budget>> build() async {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const [];
    final rows = await Supabase.instance.client
        .from('budgets')
        .select()
        .eq('user_id', user.id)
        .order('created_at', ascending: true);
    return (rows as List)
        .map((r) => Budget.fromRow(r as Map<String, dynamic>))
        .toList();
  }

  Future<void> upsert({
    required String category,
    required double monthlyLimit,
    String? id,
  }) async {
    final user = ref.read(currentUserProvider);
    if (user == null) throw StateError('Not signed in');
    final payload = {
      'user_id': user.id,
      'category': category,
      'monthly_limit': monthlyLimit,
      if (id != null) 'id': id,
    };
    await Supabase.instance.client
        .from('budgets')
        .upsert(payload, onConflict: 'user_id,category');
    ref.invalidateSelf();
  }

  Future<void> delete(String id) async {
    await Supabase.instance.client.from('budgets').delete().eq('id', id);
    ref.invalidateSelf();
  }
}

final budgetsProvider =
    AsyncNotifierProvider<BudgetsNotifier, List<Budget>>(BudgetsNotifier.new);

/// Computes spend-per-category for the current month from the transactions list.
final budgetStatusesProvider = Provider<List<BudgetStatus>>((ref) {
  final budgets = ref.watch(budgetsProvider).value ?? const [];
  final txns = ref.watch(transactionsProvider).value ?? const [];
  final now = DateTime.now();
  final monthStart = DateTime(now.year, now.month, 1);
  return budgets.map((b) {
    final spent = txns
        .where((t) =>
            (t.category ?? '') == b.category &&
            t.amount > 0 &&
            t.createdAt.isAfter(monthStart))
        .fold<double>(0, (sum, t) => sum + (t.amountHome ?? t.amount));
    return BudgetStatus(budget: b, spent: spent);
  }).toList();
});
