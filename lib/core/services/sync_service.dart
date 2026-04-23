import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'offline_database.dart';

class SyncService {
  final OfflineDatabase _db;
  final _supabase = Supabase.instance.client;
  final _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _sub;
  bool _syncing = false;

  SyncService(this._db);

  /// Call once during app startup (after Supabase.initialize) to
  /// auto-drain the queue whenever connectivity returns.
  void startAutoSync() {
    _sub = _connectivity.onConnectivityChanged.listen((results) {
      final online = results.any((r) => r != ConnectivityResult.none);
      if (online) unawaited(syncPending());
    });
    // Run once immediately in case we boot up already online with a non-empty queue.
    unawaited(syncPending());
  }

  Future<void> dispose() async {
    await _sub?.cancel();
  }

  /// Sync pending offline transactions to Supabase.
  ///
  /// Conflict resolution:
  ///   - Client sets `client_updated_at` at save time (see [OfflineDatabase.enqueue]).
  ///   - Server maintains `updated_at` via the moddatetime trigger from Step 1.3.
  ///   - Upsert with `onConflict: 'id'` — if the server row's `updated_at` is newer
  ///     than the queued `client_updated_at`, the application layer compares the two
  ///     and discards the stale offline edit. (See [_serverHasNewer].)
  Future<void> syncPending() async {
    if (_syncing) return;             // prevent overlapping syncs
    if (_supabase.auth.currentSession == null) return;  // not signed in
    _syncing = true;
    try {
      final pending = await _db.getPending();
      if (pending.isEmpty) return;

      for (final item in pending) {
        try {
          final tx = jsonDecode(item.transactionJson) as Map<String, dynamic>;
          tx['client_updated_at'] = item.clientUpdatedAt.toIso8601String();

          if (await _serverHasNewer(tx['id'] as String?, item.clientUpdatedAt)) {
            // Server has a more recent edit from another device — drop local change.
            await _db.markSynced(item.id);
            continue;
          }

          await _supabase.from('transactions').upsert(tx, onConflict: 'id');
          await _db.markSynced(item.id);
        } catch (e, st) {
          // Log and continue — do not abort entire sync for one failed item.
          debugPrint('Sync failed for item ${item.id}: $e\n$st');
        }
      }
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
