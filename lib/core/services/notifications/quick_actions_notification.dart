import 'dart:async';

import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../analytics_service.dart';
import '../log_service.dart';

/// Persistent "quick actions" notification: shows today's expense total and
/// four shortcut action buttons in the system tray.
///
/// Decisions:
/// - Regular ongoing notification (`setOngoing(true)`), not a foreground
///   service — the user can disable via system long-press on Android 14+.
/// - Importance low (no sound/vibration/heads-up). Lock-screen visibility
///   secret: the body shows the expense amount and must not leak on the
///   lockscreen. Hide Amounts is the in-tray mitigation.
/// - Single notification id reused so subsequent `show` calls replace in
///   place without flicker.
/// - Tap targets a `loit://` URI; `DeepLinkService` already listens to the
///   `app_links` stream and routes via `appRouterProvider`.
class QuickActionsNotification {
  static const channelId = 'loit_quick_actions';
  static const _notificationId = 1001;
  static const _alarmId = 1002;

  static const tapPayloadScan = 'loit://scan';
  static const tapPayloadAdd = 'loit://transactions/add';
  static const tapPayloadViewTransactions = 'loit://transactions';
  static const tapPayloadViewRooms = 'loit://rooms';

  // Bridge to the native QuickActionsForegroundService. Native side posts the
  // ongoing notification so it cannot be swiped (FGS on Android 14+).
  // Action-button + body taps fire VIEW intents on `loit://...` URIs which
  // app_links + DeepLinkService already route — no FLN tap callback needed.
  static const _fgsChannel = MethodChannel('loit/quick_actions_fgs');

  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  /// Kept for API compatibility — taps are now routed natively via PendingIntent
  /// VIEW intents on the `loit://` scheme (see DeepLinkService). The `onTap`
  /// callback is retained but unused; remove from call sites in a later sweep.
  static Future<void> init({
    required void Function(String deepLink) onTap,
  }) async {
    if (_initialized) return;
    _initialized = true;
  }

  /// Start (or update) the foreground-service-backed persistent notification.
  static Future<void> show({
    required String title,
    required String body,
    required String channelName,
    required String channelDescription,
    required String scanLabel,
    required String addLabel,
    required String viewTransactionsLabel,
    required String viewRoomsLabel,
    required bool hideAmounts,
    double? amountForAnalytics,
  }) async {
    try {
      await _fgsChannel.invokeMethod<void>('start', <String, String>{
        'title': title,
        'body': body,
        'channelName': channelName,
        'channelDesc': channelDescription,
        'scan': scanLabel,
        'add': addLabel,
        'viewTx': viewTransactionsLabel,
        'viewRooms': viewRoomsLabel,
      });
    } catch (e) {
      Log.w('QuickActions', 'fgs start failed', error: e);
    }

    if (hideAmounts) {
      unawaited(Analytics.quickActionsNotifAmountHidden());
    } else if (amountForAnalytics != null && amountForAnalytics > 0) {
      unawaited(Analytics.quickActionsNotifAmountShown(
          _bucketAmount(amountForAnalytics)));
    }
  }

  static Future<void> cancel() async {
    try {
      await _fgsChannel.invokeMethod<void>('stop');
    } catch (e) {
      Log.w('QuickActions', 'fgs stop failed', error: e);
    }
    // Defensive: also clear any leftover FLN-posted notification from an
    // older install that pre-dates the foreground service.
    try {
      await _plugin.cancel(_notificationId);
    } catch (_) {}
  }

  /// Schedule the next midnight rollover. Reschedules from the alarm
  /// callback so we self-perpetuate without an in-process timer. Survives
  /// process death; the BOOT_COMPLETED receiver also calls this on reboot.
  static Future<void> scheduleMidnightRollover() async {
    final now = DateTime.now();
    final next = DateTime(now.year, now.month, now.day)
        .add(const Duration(days: 1));
    try {
      await AndroidAlarmManager.oneShotAt(
        next,
        _alarmId,
        _midnightCallback,
        exact: true,
        wakeup: true,
        rescheduleOnReboot: true,
        allowWhileIdle: true,
      );
    } catch (e) {
      Log.w('QuickActions', 'midnight alarm schedule failed', error: e);
    }
  }

  static Future<void> cancelMidnightRollover() async {
    try {
      await AndroidAlarmManager.cancel(_alarmId);
    } catch (_) {/* best-effort */}
  }

  /// Check (don't request) POST_NOTIFICATIONS via the FLN plugin. The FCM
  /// permission flow (`PushService.initialize`) is the canonical asker;
  /// quick-actions just piggy-backs.
  static Future<bool> hasNotificationPermission() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return true;
    try {
      return (await android.areNotificationsEnabled()) ?? false;
    } catch (e) {
      Log.w('QuickActions', 'permission check failed', error: e);
      return false;
    }
  }

  // ---- helpers ----

  static String _bucketAmount(double amount) {
    if (amount <= 0) return '0';
    if (amount < 50000) return '1-50k';
    if (amount < 200000) return '50k-200k';
    if (amount < 1000000) return '200k-1M';
    return '1M+';
  }
}

/// Top-level callback for `android_alarm_manager_plus`. Runs in a background
/// isolate without Flutter/Riverpod — keep it tiny.
///
/// The persistent notification itself is now hosted by a native foreground
/// service that survives across days, so we no longer post a notification
/// here. We only self-reschedule so the alarm keeps ticking; the body text
/// (today's expense total) refreshes on the next app foreground via
/// `QuickActionsNotification.show()`.
@pragma('vm:entry-point')
Future<void> _midnightCallback() async {
  try {
    final now = DateTime.now();
    final next =
        DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
    await AndroidAlarmManager.oneShotAt(
      next,
      1002,
      _midnightCallback,
      exact: true,
      wakeup: true,
      rescheduleOnReboot: true,
      allowWhileIdle: true,
    );
  } catch (e) {
    if (kDebugMode) {
      // No Sentry/Log in alarm isolate without ensureInitialized.
      // ignore: avoid_print
      print('quick-actions midnight callback error: $e');
    }
  }
}

/// Mirror the localized strings the alarm isolate needs into SharedPreferences
/// from the main isolate. Call from the foreground service whenever locale or
/// pref-toggles change.
Future<void> mirrorChannelStringsForAlarm({
  required String title,
  required String launcherBody,
  required String channelName,
  required String channelDescription,
  required String scan,
  required String add,
  required String viewTransactions,
  required String viewRooms,
}) async {
  final sp = await SharedPreferences.getInstance();
  await sp.setString('quickActions.alarm.title', title);
  await sp.setString('quickActions.alarm.launcher', launcherBody);
  await sp.setString('quickActions.alarm.channelName', channelName);
  await sp.setString('quickActions.alarm.channelDescription', channelDescription);
  await sp.setString('quickActions.alarm.scan', scan);
  await sp.setString('quickActions.alarm.add', add);
  await sp.setString('quickActions.alarm.viewTransactions', viewTransactions);
  await sp.setString('quickActions.alarm.viewRooms', viewRooms);
}

