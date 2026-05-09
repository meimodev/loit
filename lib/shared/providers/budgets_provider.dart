import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/services/log_service.dart';
import '../widgets/connectivity_banner.dart';
import 'auth_providers.dart';
import 'transactions_provider.dart';

enum BudgetPeriod { weekly, monthly, yearly, custom }

/// Pure-data variant of [Budget.windowStart] callable without a [Budget]
/// instance — used by aggregation providers that read raw rows from
/// `room_budgets` / `budgets`.
DateTime budgetWindowStart({
  required BudgetPeriod period,
  required int resetDay,
  int? customDays,
  required DateTime now,
}) {
  switch (period) {
    case BudgetPeriod.weekly:
      final diff = (now.weekday - resetDay) % 7;
      return DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: diff));
    case BudgetPeriod.monthly:
      if (resetDay == 0) {
        final prevMonthLast = DateTime(now.year, now.month, 0);
        final thisMonthLast = DateTime(now.year, now.month + 1, 0);
        return now.day < thisMonthLast.day ? prevMonthLast : thisMonthLast;
      }
      final anchorThis = DateTime(now.year, now.month, resetDay);
      return now.isBefore(anchorThis)
          ? DateTime(now.year, now.month - 1, resetDay)
          : anchorThis;
    case BudgetPeriod.yearly:
      final anchorThis = DateTime(now.year, resetDay, 1);
      return now.isBefore(anchorThis)
          ? DateTime(now.year - 1, resetDay, 1)
          : anchorThis;
    case BudgetPeriod.custom:
      final n = customDays ?? 30;
      return DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: n));
  }
}

extension BudgetPeriodX on BudgetPeriod {
  String get wire => switch (this) {
        BudgetPeriod.weekly => 'weekly',
        BudgetPeriod.monthly => 'monthly',
        BudgetPeriod.yearly => 'yearly',
        BudgetPeriod.custom => 'custom',
      };

  String get label => switch (this) {
        BudgetPeriod.weekly => 'Weekly',
        BudgetPeriod.monthly => 'Monthly',
        BudgetPeriod.yearly => 'Yearly',
        BudgetPeriod.custom => 'Custom',
      };

  static BudgetPeriod fromWire(String? s) => switch (s) {
        'weekly' => BudgetPeriod.weekly,
        'yearly' => BudgetPeriod.yearly,
        'custom' => BudgetPeriod.custom,
        _ => BudgetPeriod.monthly,
      };
}

class Budget {
  final String id;
  final String category;
  final double monthlyLimit;
  final BudgetPeriod period;
  final int resetDay;
  final int? customDays;

  const Budget({
    required this.id,
    required this.category,
    required this.monthlyLimit,
    this.period = BudgetPeriod.monthly,
    this.resetDay = 1,
    this.customDays,
  });

  factory Budget.fromRow(Map<String, dynamic> r) => Budget(
        id: r['id'] as String,
        category: r['category'] as String,
        monthlyLimit: ((r['monthly_limit'] as num?) ?? 0).toDouble(),
        period: BudgetPeriodX.fromWire(r['period'] as String?),
        resetDay: ((r['reset_day'] as num?) ?? 1).toInt(),
        customDays: (r['custom_days'] as num?)?.toInt(),
      );

  /// Start of the current cycle window for this budget, given [now].
  DateTime windowStart(DateTime now) => budgetWindowStart(
        period: period,
        resetDay: resetDay,
        customDays: customDays,
        now: now,
      );

  /// Length of current cycle in days (for "Day X / N" UI).
  int cycleDays(DateTime now) {
    switch (period) {
      case BudgetPeriod.weekly:
        return 7;
      case BudgetPeriod.monthly:
        final start = windowStart(now);
        final next = DateTime(start.year, start.month + 1, start.day);
        return next.difference(start).inDays;
      case BudgetPeriod.yearly:
        return DateTime(now.year + 1, 1, 1)
            .difference(DateTime(now.year, 1, 1))
            .inDays;
      case BudgetPeriod.custom:
        return customDays ?? 30;
    }
  }
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
    BudgetPeriod period = BudgetPeriod.monthly,
    int resetDay = 1,
    int? customDays,
    String? id,
  }) async {
    final user = ref.read(currentUserProvider);
    if (user == null) throw StateError('Not signed in');
    final payload = {
      'user_id': user.id,
      'category': category,
      'monthly_limit': monthlyLimit,
      'period': period.wire,
      'reset_day': resetDay,
      'custom_days': period == BudgetPeriod.custom ? customDays : null,
      if (id != null) 'id': id,
    };
    if (ref.read(offlineDebugOverrideProvider) == true) {
      ref.invalidateSelf();
      return;
    }
    final result = await Supabase.instance.client
        .from('budgets')
        .upsert(payload, onConflict: 'user_id,category')
        .select();
    Log.i('BudgetsNotifier',
        'Upserted budget "$category", returned ${result.length} row(s)');
    ref.invalidateSelf();
  }

  Future<void> delete(String id) async {
    if (ref.read(offlineDebugOverrideProvider) == true) {
      ref.invalidateSelf();
      return;
    }
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
  return budgets.map((b) {
    final start = b.windowStart(now);
    final spent = txns
        .where((t) =>
            !t.isTransfer &&
            !t.isIncome &&
            (t.category ?? '') == b.category &&
            !t.createdAt.isBefore(start))
        .fold<double>(0, (sum, t) => sum + (t.amountHome ?? t.amount).abs());
    return BudgetStatus(budget: b, spent: spent);
  }).toList();
});
