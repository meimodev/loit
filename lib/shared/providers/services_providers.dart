import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/currency_service.dart';
import '../../core/services/offline_database.dart';
import '../../core/services/scanner_service.dart';
import '../../core/services/sync_service.dart';

final offlineDbProvider = Provider<OfflineDatabase>((ref) {
  final db = OfflineDatabase();
  ref.onDispose(db.close);
  return db;
});

final syncServiceProvider = Provider<SyncService>((ref) {
  final db = ref.watch(offlineDbProvider);
  final svc = SyncService(db);
  ref.onDispose(svc.dispose);
  return svc;
});

final scannerServiceProvider =
    Provider<ScannerService>((ref) => ScannerService());

final currencyServiceProvider =
    Provider<CurrencyService>((ref) => CurrencyService());

