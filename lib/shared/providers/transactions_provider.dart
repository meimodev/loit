import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../widgets/connectivity_banner.dart';
import 'auth_providers.dart';
import 'services_providers.dart';

/// Transaction row shape used by UI. Kept as a typed view over Map.
///
/// `fxSnapshot` is a frozen map of rates from this txn's `currency` to every
/// supported currency, computed at create time. Display logic uses [amountIn]
/// to convert without hitting the network — even when the user changes home
/// currency or an account's currency.
class Txn {
  final String? id;
  final double amount;
  final String currency;
  final Map<String, double> fxSnapshot;
  final String? category;
  final String? notes;
  final String? receiptUrl;
  final bool aiParsed;
  final bool isManualFallback;
  final DateTime createdAt;
  final String? roomId;
  final String? roomName;
  final String type; // 'expense' | 'income' | 'transfer'
  final String? accountId;
  final String? toAccountId;

  const Txn({
    required this.id,
    required this.amount,
    required this.currency,
    required this.fxSnapshot,
    required this.category,
    required this.notes,
    required this.receiptUrl,
    required this.aiParsed,
    required this.isManualFallback,
    required this.createdAt,
    this.roomId,
    this.roomName,
    this.type = 'expense',
    this.accountId,
    this.toAccountId,
  });

  factory Txn.fromRow(Map<String, dynamic> r) {
    final rawType = r['type'] as String?;
    final String type;
    if (rawType != null && (rawType == 'income' || rawType == 'expense' || rawType == 'transfer')) {
      type = rawType;
    } else {
      final amt = ((r['amount'] as num?) ?? 0).toDouble();
      type = amt < 0 ? 'expense' : 'income';
    }
    final rawSnapshot = r['fx_snapshot'];
    final snapshot = <String, double>{};
    if (rawSnapshot is Map) {
      for (final entry in rawSnapshot.entries) {
        final v = entry.value;
        if (v is num) snapshot[entry.key as String] = v.toDouble();
      }
    }
    return Txn(
      id: r['id'] as String?,
      amount: ((r['amount'] as num?) ?? 0).toDouble(),
      currency: (r['currency'] as String?) ?? 'IDR',
      fxSnapshot: snapshot,
      category: r['category'] as String?,
      notes: r['notes'] as String?,
      receiptUrl: r['receipt_url'] as String?,
      aiParsed: (r['ai_parsed'] as bool?) ?? false,
      isManualFallback: (r['is_manual_fallback'] as bool?) ?? false,
      createdAt: DateTime.parse(
        (r['created_at'] as String?) ?? DateTime.now().toUtc().toIso8601String(),
      ),
      roomId: r['room_id'] as String?,
      roomName: (r['rooms'] is Map<String, dynamic>)
          ? (r['rooms'] as Map<String, dynamic>)['name'] as String?
          : null,
      type: type,
      accountId: r['account_id'] as String?,
      toAccountId: r['to_account_id'] as String?,
    );
  }

  bool get isTransfer => type == 'transfer';
  bool get isIncome => type == 'income';
  double get absAmount => amount.abs();

  /// Signed amount converted to [target] currency via the frozen snapshot.
  /// Falls back to raw [amount] if the target is missing from the snapshot
  /// (legacy rows; should not happen for txns created post-migration).
  double amountIn(String target) {
    if (target == currency) return amount;
    final rate = fxSnapshot[target];
    if (rate == null) return amount;
    return amount * rate;
  }

  double absAmountIn(String target) => amountIn(target).abs();
}

class TransactionsNotifier extends AsyncNotifier<List<Txn>> {
  @override
  Future<List<Txn>> build() async {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const [];
    final rows = await Supabase.instance.client
        .from('transactions')
        .select('*, rooms(id, name)')
        .eq('user_id', user.id)
        .order('created_at', ascending: false)
        .limit(200);
    return (rows as List)
        .map((r) => Txn.fromRow(r as Map<String, dynamic>))
        .toList();
  }

