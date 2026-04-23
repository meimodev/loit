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

@DriftDatabase(tables: [PendingTransactions])
class OfflineDatabase extends _$OfflineDatabase {
  OfflineDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

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
