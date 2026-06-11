import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'accounts_provider.dart';
import 'transactions_provider.dart';

/// Accounts owned by a room — the room's shared balance sheet (ADR 0007).
/// Includes archived rows so historical balance math stays complete; use
/// [activeRoomAccountsProvider] for pickers and the visible list.
final roomAccountsProvider =
    FutureProvider.family<List<Account>, String>((ref, roomId) async {
  final rows = await Supabase.instance.client
      .from('accounts')
      .select()
      .eq('room_id', roomId)
      .order('created_at', ascending: true);
  return (rows as List)
      .map((r) => Account.fromRow(r as Map<String, dynamic>))
      .toList();
});

/// Active (non-archived) room accounts.
final activeRoomAccountsProvider =
    Provider.family<List<Account>, String>((ref, roomId) {
  final accounts = ref.watch(roomAccountsProvider(roomId)).value ?? const [];
  return accounts.where((a) => a.archivedAt == null).toList();
});

/// Balance per room account, in the room's base currency.
///
/// A room is single-currency, so a movement's `account_id` leg leaves the
/// account and its `to_account_id` leg enters it. The personal leg of a
/// **Personal mirror** transfer is not a room account, so it is skipped here —
/// it only affects the logger's personal ledger. Liability convention matches
/// personal accounts: initial stored negative, income (paying down) adds.
final roomAccountBalancesProvider =
    FutureProvider.family<Map<String, double>, String>((ref, roomId) async {
  final accounts = await ref.watch(roomAccountsProvider(roomId).future);
  final txns = await ref.watch(roomTransactionsProvider(roomId).future);
  final byId = {for (final a in accounts) a.id: a};
  final map = <String, double>{for (final a in accounts) a.id: a.initialBalance};
  for (final t in txns) {
    final from = t.accountId;
    if (from != null && byId.containsKey(from)) {
      final v = t.absAmountIn(byId[from]!.currency);
      // income adds; expense and the outgoing leg of a transfer subtract.
      map[from] = map[from]! + (t.type == 'income' ? v : -v);
    }
    final to = t.toAccountId;
    if (to != null && byId.containsKey(to)) {
      map[to] = map[to]! + t.absAmountIn(byId[to]!.currency); // transfer in
    }
  }
  return map;
});

/// Room net worth (sum of all room-account balances) in base currency.
final roomNetWorthProvider =
    FutureProvider.family<double, String>((ref, roomId) async {
  final balances = await ref.watch(roomAccountBalancesProvider(roomId).future);
  var total = 0.0;
  for (final v in balances.values) {
    total += v;
  }
  return total;
});
