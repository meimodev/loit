import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'budgets_provider.dart';
import 'room_accounts_provider.dart';
import 'room_providers.dart';
import 'transactions_provider.dart';

/// Refreshes every room-scoped aggregate after a transaction is written inside
/// a room (add / edit / delete / account-leg change). Call from the write site
/// before navigating away. `roomAccountBalancesProvider` and
/// `roomNetWorthProvider` watch `roomTransactionsProvider` via `.future`, so
/// they rebuild automatically off the invalidation below — no need to list them.
void invalidateRoomData(WidgetRef ref, String roomId) {
  ref.invalidate(roomFeedProvider(roomId));
  ref.invalidate(roomTransactionsProvider(roomId));
  ref.invalidate(roomTotalsProvider(roomId));
  ref.invalidate(roomBudgetSpendConvertedProvider(roomId));
}

/// Aggregated totals for a room, normalized into the room's `base_currency`.
class RoomTotals {
  const RoomTotals({
    required this.income,
    required this.expense,
    required this.currency,
    required this.isStale,
  });

  final double income;
  final double expense;
  final String currency;

  /// True only when a txn is missing a usable snapshot rate for the room's
  /// base currency (legacy data). New rows always carry full snapshots.
  final bool isStale;

  double get net => income - expense;
}

double? _rateFromSnapshot(dynamic raw, String target) {
  if (raw is! Map) return null;
  final v = raw[target];
  if (v is num) return v.toDouble();
  return null;
}

/// Sums all room transactions converted into `rooms.base_currency` using each
/// txn's frozen `fx_snapshot`. Pure local math — no FX network calls.
final roomTotalsProvider =
    FutureProvider.family<RoomTotals, String>((ref, roomId) async {
  final supabase = Supabase.instance.client;

  final room = await supabase
      .from('rooms')
      .select('base_currency')
      .eq('id', roomId)
      .single();
  final base = (room['base_currency'] as String?) ?? 'IDR';

  // Pool-only totals (ADR 0013): a row whose account is not a room account is
  // an Out-of-pocket "My money" expense — the payer's spend, not the room's.
  final roomAccountIds = (await ref.watch(roomAccountsProvider(roomId).future))
      .map((a) => a.id)
      .toSet();

  final rows = await supabase
      .from('transactions')
      .select('amount, currency, type, fx_snapshot, account_id')
      .eq('room_id', roomId);

  var income = 0.0;
  var expense = 0.0;
  var anyStale = false;

  for (final m in rows) {
    final type = m['type'] as String?;
    if (type == 'transfer') continue;
    if (!roomAccountIds.contains(m['account_id'] as String?)) continue;
    final cur = (m['currency'] as String?) ?? base;
    final amt = ((m['amount'] as num?) ?? 0).toDouble().abs();
    double converted;
    if (cur == base) {
      converted = amt;
    } else {
      final rate = _rateFromSnapshot(m['fx_snapshot'], base);
      if (rate == null) {
        anyStale = true;
        continue;
      }
      converted = amt * rate;
    }
    if (type == 'income') {
      income += converted;
    } else {
      expense += converted;
    }
  }

  return RoomTotals(
    income: income,
    expense: expense,
    currency: base,
    isStale: anyStale,
  );
});

/// Per-room conversion helper used by widgets that iterate txns synchronously
/// (live filter views with pending-delete state).
class RoomFxRates {
  const RoomFxRates({
    required this.baseCurrency,
    required this.isStale,
  });
  final String baseCurrency;
  final bool isStale;

  /// Convert [amount] from a txn into the room's base currency using the
  /// txn's own snapshot. Returns null when the snapshot is missing the target
  /// (legacy row).
  double? convert(double amount, String fromCurrency, dynamic snapshot) {
    if (fromCurrency == baseCurrency) return amount;
    final r = _rateFromSnapshot(snapshot, baseCurrency);
    if (r == null) return null;
    return amount * r;
  }
}

final roomFxRatesProvider =
    FutureProvider.family<RoomFxRates, String>((ref, roomId) async {
  final supabase = Supabase.instance.client;

  final room = await supabase
      .from('rooms')
      .select('base_currency')
      .eq('id', roomId)
      .single();
  final base = (room['base_currency'] as String?) ?? 'IDR';

  return RoomFxRates(baseCurrency: base, isStale: false);
});

/// Per-budget spend for the current period window, converted into each
/// budget's own `currency` via per-txn `fx_snapshot`.
///
/// Map key: `'$category|$budgetCurrency'` → spend in `budgetCurrency`.
final roomBudgetSpendConvertedProvider = FutureProvider.family<
    ({Map<String, double> spend, bool isStale}), String>((ref, roomId) async {
  final supabase = Supabase.instance.client;

  final budgets = await supabase
      .from('room_budgets')
      .select('category, currency, period, reset_day, custom_days')
      .eq('room_id', roomId);

  final now = DateTime.now();
  final budgetCurrencies = <String, Set<String>>{};
  final windows = <String, DateTime>{};
  DateTime? earliest;
  for (final m in budgets) {
    final cat = m['category'] as String?;
    final cur = m['currency'] as String?;
    if (cat == null || cur == null) continue;
    budgetCurrencies.putIfAbsent(cat, () => <String>{}).add(cur);
    final start = budgetWindowStart(
      period: BudgetPeriodX.fromWire(m['period'] as String?),
      resetDay: ((m['reset_day'] as num?) ?? 1).toInt(),
      customDays: (m['custom_days'] as num?)?.toInt(),
      now: now,
    );
    windows[cat] = start;
    if (earliest == null || start.isBefore(earliest)) earliest = start;
  }

  final fromIso =
      (earliest ?? DateTime(now.year, now.month, 1)).toUtc().toIso8601String();

  // Pool-only spend (ADR 0013): Out-of-pocket "My money" expenses count toward
  // the payer's personal budget, never the room budget.
  final roomAccountIds = (await ref.watch(roomAccountsProvider(roomId).future))
      .map((a) => a.id)
      .toSet();

  final rows = await supabase
      .from('transactions')
      .select(
          'category, currency, amount, type, created_at, fx_snapshot, account_id')
      .eq('room_id', roomId)
      .eq('type', 'expense')
      .gte('created_at', fromIso);

  final out = <String, double>{};
  var anyStale = false;

  for (final m in rows) {
    final cat = m['category'] as String?;
    final cur = m['currency'] as String?;
    if (cat == null || cur == null) continue;
    if (!roomAccountIds.contains(m['account_id'] as String?)) continue;
    final winStart = windows[cat];
    if (winStart == null) continue;
    final createdRaw = m['created_at'];
    final createdAt = createdRaw is String
        ? DateTime.tryParse(createdRaw)?.toLocal()
        : null;
    if (createdAt == null || createdAt.isBefore(winStart)) continue;
    final amt = ((m['amount'] as num?) ?? 0).toDouble().abs();
    final targets = budgetCurrencies[cat] ?? const <String>{};
    for (final target in targets) {
      double converted;
      if (cur == target) {
        converted = amt;
      } else {
        final rate = _rateFromSnapshot(m['fx_snapshot'], target);
        if (rate == null) {
          anyStale = true;
          continue;
        }
        converted = amt * rate;
      }
      final key = '$cat|$target';
      out[key] = (out[key] ?? 0) + converted;
    }
  }

  return (spend: out, isStale: anyStale);
});
