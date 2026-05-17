import 'dart:async';

import 'package:flutter/services.dart' show PlatformException;
import 'package:purchases_flutter/purchases_flutter.dart' hide PurchaseResult;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/env.dart';
import '../config/pricing_constants.dart';
import 'log_service.dart' hide LogLevel;
import 'payment_service.dart';

/// RevenueCat-backed implementation of [PaymentService].
///
/// Why RevenueCat instead of `in_app_purchase` + a custom verify endpoint:
/// the Play Console developer account is owned by a third party, so we
/// cannot link a Google Cloud service account for direct Play Developer
/// API verification. RevenueCat hosts that integration on their side and
/// signs every entitlement event back to us via a webhook.
///
/// Flow:
/// 1. [initialize] calls [Purchases.configure] with the Android SDK key,
///    sets `appUserID = supabase user id` so RC's customer record is keyed
///    on our auth user (no anon → known reconciliation needed later).
/// 2. Purchase calls hand off to RC, which drives Play Billing. RC marks
///    the entitlement active locally. The authoritative state flip in
///    Supabase happens via the `revenuecat-webhook` Edge Function — never
///    trust the client `CustomerInfo` for granting database-side access.
/// 3. The local `CustomerInfo` is still surfaced through [purchaseUpdates]
///    so the UI can react immediately while the webhook lands.
class RevenueCatPaymentService implements PaymentService {
  static const _tag = 'RevenueCatPaymentService';

  RevenueCatPaymentService() {
    _updates = StreamController<PurchaseUpdate>.broadcast();
    _entitlementChanged = StreamController<void>.broadcast();
  }

  late final StreamController<PurchaseUpdate> _updates;
  late final StreamController<void> _entitlementChanged;
  bool _initialized = false;
  CustomerInfoUpdateListener? _customerInfoListener;
  // Dedup: RC's CustomerInfo listener fires on every refresh and re-lists all
  // active entitlements / non-sub txs. Without dedup, every state poll re-emits
  // every prior purchase as a new "purchased" event, spamming snacks/logs.
  final Set<String> _emittedEntitlementKeys = {};
  final Set<String> _emittedTxIds = {};

  @override
  Stream<PurchaseUpdate> get purchaseUpdates => _updates.stream;

  @override
  Stream<void> get entitlementChanged => _entitlementChanged.stream;

  @override
  Future<void> initialize() async {
    if (_initialized) return;
    if (Env.revenueCatAndroidKey.isEmpty) {
      Log.w(_tag, 'REVENUECAT_ANDROID_KEY missing — skipping init');
      return;
    }

    await Purchases.setLogLevel(LogLevel.warn);

    final user = Supabase.instance.client.auth.currentUser;
    final config = PurchasesConfiguration(Env.revenueCatAndroidKey)
      ..appUserID = user?.id;
    await Purchases.configure(config);

    _customerInfoListener = (info) => _onCustomerInfo(info);
    Purchases.addCustomerInfoUpdateListener(_customerInfoListener!);

    _initialized = true;
    Log.i(_tag, 'Initialized (appUserID=${user?.id ?? "anon"})');
  }

  /// Re-binds the RevenueCat customer to a Supabase user. Call after sign-in
  /// so purchases made anonymously (rare for us — purchase requires login)
  /// are still attributed correctly.
  Future<void> identify(String supabaseUserId) async {
    await initialize();
    await Purchases.logIn(supabaseUserId);
  }

  Future<void> logout() async {
    if (!_initialized) return;
    _emittedEntitlementKeys.clear();
    _emittedTxIds.clear();
    // RC throws PlatformException code 22 when logOut is called on an
    // anonymous customer (cold boot before any identify). Skip the call.
    if (await Purchases.isAnonymous) return;
    try {
      await Purchases.logOut();
    } on PlatformException catch (e) {
      if (e.code == '22') {
        Log.d(_tag, 'logOut skipped: anonymous customer');
        return;
      }
      rethrow;
    }
  }

  @override
  Future<PaymentProductDetails?> getProductDetails(String productId) async {
    await initialize();
    // RC's `getProducts` defaults to ProductCategory.subscription. Consumables
    // (e.g. `loit_scan_topup_15`) are non-subscription products and would
    // return empty under the default filter. Try subscription first, then
    // fall back to non-subscription so a single entry point works for both.
    var products = await Purchases.getProducts(
      [productId],
      productCategory: ProductCategory.subscription,
    );
    if (products.isEmpty) {
      products = await Purchases.getProducts(
        [productId],
        productCategory: ProductCategory.nonSubscription,
      );
    }
    if (products.isEmpty) return null;
    final p = products.first;
    return PaymentProductDetails(
      id: p.identifier,
      title: p.title,
      description: p.description,
      priceString: p.priceString,
      priceCurrencyCode: p.currencyCode,
      rawPriceMicros: (p.price * 1000000).toInt(),
    );
  }

  @override
  Future<PurchaseResult> purchaseSubscription(String productId) {
    return _purchase(productId, ProductCategory.subscription);
  }

