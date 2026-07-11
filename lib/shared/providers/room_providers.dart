import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/services/reachability_service.dart'
    show reachabilityServiceProvider, onlineEpochProvider;
import '../../core/services/room_service.dart';
import '../widgets/connectivity_banner.dart' show offlineDebugOverrideProvider;
import 'transactions_provider.dart';

// Service singleton — injected with the online-only gate (ADR 0014): dev
// override first, then the reachability probe.
final roomServiceProvider = Provider<RoomService>((ref) => RoomService(
      null,
      () async {
        if (ref.read(offlineDebugOverrideProvider) == true) return true;
        return !(await ref.read(reachabilityServiceProvider).isReachable());
      },
    ));

// My rooms list — invalidate after create/join/leave
final myRoomsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  ref.watch(onlineEpochProvider); // auto-heal on reconnect
  return ref.watch(roomServiceProvider).listMyRooms();
});

// Active (non-archived) rooms — the correct source for any "pick a room as a
// transaction target" surface. myRoomsProvider stays unfiltered so rooms_screen
// can still render archived rooms with their badge. Mirrors activeRoomAccountsProvider.
final activeRoomsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final rooms = await ref.watch(myRoomsProvider.future);
  return rooms.where((r) => r['is_archived'] != true).toList();
});

// Single room detail
final roomDetailProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, roomId) async {
  ref.watch(onlineEpochProvider); // auto-heal on reconnect
  return ref.watch(roomServiceProvider).getRoom(roomId);
});

// Room budgets
final roomBudgetsProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>(
        (ref, roomId) async {
  ref.watch(onlineEpochProvider); // auto-heal on reconnect
  return ref.watch(roomServiceProvider).getRoomBudgets(roomId);
});

// Current-month spend grouped by (category, currency) for a room.
// Key: 'category|currency' → summed positive expense amount.
final roomBudgetSpendProvider =
    FutureProvider.family<Map<String, double>, String>((ref, roomId) async {
  final supabase = Supabase.instance.client;
  final now = DateTime.now();
  final monthStart = DateTime(now.year, now.month, 1).toUtc().toIso8601String();
  final rows = await supabase
      .from('transactions')
      .select('category, currency, amount, type')
      .eq('room_id', roomId)
      .eq('type', 'expense')
      .gte('created_at', monthStart);
  final out = <String, double>{};
  for (final r in (rows as List)) {
    final m = r as Map<String, dynamic>;
    final cat = m['category'] as String?;
    final cur = m['currency'] as String?;
    final amt = (m['amount'] as num?)?.toDouble() ?? 0;
    if (cat == null || cur == null) continue;
    final key = '$cat|$cur';
    out[key] = (out[key] ?? 0) + amt.abs();
  }
  return out;
});

class RoomBudgetKey {
  const RoomBudgetKey({required this.roomId, required this.budgetId});
  final String roomId;
  final String budgetId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RoomBudgetKey &&
          other.roomId == roomId &&
          other.budgetId == budgetId;

  @override
  int get hashCode => Object.hash(roomId, budgetId);
}

final roomBudgetProvider =
    FutureProvider.family<Map<String, dynamic>?, RoomBudgetKey>(
        (ref, key) async {
  return ref
      .watch(roomServiceProvider)
      .getRoomBudget(roomId: key.roomId, budgetId: key.budgetId);
});

// Transactions across every room the current user is a member of. RLS limits
// visibility to rooms the user belongs to. Used by the global search screen
// so other members' room transactions also show up alongside personal rows.
final myRoomsTransactionsProvider =
    FutureProvider<List<Txn>>((ref) async {
  final rooms = await ref.watch(myRoomsProvider.future);
  final roomIds = <String>[
    for (final r in rooms)
      if (r['id'] is String) r['id'] as String,
  ];
  if (roomIds.isEmpty) return const [];
  final rows = await Supabase.instance.client
      .from('transactions')
      .select(
          '*, rooms(id, name), transaction_items(name, qty, unit_price, total_price)')
      .inFilter('room_id', roomIds)
      .order('created_at', ascending: false)
      .limit(500);
  return (rows as List)
      .map((r) => Txn.fromRow(r as Map<String, dynamic>))
      .toList();
});

