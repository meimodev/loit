import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'home_currency_provider.dart';
import 'transactions_provider.dart';

/// Total of today's expense transactions, converted into the user's
/// home currency via the per-row `fx_snapshot`.
///
/// Source: [transactionsProvider] (Supabase-backed, optimistic). Recomputes
/// whenever transactions or home currency change. Day bounds use device-local
/// time; the persistent quick-actions notification re-reads this provider on
/// the midnight alarm to roll over correctly.
final todayExpenseProvider = Provider<double>((ref) {
  final txns = ref.watch(transactionsProvider).value ?? const [];
  final currency = ref.watch(homeCurrencyProvider);
  final now = DateTime.now();
  final start = DateTime(now.year, now.month, now.day);
  final end = start.add(const Duration(days: 1));
  double sum = 0;
  for (final t in txns) {
    if (t.type != 'expense') continue;
    final created = t.createdAt.toLocal();
    if (created.isBefore(start) || !created.isBefore(end)) continue;
    sum += t.absAmountIn(currency);
  }
  return sum;
});
