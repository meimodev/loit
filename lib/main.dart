import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/config/env.dart';
import 'core/services/log_service.dart';
import 'firebase_options.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Env.assertConfigured();
  Log.init();

  Log.lifecycle('LOIT starting...');

  Log.lifecycle('Firebase initializing');
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  Log.lifecycle('Firebase ready');

  Log.lifecycle('Supabase initializing');
  await Supabase.initialize(
    url: Env.supabaseUrl,
    anonKey: Env.supabaseAnonKey,
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
    ),
  );
  Log.lifecycle('Supabase ready');

  // RevenueCat — initialized lazily by `RevenueCatPaymentService` the first
  // time `paymentServiceProvider` is read. RevenueCat wraps Play Billing
  // (and StoreKit on iOS later) and signs entitlement events back to us
  // through the `revenuecat-webhook` Edge Function.
  Log.d('Init', 'RevenueCat deferred to first paywall open');

  // PostHog — native init via AndroidManifest.xml. No Dart setup() needed.
  Log.lifecycle('PostHog ready (native init)');

  Log.lifecycle('Sentry initializing');
  await SentryFlutter.init((options) {
    options.dsn = Env.sentryDsn;
    options.tracesSampleRate = 0.2;
    options.profilesSampleRate = 0.2;
    options.environment = Env.sentryEnv;
  }, appRunner: () {
    Log.lifecycle('Sentry ready (env=${Env.sentryEnv})');
    Log.lifecycle('LOIT startup complete ✓');
    runApp(const ProviderScope(child: LoitApp()));
  });
}
