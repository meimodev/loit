import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'log_service.dart';
import 'offline_database.dart';

class SyncService {
  static const _tag = 'SyncService';

  final OfflineDatabase _db;
  final _supabase = Supabase.instance.client;
  final _connectivity = Connectivity();
  final bool Function() _isDebugOffline;
  StreamSubscription<List<ConnectivityResult>>? _sub;
  bool _syncing = false;

  SyncService(this._db, {bool Function()? isDebugOffline})
      : _isDebugOffline = isDebugOffline ?? (() => false);

  void startAutoSync() {
    Log.i(_tag, 'Auto-sync started');
    _sub = _connectivity.onConnectivityChanged.listen((results) {
      if (_isDebugOffline()) return;
      final online = results.any((r) => r != ConnectivityResult.none);
      if (online) {
        Log.d(_tag, 'Connectivity restored, draining queue');
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
    _syncing = true;
    try {
      final pending = await _db.getPending();
      if (pending.isEmpty) return;

      Log.i(_tag, 'Syncing ${pending.length} pending items');

      for (final item in pending) {
        try {
          final tx = jsonDecode(item.transactionJson) as Map<String, dynamic>;
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

          await _supabase.from('transactions').upsert(tx, onConflict: 'id');
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