  @override
  Future<PurchaseResult> purchaseOneTime(String productId) {
    return _purchase(productId, ProductCategory.nonSubscription);
  }

  Future<PurchaseResult> _purchase(
      String productId, ProductCategory category) async {
    await initialize();
    try {
      final products = await Purchases.getProducts(
        [productId],
        productCategory: category,
      );
      if (products.isEmpty) {
        return PurchaseResult(
          productId: productId,
          status: PurchaseStatus.failed,
          message: 'Product not found in RevenueCat / Play Console',
        );
      }
      // RC v8+ returns its own `PurchaseResult` (hidden in our import) wrapping
      // `customerInfo`. We unwrap it and pass `CustomerInfo` to our helpers
      // so the entitlement-check logic stays the same as the listener path.
      final rcResult = await Purchases.purchase(
        PurchaseParams.storeProduct(products.first),
      );
      var info = (rcResult as dynamic).customerInfo as CustomerInfo;

      // RC's local CustomerInfo lags the webhook-driven entitlement state by
      // a few hundred ms. Force a refresh so we don't return `pending` for a
      // purchase that already succeeded server-side.
      if (!_hasEntitlementFor(info, productId)) {
        try {
          await Purchases.invalidateCustomerInfoCache();
          info = await Purchases.getCustomerInfo();
        } catch (e) {
          Log.w(_tag, 'Post-purchase refresh failed: $e');
        }
      }

      final entitled = _hasEntitlementFor(info, productId);
      // Don't manually emit here — RC's addCustomerInfoUpdateListener fires
      // _onCustomerInfo automatically after a successful purchase. Emitting
      // both produces duplicate purchased events.
      return PurchaseResult(
        productId: productId,
        status: entitled ? PurchaseStatus.purchased : PurchaseStatus.pending,
        purchaseToken: _latestTokenFor(info, productId),
      );
    } on PlatformException catch (e) {
      final code = PurchasesErrorHelper.getErrorCode(e);
      if (code == PurchasesErrorCode.purchaseCancelledError) {
        return PurchaseResult(
          productId: productId,
          status: PurchaseStatus.cancelled,
        );
      }
      Log.e(_tag, 'Purchase failed (${code.name})', error: e);
      return PurchaseResult(
        productId: productId,
        status: PurchaseStatus.failed,
        message: code.name,
      );
    } catch (e, st) {
      Log.e(_tag, 'Purchase failed', error: e, stack: st);
      return PurchaseResult(
        productId: productId,
        status: PurchaseStatus.failed,
        message: e.toString(),
      );
    }
  }

  @override
  Future<void> restorePurchases() async {
    await initialize();
    final info = await Purchases.restorePurchases();
    _onCustomerInfo(info, isRestore: true);
  }

  void _onCustomerInfo(CustomerInfo info, {bool isRestore = false}) {
    // Always notify listeners that entitlement state may have shifted (refund,
    // billing issue, expiration, etc.). They should re-pull users.tier.
    if (!_entitlementChanged.isClosed) _entitlementChanged.add(null);
    // Server-side entitlement is authoritative via webhook → users.tier.
    // Restore intentionally re-emits everything (user pressed "Restore").
    if (isRestore) {
      _emittedEntitlementKeys.clear();
      _emittedTxIds.clear();
    }
    final status = isRestore ? PurchaseStatus.restored : PurchaseStatus.purchased;
    for (final entry in info.entitlements.active.entries) {
      final key = '${entry.key}:${entry.value.productIdentifier}:'
          '${entry.value.latestPurchaseDate}';
      if (!_emittedEntitlementKeys.add(key)) continue;
      _updates.add(PurchaseUpdate(
        productId: entry.value.productIdentifier,
        status: status,
        purchaseToken: entry.value.identifier,
      ));
    }
    for (final p in info.nonSubscriptionTransactions) {
      if (!_emittedTxIds.add(p.transactionIdentifier)) continue;
      _updates.add(PurchaseUpdate(
        productId: p.productIdentifier,
        status: status,
        purchaseToken: p.transactionIdentifier,
      ));
    }
  }

  bool _hasEntitlementFor(CustomerInfo info, String productId) {
    if (PricingConstants.subscriptionSkus.contains(productId)) {
      return info.entitlements.active.values
          .any((e) => e.productIdentifier == productId);
    }
    return info.nonSubscriptionTransactions
        .any((t) => t.productIdentifier == productId);
  }

  String? _latestTokenFor(CustomerInfo info, String productId) {
    final txs = info.nonSubscriptionTransactions
        .where((t) => t.productIdentifier == productId)
        .toList();
    if (txs.isEmpty) return null;
    return txs.last.transactionIdentifier;
  }

  @override
  Future<void> dispose() async {
    if (_customerInfoListener != null) {
      Purchases.removeCustomerInfoUpdateListener(_customerInfoListener!);
    }
    await _updates.close();
    await _entitlementChanged.close();
  }
}
