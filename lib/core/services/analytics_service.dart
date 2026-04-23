import 'package:posthog_flutter/posthog_flutter.dart';

/// All PostHog events for LOIT.
/// Call these at the exact UI moment noted in comments.
class Analytics {
  // ---- SESSION LIFECYCLE ----
  /// Call once after login success. Associates all future events with this user.
  static Future<void> identify(String userId, {String? email}) =>
      Posthog().identify(
        userId: userId,
        userProperties: {
          if (email != null) 'email': email,
        },
      );

  /// Call on sign-out to sever the distinct_id link.
  static Future<void> reset() => Posthog().reset();

  // ---- AUTH (call immediately after successful operation) ----
  static Future<void> signUp(String method) =>
      Posthog().capture(eventName: 'sign_up', properties: {'method': method});
  // method: 'email' | 'google' | 'apple'

  static Future<void> login(String method) =>
      Posthog().capture(eventName: 'login', properties: {'method': method});

  // ---- SCANNER ----
  static Future<void> scanStarted() =>
      Posthog().capture(eventName: 'scan_started');
  // Call when camera opens

  static Future<void> scanCompleted({required bool aiSuccess}) =>
      Posthog().capture(
        eventName: 'scan_completed',
        properties: {'ai_success': aiSuccess},
      );
  // Call when transaction is confirmed and saved (not just scanned)

  static Future<void> scanFailed(String reason) =>
      Posthog().capture(eventName: 'scan_failed', properties: {'reason': reason});
  // reason: 'quota_exceeded' | 'connection_error' | 'server_error'

  static Future<void> scanTopupPromptShown() =>
      Posthog().capture(eventName: 'scan_topup_prompt_shown');

  // ---- TRANSACTIONS ----
  static Future<void> transactionAdded({
    required String method,
    required String category,
  }) =>
      Posthog().capture(eventName: 'transaction_added', properties: {
        'method': method,       // 'scan' | 'manual' | 'manual_fallback'
        'category': category,
      });

  static Future<void> transactionEdited() =>
      Posthog().capture(eventName: 'transaction_edited');

  // ---- BUDGETS ----
  static Future<void> budgetCreated() =>
      Posthog().capture(eventName: 'budget_created');

  static Future<void> budgetAlertShown(String type) =>
      Posthog().capture(
        eventName: 'budget_alert_shown',
        properties: {'type': type}, // '80_percent' | 'exceeded'
      );

  // ---- PAYWALL (call when paywall screen is shown, before user acts) ----
  static Future<void> paywallSeen(String feature) =>
      Posthog().capture(
        eventName: 'paywall_seen',
        properties: {'feature': feature},
      );
  // feature: 'custom_categories' | 'unlimited_budgets' | 'export' |
  //          'receipt_storage' | 'full_history' | 'more_currencies' |
  //          'more_scan_quota' | 'more_rooms' | 'more_room_members'

  static Future<void> subscriptionStarted(String tier) =>
      Posthog().capture(
        eventName: 'subscription_started',
        properties: {'tier': tier}, // 'pro' | 'team'
      );

  static Future<void> topupPurchased(String type) =>
      Posthog().capture(
        eventName: 'topup_purchased',
        properties: {'type': type}, // 'scans' | 'storage'
      );

  // ---- ROOMS (Phase 2) ----
  static Future<void> roomCreated() =>
      Posthog().capture(eventName: 'room_created');

  static Future<void> roomJoined() =>
      Posthog().capture(eventName: 'room_joined');

  static Future<void> roomTransactionAdded() =>
      Posthog().capture(eventName: 'room_transaction_added');
}
