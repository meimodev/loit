import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/services/log_service.dart';

class AppPreferences {
  final ThemeMode themeMode;
  final String language; // 'en' | 'id' | 'system'
  final String region; // 'ID' | 'US' | etc.
  final String currency; // 'IDR' | 'USD' | ...

  // Security
  final bool biometricLock;
  final bool hideAmounts;

  // Notifications (8 toggles on notifications screen)
  final bool notifBudgetAlerts;
  final bool notifBudgetWeeklyDigest;
  final bool notifRoomActivity;
  final bool notifRoomMentions;
  final bool notifReceiptExpiry;
  final bool notifMonthlyDigest;
  final bool notifProductUpdates;

  // Scanner pipeline v2 — auto-confirm high-confidence scans after 3s.
  // Default on; user toggle in Settings → Scanning.
  final bool scanAutoConfirm;

  // Persistent quick-actions notification in system tray.
  // Default on; user toggle in Settings → Notifications.
  final bool quickActionsNotifEnabled;

  const AppPreferences({
    this.themeMode = ThemeMode.light,
    this.language = 'id',
    this.region = 'ID',
    this.currency = 'IDR',
    this.biometricLock = false,
    this.hideAmounts = false,
    this.notifBudgetAlerts = true,
    this.notifBudgetWeeklyDigest = false,
    this.notifRoomActivity = true,
    this.notifRoomMentions = true,
    this.notifReceiptExpiry = true,
    this.notifMonthlyDigest = false,
    this.notifProductUpdates = false,
    this.scanAutoConfirm = true,
    this.quickActionsNotifEnabled = true,
  });

  AppPreferences copyWith({
    ThemeMode? themeMode,
    String? language,
    String? region,
    String? currency,
    bool? biometricLock,
    bool? hideAmounts,
    bool? notifBudgetAlerts,
    bool? notifBudgetWeeklyDigest,
    bool? notifRoomActivity,
    bool? notifRoomMentions,
    bool? notifReceiptExpiry,
    bool? notifMonthlyDigest,
    bool? notifProductUpdates,
    bool? scanAutoConfirm,
    bool? quickActionsNotifEnabled,
  }) =>
      AppPreferences(
        themeMode: themeMode ?? this.themeMode,
        language: language ?? this.language,
        region: region ?? this.region,
        currency: currency ?? this.currency,
        biometricLock: biometricLock ?? this.biometricLock,
        hideAmounts: hideAmounts ?? this.hideAmounts,
        notifBudgetAlerts: notifBudgetAlerts ?? this.notifBudgetAlerts,
        notifBudgetWeeklyDigest:
            notifBudgetWeeklyDigest ?? this.notifBudgetWeeklyDigest,
        notifRoomActivity: notifRoomActivity ?? this.notifRoomActivity,
        notifRoomMentions: notifRoomMentions ?? this.notifRoomMentions,
        notifReceiptExpiry: notifReceiptExpiry ?? this.notifReceiptExpiry,
        notifMonthlyDigest: notifMonthlyDigest ?? this.notifMonthlyDigest,
        notifProductUpdates: notifProductUpdates ?? this.notifProductUpdates,
        scanAutoConfirm: scanAutoConfirm ?? this.scanAutoConfirm,
        quickActionsNotifEnabled:
            quickActionsNotifEnabled ?? this.quickActionsNotifEnabled,
      );
}

class _Keys {
  static const themeMode = 'pref.themeMode'; // 'system' | 'light' | 'dark'
  static const language = 'pref.language';
  static const region = 'pref.region';
  static const currency = 'pref.currency';
  static const biometricLock = 'pref.biometricLock';
  static const hideAmounts = 'pref.hideAmounts';
  static const notifBudgetAlerts = 'pref.notif.budgetAlerts';
  static const notifBudgetWeeklyDigest = 'pref.notif.budgetWeeklyDigest';
  static const notifRoomActivity = 'pref.notif.roomActivity';
  static const notifRoomMentions = 'pref.notif.roomMentions';
  static const notifReceiptExpiry = 'pref.notif.receiptExpiry';
  static const notifMonthlyDigest = 'pref.notif.monthlyDigest';
  static const notifProductUpdates = 'pref.notif.productUpdates';
  static const scanAutoConfirm = 'pref.scan.autoConfirm';
  static const quickActionsNotifEnabled = 'pref.notif.quickActions';
  // First time this install rendered the app, epoch ms. Seeds the Rooms intro
  // day-2 engagement trigger (ADR-0005). Set once, never overwritten.
  static const firstSeenAt = 'pref.firstSeenAt';
}

ThemeMode _decodeThemeMode(String? v) {
  switch (v) {
    case 'dark':
      return ThemeMode.dark;
    case 'system':
      return ThemeMode.system;
    case 'light':
    default:
      return ThemeMode.light;
  }
}

