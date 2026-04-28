import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/pricing_constants.dart';
import 'log_service.dart';
import 'payment_service.dart';

/// Stub [PaymentService] used until RevenueCat is wired.
///
/// Why this exists:
///   - Play Console developer account is owned by a third party so we can't
///     create RevenueCat products against real Play SKUs yet
///   - Android developer verification + 14-day closed testing window must
///     elapse before Play Developer API features unlock
///   - We want to keep building the rest of the app (paywall UI, gating,
///     analytics, dashboards) without blocking on the above
///
/// Behaviour:
///   1. [purchaseSubscription] / [purchaseOneTime] show a "Pretend Pay"
///      confirmation dialog. The dialog's [BuildContext] is provided by
///      the caller via the most-recent [bindContext] call — set it from
///      the paywall on `initState`.
///   2. On confirm, we POST to the `dummy-grant` Edge Function which
///      mirrors `revenuecat-webhook` side-effects (flip `users.tier`,
///      grant top-ups, extend storage). Same idempotency table, so the
///      swap to real RC requires no DB rewrite.
///   3. Emit a [PurchaseUpdate] so the paywall can react identically to
///      the production flow.
///
/// Swap to real impl: change `paymentServiceProvider` in
/// `services_providers.dart` from [DummyPaymentService] to
/// [RevenueCatPaymentService]. No other code changes required.
class DummyPaymentService implements PaymentService {
  static const _tag = 'DummyPaymentService';

  DummyPaymentService() {
    _updates = StreamController<PurchaseUpdate>.broadcast();
  }

  late final StreamController<PurchaseUpdate> _updates;
  BuildContext? _context;

  /// Bind a [BuildContext] used by the confirmation dialog. Call this from
  /// the paywall's `initState` (and clear in `dispose`).
  void bindContext(BuildContext context) {
    _context = context;
  }

  void unbindContext(BuildContext context) {
    if (identical(_context, context)) _context = null;
  }

  @override
  Stream<PurchaseUpdate> get purchaseUpdates => _updates.stream;

  @override
  Future<void> initialize() async {
    Log.i(_tag, 'Initialized (stub mode — no real billing)');
  }

  @override
  Future<PaymentProductDetails?> getProductDetails(String productId) async {
    final price = _priceFor(productId);
    if (price == null) return null;
    return PaymentProductDetails(
      id: productId,
      title: _titleFor(productId),
      description: 'Stub product — no real Play Console SKU',
      priceString: 'Rp${price.toString()}',
      priceCurrencyCode: 'IDR',
      rawPriceMicros: price * 1000000,
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
    final ctx = _context;
    if (ctx == null || !ctx.mounted) {
      return PurchaseResult(
        productId: productId,
        status: PurchaseStatus.failed,
        message: 'No UI context bound — call bindContext() from paywall first',
      );
    }

    final confirmed = await showDialog<bool>(
      context: ctx,
      barrierDismissible: false,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Pretend Pay (stub)'),
        content: Text(
          'Simulate a successful purchase of "$productId"?\n\n'
          'No real charge — local dev stub only.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: const Text('Pay'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      _updates.add(PurchaseUpdate(
        productId: productId,
        status: PurchaseStatus.cancelled,
      ));
      return PurchaseResult(
        productId: productId,
        status: PurchaseStatus.cancelled,
      );
    }

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        throw StateError('Not signed in');
      }
      final resp = await Supabase.instance.client.functions.invoke(
        'dummy-grant',
        body: {'productId': productId, 'userId': user.id},
      );
      if (resp.status >= 400) {
        throw Exception('dummy-grant ${resp.status}: ${resp.data}');
      }
      Log.i(_tag, 'Stub grant succeeded: $productId');
      _updates.add(PurchaseUpdate(
        productId: productId,
        status: PurchaseStatus.purchased,
        purchaseToken: 'stub-${DateTime.now().millisecondsSinceEpoch}',
      ));
      return PurchaseResult(
        productId: productId,
        status: PurchaseStatus.purchased,
      );
    } catch (e, st) {
      Log.e(_tag, 'Stub grant failed', error: e, stack: st);
      _updates.add(PurchaseUpdate(
        productId: productId,
        status: PurchaseStatus.failed,
        message: e.toString(),
      ));
      return PurchaseResult(
        productId: productId,
        status: PurchaseStatus.failed,
        message: e.toString(),
      );
    }
  }

  @override
  Future<void> restorePurchases() async {
    // Nothing to restore in stub mode — the server already has whatever
    // tier the user got from prior dummy purchases. Just emit a noop
    // event so the paywall snackbar can confirm the action.
    _updates.add(const PurchaseUpdate(
      productId: 'stub-restore',
      status: PurchaseStatus.restored,
      message: 'Stub mode — entitlement is already up to date',
    ));
  }

  @override
  Future<void> dispose() async {
    await _updates.close();
  }

  int? _priceFor(String productId) => switch (productId) {
        PricingConstants.skuProMonthly => PricingConstants.proMonthlyIdr,
        PricingConstants.skuProAnnual => PricingConstants.proAnnualIdr,
        PricingConstants.skuTeamMonthly => PricingConstants.teamMonthlyIdr,
        PricingConstants.skuTeamAnnual => PricingConstants.teamAnnualIdr,
        PricingConstants.skuScanTopUp => PricingConstants.scanTopUpIdr,
        PricingConstants.skuStorageExt => PricingConstants.storageExtensionIdr,
        _ => null,
      };

  String _titleFor(String productId) => switch (productId) {
        PricingConstants.skuProMonthly => 'Pro · Monthly',
        PricingConstants.skuProAnnual => 'Pro · Annual',
        PricingConstants.skuTeamMonthly => 'Team · Monthly',
        PricingConstants.skuTeamAnnual => 'Team · Annual',
        PricingConstants.skuScanTopUp => '10 scan top-up',
        PricingConstants.skuStorageExt => '6-month storage extension',
        _ => productId,
      };
}
