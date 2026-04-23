import 'dart:async';

import 'package:flutter/material.dart';
import 'package:midtrans_sdk/midtrans_sdk.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/env.dart';

/// Thin wrapper around [MidtransSDK].
///
/// Flow:
/// 1. Flutter calls [startCheckout] with a `productKey` (e.g. `loit_pro_monthly`).
/// 2. We invoke the `midtrans-checkout` Supabase Edge Function with the user's
///    bearer token. The function signs the request with the Midtrans server
///    key and returns a Snap `token` and our own `order_id`.
/// 3. We call `MidtransSDK.startPaymentUiFlow(token)` — this shows the Midtrans
///    Snap UI (cards / GoPay / OVO / DANA / QRIS / VA) inside the app.
/// 4. Midtrans reports the transaction result via [MidtransSDK]'s transaction
///    finished callback. The authoritative source of truth is still the
///    server-side `midtrans-notification` webhook; this callback is only
///    used for UI feedback.
///
/// Tier upgrade, scan top-up credit, and receipt expiry extensions all happen
/// in the webhook — never trust the client-side result for anything that
/// touches the database.
class MidtransService {
  MidtransService._();
  static final MidtransService instance = MidtransService._();

  MidtransSDK? _sdk;
  Future<MidtransSDK>? _initFuture;

  /// Lazily initialize the SDK on first use. Concurrent callers share the
  /// same in-flight init future.
  Future<MidtransSDK> _ensureInitialized(BuildContext context) {
    if (_sdk != null) return Future.value(_sdk);
    return _initFuture ??= _init(context);
  }

  Future<MidtransSDK> _init(BuildContext context) async {
    final scheme = Theme.of(context).colorScheme;
    final sdk = await MidtransSDK.init(
      config: MidtransConfig(
        clientKey: Env.midtransClientKey,
        // Snap token is always created server-side by `midtrans-checkout`, so
        // this URL is only used as an SDK-internal fallback.
        merchantBaseUrl: Env.midtransIsProduction
            ? 'https://app.midtrans.com/snap/v1'
            : 'https://app.sandbox.midtrans.com/snap/v1',
        colorTheme: ColorTheme(
          colorPrimary: scheme.primary,
          colorPrimaryDark: scheme.primary,
          colorSecondary: scheme.secondary,
        ),
      ),
    );
    sdk.setUIKitCustomSetting(skipCustomerDetailsPages: true);
    _sdk = sdk;
    return sdk;
  }

  /// Kick off a Midtrans Snap checkout for the given product key.
  ///
  /// Returns a [MidtransCheckoutResult] describing the *client-observed*
  /// outcome. Do not grant entitlements based on this — wait for the
  /// `midtrans-notification` webhook to flip `users.tier` server-side.
  Future<MidtransCheckoutResult> startCheckout({
    required BuildContext context,
    required String productKey,
  }) async {
    final sdk = await _ensureInitialized(context);

    final resp = await Supabase.instance.client.functions.invoke(
      'midtrans-checkout',
      body: {'product_key': productKey},
    );
    if (resp.status >= 400) {
      throw Exception('Midtrans checkout init failed: ${resp.data}');
    }
    final data = resp.data as Map<String, dynamic>;
    final token = data['snap_token'] as String?;
    final orderId = data['order_id'] as String?;
    if (token == null || orderId == null) {
      throw StateError('midtrans-checkout returned malformed body: $data');
    }

    final completer = Completer<TransactionResult>();
    sdk.setTransactionFinishedCallback((result) {
      if (!completer.isCompleted) completer.complete(result);
    });

    await sdk.startPaymentUiFlow(token: token);
    final result = await completer.future;

    return MidtransCheckoutResult(
      orderId: orderId,
      status: _statusFromResult(result),
      rawMessage: result.transactionStatus ?? '',
    );
  }

  MidtransCheckoutStatus _statusFromResult(TransactionResult result) {
    if (result.isTransactionCanceled) return MidtransCheckoutStatus.cancelled;
    switch ((result.transactionStatus ?? '').toLowerCase()) {
      case 'capture':
      case 'settlement':
        return MidtransCheckoutStatus.succeeded;
      case 'pending':
        return MidtransCheckoutStatus.pending;
      case 'deny':
      case 'expire':
      case 'failure':
        return MidtransCheckoutStatus.failed;
      default:
        return MidtransCheckoutStatus.unknown;
    }
  }
}

enum MidtransCheckoutStatus { succeeded, pending, failed, cancelled, unknown }

class MidtransCheckoutResult {
  const MidtransCheckoutResult({
    required this.orderId,
    required this.status,
    required this.rawMessage,
  });
  final String orderId;
  final MidtransCheckoutStatus status;
  final String rawMessage;
}
