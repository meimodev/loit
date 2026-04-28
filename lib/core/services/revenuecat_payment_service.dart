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
  }

  late final StreamController<PurchaseUpdate> _updates;
  bool _initialized = false;
  CustomerInfoUpdateListener? _customerInfoListener;

  @override
  Stream<PurchaseUpdate> get purchaseUpdates => _updates.stream;

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
    await Purchases.logOut();
  }

  @override
  Future<PaymentProductDetails?> getProductDetails(String productId) async {
    await initialize();
    final products = await Purchases.getProducts([productId]);
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
    return _purchase(productId);
  }

  @override
  Future<PurchaseResult> purchaseOneTime(String productId) {
    return _purchase(productId);
  }

  Future<PurchaseResult> _purchase(String productId) async {
    await initialize();
    try {
      final products = await Purchases.getProducts([productId]);
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
      final rcResult = await Purchases.purchaseStoreProduct(products.first);
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
      _emitFromCustomerInfo(info, productId);
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
    // Re-emit each active entitlement / non-subscription as an update so
    // the UI can refresh. Server-side entitlement is still authoritative
    // and arrives via the webhook → Supabase `users.tier` update.
    for (final entry in info.entitlements.active.entries) {
      _updates.add(PurchaseUpdate(
        productId: entry.value.productIdentifier,
        status: isRestore
            ? PurchaseStatus.restored
            : PurchaseStatus.purchased,
        purchaseToken: entry.value.identifier,
      ));
    }
    for (final p in info.nonSubscriptionTransactions) {
      _updates.add(PurchaseUpdate(
        productId: p.productIdentifier,
        status: isRestore
            ? PurchaseStatus.restored
            : PurchaseStatus.purchased,
        purchaseToken: p.transactionIdentifier,
      ));
    }
  }

  void _emitFromCustomerInfo(CustomerInfo info, String productId) {
    if (_hasEntitlementFor(info, productId)) {
      _updates.add(PurchaseUpdate(
        productId: productId,
        status: PurchaseStatus.purchased,
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
  }
}