String _encodeThemeMode(ThemeMode m) => switch (m) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };

class PreferencesNotifier extends AsyncNotifier<AppPreferences> {
  late SharedPreferences _sp;

  @override
  Future<AppPreferences> build() async {
    _sp = await SharedPreferences.getInstance();
    // Stamp first-seen once so the Rooms intro day-2 trigger has an anchor.
    if (!_sp.containsKey(_Keys.firstSeenAt)) {
      await _sp.setInt(
          _Keys.firstSeenAt, DateTime.now().millisecondsSinceEpoch);
    }
    return AppPreferences(
      themeMode: _decodeThemeMode(_sp.getString(_Keys.themeMode)),
      language: _sp.getString(_Keys.language) ?? 'id',
      region: _sp.getString(_Keys.region) ?? 'ID',
      currency: _sp.getString(_Keys.currency) ?? 'IDR',
      biometricLock: _sp.getBool(_Keys.biometricLock) ?? false,
      hideAmounts: _sp.getBool(_Keys.hideAmounts) ?? false,
      notifBudgetAlerts: _sp.getBool(_Keys.notifBudgetAlerts) ?? true,
      notifBudgetWeeklyDigest:
          _sp.getBool(_Keys.notifBudgetWeeklyDigest) ?? false,
      notifRoomActivity: _sp.getBool(_Keys.notifRoomActivity) ?? true,
      notifRoomMentions: _sp.getBool(_Keys.notifRoomMentions) ?? true,
      notifReceiptExpiry: _sp.getBool(_Keys.notifReceiptExpiry) ?? true,
      notifMonthlyDigest: _sp.getBool(_Keys.notifMonthlyDigest) ?? false,
      notifProductUpdates: _sp.getBool(_Keys.notifProductUpdates) ?? false,
      scanAutoConfirm: _sp.getBool(_Keys.scanAutoConfirm) ?? true,
      quickActionsNotifEnabled:
          _sp.getBool(_Keys.quickActionsNotifEnabled) ?? true,
    );
  }

  Future<void> _update(AppPreferences next) async {
    state = AsyncData(next);
  }

  /// First time this install rendered the app. Anchors the Rooms intro day-2
  /// trigger (ADR-0005). Null only before the first [build] completes.
  DateTime? get firstSeen {
    final ms = _sp.getInt(_Keys.firstSeenAt);
    return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }

  Future<void> setThemeMode(ThemeMode m) async {
    await _sp.setString(_Keys.themeMode, _encodeThemeMode(m));
    final cur = state.value ?? const AppPreferences();
    await _update(cur.copyWith(themeMode: m));
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      try {
        await Supabase.instance.client
            .from('users')
            .update({'theme': _encodeThemeMode(m)})
            .eq('id', user.id);
      } catch (e) {
        Log.w('Preferences', 'theme DB write failed', error: e);
      }
    }
  }

  Future<void> syncThemeFromDb(String dbValue) async {
    final cur = state.value ?? const AppPreferences();
    final m = _decodeThemeMode(dbValue);
    if (cur.themeMode == m) return;
    await _sp.setString(_Keys.themeMode, dbValue);
    await _update(cur.copyWith(themeMode: m));
  }

  Future<void> setLanguage(String v) async {
    await _sp.setString(_Keys.language, v);
    final cur = state.value ?? const AppPreferences();
    await _update(cur.copyWith(language: v));
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      try {
        await Supabase.instance.client
            .from('users')
            .update({'language': v})
            .eq('id', user.id);
      } catch (e) {
        Log.w('Preferences', 'language DB write failed', error: e);
      }
    }
  }

  Future<void> setRegion(String v) async {
    await _sp.setString(_Keys.region, v);
    final cur = state.value ?? const AppPreferences();
    await _update(cur.copyWith(region: v));
  }

  Future<void> setCurrency(String v) async {
    await _sp.setString(_Keys.currency, v);
    final cur = state.value ?? const AppPreferences();
    await _update(cur.copyWith(currency: v));
    // Write-through to DB so server-side reports + other devices pick up the
    // change. Best-effort: SharedPreferences remains the offline-safe mirror.
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      try {
        await Supabase.instance.client
            .from('users')
            .update({'home_currency': v})
            .eq('id', user.id);
      } catch (e) {
        Log.w('Preferences', 'home_currency DB write failed', error: e);
      }
    }
  }

  /// Pull DB-canonical home_currency into SharedPreferences. Called by
  /// `app.dart` from realtime updates and on `AppLifecycleState.resumed`
  /// so the local mirror eventually catches up to webhook/multi-device edits.
  Future<void> syncCurrencyFromDb(String dbValue) async {
    final cur = state.value ?? const AppPreferences();
    if (cur.currency == dbValue) return;
    await _sp.setString(_Keys.currency, dbValue);
    await _update(cur.copyWith(currency: dbValue));
  }

  /// Mirror DB-canonical `users.hide_amounts` into local cache.
  Future<void> syncHideAmountsFromDb(bool dbValue) async {
    final cur = state.value ?? const AppPreferences();
    if (cur.hideAmounts == dbValue) return;
    await _sp.setBool(_Keys.hideAmounts, dbValue);
    await _update(cur.copyWith(hideAmounts: dbValue));
  }

  /// Mirror DB-canonical `users.language` into local SharedPreferences cache.
  Future<void> syncLanguageFromDb(String dbValue) async {
    final cur = state.value ?? const AppPreferences();
    if (cur.language == dbValue) return;
    await _sp.setString(_Keys.language, dbValue);
    await _update(cur.copyWith(language: dbValue));
  }

  Future<void> setBool(String key, bool value) async {
    await _sp.setBool(key, value);
    final cur = state.value ?? const AppPreferences();
    final next = switch (key) {
      _Keys.biometricLock => cur.copyWith(biometricLock: value),
      _Keys.hideAmounts => cur.copyWith(hideAmounts: value),
      _Keys.notifBudgetAlerts => cur.copyWith(notifBudgetAlerts: value),
      _Keys.notifBudgetWeeklyDigest =>
        cur.copyWith(notifBudgetWeeklyDigest: value),
      _Keys.notifRoomActivity => cur.copyWith(notifRoomActivity: value),
      _Keys.notifRoomMentions => cur.copyWith(notifRoomMentions: value),
      _Keys.notifReceiptExpiry => cur.copyWith(notifReceiptExpiry: value),
      _Keys.notifMonthlyDigest => cur.copyWith(notifMonthlyDigest: value),
      _Keys.notifProductUpdates => cur.copyWith(notifProductUpdates: value),
      _Keys.scanAutoConfirm => cur.copyWith(scanAutoConfirm: value),
      _Keys.quickActionsNotifEnabled =>
        cur.copyWith(quickActionsNotifEnabled: value),
      _ => cur,
    };
    await _update(next);

    if (key == _Keys.hideAmounts) {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        try {
          await Supabase.instance.client
              .from('users')
              .update({'hide_amounts': value})
              .eq('id', user.id);
        } catch (e) {
          Log.w('Preferences', 'hide_amounts DB write failed', error: e);
        }
      }
    }
  }
}

