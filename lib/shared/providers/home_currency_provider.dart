import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_providers.dart';
import 'preferences_provider.dart';

/// Effective home currency for the current session.
///
/// Source priority:
/// 1. `users.home_currency` (DB) via [userProfileProvider] — canonical, written
///    by the webhook + settings screen, stays in sync across devices.
/// 2. `preferencesProvider.currency` (SharedPreferences) — local mirror, used
///    while the DB row is still loading or when offline.
/// 3. `'IDR'` — final fallback.
///
/// Call sites read this provider instead of either source directly so DB↔local
/// drift is invisible to UI code.
final homeCurrencyProvider = Provider<String>((ref) {
  final profile = ref.watch(userProfileProvider).value;
  if (profile != null && profile.homeCurrency.isNotEmpty) {
    return profile.homeCurrency;
  }
  final prefs = ref.watch(preferencesProvider).value;
  return prefs?.currency ?? 'IDR';
});
