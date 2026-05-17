import 'package:posthog_flutter/posthog_flutter.dart';

import 'log_service.dart';

/// All PostHog events for LOIT.
/// Call these at the exact UI moment noted in comments.
class Analytics {
  static const _tag = 'Analytics';

  // ---- SESSION LIFECYCLE ----
  /// Call once after login success. Associates all future events with this user.
  static Future<void> identify(String userId, {String? email}) {
    Log.i(_tag, 'Identify user=$userId');
    return Posthog().identify(
      userId: userId,
      userProperties: {if (email != null) 'email': email},
    );
  }

  /// Call on sign-out to sever the distinct_id link.
  static Future<void> reset() {
    Log.i(_tag, 'Reset (sign-out)');
    return Posthog().reset();
  }

  // ---- AUTH ----
  static Future<void> signUp(String method) =>
      _capture('sign_up', {'method': method});

  static Future<void> login(String method) =>
      _capture('login', {'method': method});

  // ---- SCANNER ----
  static Future<void> scanStarted() => _capture('scan_started');

  static Future<void> scanCompleted({required bool aiSuccess}) =>
      _capture('scan_completed', {'ai_success': aiSuccess});

  static Future<void> scanFailed(String reason) =>
      _capture('scan_failed', {'reason': reason});

  static Future<void> scanTopupPromptShown() =>
      _capture('scan_topup_prompt_shown');

  // ---- SCANNER PIPELINE v2 ----
  static Future<void> scanPreprocessed({
    required int durationMs,
    required int origBytes,
    required int processedBytes,
  }) =>
      _capture('scan_preprocessed', {
        'duration_ms': durationMs,
        'orig_bytes': origBytes,
        'processed_bytes': processedBytes,
      });

  static Future<void> scanQualityGateFailed(String reason) =>
      _capture('scan_quality_gate_failed', {'reason': reason});

  static Future<void> scanApiCalled({
    required int imageBytes,
    required int promptTokensEst,
  }) =>
      _capture('scan_api_called', {
        'image_bytes': imageBytes,
        'prompt_tokens_est': promptTokensEst,
      });

  static Future<void> scanApiReturned({
    required bool isTransaction,
    String? transactionKind,
    required String confidenceBucket, // 'high' | 'medium' | 'low'
  }) =>
      _capture('scan_api_returned', {
        'is_transaction': isTransaction,
        if (transactionKind != null) 'transaction_kind': transactionKind,
        'confidence_bucket': confidenceBucket,
      });

  static Future<void> scanReconciliationWarning() =>
      _capture('scan_reconciliation_warning');

  static Future<void> scanUserEditedField(String field) =>
      _capture('scan_user_edited_field', {'field': field});

  static Future<void> scanSaved() => _capture('scan_saved');

  static Future<void> scanCancelled() => _capture('scan_cancelled');

  static Future<void> scanQuotaRefunded(String reason) =>
      _capture('scan_quota_refunded', {'reason': reason});

  // ---- TRANSACTIONS ----
  static Future<void> transactionAdded({
    required String method,
    required String category,
  }) =>
      _capture('transaction_added', {'method': method, 'category': category});

  static Future<void> transactionEdited() => _capture('transaction_edited');

  // ---- BUDGETS ----
  static Future<void> budgetCreated() => _capture('budget_created');

  static Future<void> budgetAlertShown(String type) =>
      _capture('budget_alert_shown', {'type': type});

  // ---- PAYWALL ----
  static Future<void> paywallSeen(String feature) =>
      _capture('paywall_seen', {'feature': feature});

  static Future<void> subscriptionStarted(String tier) =>
      _capture('subscription_started', {'tier': tier});

  static Future<void> topupPurchased(String type) =>
      _capture('topup_purchased', {'type': type});

  // ---- ROOMS (Phase 2) ----
  static Future<void> roomsIntroSeen() => _capture('rooms_intro_seen');

  static Future<void> roomCreated() => _capture('room_created');

  static Future<void> roomJoined() => _capture('room_joined');

  static Future<void> roomTransactionAdded() =>
      _capture('room_transaction_added');

  /// Central capture with terminal logging. All events route through here.
  static Future<void> _capture(
    String eventName, [
    Map<String, Object>? properties,
  ]) {
    Log.analytics(eventName, properties);
    return Posthog().capture(eventName: eventName, properties: properties);
  }
}
