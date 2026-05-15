/// Compile-time environment bindings.
/// Populated via `--dart-define-from-file=env.json`.
///
/// Each [String.fromEnvironment] call resolves at compile time. Missing
/// keys fail fast with a clear error during app startup (see [Env.assertConfigured]).
class Env {
  const Env._();

  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
  );
  static const String sentryDsn = String.fromEnvironment('SENTRY_DSN');
  static const String postHogKey = String.fromEnvironment('POSTHOG_API_KEY');

  /// `"true"` swaps the real `RevenueCatPaymentService` for the in-app
  /// stub (`DummyPaymentService`) — purchases settle via a "Pretend Pay"
  /// dialog and a server-side `dummy-grant` Edge Function. Used while
  /// the Play Console developer account / RevenueCat onboarding is still
  /// being unblocked. **Must be `"false"` (or removed) before launch.**
  static const String _paymentStubRaw = String.fromEnvironment(
    'PAYMENT_STUB',
    defaultValue: 'true',
  );
  static bool get paymentStub => _paymentStubRaw.toLowerCase() == 'true';

  /// RevenueCat **public** SDK key for Android (format `goog_...`). Safe to
  /// ship in the client binary. The corresponding **secret** API key
  /// (`sk_...`) and the webhook signing secret stay server-side as Supabase
  /// Edge Function secrets (`REVENUECAT_WEBHOOK_AUTH`).
  static const String revenueCatAndroidKey = String.fromEnvironment(
    'REVENUECAT_ANDROID_KEY',
  );

  /// RevenueCat iOS SDK key (format `appl_...`). Empty until iOS launches.
  static const String revenueCatIosKey = String.fromEnvironment(
    'REVENUECAT_IOS_KEY',
  );

  /// Sentry environment tag (e.g. 'dev', 'staging', 'prod').
  static const String sentryEnv = String.fromEnvironment(
    'SENTRY_ENV',
    defaultValue: 'dev',
  );

  /// Google **Web** OAuth client ID (from Google Cloud Console → APIs &
  /// Services → Credentials → Web application). Used as `serverClientId`
  /// for `GoogleSignIn` so the issued ID token's `aud` claim matches what
  /// Supabase validates against. Safe to ship in the client binary.
  static const String googleWebClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
  );

  /// Call once at startup. Throws [StateError] if a required value is missing
  /// so misconfigured builds fail immediately instead of crashing deep in auth.
  static void assertConfigured() {
    const required = <String, String>{
      'SUPABASE_URL': supabaseUrl,
      'SUPABASE_ANON_KEY': supabaseAnonKey,
      'SENTRY_DSN': sentryDsn,
      'POSTHOG_API_KEY': postHogKey,
      'GOOGLE_WEB_CLIENT_ID': googleWebClientId,
    };
    final missing = required.entries
        .where((e) => e.value.isEmpty)
        .map((e) => e.key)
        .toList();
    if (missing.isNotEmpty) {
      throw StateError(
        'Missing compile-time env values: ${missing.join(', ')}. '
        'Run with --dart-define-from-file=env.json',
      );
    }
  }
}
