import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/services/currency_service.dart';
import 'auth_providers.dart';
import 'services_providers.dart';

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

  /// True when at least one underlying FX rate was served from a stale cache
  /// (rate provider unreachable). Surface a "≈ stale" hint in the UI.
  final bool isStale;

  double get net => income - expense;
}

/// Sums all room transactions converted into `rooms.base_currency`.
///
/// Read-time conversion: each txn keeps its original `currency`, and the
/// rate is looked up via `currencyServiceProvider`. Avoids backfilling
/// historical rows when a member posts in a non-room currency.
final roomTotalsProvider =
    FutureProvider.family<RoomTotals, String>((ref, roomId) async {
  final supabase = Supabase.instance.client;
  final fx = ref.watch(currencyServiceProvider);
  final tierStr = ref.watch(userProfileProvider).value?.tier ?? 'free';
  final tier = UserTier.fromString(tierStr);

  final room = await supabase
      .from('rooms')
      .select('base_currency')
      .eq('id', roomId)
      .single();
  final base = (room['base_currency'] as String?) ?? 'IDR';

  final rows = await supabase
      .from('transactions')
      .select('amount, currency, type')
      .eq('room_id', roomId);

  final pairs = <(String, String)>{};
  for (final m in rows) {
    final cur = (m['currency'] as String?) ?? base;
    if (cur != base) pairs.add((cur, base));
  }

  final rates = await fx.getRates(pairs: pairs, tier: tier);

  var income = 0.0;
  var expense = 0.0;
  var anyStale = false;

  for (final m in rows) {
    final type = m['type'] as String?;
    if (type == 'transfer') continue;
    final cur = (m['currency'] as String?) ?? base;
    final amt = ((m['amount'] as num?) ?? 0).toDouble().abs();
    double converted;
    if (cur == base) {
      converted = amt;
    } else {
      final fxRate = rates['$cur→$base'];
      if (fxRate == null) {
        anyStale = true;
        continue;
      }
      converted = amt * fxRate.rate;
      if (fxRate.isStale) anyStale = true;
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

/// FX rates for every distinct non-base currency observed in a room's
/// transactions, keyed by source currency code (e.g. `'USD'`). Use this
/// when iterating txns synchronously and applying conversion in-place
/// (e.g. live filtering with pending-delete state).
class RoomFxRates {
  const RoomFxRates({
    required this.baseCurrency,
    required this.rates,
    required this.isStale,
  });
  final String baseCurrency;
  final Map<String, double> rates;
  final bool isStale;

  /// Convert [amount] from [from] into the room's base currency.
  /// Returns null when the rate is missing — caller decides UX.
  double? convert(double amount, String from) {
    if (from == baseCurrency) return amount;
    final r = rates[from];
    if (r == null) return null;
    return amount * r;
  }
}

final roomFxRatesProvider =
    FutureProvider.family<RoomFxRates, String>((ref, roomId) async {
  final supabase = Supabase.instance.client;
  final fx = ref.watch(currencyServiceProvider);
  final tierStr = ref.watch(userProfileProvider).value?.tier ?? 'free';
  final tier = UserTier.fromString(tierStr);

  final room = await supabase
      .from('rooms')
      .select('base_currency')
      .eq('id', roomId)
      .single();
  final base = (room['base_currency'] as String?) ?? 'IDR';

  final rows = await supabase
      .from('transactions')
      .select('currency')
      .eq('room_id', roomId);

  final foreign = <String>{
    for (final m in rows) (m['currency'] as String?) ?? base,
  }..remove(base);

  final pairs = {for (final c in foreign) (c, base)};
  final fetched = await fx.getRates(pairs: pairs, tier: tier);

  final rates = <String, double>{};
  var anyStale = false;
  for (final c in foreign) {
    final f = fetched['$c→$base'];
    if (f == null) {
      anyStale = true;
      continue;
    }
    rates[c] = f.rate;
    if (f.isStale) anyStale = true;
  }

  return RoomFxRates(
    baseCurrency: base,
    rates: rates,
    isStale: anyStale,
  );
});

/// Per-budget spend for the current month, converted into each budget's
/// own `currency`. Replaces the raw same-currency-only roomBudgetSpendProvider
/// for screens that need correct totals across mixed-currency members.
///
/// Map key: `'$category|$budgetCurrency'` → spend in `budgetCurrency`.
final roomBudgetSpendConvertedProvider = FutureProvider.family<
    ({Map<String, double> spend, bool isStale}), String>((ref, roomId) async {
  final supabase = Supabase.instance.client;
  final fx = ref.watch(currencyServiceProvider);
  final tierStr = ref.watch(userProfileProvider).value?.tier ?? 'free';
  final tier = UserTier.fromString(tierStr);

  final budgets = await supabase
      .from('room_budgets')
      .select('category, currency')
      .eq('room_id', roomId);

  final budgetCurrencies = <String, Set<String>>{};
  for (final m in budgets) {
    final cat = m['category'] as String?;
    final cur = m['currency'] as String?;
    if (cat == null || cur == null) continue;
    budgetCurrencies.putIfAbsent(cat, () => <String>{}).add(cur);
  }

  final now = DateTime.now();
  final monthStart = DateTime(now.year, now.month, 1).toUtc().toIso8601String();

  final rows = await supabase
      .from('transactions')
      .select('category, currency, amount, type')
      .eq('room_id', roomId)
      .eq('type', 'expense')
      .gte('created_at', monthStart);

  final pairs = <(String, String)>{};
  for (final m in rows) {
    final cat = m['category'] as String?;
    final cur = m['currency'] as String?;
    if (cat == null || cur == null) continue;
    final targets = budgetCurrencies[cat];
    if (targets == null) continue;
    for (final target in targets) {
      if (cur != target) pairs.add((cur, target));
    }
  }

  final rates = await fx.getRates(pairs: pairs, tier: tier);

  final out = <String, double>{};
  var anyStale = false;

  for (final m in rows) {
    final cat = m['category'] as String?;
    final cur = m['currency'] as String?;
    if (cat == null || cur == null) continue;
    final amt = ((m['amount'] as num?) ?? 0).toDouble().abs();
    final targets = budgetCurrencies[cat] ?? const <String>{};
    for (final target in targets) {
      double converted;
      if (cur == target) {
        converted = amt;
      } else {
        final fxRate = rates['$cur→$target'];
        if (fxRate == null) {
          anyStale = true;
          continue;
        }
        converted = amt * fxRate.rate;
        if (fxRate.isStale) anyStale = true;
      }
      final key = '$cat|$target';
      out[key] = (out[key] ?? 0) + converted;
    }
  }

  return (spend: out, isStale: anyStale);
});

