import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/services/currency_service.dart';
import '../../core/services/log_service.dart';
import '../widgets/connectivity_banner.dart';
import 'accounts_provider.dart';
import 'auth_providers.dart';
import 'home_currency_provider.dart';
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
  final String currency;
  final BudgetPeriod period;
  final int resetDay;
  final int? customDays;
  final double rolloverAmount;
  final DateTime? rolloverCycleStart;

  const Budget({
    required this.id,
    required this.category,
    required this.monthlyLimit,
    required this.currency,
    this.period = BudgetPeriod.monthly,
    this.resetDay = 1,
    this.customDays,
    this.rolloverAmount = 0,
    this.rolloverCycleStart,
  });

  factory Budget.fromRow(Map<String, dynamic> r) => Budget(
        id: r['id'] as String,
        category: r['category'] as String,
        monthlyLimit: ((r['monthly_limit'] as num?) ?? 0).toDouble(),
        currency: (r['currency'] as String?) ?? 'IDR',
        period: BudgetPeriodX.fromWire(r['period'] as String?),
        resetDay: ((r['reset_day'] as num?) ?? 1).toInt(),
        customDays: (r['custom_days'] as num?)?.toInt(),
        rolloverAmount:
            ((r['rollover_amount'] as num?) ?? 0).toDouble(),
        rolloverCycleStart: r['rollover_cycle_start'] == null
            ? null
            : DateTime.parse(r['rollover_cycle_start'] as String).toLocal(),
      );

  /// Start of the next cycle after [from].
  DateTime nextWindowStart(DateTime from) {
    final current = windowStart(from);
    switch (period) {
      case BudgetPeriod.weekly:
        return current.add(const Duration(days: 7));
      case BudgetPeriod.monthly:
        return DateTime(current.year, current.month + 1, current.day);
      case BudgetPeriod.yearly:
        return DateTime(current.year + 1, current.month, current.day);
      case BudgetPeriod.custom:
        return current.add(Duration(days: customDays ?? 30));
    }
  }

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
  final double effectiveLimit;
  /// `budget.monthlyLimit` converted into the user's current home currency
  /// via live FX. Display sites should prefer this over `budget.monthlyLimit`,
  /// which is in the budget's stored `currency`.
  final double monthlyLimit;
  /// `budget.rolloverAmount` converted into the user's current home currency.
  final double rolloverAmount;
  double get ratio => effectiveLimit <= 0 ? 0 : spent / effectiveLimit;
  bool get isOver => ratio >= 1.0;
  bool get isNearLimit => ratio >= 0.8 && !isOver;
  bool get rolloverActive => effectiveLimit < monthlyLimit;
  const BudgetStatus({
    required this.budget,
    required this.spent,
    required this.effectiveLimit,
    required this.monthlyLimit,
    required this.rolloverAmount,
  });
}

class BudgetsNotifier extends AsyncNotifier<List<Budget>> {
  final Set<String> _restampInflight = <String>{};

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
    required String currency,
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
      'currency': currency,
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

  /// Stamp a one-shot rollover penalty equal to [overspend] on the
  /// budget's *next* cycle window. The penalty is consumed exactly once
  /// when that window becomes active.
  Future<void> rollOver({
    required String budgetId,
    required double overspend,
    required DateTime nextCycleStart,
  }) async {
    if (overspend <= 0) return;
    if (ref.read(offlineDebugOverrideProvider) == true) {
      ref.invalidateSelf();
      return;
    }
    await Supabase.instance.client.from('budgets').update({
      'rollover_amount': overspend,
      'rollover_cycle_start': nextCycleStart.toUtc().toIso8601String(),
    }).eq('id', budgetId);
    Log.i('BudgetsNotifier',
        'Rolled over $overspend onto cycle starting $nextCycleStart for $budgetId');
    ref.invalidateSelf();
  }

  /// Auto-restamp the pending rollover when current-cycle overspend has
  /// grown beyond the previously stamped amount. [currentOverspendHome] is
  /// in the user's home currency; it is converted back to the budget's
  /// stored currency before persisting. No-op if not stamped, not larger,
  /// or a write is already in flight for this id.
  void maybeRestampRollover({
    required Budget budget,
    required double currentOverspendHome,
    required String homeCurrency,
    required Map<String, double>? rates,
  }) {
    if (budget.rolloverCycleStart == null) return;
    final overspendBudgetCcy = toBudgetCurrency(
      amountHome: currentOverspendHome,
      budgetCurrency: budget.currency,
      home: homeCurrency,
      rates: rates,
    );
    if (overspendBudgetCcy <= budget.rolloverAmount + 0.01) return;
    if (_restampInflight.contains(budget.id)) return;
    _restampInflight.add(budget.id);
    Future<void>.microtask(() async {
      try {
        await rollOver(
          budgetId: budget.id,
          overspend: overspendBudgetCcy,
          nextCycleStart: budget.rolloverCycleStart!,
        );
      } finally {
        _restampInflight.remove(budget.id);
      }
    });
  }

  static double toBudgetCurrency({
    required double amountHome,
    required String budgetCurrency,
    required String home,
    required Map<String, double>? rates,
  }) {
    if (budgetCurrency == home || amountHome == 0) return amountHome;
    if (rates == null) return amountHome;
    try {
      return amountHome *
          CurrencyService.convert(from: home, to: budgetCurrency, rates: rates);
    } catch (_) {
      return amountHome;
    }
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

/// Computes spend-per-category for the current period in the user's
/// home currency. Each contributing transaction is converted via its
/// `fx_snapshot`. Budget limits stored in their own `currency` are
/// converted on-the-fly to home currency via live FX rates.
final budgetStatusesProvider = Provider<List<BudgetStatus>>((ref) {
  final budgets = ref.watch(budgetsProvider).value ?? const [];
  final txns = ref.watch(transactionsProvider).value ?? const [];
  final home = ref.watch(homeCurrencyProvider);
  final rates = ref.watch(usdBaseRatesProvider).value;
  final now = DateTime.now();
  final notifier = ref.read(budgetsProvider.notifier);

  double toHome(String from, double amt) {
    if (from == home || amt == 0) return amt;
    if (rates == null) return amt;
    try {
      return amt * CurrencyService.convert(from: from, to: home, rates: rates);
    } catch (_) {
      return amt;
    }
  }

  final result = budgets.map((b) {
    final start = b.windowStart(now);
    final spent = txns
        .where((t) =>
            !t.isTransfer &&
            !t.isIncome &&
            (t.category ?? '') == b.category &&
            !t.createdAt.isBefore(start))
        .fold<double>(0, (sum, t) => sum + t.absAmountIn(home));
    final limitHome = toHome(b.currency, b.monthlyLimit);
    final rolloverHome = toHome(b.currency, b.rolloverAmount);
    final r = b.rolloverCycleStart;
    final sameDay = r != null &&
        r.year == start.year &&
        r.month == start.month &&
        r.day == start.day;
    final effective = (sameDay && rolloverHome != 0)
        ? (limitHome - rolloverHome).clamp(0, double.infinity).toDouble()
        : limitHome;
    return BudgetStatus(
      budget: b,
      spent: spent,
      effectiveLimit: effective,
      monthlyLimit: limitHome,
      rolloverAmount: rolloverHome,
    );
  }).toList();
  for (final s in result) {
    final overspend = s.spent - s.monthlyLimit;
    if (overspend > 0) {
      notifier.maybeRestampRollover(
        budget: s.budget,
        currentOverspendHome: overspend,
        homeCurrency: home,
        rates: rates,
      );
    }
  }
  return result;
});
