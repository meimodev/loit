import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/services/currency_service.dart';
import '../../core/services/log_service.dart';
import '../../core/services/reachability_service.dart';
import '../widgets/connectivity_banner.dart';
import 'auth_providers.dart';
import 'services_providers.dart';
import 'supported_currencies_provider.dart';

/// Transaction row shape used by UI. Kept as a typed view over Map.
///
/// `fxSnapshot` is a frozen map of rates from this txn's `currency` to every
/// supported currency, computed at create time. Display logic uses [amountIn]
/// to convert without hitting the network — even when the user changes home
/// currency or an account's currency.
/// Canonical origin of a transaction. Mirrors the
/// `transactions.source` column added in migration
/// `20260521000001_transactions_source.sql`.
enum TxnSource { manual, scanned, botImage, botChat }

TxnSource _txnSourceFromString(String? raw, {required bool aiParsed}) {
  switch (raw) {
    case 'manual':
      return TxnSource.manual;
    case 'scanned':
      return TxnSource.scanned;
    case 'bot_image':
      return TxnSource.botImage;
    case 'bot_chat':
      return TxnSource.botChat;
  }
  return aiParsed ? TxnSource.scanned : TxnSource.manual;
}

String txnSourceToString(TxnSource s) {
  switch (s) {
    case TxnSource.manual:
      return 'manual';
    case TxnSource.scanned:
      return 'scanned';
    case TxnSource.botImage:
      return 'bot_image';
    case TxnSource.botChat:
      return 'bot_chat';
  }
}

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
  final TxnSource source;
  final DateTime createdAt;
  final String? roomId;
  final String? roomName;
  final String type; // 'expense' | 'income' | 'transfer'
  final String? accountId;
  final String? toAccountId;
  final String? userId;
  // Payer identity — populated only for room-account movements (the `users`
  // join). Null for personal rows. See ADR 0010.
  final String? payerName;
  final String? payerEmail;
  final String? payerAvatarUrl;

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
    this.source = TxnSource.manual,
    this.roomId,
    this.roomName,
    this.type = 'expense',
    this.accountId,
    this.toAccountId,
    this.userId,
    this.payerName,
    this.payerEmail,
    this.payerAvatarUrl,
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
    final aiParsed = (r['ai_parsed'] as bool?) ?? false;
    return Txn(
      id: r['id'] as String?,
      amount: ((r['amount'] as num?) ?? 0).toDouble(),
      currency: (r['currency'] as String?) ?? 'IDR',
      fxSnapshot: snapshot,
      category: r['category'] as String?,
      notes: r['notes'] as String?,
      receiptUrl: r['receipt_url'] as String?,
      aiParsed: aiParsed,
      isManualFallback: (r['is_manual_fallback'] as bool?) ?? false,
      source: _txnSourceFromString(r['source'] as String?, aiParsed: aiParsed),
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
      userId: r['user_id'] as String?,
      payerName: (r['users'] is Map<String, dynamic>)
          ? (r['users'] as Map<String, dynamic>)['name'] as String?
          : null,
      payerEmail: (r['users'] is Map<String, dynamic>)
          ? (r['users'] as Map<String, dynamic>)['email'] as String?
          : null,
      payerAvatarUrl: (r['users'] is Map<String, dynamic>)
          ? (r['users'] as Map<String, dynamic>)['avatar_url'] as String?
          : null,
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

/// Thrown when a connectivity-required action (a transaction touching a room
/// account) is attempted offline. Room-account movements are online-only so the
/// shared balance never diverges across members — see ADR 0007.
class OnlineOnlyActionException implements Exception {
  const OnlineOnlyActionException();
  @override
  String toString() => 'This action needs an internet connection.';
}

class TransactionsNotifier extends AsyncNotifier<List<Txn>> {
  RealtimeChannel? _channel;

  @override
  Future<List<Txn>> build() async {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const [];

    // Realtime: any insert/update/delete on this user's rows refetches the
    // feed. Catches bot-originated writes from the messaging pipeline.
    _channel?.unsubscribe();
    final channel = Supabase.instance.client
        .channel('public:transactions:user=${user.id}');
    for (final ev in const [
      PostgresChangeEvent.insert,
      PostgresChangeEvent.update,
      PostgresChangeEvent.delete,
    ]) {
      channel.onPostgresChanges(
        event: ev,
        schema: 'public',
        table: 'transactions',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'user_id',
          value: user.id,
        ),
        callback: (payload) {
          Log.i(
            'TransactionsProvider',
            'realtime event ${payload.eventType.name} '
                'id=${(payload.newRecord['id'] ?? payload.oldRecord['id'])} '
                'source=${payload.newRecord['source']}',
          );
          ref.invalidateSelf();
        },
      );
    }
    channel.subscribe((status, err) {
      Log.i(
        'TransactionsProvider',
        'realtime subscribe status=$status err=$err',
      );
    });
    _channel = channel;
    ref.onDispose(() {
      channel.unsubscribe();
    });

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
  Future<String?> addTransaction(
    Map<String, dynamic> payload, {
    bool requireOnline = false,
  }) async {
    final user = ref.read(currentUserProvider);
    if (user == null) throw StateError('Not signed in');

    // Drop caller-side meta keys (e.g. `_image_path` from scan review) so they
    // never reach Supabase — unknown columns would 400 the insert and trap the
    // row in the offline queue forever.
    payload.removeWhere((k, _) => k.startsWith('_'));

    // Legacy alias: some callers (older scan review code path, scanner OCR
    // output) emit `date` instead of `created_at`. The schema has no `date`
    // column, so the insert 400s and the row queues forever. Normalize here
    // so future callers can't reintroduce the bug silently.
    if (payload.containsKey('date') && !payload.containsKey('created_at')) {
      payload['created_at'] = payload.remove('date');
    } else if (payload.containsKey('date')) {
      payload.remove('date');
    }

    // `fx_snapshot` is NOT NULL on `transactions`. Scan review didn't build
    // one, so the insert would 400 and the row would queue forever. Compute
    // on the fly here as a safety net for any caller that forgot.
    if (payload['fx_snapshot'] == null) {
      final currency = (payload['currency'] as String?) ?? 'IDR';
      Map<String, double> snapshot;
      try {
        final rates =
            await ref.read(currencyServiceProvider).loadUsdBaseRates();
        final supported = ref.read(supportedCurrenciesProvider).value;
        final codes =
            supported?.codes ?? rates.keys.toList(growable: false);
        snapshot = CurrencyService.buildSnapshot(
          from: currency,
          rates: rates,
          supported: codes,
        );
      } catch (_) {
        // Offline + no cache: self-rate only. Display falls back to raw
        // amount when target currency is missing from the snapshot.
        snapshot = {currency: 1.0};
      }
      payload['fx_snapshot'] = snapshot;
    }

    payload['user_id'] = user.id;
    payload['client_updated_at'] = DateTime.now().toUtc().toIso8601String();

    // Canonical origin. Callers that omit `source` are treated as manual; the
    // dedicated scanner / bot paths set it explicitly.
    payload['source'] ??= 'manual';

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

    // Items are written to `transaction_items` after the parent insert.
    final items = _coerceItems(payload.remove('items'));

    // No optimistic add: the row only appears in UI after the write path
    // resolves (online insert success OR offline enqueue confirmation). This
    // way the UI reflects the real outcome instead of always looking
    // "offline-saved" before the network call completes.
    if (await _isOffline()) {
      // Room-account movements must not queue offline (shared-state divergence).
      if (requireOnline) throw const OnlineOnlyActionException();
      final db = ref.read(offlineDbProvider);
      // Re-attach items so the queued row can replay items on sync.
      if (items.isNotEmpty) payload['items'] = items;
      await db.enqueue(payload);
      // Surface the queued row locally so the user sees their entry.
      final queued = Txn.fromRow({
        ...payload,
        'created_at': DateTime.now().toUtc().toIso8601String(),
      });
      state = AsyncData([queued, ...(state.value ?? const [])]);
      return null;
    }

    try {
      final inserted = await Supabase.instance.client
          .from('transactions')
          .insert(payload)
          .select('*, rooms(id, name)')
          .single();
      final newId = inserted['id'] as String?;
      if (newId != null && items.isNotEmpty) {
        try {
          await Supabase.instance.client
              .from('transaction_items')
              .insert([
            for (final it in items)
              {
                'transaction_id': newId,
                'name': it['name'] ?? '',
                if (it['qty'] != null) 'qty': it['qty'],
                if (it['unit_price'] != null) 'unit_price': it['unit_price'],
                if (it['total_price'] != null)
                  'total_price': it['total_price'],
              },
          ]);
        } catch (_) {/* best-effort */}
      }
      // Prepend the canonical row now that the insert has resolved.
      final current = state.value ?? const [];
      state = AsyncData([Txn.fromRow(inserted), ...current]);
      return newId;
    } catch (e) {
      // Room-account movements never fall back to the offline queue.
      if (requireOnline) rethrow;
      Log.w('TransactionsProvider', 'Online insert failed, enqueuing', error: e);
      if (items.isNotEmpty) payload['items'] = items;
      final db = ref.read(offlineDbProvider);
      await db.enqueue(payload);
      // Mirror the queued row into local state so the user sees their entry.
      final queued = Txn.fromRow({
        ...payload,
        'created_at': DateTime.now().toUtc().toIso8601String(),
      });
      state = AsyncData([queued, ...(state.value ?? const [])]);
      return null;
    }
  }

  List<Map<String, dynamic>> _coerceItems(Object? raw) {
    if (raw is! List) return const [];
    final out = <Map<String, dynamic>>[];
    for (final r in raw) {
      if (r is Map) out.add(Map<String, dynamic>.from(r));
    }
    return out;
  }

  Future<void> updateTransaction(
    String id,
    Map<String, dynamic> payload,
  ) async {
    payload.removeWhere((k, _) => k.startsWith('_'));
    payload['client_updated_at'] = DateTime.now().toUtc().toIso8601String();
    payload['id'] = id;

    final hasItemsKey = payload.containsKey('items');
    final items = _coerceItems(payload.remove('items'));

    if (await _isOffline()) {
      final queued = {...payload};
      if (hasItemsKey) queued['items'] = items;
      await ref.read(offlineDbProvider).enqueue(queued);
      ref.invalidateSelf();
      return;
    }

    try {
      await Supabase.instance.client
          .from('transactions')
          .update(payload)
          .eq('id', id);
      if (hasItemsKey) {
        try {
          await Supabase.instance.client
              .from('transaction_items')
              .delete()
              .eq('transaction_id', id);
          if (items.isNotEmpty) {
            await Supabase.instance.client
                .from('transaction_items')
                .insert([
              for (final it in items)
                {
                  'transaction_id': id,
                  'name': it['name'] ?? '',
                  if (it['qty'] != null) 'qty': it['qty'],
                  if (it['unit_price'] != null) 'unit_price': it['unit_price'],
                  if (it['total_price'] != null)
                    'total_price': it['total_price'],
                },
            ]);
          }
        } catch (_) {/* best-effort */}
      }
    } catch (e) {
      Log.w('TransactionsProvider', 'Online update failed, enqueuing', error: e);
      final queued = {...payload};
      if (hasItemsKey) queued['items'] = items;
      await ref.read(offlineDbProvider).enqueue(queued);
    }
    ref.invalidateSelf();
  }

  Future<void> deleteTransaction(String id) async {
    if (await _isOffline()) {
      await ref.read(offlineDbProvider).enqueue({'_op': 'delete', 'id': id});
      final cur = state.value ?? const [];
      state = AsyncData(cur.where((t) => t.id != id).toList());
      return;
    }

    try {
      await Supabase.instance.client.from('transactions').delete().eq('id', id);
      final cur = state.value ?? const [];
      state = AsyncData(cur.where((t) => t.id != id).toList());
    } catch (_) {
      await ref.read(offlineDbProvider).enqueue({'_op': 'delete', 'id': id});
      final cur = state.value ?? const [];
      state = AsyncData(cur.where((t) => t.id != id).toList());
    }
  }

  Future<void> refresh() => ref.refresh(transactionsProvider.future);

  /// Resolves the offline gate via [ReachabilityService] — combines network
  /// interface state with an active HEAD probe. Replaces the prior
  /// interface-only check which mis-classified captive-portal / hotspot-
  /// without-upstream networks as online. Honors the dev debug override.
  Future<bool> _isOffline() async {
    if (ref.read(offlineDebugOverrideProvider) == true) return true;
    final reach = ref.read(reachabilityServiceProvider);
    return !(await reach.isReachable());
  }
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