final preferencesProvider =
    AsyncNotifierProvider<PreferencesNotifier, AppPreferences>(
        PreferencesNotifier.new);

/// SharedPreferences warmed by [warmPreferences] in `main()` before `runApp`,
/// so [themeModePrefProvider] / [localePrefProvider] can resolve the *saved*
/// value synchronously on the very first frame. Without it those providers fall
/// back to `light` / `id` during the async `preferencesProvider` load, and a
/// saved-dark user gets a one-frame light flash on cold start.
SharedPreferences? _bootPrefs;

/// Warm the SharedPreferences singleton ahead of the first frame. Idempotent.
Future<void> warmPreferences() async {
  _bootPrefs = await SharedPreferences.getInstance();
}

/// Synchronous theme-mode for `MaterialApp.themeMode`.
final themeModePrefProvider = Provider<ThemeMode>((ref) {
  final async = ref.watch(preferencesProvider);
  return async.maybeWhen(
    data: (p) => p.themeMode,
    orElse: () => _decodeThemeMode(_bootPrefs?.getString(_Keys.themeMode)),
  );
});

/// Synchronous locale for `MaterialApp.router.locale`.
final localePrefProvider = Provider<Locale?>((ref) {
  final lang = ref.watch(preferencesProvider).maybeWhen(
        data: (p) => p.language,
        orElse: () => _bootPrefs?.getString(_Keys.language) ?? 'id',
      );
  return switch (lang) {
    'en' => const Locale('en'),
    'id' => const Locale('id'),
    _ => null,
  };
});

/// Pref keys exposed for convenience in widgets calling [setBool].
class PrefKeys {
  static const biometricLock = _Keys.biometricLock;
  static const hideAmounts = _Keys.hideAmounts;
  static const notifBudgetAlerts = _Keys.notifBudgetAlerts;
  static const notifBudgetWeeklyDigest = _Keys.notifBudgetWeeklyDigest;
  static const notifRoomActivity = _Keys.notifRoomActivity;
  static const notifRoomMentions = _Keys.notifRoomMentions;
  static const notifReceiptExpiry = _Keys.notifReceiptExpiry;
  static const notifMonthlyDigest = _Keys.notifMonthlyDigest;
  static const notifProductUpdates = _Keys.notifProductUpdates;
  static const scanAutoConfirm = _Keys.scanAutoConfirm;
  static const quickActionsNotifEnabled = _Keys.quickActionsNotifEnabled;
}
