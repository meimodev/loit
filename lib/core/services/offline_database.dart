import 'dart:convert';
import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'offline_database.g.dart';

class PendingTransactions extends Table {
  IntColumn  get id              => integer().autoIncrement()();
  TextColumn get transactionJson => text()();
  DateTimeColumn get clientUpdatedAt => dateTime()();
  BoolColumn get synced          => boolean().withDefault(const Constant(false))();
}

/// Step 4 rate-limit log — rolling per-call timestamps (UTC ms epoch).
/// One row per scan attempt. Aged-out rows pruned by [ScanRateLimiter].
class ScanRateLog extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get callMs => integer()();
}

/// Step 9 fallback — when `increment_scan_quota` RPC fails offline, queue the
/// increment locally. SyncService drains on connectivity restore.
class PendingScanCounts extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get atMs => integer()();
  BoolColumn get synced => boolean().withDefault(const Constant(false))();
}

@DriftDatabase(tables: [PendingTransactions, ScanRateLog, PendingScanCounts])
class OfflineDatabase extends _$OfflineDatabase {
  OfflineDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.createTable(scanRateLog);
            await m.createTable(pendingScanCounts);
          }
        },
      );

  Future<void> enqueue(Map<String, dynamic> transaction) =>
      into(pendingTransactions).insert(
        PendingTransactionsCompanion.insert(
          transactionJson: jsonEncode(transaction),
          clientUpdatedAt: DateTime.now().toUtc(),
        ),
      );

  Future<List<PendingTransaction>> getPending() =>
      (select(pendingTransactions)
            ..where((t) => t.synced.equals(false))
            ..orderBy([(t) => OrderingTerm.asc(t.clientUpdatedAt)]))
          .get();

  Future<void> markSynced(int id) =>
      (update(pendingTransactions)..where((t) => t.id.equals(id)))
          .write(const PendingTransactionsCompanion(synced: Value(true)));
}

LazyDatabase _openConnection() => LazyDatabase(() async {
  final dir  = await getApplicationDocumentsDirectory();
  final file = File(p.join(dir.path, 'loit_offline.db'));
  return NativeDatabase.createInBackground(file);
});
