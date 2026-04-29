import 'dart:async';

/// Platform-agnostic payment interface. The rest of the app must only
/// interact with payments through this contract — concrete implementations
/// (Google Play, future StoreKit) are wired via `paymentServiceProvider`.
abstract class PaymentService {
  /// Initialise the underlying billing client and prefetch product details.
  /// Safe to call multiple times — implementations are idempotent.
  Future<void> initialize();

  /// Fetch product metadata (title, localized price string) for the given SKU.
  Future<PaymentProductDetails?> getProductDetails(String productId);

  /// Launch a purchase flow for a recurring subscription SKU.
  Future<PurchaseResult> purchaseSubscription(String productId);

  /// Launch a purchase flow for a one-time consumable / non-consumable SKU.
  Future<PurchaseResult> purchaseOneTime(String productId);

  /// Trigger Play/StoreKit's restore flow. Re-emits past entitlements via
  /// [purchaseUpdates] so the app can re-verify them with the backend.
  Future<void> restorePurchases();

  /// Stream of purchase state transitions surfaced from the platform billing
  /// client. Subscription should be live for the lifetime of the app.
  Stream<PurchaseUpdate> get purchaseUpdates;

  /// Fires whenever the underlying customer entitlement state changes —
  /// including refund / revoke cases that don't surface as a [PurchaseUpdate]
  /// (since revoked entitlements aren't "purchases"). Listeners typically
  /// re-fetch the server-side profile (`users.tier`) when this fires.
  Stream<void> get entitlementChanged;

  /// Release platform resources. Called on app shutdown.
  Future<void> dispose();
}

class PaymentProductDetails {
  const PaymentProductDetails({
    required this.id,
    required this.title,
    required this.description,
    required this.priceString,
    required this.priceCurrencyCode,
    this.rawPriceMicros,
  });

  final String id;
  final String title;
  final String description;
  final String priceString;
  final String priceCurrencyCode;
  final int? rawPriceMicros;
}

enum PurchaseStatus { purchased, pending, cancelled, failed, restored }

class PurchaseResult {
  const PurchaseResult({
    required this.productId,
    required this.status,
    this.purchaseToken,
    this.message,
  });

  final String productId;
  final PurchaseStatus status;
  final String? purchaseToken;
  final String? message;

  bool get isTerminalSuccess =>
      status == PurchaseStatus.purchased || status == PurchaseStatus.restored;
}

class PurchaseUpdate {
  const PurchaseUpdate({
    required this.productId,
    required this.status,
    this.purchaseToken,
    this.message,
  });

  final String productId;
  final PurchaseStatus status;
  final String? purchaseToken;
  final String? message;
}
