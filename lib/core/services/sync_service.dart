import 'dart:async';
import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'log_service.dart';
import 'offline_database.dart';
import 'reachability_service.dart';

class SyncService {
  static const _tag = 'SyncService';

  final OfflineDatabase _db;
  final ReachabilityService _reachability;
  final _supabase = Supabase.instance.client;
  final bool Function() _isDebugOffline;
  StreamSubscription<bool>? _sub;
  bool _syncing = false;
  bool? _lastOnline;

  SyncService(
    this._db, {
    required ReachabilityService reachability,
    bool Function()? isDebugOffline,
  })  : _reachability = reachability,
        _isDebugOffline = isDebugOffline ?? (() => false);

  void startAutoSync() {
    Log.i(_tag, 'Auto-sync started');
    // Drain whenever reachability flips from offline → online. A simple
    // "is online now" listener would re-drain on every periodic probe; we
    // care about the transition.
    _sub = _reachability.onStatusChange.listen((online) {
      if (_isDebugOffline()) return;
      final wasOnline = _lastOnline == true;
      _lastOnline = online;
      if (online && !wasOnline) {
        Log.d(_tag, 'Reachability restored, draining queue');
        unawaited(syncPending());
      }
    });
    unawaited(syncPending());
  }

  Future<void> dispose() async {
    await _sub?.cancel();
    Log.d(_tag, 'Disposed');
  }

  Future<void> syncPending() async {
    if (_syncing) return;
    if (_supabase.auth.currentSession == null) return;
    if (_isDebugOffline()) return;
    // Gate on actual reachability — if the probe fails, skip the round-trip
    // so we don't waste a request only to land the row back in the queue.
    if (!await _reachability.isReachable()) {
      Log.d(_tag, 'Skip drain: reachability probe failed');
      return;
    }
    _syncing = true;
    try {
      final pending = await _db.getPending();
      if (pending.isEmpty) return;

      Log.i(_tag, 'Syncing ${pending.length} pending items');

      for (final item in pending) {
        try {
          final tx = jsonDecode(item.transactionJson) as Map<String, dynamic>;

          if (tx['_op'] == 'delete') {
            final id = tx['id'] as String?;
            if (id != null) {
              await _supabase.from('transactions').delete().eq('id', id);
            }
            await _db.markSynced(item.id);
            Log.d(_tag, 'Synced delete for item ${item.id}');
            continue;
          }

          // Strip caller-side meta keys (e.g. `_image_path` from scan review).
          // Historical rows queued before the provider-side strip landed are
          // self-healed here so upsert no longer 400s on unknown columns.
          tx.removeWhere((k, _) => k.startsWith('_'));

          // Self-heal rows queued with the legacy `date` field (scan review
          // bug — no `date` column on `transactions`). Map to `created_at`
          // so previously-trapped rows finally sync on the next drain.
          if (tx.containsKey('date') && !tx.containsKey('created_at')) {
            tx['created_at'] = tx.remove('date');
          } else if (tx.containsKey('date')) {
            tx.remove('date');
          }

          // Self-heal rows queued without `fx_snapshot` (scan review prior
          // to the addTransaction safety net). Insert minimal self-rate so
          // the NOT NULL constraint passes; display falls back gracefully.
          if (tx['fx_snapshot'] == null) {
            final currency = (tx['currency'] as String?) ?? 'IDR';
            tx['fx_snapshot'] = {currency: 1.0};
          }

          // Self-heal rows queued before `source` existed. Derive from the
          // legacy `ai_parsed` boolean so the NOT NULL constraint passes
          // with the same value the migration backfill would have chosen.
          if (tx['source'] == null) {
            tx['source'] = (tx['ai_parsed'] == true) ? 'scanned' : 'manual';
          }

          tx['client_updated_at'] = item.clientUpdatedAt.toIso8601String();

          // Normalize fields that are required after the accounts migration but
          // may be absent from rows queued before the upgrade.
          if (tx['type'] == null) {
            final amt = (tx['amount'] as num?)?.toDouble() ?? 0;
            tx['type'] = amt < 0 ? 'income' : 'expense';
          }
          if (tx['account_id'] == null) {
            final userId = tx['user_id'] as String?;
            if (userId == null) {
              Log.i(_tag, 'No user_id in payload for item ${item.id}, skipping');
              continue;
            }
            final cashRows = await _supabase
                .from('accounts')
                .select('id')
                .eq('user_id', userId)
                .eq('name', 'Cash')
                .limit(1);
            if ((cashRows as List).isEmpty) {
              Log.i(_tag, 'No Cash account for user $userId, skipping item ${item.id}');
              continue;
            }
            tx['account_id'] = cashRows[0]['id'] as String;
          }

          if (await _serverHasNewer(tx['id'] as String?, item.clientUpdatedAt)) {
            Log.d(_tag, 'Item ${item.id} superseded by server, skipping');
            await _db.markSynced(item.id);
            continue;
          }

          final hasItemsKey = tx.containsKey('items');
          final rawItems = tx.remove('items');
          final upserted = await _supabase
              .from('transactions')
              .upsert(tx, onConflict: 'id')
              .select('id')
              .single();
          final txnId = (upserted['id'] as String?) ?? tx['id'] as String?;
          if (hasItemsKey && txnId != null) {
            try {
              await _supabase
                  .from('transaction_items')
                  .delete()
                  .eq('transaction_id', txnId);
              if (rawItems is List && rawItems.isNotEmpty) {
                await _supabase.from('transaction_items').insert([
                  for (final r in rawItems)
                    if (r is Map)
                      {
                        'transaction_id': txnId,
                        'name': r['name'] ?? '',
                        if (r['qty'] != null) 'qty': r['qty'],
                        if (r['unit_price'] != null)
                          'unit_price': r['unit_price'],
                        if (r['total_price'] != null)
                          'total_price': r['total_price'],
                      },
                ]);
              }
            } catch (e) {
              Log.w(_tag, 'Items replay failed for ${item.id}: $e');
            }
          }
          await _db.markSynced(item.id);
          Log.d(_tag, 'Synced item ${item.id}');
        } catch (e, st) {
          Log.e(_tag, 'Sync failed for item ${item.id}', error: e, stack: st);
        }
      }
      Log.i(_tag, 'Sync complete');
    } finally {
      _syncing = false;
    }
  }

  Future<bool> _serverHasNewer(String? id, DateTime clientUpdatedAt) async {
    if (id == null) return false; // INSERT — nothing to compare
    final row = await _supabase
        .from('transactions')
        .select('updated_at')
        .eq('id', id)
        .maybeSingle();
    if (row == null) return false;
    final serverTs = DateTime.parse(row['updated_at'] as String);
    return serverTs.isAfter(clientUpdatedAt);
  }
}
