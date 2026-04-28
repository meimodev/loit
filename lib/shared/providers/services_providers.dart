import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/currency_service.dart';
import '../../core/config/env.dart';
import '../../core/services/dummy_payment_service.dart';
import '../../core/services/offline_database.dart';
import '../../core/services/payment_service.dart';
import '../../core/services/revenuecat_payment_service.dart';
import '../../core/services/receipt_service.dart';
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

final receiptServiceProvider =
    Provider<ReceiptService>((ref) => ReceiptService());

/// Single source of truth for the platform billing implementation.
/// Platform detection lives **only** here — feature code talks to the
/// abstract [PaymentService]. iOS/StoreKit can plug in later by adding a
/// branch below.
final paymentServiceProvider = Provider<PaymentService>((ref) {
  // Stub mode short-circuits the real billing path. Useful while
  // RevenueCat onboarding / Play Console verification are pending — the
  // app still flips `users.tier` end-to-end via the `dummy-grant` Edge
  // Function so paywall, gating, and analytics can be exercised.
  if (Env.paymentStub) {
    final svc = DummyPaymentService();
    // ignore: discarded_futures
    svc.initialize();
    ref.onDispose(svc.dispose);
    return svc;
  }

  // RevenueCat handles both Android (Play Billing) and iOS (StoreKit) under
  // the hood, so we no longer need a per-platform branch here. The platform
  // check is kept as a safety guard until iOS is officially launched.
  if (!Platform.isAndroid) {
    throw UnimplementedError('Payment not supported on this platform yet.');
  }
  final svc = RevenueCatPaymentService();
  // ignore: discarded_futures
  svc.initialize();
  ref.onDispose(svc.dispose);
  return svc;
});

