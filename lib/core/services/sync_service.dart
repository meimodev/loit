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
  StreamSubscription<List<ConnectivityResult>>? _sub;
  bool _syncing = false;

  SyncService(this._db);

  void startAutoSync() {
    Log.i(_tag, 'Auto-sync started');
    _sub = _connectivity.onConnectivityChanged.listen((results) {
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
    _syncing = true;
    try {
      final pending = await _db.getPending();
      if (pending.isEmpty) return;

      Log.i(_tag, 'Syncing ${pending.length} pending items');

      for (final item in pending) {
        try {
          final tx = jsonDecode(item.transactionJson) as Map<String, dynamic>;
          tx['client_updated_at'] = item.clientUpdatedAt.toIso8601String();

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