// Real-time room feed (transactions in a room)
final roomFeedProvider = FutureProvider.family<List<Map<String, dynamic>>, String>(
    (ref, roomId) async {
  ref.watch(onlineEpochProvider); // auto-heal on reconnect
  final supabase = Supabase.instance.client;

  final initial = await supabase
      .from('transactions')
      .select(
          '*, users:room_member_profile(name, email, avatar_url), transaction_items(name, qty, unit_price, total_price)')
      .eq('room_id', roomId)
      .order('created_at', ascending: false)
      .limit(50);

  // Subscribe to realtime
  final channel = supabase
      .channel('room:$roomId')
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'transactions',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'room_id',
          value: roomId,
        ),
        callback: (_) {
          // On any change, invalidate to re-fetch with joined user data
          ref.invalidateSelf();
        },
      )
      .subscribe();

  ref.onDispose(() => channel.unsubscribe());

  return List<Map<String, dynamic>>.from(initial);
});

// Single transaction inside a room (for room tx detail fallback when no
// route extra is provided). Keys by `(roomId, txId)`.
class RoomTxKey {
  const RoomTxKey({required this.roomId, required this.txId});
  final String roomId;
  final String txId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RoomTxKey && other.roomId == roomId && other.txId == txId;

  @override
  int get hashCode => Object.hash(roomId, txId);
}

final roomTransactionProvider =
    FutureProvider.family<Txn?, RoomTxKey>((ref, key) async {
  final supabase = Supabase.instance.client;
  final row = await supabase
      .from('transactions')
      .select(
          '*, users:room_member_profile(name, email, avatar_url), transaction_items(name, qty, unit_price, total_price)')
      .eq('room_id', key.roomId)
      .eq('id', key.txId)
      .maybeSingle();
  if (row == null) return null;
  return Txn.fromRow(row);
});

// Pending room-tx deletes (txId set) — feed filters these out so the
// row disappears immediately on swipe; a timer commits the actual
// Supabase delete after the snackbar window unless the user undoes.
class PendingRoomTxDeletes extends Notifier<Set<String>> {
  final Map<String, Timer> _timers = {};

  @override
  Set<String> build() {
    ref.onDispose(() {
      for (final t in _timers.values) {
        t.cancel();
      }
      _timers.clear();
    });
    return const {};
  }

  void schedule({
    required String txId,
    required String roomId,
    Duration delay = const Duration(seconds: 5),
  }) {
    _timers[txId]?.cancel();
    state = {...state, txId};
    _timers[txId] = Timer(delay, () async {
      _timers.remove(txId);
      if (!state.contains(txId)) return;
      try {
        await Supabase.instance.client
            .from('transactions')
            .delete()
            .eq('id', txId);
      } finally {
        state = {...state}..remove(txId);
        ref.invalidate(roomFeedProvider(roomId));
        ref.invalidate(transactionsProvider);
      }
    });
  }

  void undo(String txId) {
    _timers[txId]?.cancel();
    _timers.remove(txId);
    if (!state.contains(txId)) return;
    state = {...state}..remove(txId);
  }
}

final pendingRoomTxDeletesProvider =
    NotifierProvider<PendingRoomTxDeletes, Set<String>>(
  PendingRoomTxDeletes.new,
);

// Room member count — derived from detail
final roomMemberCountProvider =
    Provider.family<int, String>((ref, roomId) {
  final detail = ref.watch(roomDetailProvider(roomId));
  return detail.maybeWhen(
    data: (room) {
      final members = room['room_members'];
      if (members is List) return members.length;
      return 0;
    },
    orElse: () => 0,
  );
});