  /// Insert a new personal transaction. Writes online if possible, otherwise
  /// enqueues offline. UI state is optimistically updated.
  /// Returns the inserted transaction id when the online insert succeeds,
  /// or `null` when the row was queued offline (no id yet).
  Future<String?> addTransaction(Map<String, dynamic> payload) async {
    final user = ref.read(currentUserProvider);
    if (user == null) throw StateError('Not signed in');

    payload['user_id'] = user.id;
    payload['client_updated_at'] = DateTime.now().toUtc().toIso8601String();

    // Defensive defaults: ensure type and account_id are present so offline-queued
    // rows survive the accounts migration constraints when synced later.
    payload['type'] ??= ((payload['amount'] as num?)?.toDouble() ?? 0) < 0
        ? 'expense'
        : 'income';
    if (payload['account_id'] == null) {
      // Best-effort: look up Cash account directly to avoid circular dependency
      // with accountsProvider. SyncService also handles this for queued rows.
      try {
        final rows = await Supabase.instance.client
            .from('accounts')
            .select('id')
            .eq('user_id', user.id)
            .eq('name', 'Cash')
            .limit(1);
        if ((rows as List).isNotEmpty) {
          payload['account_id'] = rows[0]['id'] as String;
        }
      } catch (_) {}
    }

    // Optimistic local add
    final optimistic = Txn.fromRow({
      ...payload,
      'created_at': DateTime.now().toUtc().toIso8601String(),
    });
    state = AsyncData([optimistic, ...(state.value ?? const [])]);

    if (ref.read(offlineDebugOverrideProvider) == true) {
      final db = ref.read(offlineDbProvider);
      await db.enqueue(payload);
      return null;
    }

    try {
      final inserted = await Supabase.instance.client
          .from('transactions')
          .insert(payload)
          .select('*, rooms(id, name)')
          .single();
      // Replace the optimistic head with the canonical row.
      final current = state.value ?? const [];
      final replaced = [Txn.fromRow(inserted), ...current.skip(1)];
      state = AsyncData(replaced);
      return inserted['id'] as String?;
    } catch (_) {
      // Enqueue for later sync.
      final db = ref.read(offlineDbProvider);
      await db.enqueue(payload);
      return null;
    }
  }

  Future<void> updateTransaction(
    String id,
    Map<String, dynamic> payload,
  ) async {
    payload['client_updated_at'] = DateTime.now().toUtc().toIso8601String();
    payload['id'] = id;

    if (ref.read(offlineDebugOverrideProvider) == true) {
      await ref.read(offlineDbProvider).enqueue({...payload});
      ref.invalidateSelf();
      return;
    }

    try {
      await Supabase.instance.client
          .from('transactions')
          .update(payload)
          .eq('id', id);
    } catch (_) {
      await ref.read(offlineDbProvider).enqueue({...payload});
    }
    ref.invalidateSelf();
  }

  Future<void> deleteTransaction(String id) async {
    final cur = state.value ?? const [];
    state = AsyncData(cur.where((t) => t.id != id).toList());

    if (ref.read(offlineDebugOverrideProvider) == true) {
      await ref.read(offlineDbProvider).enqueue({'_op': 'delete', 'id': id});
      return;
    }

    try {
      await Supabase.instance.client.from('transactions').delete().eq('id', id);
    } catch (_) {
      await ref.read(offlineDbProvider).enqueue({'_op': 'delete', 'id': id});
    }
  }

  Future<void> refresh() => ref.refresh(transactionsProvider.future);
}

final transactionsProvider =
    AsyncNotifierProvider<TransactionsNotifier, List<Txn>>(
      TransactionsNotifier.new,
    );

/// All transactions made inside a given room (any member). RLS limits
/// visibility to room members. Used by the per-room Reports screen.
final roomTransactionsProvider =
    FutureProvider.family<List<Txn>, String>((ref, roomId) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return const [];
  final rows = await Supabase.instance.client
      .from('transactions')
      .select('*, rooms(id, name)')
      .eq('room_id', roomId)
      .order('created_at', ascending: false)
      .limit(1000);
  return (rows as List)
      .map((r) => Txn.fromRow(r as Map<String, dynamic>))
      .toList();
});
