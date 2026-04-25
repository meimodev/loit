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
