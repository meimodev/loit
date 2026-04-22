# LOIT — AI Build Guide
### Full Phase-by-Phase Execution Instructions

> This document is written for AI-assisted development. Every step has a clear goal, explicit file paths, complete code, and a validation checklist. Execute steps strictly in order — later steps have hard dependencies on earlier ones. Do not skip validations.

**Purpose:** Build LOIT from zero to production using Flutter + Supabase with robust offline support, OCR bill scanning, budgets, shared room finance, subscriptions, and full deployment guidance.

**Audience:** AI coding agent or developer following explicit step-by-step implementation instructions.

**Last refreshed:** April 2026
**Target stack:** Flutter 3.24+, Dart 3.8+, Riverpod 3, Supabase Flutter 2.8+, Drift 2.22+, Deno 1.45+, Claude Sonnet 4.6, Stripe 17.x, Stripe Flutter 12.x, PostHog Flutter 5.x, Sentry Flutter 8.x.

**Configuration philosophy:**
- Client-safe keys → `env.json` compiled in via `--dart-define-from-file=env.json` (not `flutter_dotenv`).
- Private secrets → Supabase Secrets / platform-native config only.
- Code generation → `dart run build_runner` (not `flutter pub run build_runner`, which is deprecated).
- Reactive state → Riverpod 3 `Notifier`/`AsyncNotifier` with code generation (`@riverpod`). `StateNotifier` is legacy.

---

## Table of Contents

1. [Prerequisites & Environment](#prerequisites--environment)
2. [Phase 1 — Personal Core (Weeks 1–8)](#phase-1--personal-core-weeks-18)
3. [Phase 2 — Shared Rooms (Weeks 9–13)](#phase-2--shared-rooms-weeks-913)
4. [Phase 3 — Pro Layer (Weeks 14–17)](#phase-3--pro-layer-weeks-1417)
5. [Phase 4 — Polish & Launch (Weeks 18–20)](#phase-4--polish--launch-weeks-1820)

---

## Prerequisites & Environment

### Accounts to Create Before Starting

| Service | Purpose | Notes |
|---|---|---|
| Supabase | Database, Auth, Storage, Edge Functions | Free tier at launch |
| Anthropic | Claude API for bill scanning | Pay-per-use |
| Firebase Cloud Messaging | Push notifications | Free at launch |
| Resend | Transactional email | Free (3,000/mo) |
| Sentry | Error monitoring | Free (5,000 errors/mo) |
| PostHog | Analytics | Free (1M events/mo) |
| Stripe | Subscriptions + one-time payments | 1.5% + Rp5,142/txn |
| Xendit | Indonesian payment methods (GoPay, OVO, DANA) | 1.5–2.9%/txn |
| Open Exchange Rates | 180+ currency FX rates (Pro/Team) | Startup plan when needed |
| Apple Developer | iOS App Store | $99/yr |
| Google Play | Android Play Store | $25 one-time |

### Local Tools Required

```bash
# Verify these are installed before starting
flutter --version       # Flutter 3.24+ stable channel (required for Dart 3.8+ and current Stripe/Firebase plugins)
dart --version          # Dart 3.8+ (bundled with recent Flutter stable)
flutterfire --version   # FlutterFire CLI (Firebase config generation for Phase 2 push notifications)
supabase --version      # Supabase CLI >=1.200 — `brew install supabase/tap/supabase`
node --version          # Node.js 20 LTS+ (required by current Supabase CLI and Stripe CLI)
deno --version          # Deno 1.45+ (for Edge Function local testing; bundled with Supabase CLI 1.190+)
stripe --version        # Stripe CLI — `brew install stripe/stripe-cli/stripe` (for webhook testing in Phase 3)
```

> Note: do **NOT** install the Supabase CLI globally with `npm install -g supabase` — that package is deprecated. Use Homebrew, Scoop, or the official installer from <https://supabase.com/docs/guides/cli/getting-started>.

### Project Environment Files — Client vs Server

LOIT uses **two separate secret stores** that must never be mixed:

| Store | Used by | Contains | Delivery mechanism |
|---|---|---|---|
| `env.json` (project root) | Flutter client ONLY | Public/anon keys only (Supabase URL, anon key, PostHog key, Sentry DSN, Stripe publishable key) | Compiled in via `--dart-define-from-file=env.json` |
| Supabase Secrets (server) | Edge Functions ONLY | All private secrets (service-role, Anthropic, Stripe secret + webhook signing, Xendit, OpenExchangeRates app ID, Resend, Firebase service account JSON) | `supabase secrets set KEY=value` |

**Why `--dart-define-from-file` and not `flutter_dotenv`?**
- Values become compile-time constants (`const String.fromEnvironment(...)`), enabling tree-shaking and dead-code elimination of unused branches.
- No runtime asset read → faster cold start on low-end Android devices (common in Indonesia).
- Works with `flutter build appbundle`/`ipa` without shipping a `.env` file inside the app bundle (which would be trivially extractable with `apktool`).
- Flutter-official pattern since Flutter 3.7.

1. Create `env.json` in the project root. **This file contains ONLY client-safe keys.** No service-role, no Anthropic, no Stripe secret:
```json
{
  "SUPABASE_URL": "https://xxxx.supabase.co",
  "SUPABASE_ANON_KEY": "eyJ...",
  "SENTRY_DSN": "https://...@sentry.io/...",
  "POSTHOG_API_KEY": "phc_...",
  "STRIPE_PUBLISHABLE_KEY": "pk_..."
}
```

2. Create `env.production.json` with the same keys but production values. `env.json` is for dev.

3. Add to `.gitignore`:
```
env.json
env.*.json
*.env
.env
```

4. Add an `env.example.json` to the repo (committed) with placeholder values so new contributors know which keys are required.

5. Server-side secrets are set **only** via the Supabase CLI (covered in Steps 1.6 and 3.1):
```bash
supabase secrets set ANTHROPIC_API_KEY=sk-ant-...
supabase secrets set STRIPE_SECRET_KEY=sk_...
supabase secrets set STRIPE_WEBHOOK_SECRET=whsec_...
supabase secrets set XENDIT_SECRET_KEY=xnd_...
supabase secrets set RESEND_API_KEY=re_...
supabase secrets set OPEN_EXCHANGE_RATES_APP_ID=...
supabase secrets set FIREBASE_SERVICE_ACCOUNT_JSON_BASE64=...
```

The `SUPABASE_URL` and `SUPABASE_SERVICE_ROLE_KEY` are **auto-injected** into every Edge Function by the Supabase runtime — do not set them manually via `secrets set` (it will be silently overridden).

### Running the App with Env Values

```bash
# Dev
flutter run --dart-define-from-file=env.json

# Production build
flutter build appbundle --dart-define-from-file=env.production.json
flutter build ipa       --dart-define-from-file=env.production.json
```

Add VS Code launch configs in `.vscode/launch.json` for one-click runs:
```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "LOIT (dev)",
      "request": "launch",
      "type": "dart",
      "toolArgs": ["--dart-define-from-file=env.json"]
    },
    {
      "name": "LOIT (prod)",
      "request": "launch",
      "type": "dart",
      "toolArgs": ["--dart-define-from-file=env.production.json"],
      "flutterMode": "release"
    }
  ]
}
```

---

## Phase 1 — Personal Core (Weeks 1–8)

**Goal:** A fully working personal finance tracker. No shared features. This phase must be self-contained and valuable even if a user never creates or joins a room.

---

### Step 1.1 — Flutter Project Scaffolding

**Goal:** Create the Flutter project with the correct folder structure, modern dependency versions (Riverpod 3, Supabase Flutter 2.8+, Drift 2.22+), platform permissions configured, and all services initialized correctly at startup.

**Actions:**

1. Create the project:
```bash
flutter create loit_app --org com.loit --platforms ios,android
cd loit_app
```

2. Replace the `dependencies` and `dev_dependencies` sections in `pubspec.yaml`.
   Versions below are current as of April 2026 — run `flutter pub outdated` after pasting to catch any newer constraints:
```yaml
environment:
  sdk: ">=3.8.0 <4.0.0"
  flutter: ">=3.24.0"

dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter

  # Supabase (client SDK — auth, realtime, storage, postgrest, functions)
  supabase_flutter: ^2.8.0

  # State management — Riverpod 3 (Notifier/AsyncNotifier API, code-gen first)
  flutter_riverpod: ^3.0.0
  riverpod_annotation: ^3.0.0

  # Navigation — declarative routing with deep-link support (used for Phase 2 invite links)
  go_router: ^14.6.0

  # HTTP — used for Edge Function calls and FX providers
  http: ^1.2.2

  # Offline storage — SQLite queue for transactions added while offline
  drift: ^2.22.0
  sqlite3_flutter_libs: ^0.5.26
  path_provider: ^2.1.5
  path: ^1.9.0

  # Image handling — scanner compression + receipt uploads
  image_picker: ^1.1.2
  image: ^4.3.0

  # Charts — budget/spending reports
  fl_chart: ^0.69.2

  # Locale-aware formatting (currency, dates, numbers)
  intl: ^0.20.2

  # Push notifications — Firebase Cloud Messaging (Riverpod 3 compatible)
  firebase_core: ^4.7.0
  firebase_messaging: ^16.2.0

  # Payments — Stripe Flutter for non-Indonesian markets
  flutter_stripe: ^12.6.0

  # Error monitoring — Sentry Flutter v8 (with source maps + release tracking)
  sentry_flutter: ^8.10.0

  # Product analytics — PostHog Flutter v5 (Notifier-friendly, background queueing)
  posthog_flutter: ^5.0.0

  # Secure token storage (used for Supabase session persistence fallback + biometric gate)
  flutter_secure_storage: ^9.2.2

  # Connectivity detection — drives offline UI and triggers sync-on-reconnect
  connectivity_plus: ^6.1.0

  # Scanner hardware + QR
  camera: ^0.11.0+2
  qr_flutter: ^4.1.0
  mobile_scanner: ^5.2.3

  # Biometric app lock (Face ID / Touch ID / Android BiometricPrompt)
  local_auth: ^2.3.0

  # URL launcher — opens Stripe/Xendit checkout pages
  url_launcher: ^6.3.1

  # Deep linking (Phase 2 invite flow) — handles uni_links + custom schemes + universal links
  app_links: ^6.3.2

  # Export
  csv: ^6.0.0
  pdf: ^3.11.1
  printing: ^5.13.2
  share_plus: ^10.1.2

dev_dependencies:
  flutter_test:
    sdk: flutter
  build_runner: ^2.4.13
  custom_lint: ^0.8.1
  riverpod_generator: ^3.0.0
  riverpod_lint: ^3.0.0
  drift_dev: ^2.22.0
  flutter_lints: ^5.0.0

flutter:
  uses-material-design: true
  generate: true   # enables gen_l10n for Phase 4 localization
```

3. Install:
```bash
flutter pub get
```

4. Create folder structure:
```bash
mkdir -p lib/core/{config,services,utils,theme,routing}
mkdir -p lib/features/{auth,dashboard,transactions,budgets,reports,scanner,rooms,room_detail,settings,paywall}
mkdir -p lib/shared/{widgets,models,providers}
mkdir -p lib/l10n
mkdir -p supabase/{functions,migrations}
mkdir -p assets/icons
```

5. Create `lib/core/config/env.dart` using compile-time constants:
```dart
/// Compile-time environment bindings.
/// Populated via `--dart-define-from-file=env.json`.
///
/// Each [String.fromEnvironment] call resolves at compile time. Missing
/// keys fail fast with a clear error during app startup (see [Env.assertConfigured]).
class Env {
  const Env._();

  static const String supabaseUrl      = String.fromEnvironment('SUPABASE_URL');
  static const String supabaseAnonKey  = String.fromEnvironment('SUPABASE_ANON_KEY');
  static const String sentryDsn        = String.fromEnvironment('SENTRY_DSN');
  static const String postHogKey       = String.fromEnvironment('POSTHOG_API_KEY');
  static const String stripePublishableKey = String.fromEnvironment('STRIPE_PUBLISHABLE_KEY');

  /// Call once at startup. Throws [StateError] if a required value is missing
  /// so misconfigured builds fail immediately instead of crashing deep in auth.
  static void assertConfigured() {
    const required = <String, String>{
      'SUPABASE_URL'          : supabaseUrl,
      'SUPABASE_ANON_KEY'     : supabaseAnonKey,
      'SENTRY_DSN'            : sentryDsn,
      'POSTHOG_API_KEY'       : postHogKey,
      'STRIPE_PUBLISHABLE_KEY': stripePublishableKey,
    };
    final missing = required.entries.where((e) => e.value.isEmpty).map((e) => e.key).toList();
    if (missing.isNotEmpty) {
      throw StateError(
        'Missing compile-time env values: ${missing.join(', ')}. '
        'Run with --dart-define-from-file=env.json',
      );
    }
  }
}
```

6. Initialize services in `lib/main.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:posthog_flutter/posthog_flutter.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_stripe/flutter_stripe.dart' as stripe;

import 'core/config/env.dart';
import 'firebase_options.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Env.assertConfigured();

  // Firebase — required for Firebase Messaging token registration and push opens.
  // `firebase_options.dart` is generated by `flutterfire configure`.
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Supabase — must be initialized before any widget uses `Supabase.instance`.
  // authFlowType: pkce is required for OAuth deep-link callbacks on iOS/Android.
  await Supabase.initialize(
    url: Env.supabaseUrl,
    anonKey: Env.supabaseAnonKey,
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
    ),
  );

  // Stripe Flutter — publishable key only. The secret key stays server-side.
  stripe.Stripe.publishableKey = Env.stripePublishableKey;
  await stripe.Stripe.instance.applySettings();

  // PostHog — native init is configured in Info.plist / AndroidManifest.xml
  // (see steps 7–8 below). With native-only init, no Dart setup() call is needed;
  // the SDK auto-initializes on first use. Identification happens on login
  // (see Analytics.login in Step 1.10).

  // Sentry — wraps runApp to capture uncaught zone errors.
  await SentryFlutter.init(
    (options) {
      options.dsn = Env.sentryDsn;
      options.tracesSampleRate = 0.2;        // 20% of transactions
      options.profilesSampleRate = 0.2;
      options.environment = const String.fromEnvironment('SENTRY_ENV', defaultValue: 'dev');
    },
    appRunner: () => runApp(const ProviderScope(child: LoitApp())),
  );
}
```

Before the first build, generate Firebase config and native platform files:
```bash
dart pub global activate flutterfire_cli
flutterfire configure \
  --project=<your-firebase-project-id> \
  --platforms=android,ios \
  --ios-bundle-id=com.loit \
  --android-package-name=com.loit
```

This generates `lib/firebase_options.dart` and wires Firebase into `android/` + `ios/`. After running it, verify:
- `android/app/google-services.json` exists
- `ios/Runner/GoogleService-Info.plist` exists
- `android/app/build.gradle` contains the Google Services plugin

7. **iOS platform config** — edit `ios/Runner/Info.plist` and add inside the top-level `<dict>`:
```xml
<!-- Camera + photo library permissions (scanner + receipt upload) -->
<key>NSCameraUsageDescription</key>
<string>LOIT uses your camera to scan receipts.</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>LOIT needs access to your photos to upload receipts.</string>

<!-- FaceID (local_auth biometric lock) -->
<key>NSFaceIDUsageDescription</key>
<string>LOIT uses Face ID to unlock your finance data.</string>

<!-- PostHog v5 native init — replaces the deprecated Posthog().setup() call -->
<key>com.posthog.posthog.API_KEY</key>
<string>$(POSTHOG_API_KEY)</string>
<key>com.posthog.posthog.POSTHOG_HOST</key>
<string>https://us.i.posthog.com</string>

<!-- Deep link scheme for Supabase OAuth + Phase 2 invite links -->
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleTypeRole</key><string>Editor</string>
    <key>CFBundleURLName</key><string>com.loit</string>
    <key>CFBundleURLSchemes</key>
    <array><string>com.loit</string></array>
  </dict>
</array>
```

> `$(POSTHOG_API_KEY)` is resolved from your Xcode build settings — add an entry in `ios/Runner/Runner.xcconfig` for each build configuration. If you prefer not to use xcconfig, paste the literal key.

8. **Android platform config** — edit `android/app/src/main/AndroidManifest.xml`:

Inside `<manifest>` (top-level, before `<application>`):
```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.USE_BIOMETRIC" />
<uses-permission android:name="android.permission.USE_FINGERPRINT" />
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
```

Inside `<application>`:
```xml
<!-- PostHog v5 native init -->
<meta-data
  android:name="com.posthog.posthog.API_KEY"
  android:value="${POSTHOG_API_KEY}" />
<meta-data
  android:name="com.posthog.posthog.POSTHOG_HOST"
  android:value="https://us.i.posthog.com" />
```

Inside the `MainActivity` `<activity>` block, add intent filters for OAuth + invite deep links:
```xml
<intent-filter android:autoVerify="true">
  <action android:name="android.intent.action.VIEW" />
  <category android:name="android.intent.category.DEFAULT" />
  <category android:name="android.intent.category.BROWSABLE" />
  <data android:scheme="com.loit" android:host="callback" />
</intent-filter>
```

In `android/app/build.gradle`, inside `defaultConfig { ... }`:
```gradle
manifestPlaceholders += [
  POSTHOG_API_KEY: project.findProperty("POSTHOG_API_KEY") ?: ""
]
minSdkVersion 23      // required by flutter_stripe and local_auth biometrics
targetSdkVersion 34
compileSdkVersion 35
```

> `flutterfire configure` normally inserts the Firebase native config automatically. If Android push notifications still do not work, verify `android/app/build.gradle` applies `com.google.gms.google-services` and that `google-services.json` is present.

Pass `POSTHOG_API_KEY` at build time:
```bash
flutter build appbundle --dart-define-from-file=env.production.json \
  --android-project-arg=POSTHOG_API_KEY=phc_...
```

**Validation:**
- [ ] `flutter doctor` — no errors
- [ ] `flutter pub get` — completes without errors (no version conflicts from Riverpod 3 migration)
- [ ] Folder structure matches list above
- [ ] `flutter run --dart-define-from-file=env.json` boots on both iOS simulator and Android emulator without hitting `Env.assertConfigured()` throw
- [ ] Camera permission prompt appears on first scan attempt (iOS + Android)
- [ ] PostHog dashboard → Live Events shows the app's heartbeat immediately after launch

---

### Step 1.2 — Supabase Project Setup

**Goal:** Initialize the Supabase project, enable auth providers (with correct PKCE redirect URLs), enable required PostgreSQL extensions, and pre-create the Storage bucket plus keep-alive placeholder file that Step 4.3 will ping.

**Actions:**

1. Log in and link project (replace `YOUR_PROJECT_REF` with the 20-char ID from the Supabase URL, e.g. `abcd1234wxyz...`):
```bash
supabase login
supabase link --project-ref YOUR_PROJECT_REF
supabase init          # only needed on first run — creates supabase/config.toml
```

2. **Enable auth providers** — Supabase Dashboard → Authentication → Providers:
   - **Email** — keep enabled (default). Under settings, toggle on "Confirm email" for production.
   - **Google** — enable, then paste Google Cloud OAuth 2.0 client ID + secret. Create the client in [Google Cloud Console](https://console.cloud.google.com/apis/credentials) with type "iOS" AND "Web application" (both are required — web for the Supabase exchange, iOS for the native deep link).
   - **Apple** — enable, paste Apple Services ID, Team ID, Key ID, and the `.p8` private key contents. Required for App Store review.

3. **Configure redirect URLs** — Dashboard → Authentication → URL Configuration:
   - **Site URL** — `com.loit://callback` (must match the `CFBundleURLSchemes` / Android intent filter from Step 1.1)
   - **Redirect URLs** (one per line):
     ```
     com.loit://callback
     com.loit://callback/**
     ```
   - Without both entries, PKCE OAuth returns will fail with `redirect_uri not allowed`.

4. **Enable required PostgreSQL extensions** — run in Supabase Dashboard → SQL Editor:
```sql
-- Required for updated_at auto-trigger (Step 1.3)
CREATE EXTENSION IF NOT EXISTS moddatetime;

-- Required for gen_random_uuid() column defaults (bundled with Supabase but explicit is safer)
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Required by Phase 3 receipt-expiry cron (pg_cron) and Phase 4 keep-alive
CREATE EXTENSION IF NOT EXISTS pg_cron;
```

5. **Create the `receipts` Storage bucket and `.keep` placeholder** (prevents a 404 on the Phase 4 keep-alive cron, which HEADs this file every 3 days):

   Option A — via Dashboard:
   - Storage → New Bucket → name `receipts`, visibility **Private**
   - Public access: off
   - Allowed MIME types: `image/jpeg, image/png`
   - Max file size: `5 MB`
   - Upload a zero-byte file manually at path `.keep`

   Option B — via CLI (Supabase CLI 1.200+):
```bash
# Create bucket (private, 5 MB limit, JPEG/PNG only)
supabase storage create-bucket receipts \
  --visibility private \
  --file-size-limit 5MB \
  --allowed-mime-types image/jpeg,image/png

# Upload the placeholder
echo "" > /tmp/.keep
supabase storage cp /tmp/.keep "supabase://receipts/.keep"
```

> The CLI scheme changed from `ss:///` to `supabase://` in CLI 1.175+. Use `supabase storage --help` to confirm for your installed version.

**Validation:**
- [ ] `supabase status` returns linked project info (no "project not linked" error)
- [ ] Google and Apple auth providers show green-enabled in Dashboard
- [ ] Test OAuth from the simulator: tapping Google sign-in opens the browser and returns to the app via `com.loit://callback` without "redirect_uri not allowed"
- [ ] `receipts` bucket exists, is **Private**, and allows only `image/jpeg`/`image/png`
- [ ] `.keep` file exists at the bucket root (`supabase storage ls supabase://receipts` shows it)
- [ ] `moddatetime`, `pgcrypto`, `pg_cron` extensions show as enabled in Dashboard → Database → Extensions

---

### Step 1.3 — Phase 1 Database Schema

**Goal:** Create all Phase 1 tables with correct types, constraints, triggers, and the auto-user-creation trigger.

Create `supabase/migrations/20240101000000_phase1_schema.sql`:

```sql
-- ================================================================
-- USERS TABLE
-- ================================================================
CREATE TABLE users (
  id                    uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  email                 text UNIQUE NOT NULL,
  name                  text NOT NULL,
  avatar_url            text,
  home_currency         text DEFAULT 'IDR',
  tier                  text DEFAULT 'free' CHECK (tier IN ('free', 'pro', 'team')),
  scans_used_this_month int DEFAULT 0,
  -- Use timestamptz (not date) to avoid timezone edge cases at month boundary
  -- (e.g. Dec 31 23:59 UTC+7 is Jan 1 in UTC — date type would mishandle this)
  scan_reset_date       timestamptz DEFAULT date_trunc('month', now()),
  has_used_demo_scan    boolean DEFAULT false,
  created_at            timestamptz DEFAULT now()
);

-- ================================================================
-- TRANSACTIONS TABLE
-- ================================================================
CREATE TABLE transactions (
  id                   uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id              uuid REFERENCES users(id) ON DELETE CASCADE,
  room_id              uuid,  -- FK to rooms added via ALTER TABLE in Phase 2 migration
  merchant             text,
  amount               numeric NOT NULL,
  currency             text NOT NULL,
  amount_home_currency numeric,
  fx_rate              numeric,
  category             text,
  notes                text,
  receipt_url          text,    -- Stores storage path (not signed URL); re-sign on each view
  receipt_expires_at   timestamptz,
  ai_parsed            boolean DEFAULT false,
  is_manual_fallback   boolean DEFAULT false,
  -- Set by Flutter client at moment of save; used for offline conflict resolution
  client_updated_at    timestamptz,
  -- Managed by moddatetime trigger; server-side conflict resolution wins over older client_updated_at
  updated_at           timestamptz DEFAULT now(),
  created_at           timestamptz DEFAULT now()
);

-- Auto-update updated_at on every row UPDATE
CREATE TRIGGER set_transactions_updated_at
  BEFORE UPDATE ON transactions
  FOR EACH ROW
  EXECUTE FUNCTION moddatetime(updated_at);

-- ================================================================
-- TRANSACTION ITEMS TABLE
-- Line items extracted by AI scanner (name, qty, unit_price, total_price).
-- Stored alongside each scanned transaction for future feature use.
-- ================================================================
CREATE TABLE transaction_items (
  id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  transaction_id uuid REFERENCES transactions(id) ON DELETE CASCADE NOT NULL,
  name           text NOT NULL,
  qty            numeric DEFAULT 1,
  unit_price     numeric,
  total_price    numeric,
  created_at     timestamptz DEFAULT now()
);

-- ================================================================
-- BUDGETS TABLE
-- ================================================================
CREATE TABLE budgets (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id       uuid REFERENCES users(id) ON DELETE CASCADE,
  category      text NOT NULL,
  monthly_limit numeric NOT NULL,
  created_at    timestamptz DEFAULT now(),
  UNIQUE(user_id, category)
);

-- ================================================================
-- FX RATES CACHE TABLE
-- Staleness is tier-aware (checked in currency_service.dart):
--   Free tier (Frankfurter):          stale after 25 hours
--   Pro/Team tier (Open Exchange Rates): stale after 35 minutes
-- If provider is unreachable, stale cached rate is used with
-- "Rates may be outdated" label shown in UI.
-- ================================================================
CREATE TABLE fx_rates (
  base_currency   text NOT NULL,
  target_currency text NOT NULL,
  rate            numeric NOT NULL,
  fetched_at      timestamptz DEFAULT now(),
  PRIMARY KEY (base_currency, target_currency)
);

-- ================================================================
-- AUTO-CREATE PUBLIC USER ROW ON AUTH SIGNUP
-- Mirrors auth.users → public.users automatically.
-- ================================================================
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  INSERT INTO public.users (id, email, name, avatar_url)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'full_name', split_part(NEW.email, '@', 1)),
    NEW.raw_user_meta_data->>'avatar_url'
  );
  RETURN NEW;
END;
$$;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION handle_new_user();

-- ================================================================
-- PERFORMANCE INDEXES
-- The most common query patterns are:
--   1. "list my transactions, newest first"            → (user_id, created_at DESC)
--   2. "list transactions in a room, newest first"     → (room_id, created_at DESC)
--   3. "find transaction by id with items"             → FK on transaction_items already covers it
--   4. "my budget for a category"                      → UNIQUE(user_id, category) already covers it
-- Partial index on room_id skips the ~90% of rows that have room_id = NULL
-- (personal-only transactions), keeping the room index small and fast.
-- ================================================================
CREATE INDEX idx_transactions_user_created
  ON transactions (user_id, created_at DESC);

CREATE INDEX idx_transactions_room_created
  ON transactions (room_id, created_at DESC)
  WHERE room_id IS NOT NULL;

CREATE INDEX idx_transactions_receipt_expiry
  ON transactions (receipt_expires_at)
  WHERE receipt_url IS NOT NULL;  -- used by receipt-expiry-cron (Phase 3)

CREATE INDEX idx_transaction_items_txn
  ON transaction_items (transaction_id);
```

Apply:
```bash
supabase db push
```

**Validation:**
- [ ] All 5 tables exist in Dashboard → Table Editor
- [ ] `transactions.updated_at` column exists (type: `timestamptz`)
- [ ] `moddatetime` trigger `set_transactions_updated_at` exists on `transactions`
- [ ] `transaction_items` table exists with FK to `transactions(id) ON DELETE CASCADE`
- [ ] `users.scan_reset_date` is `timestamptz` (NOT `date`)
- [ ] Sign up a test user → row auto-appears in `public.users`

---

### Step 1.4 — Row Level Security (RLS)

**Goal:** Enforce that users can only access their own data. Every table must have RLS enabled.

Create `supabase/migrations/20240101000001_phase1_rls.sql`:

```sql
-- Enable RLS on all Phase 1 tables
ALTER TABLE users             ENABLE ROW LEVEL SECURITY;
ALTER TABLE transactions      ENABLE ROW LEVEL SECURITY;
ALTER TABLE transaction_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE budgets           ENABLE ROW LEVEL SECURITY;
ALTER TABLE fx_rates          ENABLE ROW LEVEL SECURITY;

-- ----------------------------------------------------------------
-- USERS
-- ----------------------------------------------------------------
CREATE POLICY "users_select_own" ON users
  FOR SELECT USING (auth.uid() = id);

CREATE POLICY "users_update_own" ON users
  FOR UPDATE USING (auth.uid() = id);

-- ----------------------------------------------------------------
-- TRANSACTIONS (personal only — extended in Phase 2 for rooms)
-- ----------------------------------------------------------------
CREATE POLICY "transactions_select_own" ON transactions
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "transactions_insert_own" ON transactions
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "transactions_update_own" ON transactions
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "transactions_delete_own" ON transactions
  FOR DELETE USING (auth.uid() = user_id);

-- ----------------------------------------------------------------
-- TRANSACTION ITEMS (accessible if parent transaction is owned by user)
-- ----------------------------------------------------------------
CREATE POLICY "items_select_own" ON transaction_items
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM transactions t
      WHERE t.id = transaction_id AND t.user_id = auth.uid()
    )
  );

CREATE POLICY "items_insert_own" ON transaction_items
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM transactions t
      WHERE t.id = transaction_id AND t.user_id = auth.uid()
    )
  );

CREATE POLICY "items_delete_own" ON transaction_items
  FOR DELETE USING (
    EXISTS (
      SELECT 1 FROM transactions t
      WHERE t.id = transaction_id AND t.user_id = auth.uid()
    )
  );

-- ----------------------------------------------------------------
-- BUDGETS
-- ----------------------------------------------------------------
CREATE POLICY "budgets_select_own" ON budgets
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "budgets_insert_own" ON budgets
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "budgets_update_own" ON budgets
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "budgets_delete_own" ON budgets
  FOR DELETE USING (auth.uid() = user_id);

-- ----------------------------------------------------------------
-- FX RATES (all authenticated users can read; only service role writes)
-- ----------------------------------------------------------------
CREATE POLICY "fx_rates_select_all" ON fx_rates
  FOR SELECT USING (auth.role() = 'authenticated');
```

**Validation:**
- [ ] RLS enabled on all 5 tables (green shield in Dashboard)
- [ ] User A cannot read User B's transactions (test with two test accounts)
- [ ] User A cannot read User B's budgets

---

### Step 1.5 — Scan Quota SQL Functions

**Goal:** Create atomic, race-condition-safe quota enforcement functions called by the scan-receipt Edge Function.

Create `supabase/migrations/20240101000002_scan_quota_functions.sql`:

```sql
-- ================================================================
-- RESET SCAN QUOTA (safe month boundary — year-safe comparison)
-- Compares both year AND month to handle December → January correctly.
-- ================================================================
CREATE OR REPLACE FUNCTION reset_scan_quota_if_new_month(p_user_id uuid)
RETURNS void LANGUAGE plpgsql AS $$
BEGIN
  UPDATE users
  SET
    scans_used_this_month = 0,
    scan_reset_date       = date_trunc('month', now())
  WHERE id = p_user_id
    AND (
      EXTRACT(YEAR  FROM now()) != EXTRACT(YEAR  FROM scan_reset_date) OR
      EXTRACT(MONTH FROM now()) != EXTRACT(MONTH FROM scan_reset_date)
    );
END;
$$;

-- ================================================================
-- ATOMIC QUOTA INCREMENT
-- Only increments if current count < limit.
-- Returns new count, or NULL if quota is already at limit.
-- Single UPDATE...RETURNING eliminates the race condition of
-- a read-then-check flow allowing two simultaneous requests through.
-- ================================================================
CREATE OR REPLACE FUNCTION increment_scan_quota(p_user_id uuid, p_limit int)
RETURNS int LANGUAGE plpgsql AS $$
DECLARE
  new_count int;
BEGIN
  UPDATE users
  SET scans_used_this_month = scans_used_this_month + 1
  WHERE id = p_user_id
    AND scans_used_this_month < p_limit
  RETURNING scans_used_this_month INTO new_count;

  RETURN new_count; -- NULL means quota was already at limit (no row updated)
END;
$$;
```

Apply:
```bash
supabase db push
```

**Validation:**
- [ ] Both functions exist in Dashboard → Database → Functions
- [ ] `increment_scan_quota` with `p_limit=1`: first call returns `1`, second returns `NULL`
- [ ] `reset_scan_quota_if_new_month`: calling twice in the same month has no effect on second call

---

### Step 1.6 — Edge Function: scan-receipt

**Goal:** Server-side proxy that (1) validates the caller's JWT, (2) enforces the monthly scan quota atomically, (3) calls the Claude Sonnet 4.6 vision API with the user's compressed receipt image, and (4) returns a typed, structured response. The Anthropic API key never ships with the mobile binary.

**Why server-side?** If the Anthropic API key were bundled in the Flutter client, an attacker could extract it via `apktool`, `strings`, or IPA decryption and drain the billing account in minutes. This Edge Function holds the key behind Supabase's JWT auth wall.

Create `supabase/functions/scan-receipt/index.ts`:

```typescript
// Deno runtime. Supabase Edge Functions run on Deno 1.45+.
// Pin dependency versions — `npm:` specifiers without a version pick
// whatever is cached, which breaks reproducibility across deployments.
import { serve } from 'https://deno.land/std@0.224.0/http/server.ts';
import Anthropic from 'npm:@anthropic-ai/sdk@0.32.1';
import { createClient } from 'npm:@supabase/supabase-js@2.46.1';

const anthropic = new Anthropic({ apiKey: Deno.env.get('ANTHROPIC_API_KEY')! });

// Service-role client — bypasses RLS. Only used for quota increment
// and the demo-scan flag update. All user-scoped reads validate JWT first.
const supabase = createClient(
  Deno.env.get('SUPABASE_URL')!,
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
);

// CORS — the Edge Function is called directly from the Flutter app via HTTPS,
// and during dev from the Supabase Studio function tester (browser origin).
// Without these headers the browser-based tester fails with CORS errors.
const CORS_HEADERS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

const SCANNER_PROMPT = `You are a receipt parsing assistant. Analyze the receipt image and return ONLY valid JSON.
Do not include any explanation, preamble, or markdown formatting.

{
  "merchant": "",
  "address": "",
  "date": "YYYY-MM-DD",
  "time": "HH:MM",
  "currency": "ISO 4217 code",
  "items": [
    { "name": "", "qty": 1, "unit_price": 0.00, "total_price": 0.00 }
  ],
  "subtotal": 0.00,
  "tax": 0.00,
  "tip": 0.00,
  "total": 0.00,
  "payment_method": "",
  "category": "dining|groceries|transport|shopping|entertainment|utilities|health|travel|other"
}

If any field cannot be determined, use null. Never guess — use null if unsure.`;

/**
 * Extract partial fields from malformed AI response using targeted regex patterns.
 * This runs server-side so the client receives a clean structured object,
 * not raw unparseable text that would require unsafe client-side parsing.
 */
function extractPartialFields(rawText: string): Record<string, unknown> {
  const partial: Record<string, unknown> = {};

  const patterns: [string, RegExp][] = [
    ['merchant',       /"merchant"\s*:\s*"([^"]+)"/],
    ['date',           /"date"\s*:\s*"(\d{4}-\d{2}-\d{2})"/],
    ['total',          /"total"\s*:\s*([\d.]+)/],
    ['currency',       /"currency"\s*:\s*"([A-Z]{3})"/],
    ['category',       /"category"\s*:\s*"([^"]+)"/],
    ['tax',            /"tax"\s*:\s*([\d.]+)/],
    ['subtotal',       /"subtotal"\s*:\s*([\d.]+)/],
    ['payment_method', /"payment_method"\s*:\s*"([^"]+)"/],
  ];

  for (const [key, regex] of patterns) {
    const match = rawText.match(regex);
    if (match) partial[key] = match[1];
  }

  // Attempt to salvage the items array even if the outer JSON is broken
  const itemsMatch = rawText.match(/"items"\s*:\s*(\[[\s\S]*?\])/);
  if (itemsMatch) {
    try {
      partial['items'] = JSON.parse(itemsMatch[1]);
    } catch {
      // Items array is also malformed — skip, don't include
    }
  }

  return partial;
}

async function getUserFromJWT(
  req: Request,
): Promise<{ id: string; tier: string; has_used_demo_scan: boolean } | null> {
  const authHeader = req.headers.get('Authorization');
  if (!authHeader) return null;

  const token = authHeader.replace('Bearer ', '');
  const { data: { user }, error } = await supabase.auth.getUser(token);
  if (error || !user) return null;

  const { data: profile } = await supabase
    .from('users')
    .select('tier, has_used_demo_scan')
    .eq('id', user.id)
    .single();

  return {
    id: user.id,
    tier: profile?.tier ?? 'free',
    has_used_demo_scan: profile?.has_used_demo_scan ?? false,
  };
}

async function incrementQuotaIfAllowed(userId: string, tier: string): Promise<boolean> {
  const limits: Record<string, number> = { free: 8, pro: 50, team: 999999 };
  const limit = limits[tier] ?? 8;

  await supabase.rpc('reset_scan_quota_if_new_month', { p_user_id: userId });

  const { data, error } = await supabase.rpc('increment_scan_quota', {
    p_user_id: userId,
    p_limit: limit,
  });

  return !!data && !error;
}

function jsonResponse(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { 'Content-Type': 'application/json', ...CORS_HEADERS },
  });
}

serve(async (req) => {
  // CORS preflight (fires automatically from browser-based tools)
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: CORS_HEADERS });
  }
  if (req.method !== 'POST') {
    return new Response('Method Not Allowed', { status: 405, headers: CORS_HEADERS });
  }

  const user = await getUserFromJWT(req);
  if (!user) return jsonResponse({ error: 'Unauthorized' }, 401);

  let body: { image?: string; is_demo?: boolean };
  try {
    body = await req.json();
  } catch {
    return jsonResponse({ error: 'Invalid JSON body' }, 400);
  }
  const { image, is_demo } = body;
  if (!image) return jsonResponse({ error: 'Missing image' }, 400);

  // Defensive cap: refuse payloads > ~8 MB base64 (≈6 MB decoded).
  // Flutter compresses to <500 KB, so anything larger is a bug or abuse.
  if (image.length > 8 * 1024 * 1024) {
    return jsonResponse({ error: 'Image too large' }, 413);
  }

  // Demo scan: free for the very first attempt only, even on free tier.
  const isDemoScan = is_demo === true && !user.has_used_demo_scan;

  if (!isDemoScan) {
    const allowed = await incrementQuotaIfAllowed(user.id, user.tier);
    if (!allowed) return jsonResponse({ error: 'Quota exceeded' }, 402);
  } else {
    await supabase
      .from('users')
      .update({ has_used_demo_scan: true })
      .eq('id', user.id);
  }

  try {
    const result = await anthropic.messages.create({
      // Claude Sonnet 4.6 — current latest as of April 2026.
      // See https://platform.claude.com/docs/en/about-claude/models/overview
      // If upgrading, prefer dated IDs like `claude-sonnet-4-6-20260318` for
      // deterministic builds.
      model: 'claude-sonnet-4-6',
      max_tokens: 1024,
      messages: [{
        role: 'user',
        content: [
          { type: 'image', source: { type: 'base64', media_type: 'image/jpeg', data: image } },
          { type: 'text', text: SCANNER_PROMPT },
        ],
      }],
    });

    const text = result.content[0]?.type === 'text' ? result.content[0].text : '';

    try {
      const parsed = JSON.parse(text);
      return jsonResponse(parsed, 200);
    } catch {
      // AI returned unparseable JSON — extract partial fields server-side
      // so the Flutter client receives a safe structured object, not raw text.
      const partialFields = extractPartialFields(text);
      return jsonResponse({ ai_failure: true, partial_fields: partialFields }, 422);
    }
  } catch (err) {
    console.error('Claude API error:', err);
    // 500 = upstream/connection error → client shows retry screen (NOT manual entry form).
    return jsonResponse({ error: 'Scan service unavailable' }, 500);
  }
});
```

Deploy:
```bash
supabase functions deploy scan-receipt

# Set server-side secrets (never in Flutter client binary).
# SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY are auto-injected — do not set manually.
supabase secrets set ANTHROPIC_API_KEY=sk-ant-...
```

Local testing (optional, recommended before first deploy):
```bash
supabase functions serve scan-receipt --env-file ./supabase/functions/.env
# Then curl from another terminal:
curl -X POST http://localhost:54321/functions/v1/scan-receipt \
  -H "Authorization: Bearer <your_anon_or_session_token>" \
  -H "Content-Type: application/json" \
  -d '{"image":"<base64>","is_demo":true}'
```

**Validation:**
- [ ] Function deploys without error
- [ ] Valid JWT + real receipt image → 200 with parsed JSON
- [ ] Blurry/non-receipt image → 422 with `partial_fields` structured object (not raw text)
- [ ] Invalid/expired JWT → 401
- [ ] Exhausted quota → 402
- [ ] First-time demo scan with `is_demo: true` → succeeds, doesn't decrement quota
- [ ] Second demo attempt with `is_demo: true` on same account → counted against quota normally

---

### Step 1.7 — Flutter: ScannerService

**Goal:** Client-side pipeline that (1) loads the captured photo from disk, (2) compresses it to a 720p-bounded JPEG to keep the Claude vision bill down and upload fast on Indonesian 3G, (3) calls the Edge Function from Step 1.6, and (4) maps every HTTP response code to a typed [ScanResult] so the UI can make safe decisions without parsing raw text.

**Design notes (important for UI layer):**
- `ScanErrorType.aiFailure` (422) means the image uploaded fine but Claude could not produce valid JSON — open the manual-entry form and pre-fill whatever `partial_fields` the server was able to recover.
- `ScanErrorType.connectionError` and `ScanErrorType.serverError` should NOT open the manual entry form — show a retry screen. A scan that never reached Anthropic should not silently turn into a manual-entry flow; otherwise users blame the app when the network was at fault.
- Compression runs on the main isolate. Consider `compute()` if you ever see jank on low-end Androids during the scan → confirm flow.

Create `lib/core/services/scanner_service.dart`:

```dart
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/env.dart';

enum ScanErrorType {
  aiFailure,       // 422 — open manual entry form with pre-filled fields
  quotaExceeded,   // 402 — show upgrade/top-up prompt
  connectionError, // No internet — show retry button; do NOT open manual entry
  serverError,     // 5xx — show retry button; do NOT open manual entry
}

class ScanResult {
  final bool success;
  final Map<String, dynamic>? parsedData;
  final Map<String, dynamic>? partialFields;
  final ScanErrorType? errorType;

  const ScanResult._({
    required this.success,
    this.parsedData,
    this.partialFields,
    this.errorType,
  });

  factory ScanResult.success(Map<String, dynamic> data) =>
      ScanResult._(success: true, parsedData: data);

  factory ScanResult.aiFailure(Map<String, dynamic> partial) =>
      ScanResult._(success: false, partialFields: partial, errorType: ScanErrorType.aiFailure);

  factory ScanResult.quotaExceeded() =>
      ScanResult._(success: false, errorType: ScanErrorType.quotaExceeded);

  factory ScanResult.connectionError() =>
      ScanResult._(success: false, errorType: ScanErrorType.connectionError);

  factory ScanResult.serverError() =>
      ScanResult._(success: false, errorType: ScanErrorType.serverError);
}

class ScannerService {
  static const int _maxLongSide = 1280; // cap longest edge; other edge scales proportionally
  static const int _jpegQuality = 85;   // visually lossless for receipts, ~60% smaller than quality 100

  /// Decode → downscale → re-encode as JPEG.
  /// Returns bytes ready for base64 transmission to the Edge Function.
  ///
  /// Uses `image` package 4.x API: pass EITHER `width` OR `height` (not both)
  /// to preserve aspect ratio automatically. Passing both stretches the image.
  Future<Uint8List> compressTo720p(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) throw Exception('Could not decode image');

    final longest = decoded.width > decoded.height ? decoded.width : decoded.height;
    final resized = longest > _maxLongSide
        ? img.copyResize(
            decoded,
            width:  decoded.width  >= decoded.height ? _maxLongSide : null,
            height: decoded.height >  decoded.width  ? _maxLongSide : null,
            interpolation: img.Interpolation.average,
          )
        : decoded;

    return img.encodeJpg(resized, quality: _jpegQuality);
  }

  Future<ScanResult> scanReceipt(File imageFile, {bool isDemo = false}) async {
    try {
      final imageBytes = await compressTo720p(imageFile);
      final base64Image = base64Encode(imageBytes);

      final session = Supabase.instance.client.auth.currentSession;
      if (session == null) return ScanResult.serverError();

      final response = await http.post(
        Uri.parse('${Env.supabaseUrl}/functions/v1/scan-receipt'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${session.accessToken}',
        },
        body: jsonEncode({'image': base64Image, 'is_demo': isDemo}),
      ).timeout(const Duration(seconds: 30));

      switch (response.statusCode) {
        case 200:
          final parsed = jsonDecode(response.body) as Map<String, dynamic>;
          return ScanResult.success(parsed);

        case 422:
          // Server has already extracted partial fields — safe to use directly
          final body = jsonDecode(response.body) as Map<String, dynamic>;
          final partial = (body['partial_fields'] as Map<String, dynamic>?) ?? {};
          return ScanResult.aiFailure(partial);

        case 402:
          return ScanResult.quotaExceeded();

        default:
          return ScanResult.serverError();
      }
    } on SocketException {
      return ScanResult.connectionError();
    } on http.ClientException {
      return ScanResult.connectionError();
    } catch (_) {
      return ScanResult.serverError();
    }
  }
}
```

**Validation:**
- [ ] `compressTo720p` output: decoded longest edge ≤ 1280, aspect ratio preserved (no stretching)
- [ ] Compressed JPEG size < 500 KB for a typical 12 MP phone photo
- [ ] `ScanErrorType.aiFailure` result contains a structured `partialFields` map (not raw text)
- [ ] `connectionError` and `serverError` are distinct types (different UI responses)
- [ ] Timeout after 30 seconds returns `connectionError`
- [ ] Supabase session expired → `scanReceipt` returns `serverError` (not silent success)

---

### Step 1.8 — Flutter: CurrencyService (Tier-Aware Staleness)

**Goal:** FX rate fetching with staleness thresholds that differ between Free and Pro/Team tiers.

Create `lib/core/services/currency_service.dart`:

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/env.dart';

class FxRate {
  final double rate;
  final bool isStale;
  const FxRate({required this.rate, required this.isStale});
}

class CurrencyService {
  // Free tier uses Frankfurter — treat as stale after 25 hours
  static const Duration _freeTierStaleness  = Duration(hours: 25);
  // Pro/Team use Open Exchange Rates (30-min refresh) — treat as stale after 35 minutes
  static const Duration _paidTierStaleness  = Duration(minutes: 35);

  static const String _frankfurterBase = 'https://api.frankfurter.app';
  static const String _oxrBase         = 'https://openexchangerates.org/api';

  final _supabase = Supabase.instance.client;

  Duration _stalenessDuration(String tier) =>
      (tier == 'pro' || tier == 'team') ? _paidTierStaleness : _freeTierStaleness;

  Future<FxRate> getRate({
    required String from,
    required String to,
    required String userTier,
  }) async {
    if (from == to) return const FxRate(rate: 1.0, isStale: false);

    final cached = await _getCachedRate(from, to);
    final threshold = _stalenessDuration(userTier);

    if (cached != null) {
      final age = DateTime.now().toUtc().difference(cached.$2);
      if (age < threshold) return FxRate(rate: cached.$1, isStale: false);
    }

    try {
      final rate = await _fetchRate(from, to, userTier);
      await _cacheRate(from, to, rate);
      return FxRate(rate: rate, isStale: false);
    } catch (_) {
      if (cached != null) return FxRate(rate: cached.$1, isStale: true);
      rethrow;
    }
  }

  Future<double> _fetchRate(String from, String to, String tier) async {
    return (tier == 'pro' || tier == 'team')
        ? _fetchFromOpenExchangeRates(from, to)
        : _fetchFromFrankfurter(from, to);
  }

  Future<double> _fetchFromFrankfurter(String from, String to) async {
    final uri = Uri.parse('$_frankfurterBase/latest?from=$from&to=$to');
    final res = await http.get(uri).timeout(const Duration(seconds: 10));
    if (res.statusCode != 200) throw Exception('Frankfurter fetch failed');
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return (data['rates'][to] as num).toDouble();
  }

  Future<double> _fetchFromOpenExchangeRates(String from, String to) async {
    final appId = Env.openExchangeRatesAppId;
    final uri = Uri.parse('$_oxrBase/latest.json?app_id=$appId&base=$from&symbols=$to');
    final res = await http.get(uri).timeout(const Duration(seconds: 10));
    if (res.statusCode != 200) throw Exception('OXR fetch failed');
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return (data['rates'][to] as num).toDouble();
  }

  Future<(double, DateTime)?> _getCachedRate(String from, String to) async {
    final result = await _supabase
        .from('fx_rates')
        .select('rate, fetched_at')
        .eq('base_currency', from)
        .eq('target_currency', to)
        .maybeSingle();
    if (result == null) return null;
    return (
      (result['rate'] as num).toDouble(),
      DateTime.parse(result['fetched_at'] as String)
    );
  }

  Future<void> _cacheRate(String from, String to, double rate) async {
    await _supabase.from('fx_rates').upsert({
      'base_currency': from,
      'target_currency': to,
      'rate': rate,
      'fetched_at': DateTime.now().toUtc().toIso8601String(),
    });
  }
}
```

**Validation:**
- [ ] Free tier: `getRate` returns `isStale: false` immediately after fetch, `isStale: true` after 25h+ (test by manually back-dating `fetched_at` in DB)
- [ ] Pro/Team: same logic but threshold is 35 minutes
- [ ] On provider failure: stale cache returned with `isStale: true`
- [ ] UI shows "Rates may be outdated" banner when `isStale == true`

---

### Step 1.9 — Offline Queue (Drift + Connectivity Trigger)

**Goal:** When the device is offline, queue personal transactions in a local SQLite database (Drift). When connectivity returns, drain the queue to Supabase in insertion order with correct conflict resolution.

**Architecture:**
1. UI writes every new personal transaction both to Drift (`pending_transactions`) AND optimistically to the in-memory Riverpod state so the list updates instantly.
2. A `SyncService` exposes `syncPending()` which iterates unsynced Drift rows, upserts to Supabase, and marks each row synced.
3. A `ConnectivityTrigger` listens to `connectivity_plus` and calls `syncPending()` whenever connectivity flips from none → wifi/mobile.
4. Conflict resolution is driven by `client_updated_at` (set at save time, not sync time) vs server `updated_at` (maintained by the `moddatetime` trigger from Step 1.3). The newer timestamp wins.

Create `lib/core/services/offline_database.dart`:

```dart
import 'dart:convert';
import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'offline_database.g.dart';

class PendingTransactions extends Table {
  IntColumn  get id              => integer().autoIncrement()();
  TextColumn get transactionJson => text()();
  DateTimeColumn get clientUpdatedAt => dateTime()();
  BoolColumn get synced          => boolean().withDefault(const Constant(false))();
}

@DriftDatabase(tables: [PendingTransactions])
class OfflineDatabase extends _$OfflineDatabase {
  OfflineDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  Future<void> enqueue(Map<String, dynamic> transaction) =>
      into(pendingTransactions).insert(
        PendingTransactionsCompanion.insert(
          transactionJson: jsonEncode(transaction),
          clientUpdatedAt: DateTime.now().toUtc(),
        ),
      );

  Future<List<PendingTransaction>> getPending() =>
      (select(pendingTransactions)
            ..where((t) => t.synced.equals(false))
            ..orderBy([(t) => OrderingTerm.asc(t.clientUpdatedAt)]))
          .get();

  Future<void> markSynced(int id) =>
      (update(pendingTransactions)..where((t) => t.id.equals(id)))
          .write(const PendingTransactionsCompanion(synced: Value(true)));
}

LazyDatabase _openConnection() => LazyDatabase(() async {
  final dir  = await getApplicationDocumentsDirectory();
  final file = File(p.join(dir.path, 'loit_offline.db'));
  return NativeDatabase.createInBackground(file);
});
```

Create `lib/core/services/sync_service.dart`:

```dart
import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'offline_database.dart';

class SyncService {
  final OfflineDatabase _db;
  final _supabase = Supabase.instance.client;
  final _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _sub;
  bool _syncing = false;

  SyncService(this._db);

  /// Call once during app startup (after Supabase.initialize) to
  /// auto-drain the queue whenever connectivity returns.
  void startAutoSync() {
    _sub = _connectivity.onConnectivityChanged.listen((results) {
      final online = results.any((r) => r != ConnectivityResult.none);
      if (online) unawaited(syncPending());
    });
    // Run once immediately in case we boot up already online with a non-empty queue.
    unawaited(syncPending());
  }

  Future<void> dispose() async {
    await _sub?.cancel();
  }

  /// Sync pending offline transactions to Supabase.
  ///
  /// Conflict resolution:
  ///   - Client sets `client_updated_at` at save time (see [OfflineDatabase.enqueue]).
  ///   - Server maintains `updated_at` via the moddatetime trigger from Step 1.3.
  ///   - Upsert with `onConflict: 'id'` — if the server row's `updated_at` is newer
  ///     than the queued `client_updated_at`, the application layer compares the two
  ///     and discards the stale offline edit. (See [_serverHasNewer].)
  Future<void> syncPending() async {
    if (_syncing) return;             // prevent overlapping syncs
    if (_supabase.auth.currentSession == null) return;  // not signed in
    _syncing = true;
    try {
      final pending = await _db.getPending();
      if (pending.isEmpty) return;

      for (final item in pending) {
        try {
          final tx = jsonDecode(item.transactionJson) as Map<String, dynamic>;
          tx['client_updated_at'] = item.clientUpdatedAt.toIso8601String();

          if (await _serverHasNewer(tx['id'] as String?, item.clientUpdatedAt)) {
            // Server has a more recent edit from another device — drop local change.
            await _db.markSynced(item.id);
            continue;
          }

          await _supabase.from('transactions').upsert(tx, onConflict: 'id');
          await _db.markSynced(item.id);
        } catch (e, st) {
          // Log and continue — do not abort entire sync for one failed item.
          debugPrint('Sync failed for item ${item.id}: $e\n$st');
        }
      }
    } finally {
      _syncing = false;
    }
  }

  Future<bool> _serverHasNewer(String? id, DateTime clientUpdatedAt) async {
    if (id == null) return false; // INSERT — nothing to compare
    final row = await _supabase
        .from('transactions')
        .select('updated_at')
        .eq('id', id)
        .maybeSingle();
    if (row == null) return false;
    final serverTs = DateTime.parse(row['updated_at'] as String);
    return serverTs.isAfter(clientUpdatedAt);
  }
}
```

Generate Drift + Riverpod code (use `dart run`; `flutter pub run` is deprecated since Flutter 3.10):
```bash
dart run build_runner build --delete-conflicting-outputs
```

**Validation:**
- [ ] Enable airplane mode → add transaction → transaction saved in local Drift DB
- [ ] Disable airplane mode → `syncPending()` fires → transaction appears in Supabase
- [ ] `client_updated_at` is set to the moment the user tapped save (not sync time)
- [ ] Syncing twice doesn't create duplicate rows (upsert on `id`)

---

### Step 1.10 — Analytics: PostHog Event Taxonomy

**Goal:** Instrument all core analytics events. Every event listed here must be called at the exact point noted. This taxonomy is the single source of truth — do not invent new event names without updating this file and the PostHog dashboard.

**Conventions:**
- Event names are `snake_case` verbs or noun+verb: `sign_up`, `scan_completed`.
- Property values are always stringly-typed enums with a fixed set of allowed values (see per-method doc comments).
- Call `Analytics.identify(userId, email)` **once** after a successful login so all subsequent events are user-scoped.
- Call `Analytics.reset()` after sign-out to clear the distinct_id.

Create `lib/core/services/analytics_service.dart`:

```dart
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
      Posthog().capture(eventName: 'scan_completed',
          properties: {'ai_success': aiSuccess});
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
      Posthog().capture(eventName: 'budget_alert_shown',
          properties: {'type': type}); // '80_percent' | 'exceeded'

  // ---- PAYWALL (call when paywall screen is shown, before user acts) ----
  static Future<void> paywallSeen(String feature) =>
      Posthog().capture(eventName: 'paywall_seen',
          properties: {'feature': feature});
  // feature: 'custom_categories' | 'unlimited_budgets' | 'export' |
  //          'receipt_storage' | 'full_history' | 'more_currencies' |
  //          'more_scan_quota' | 'more_rooms' | 'more_room_members'

  static Future<void> subscriptionStarted(String tier) =>
      Posthog().capture(eventName: 'subscription_started',
          properties: {'tier': tier}); // 'pro' | 'team'

  static Future<void> topupPurchased(String type) =>
      Posthog().capture(eventName: 'topup_purchased',
          properties: {'type': type}); // 'scans' | 'storage'

  // ---- ROOMS (Phase 2) ----
  static Future<void> roomCreated() =>
      Posthog().capture(eventName: 'room_created');

  static Future<void> roomJoined() =>
      Posthog().capture(eventName: 'room_joined');

  static Future<void> roomTransactionAdded() =>
      Posthog().capture(eventName: 'room_transaction_added');
}
```

**Validation:**
- [ ] Sign up with email → `sign_up` event appears in PostHog with `method: 'email'`
- [ ] Complete a scan → `scan_completed` with correct `ai_success` value
- [ ] Tap a gated feature → `paywall_seen` with correct `feature` name
- [ ] No events fire when user has no internet (PostHog SDK queues internally)

---

### Step 1.11 — Phase 1 Deliverables Checklist

Do not proceed to Phase 2 until every item below is checked.

- [ ] Auth: email + Google + Apple SSO working on real device (not just simulator)
- [ ] New user row auto-created in `public.users` on signup (check Dashboard)
- [ ] Personal dashboard renders real data from Supabase
- [ ] Manual transaction entry works and saves correctly
- [ ] **Offline queue:** Add transaction with airplane mode on → sync on reconnect → appears in Supabase
- [ ] **Conflict resolution:** `client_updated_at` set correctly; older server record does not overwrite newer offline edit
- [ ] AI scanner: scan → Edge Function → Sonnet → confirm screen → transaction + items saved
- [ ] **AI failure path:** 422 → `partial_fields` pre-fills manual entry form (no raw text parsed client-side)
- [ ] Connection error → retry screen shown (manual entry form does NOT open)
- [ ] Server error → retry screen shown (manual entry form does NOT open)
- [ ] Quota exceeded → upgrade/top-up sheet shown
- [ ] Demo scan: `has_used_demo_scan` flag prevents it counting against quota
- [ ] `transaction_items` rows saved alongside each AI-scanned transaction
- [ ] Budget goals: 3 categories on Free, unlimited on Pro/Team
- [ ] Budget 80% alert and overage alert fire correctly
- [ ] Frankfurter FX: 10 currencies, stale after 25h, shows "Rates may be outdated" label
- [ ] Spending reports: 3-month history, charts render correctly
- [ ] **Schema checks:** `scan_reset_date` is `timestamptz`; `transactions.updated_at` updates automatically via trigger
- [ ] PostHog: `sign_up`, `scan_completed`, `transaction_added`, `paywall_seen` all firing
- [ ] **Security:** `strings` tool on compiled APK confirms Anthropic API key is absent from binary
- [ ] App runs stably on iOS and Android without crashes or ANRs

---

## Phase 2 — Shared Rooms (Weeks 9–13)

**Goal:** Add the invite-only shared layer on top of the complete personal app. Rooms are for shared expense visibility and group budgeting — not debt or payment tracking. Internet connection is required for all room features.

---

### Step 2.1 — Phase 2 Database Schema

**Goal:** Create rooms, room_members, room_invites, room_budgets tables, and add the FK from transactions to rooms.

Create `supabase/migrations/20240201000000_phase2_schema.sql`:

```sql
-- ================================================================
-- ROOMS TABLE
-- ================================================================
CREATE TABLE rooms (
  id               uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name             text NOT NULL,
  description      text,
  base_currency    text DEFAULT 'IDR',
  created_by       uuid REFERENCES users(id),
  sync_to_personal boolean DEFAULT false,
  invite_token     text UNIQUE DEFAULT gen_random_uuid()::text,
  is_archived      boolean DEFAULT false,
  archived_at      timestamptz,
  budget_auto_reset boolean DEFAULT false,
  created_at       timestamptz DEFAULT now()
);

-- ================================================================
-- ROOM MEMBERS TABLE
-- ================================================================
CREATE TABLE room_members (
  id        uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  room_id   uuid REFERENCES rooms(id) ON DELETE CASCADE,
  user_id   uuid REFERENCES users(id) ON DELETE CASCADE,
  role      text DEFAULT 'member' CHECK (role IN ('admin', 'member')),
  joined_at timestamptz DEFAULT now(),
  UNIQUE(room_id, user_id)
);

-- ================================================================
-- ROOM INVITES TABLE
-- IMPORTANT: No table-level unique(room_id, invited_user_id) constraint.
-- Instead, a PARTIAL UNIQUE INDEX on status='pending' only.
-- This allows re-inviting a user after their previous invite expired or was revoked.
-- A table-level unique constraint would permanently block re-invites.
-- ================================================================
CREATE TABLE room_invites (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  room_id         uuid REFERENCES rooms(id) ON DELETE CASCADE,
  invited_user_id uuid REFERENCES users(id) ON DELETE CASCADE,
  invite_token    text NOT NULL,
  status          text DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'expired')),
  created_at      timestamptz DEFAULT now(),
  expires_at      timestamptz DEFAULT now() + interval '7 days'
);

-- Partial index: only one PENDING invite per user per room at a time.
-- Accepted and expired invites do not block re-invites.
CREATE UNIQUE INDEX room_invites_pending_unique
  ON room_invites(room_id, invited_user_id)
  WHERE status = 'pending';

-- ================================================================
-- ROOM BUDGETS TABLE
-- ================================================================
CREATE TABLE room_budgets (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  room_id      uuid REFERENCES rooms(id) ON DELETE CASCADE,
  category     text NOT NULL,
  budget_limit numeric NOT NULL,
  currency     text NOT NULL,
  created_by   uuid REFERENCES users(id),
  created_at   timestamptz DEFAULT now(),
  UNIQUE(room_id, category)
);

-- ================================================================
-- ADD FK FROM TRANSACTIONS TO ROOMS (Phase 2 migration)
-- Room_id column already exists from Phase 1 — just add the constraint.
-- ON DELETE SET NULL: if a room is deleted, transaction records are kept
-- but unlinked from the room.
-- ================================================================
ALTER TABLE transactions
  ADD CONSTRAINT fk_room
  FOREIGN KEY (room_id) REFERENCES rooms(id) ON DELETE SET NULL;

-- ================================================================
-- PHASE 2 INDEXES
-- `is_room_member(uuid)` is called on every query that touches rooms,
-- room_members, room_budgets, or room-scoped transactions.
-- The UNIQUE(room_id, user_id) from room_members already provides a btree
-- usable for this lookup; we add user_id-first too for "my rooms" queries.
-- ================================================================
CREATE INDEX idx_room_members_user ON room_members (user_id);

-- Looking up invites by token (the invite acceptance hot path).
CREATE INDEX idx_room_invites_token ON room_invites (invite_token)
  WHERE status = 'pending';
```

Apply:
```bash
supabase db push
```

**Validation:**
- [ ] `rooms`, `room_members`, `room_invites`, `room_budgets` tables exist
- [ ] `room_invites` has NO `UNIQUE(room_id, invited_user_id)` table constraint
- [ ] `room_invites_pending_unique` partial index exists (Dashboard → Database → Indexes)
- [ ] Test: insert pending invite for user A + room X → succeeds
- [ ] Test: insert second pending invite for same user A + room X → fails (index blocks it)
- [ ] Test: update first invite to `status='expired'` → insert new pending invite for same user A + room X → succeeds
- [ ] `transactions.room_id` FK now active

---

### Step 2.2 — Phase 2 Row Level Security

**Critical RLS pitfall:** A naive `room_members_select` policy like `USING (EXISTS (SELECT 1 FROM room_members WHERE ...))` causes **infinite recursion** because evaluating the policy requires querying `room_members`, which triggers the same policy. PostgreSQL errors out with `infinite recursion detected in policy for relation "room_members"`.

**Fix:** define a `SECURITY DEFINER` helper function (`is_room_member`) that bypasses RLS inside the function body. The function runs with the privileges of its owner (postgres), not the calling user, so querying `room_members` inside it doesn't re-trigger the policy.

Create `supabase/migrations/20240201000001_phase2_rls.sql`:

```sql
-- ================================================================
-- HELPER: is_room_member (SECURITY DEFINER — breaks RLS recursion)
-- SECURITY DEFINER: runs with owner privileges, skipping RLS on
-- room_members so we can safely query it from a room_members policy.
-- STABLE: enables PostgreSQL's policy-result caching within a query.
-- ================================================================
CREATE OR REPLACE FUNCTION is_room_member(p_room_id uuid)
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM room_members
    WHERE room_id = p_room_id AND user_id = auth.uid()
  );
$$;

REVOKE ALL ON FUNCTION is_room_member(uuid) FROM public;
GRANT EXECUTE ON FUNCTION is_room_member(uuid) TO authenticated;

-- ================================================================
ALTER TABLE rooms        ENABLE ROW LEVEL SECURITY;
ALTER TABLE room_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE room_invites ENABLE ROW LEVEL SECURITY;
ALTER TABLE room_budgets ENABLE ROW LEVEL SECURITY;

-- ROOMS: visible to members only
CREATE POLICY "rooms_select_member" ON rooms
  FOR SELECT USING (is_room_member(id));

CREATE POLICY "rooms_insert_own" ON rooms
  FOR INSERT WITH CHECK (created_by = auth.uid());

CREATE POLICY "rooms_update_creator" ON rooms
  FOR UPDATE USING (created_by = auth.uid());

-- ROOM MEMBERS: visible to all members of the same room.
-- Uses the SECURITY DEFINER helper to avoid self-recursion.
CREATE POLICY "room_members_select" ON room_members
  FOR SELECT USING (is_room_member(room_id));

-- A user may only insert themselves as a member. (Invite acceptance uses
-- the SECURITY DEFINER function `accept_room_invite` to bypass this — see Step 2.5.)
CREATE POLICY "room_members_insert_self" ON room_members
  FOR INSERT WITH CHECK (user_id = auth.uid());

-- Members can leave the room; room creators can kick.
CREATE POLICY "room_members_delete" ON room_members
  FOR DELETE USING (
    user_id = auth.uid()
    OR EXISTS (SELECT 1 FROM rooms r WHERE r.id = room_id AND r.created_by = auth.uid())
  );

-- ROOM INVITES: visible to the invited user and the room creator.
CREATE POLICY "room_invites_select" ON room_invites
  FOR SELECT USING (
    invited_user_id = auth.uid()
    OR EXISTS (SELECT 1 FROM rooms r WHERE r.id = room_id AND r.created_by = auth.uid())
  );

-- ROOM BUDGETS: readable by all members; insert/update by members (both roles).
CREATE POLICY "room_budgets_select" ON room_budgets
  FOR SELECT USING (is_room_member(room_id));

CREATE POLICY "room_budgets_insert" ON room_budgets
  FOR INSERT WITH CHECK (is_room_member(room_id));

CREATE POLICY "room_budgets_update" ON room_budgets
  FOR UPDATE USING (is_room_member(room_id));

-- TRANSACTIONS: drop the Phase 1 personal-only policies and recreate
-- with room-aware SELECT/INSERT. UPDATE/DELETE remain owner-only
-- (shared edits are an explicit non-goal — owner of the row can edit it).
DROP POLICY IF EXISTS "transactions_select_own" ON transactions;
DROP POLICY IF EXISTS "transactions_insert_own" ON transactions;

CREATE POLICY "transactions_select_own_or_room" ON transactions
  FOR SELECT USING (
    auth.uid() = user_id
    OR (room_id IS NOT NULL AND is_room_member(room_id))
  );

CREATE POLICY "transactions_insert_own_or_room" ON transactions
  FOR INSERT WITH CHECK (
    auth.uid() = user_id
    AND (room_id IS NULL OR is_room_member(room_id))
  );
-- transactions_update_own / transactions_delete_own from Phase 1 are left intact.
```

**Validation:**
- [ ] Schema migrates cleanly (no `infinite recursion detected in policy` error)
- [ ] User A and User B in the same room: User A can see User B's transactions posted to that room
- [ ] User A CANNOT see User B's transactions posted to a different room User A is not in
- [ ] User A CANNOT see User B's personal transactions (no room_id)
- [ ] User A tries to insert a transaction with `room_id` for a room they're not in → RLS denies
- [ ] User A tries to kick User B from a room they don't own → RLS denies the DELETE on `room_members`
- [ ] User A leaves a room (DELETE own row from `room_members`) → succeeds

---

### Step 2.3 — Flutter: Real-Time Room Feed (Riverpod 3 AsyncNotifier)

**Goal:** Implement the Supabase Realtime WebSocket channel for a single room with INSERT, UPDATE, and DELETE handling. Uses Riverpod 3's family `AsyncNotifier` so the initial fetch is represented as an `AsyncValue` (loading/error/data) without hand-rolled state.

**Architecture:**
- `RoomFeedNotifier` is a family Notifier keyed by `roomId`.
- `build(roomId)` does the initial fetch and subscribes to the realtime channel.
- `ref.onDispose` is used to unsubscribe the channel — no memory leaks even when Riverpod auto-disposes the provider.
- The `INSERT` payload from realtime does not include joined data (`users(name, avatar_url)`), so we re-fetch just that row after insert. This avoids showing "Unknown user" cards briefly.

Create `lib/features/room_detail/room_feed_controller.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'room_feed_controller.g.dart';

@riverpod
class RoomFeed extends _$RoomFeed {
  RealtimeChannel? _channel;

  @override
  Future<List<Map<String, dynamic>>> build(String roomId) async {
    final supabase = Supabase.instance.client;

    // Initial fetch — joined with user profile for avatar/name in the feed UI.
    final initial = await supabase
        .from('transactions')
        .select('*, users(name, avatar_url)')
        .eq('room_id', roomId)
        .order('created_at', ascending: false)
        .limit(50);

    // Subscribe to realtime changes scoped to this room only (RLS applies too).
    _channel = supabase
        .channel('room:$roomId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'transactions',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'room_id',
            value: roomId,
          ),
          callback: (payload) => _onInsert(payload, supabase, roomId),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'transactions',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'room_id',
            value: roomId,
          ),
          callback: _onUpdate,
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.delete,
          schema: 'public',
          table: 'transactions',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'room_id',
            value: roomId,
          ),
          callback: _onDelete,
        )
        .subscribe();

    // Ensure the channel is closed when the provider is disposed (e.g. user leaves screen).
    ref.onDispose(() => _channel?.unsubscribe());

    return List<Map<String, dynamic>>.from(initial);
  }

  Future<void> _onInsert(
    PostgresChangePayload payload,
    SupabaseClient supabase,
    String roomId,
  ) async {
    // Realtime payload doesn't include joined user info — fetch it so the card
    // renders with avatar + name instead of "Unknown user".
    final enriched = await supabase
        .from('transactions')
        .select('*, users(name, avatar_url)')
        .eq('id', payload.newRecord['id'] as Object)
        .maybeSingle();
    if (enriched == null) return;
    final current = state.valueOrNull ?? const [];
    state = AsyncData([enriched, ...current]);
  }

  void _onUpdate(PostgresChangePayload payload) {
    final current = state.valueOrNull ?? const [];
    state = AsyncData(current.map((t) =>
        t['id'] == payload.newRecord['id'] ? payload.newRecord : t).toList());
  }

  void _onDelete(PostgresChangePayload payload) {
    final current = state.valueOrNull ?? const [];
    state = AsyncData(current.where((t) => t['id'] != payload.oldRecord['id']).toList());
  }
}
```

After editing, regenerate the `.g.dart` file:
```bash
dart run build_runner build --delete-conflicting-outputs
```

**Enable Supabase Realtime for the `transactions` table** (Dashboard → Database → Replication → enable `transactions`). Without this toggle, the client connects but never receives events.

**Validation:**
- [ ] Transaction added on Device A appears on Device B within 1 second, with the correct user avatar and name
- [ ] Transaction deleted on Device A disappears on Device B in real-time
- [ ] Channel is unsubscribed when leaving the room screen — confirmed via Flutter DevTools network inspector showing the WebSocket closing
- [ ] Re-entering the room screen rebuilds the feed without duplicate subscriptions
- [ ] `AsyncValue.loading` state shows a skeleton; `AsyncValue.error` state shows a retry button

---

### Step 2.4 — Room Feed: Empty State

**Goal:** Display a clear empty state with a CTA when a new room has no transactions.

In `lib/features/room_detail/room_feed_screen.dart`:

```dart
Widget _buildFeed(List<Map<String, dynamic>> transactions) {
  if (transactions.isEmpty) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text('No expenses yet',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text('Be the first to log an expense',
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: Colors.grey.shade500)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _openAddExpense(),
            icon: const Icon(Icons.add),
            label: const Text('Add Expense'),
          ),
        ],
      ),
    );
  }
  return ListView.builder(
    itemCount: transactions.length,
    itemBuilder: (_, i) => _TransactionCard(transaction: transactions[i]),
  );
}
```

**Validation:**
- [ ] New room → empty state with icon, message, and CTA button visible
- [ ] Adding a transaction dismisses the empty state immediately (real-time update)

---

### Step 2.5 — Invite Flow: Generate Link + QR + Accept

**Goal:** Implement the full invite lifecycle: (1) creator generates a shareable invite link and QR code for a room, (2) invitee opens the link and is either bounced to the sign-up screen or directly into the "Join Room" confirmation, (3) acceptance inserts a `room_members` row and marks the `room_invites` row `accepted`.

**Link format:**
```
https://loit.app/invite/{invite_token}
```
This HTTPS URL works from anywhere (email, WhatsApp, SMS) and is the target of the iOS Universal Link and Android App Link configured in Step 2.6. A `com.loit://invite/{token}` mirror is emitted for custom-scheme fallback on older Android versions.

**Actions:**

1. **Invite creation — Edge Function.** Creating an invite server-side (rather than client-side) guarantees the `room_invites` row is inserted with RLS-bypassed privileges and prevents clients from fabricating invite_tokens.

   Create `supabase/functions/create-room-invite/index.ts`:
```typescript
import { serve } from 'https://deno.land/std@0.224.0/http/server.ts';
import { createClient } from 'npm:@supabase/supabase-js@2.46.1';

const supabase = createClient(
  Deno.env.get('SUPABASE_URL')!,
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
);

serve(async (req) => {
  if (req.method !== 'POST') return new Response('Method Not Allowed', { status: 405 });

  const authHeader = req.headers.get('Authorization');
  if (!authHeader) return new Response('Unauthorized', { status: 401 });
  const { data: { user } } = await supabase.auth.getUser(authHeader.replace('Bearer ', ''));
  if (!user) return new Response('Unauthorized', { status: 401 });

  const { room_id, invited_email } = await req.json();

  // Caller must be a member of the room
  const { data: member } = await supabase
    .from('room_members')
    .select('role')
    .eq('room_id', room_id)
    .eq('user_id', user.id)
    .maybeSingle();
  if (!member) return new Response('Forbidden', { status: 403 });

  // Look up invited user by email. Must already exist (LOIT does not
  // support inviting non-users in Phase 2 — they must sign up first).
  const { data: invitee } = await supabase
    .from('users')
    .select('id')
    .eq('email', invited_email)
    .maybeSingle();
  if (!invitee) return new Response('Invited user not found', { status: 404 });

  // Insert new pending invite. The partial unique index from Step 2.1
  // enforces only one PENDING invite per (room, user) at a time.
  const token = crypto.randomUUID();
  const { error } = await supabase.from('room_invites').insert({
    room_id,
    invited_user_id: invitee.id,
    invite_token: token,
    expires_at: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString(),
  });
  if (error) {
    if (error.code === '23505') {
      return new Response('User already has a pending invite', { status: 409 });
    }
    return new Response(error.message, { status: 500 });
  }

  return new Response(JSON.stringify({
    invite_token: token,
    invite_url:   `https://loit.app/invite/${token}`,
  }), { status: 200, headers: { 'Content-Type': 'application/json' } });
});
```

   Deploy: `supabase functions deploy create-room-invite`

2. **Invite acceptance — SQL function.** Done as a SECURITY DEFINER function so the caller doesn't need to be a member yet:
```sql
-- supabase/migrations/20240201000002_accept_invite.sql
CREATE OR REPLACE FUNCTION accept_room_invite(p_invite_token text)
RETURNS uuid LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_invite record;
BEGIN
  SELECT * INTO v_invite
    FROM room_invites
    WHERE invite_token = p_invite_token
      AND status = 'pending'
      AND expires_at > now()
      AND invited_user_id = auth.uid();

  IF v_invite IS NULL THEN
    RAISE EXCEPTION 'Invalid, expired, or not-yours invite';
  END IF;

  INSERT INTO room_members (room_id, user_id, role)
  VALUES (v_invite.room_id, auth.uid(), 'member')
  ON CONFLICT (room_id, user_id) DO NOTHING;

  UPDATE room_invites
    SET status = 'accepted'
    WHERE id = v_invite.id;

  RETURN v_invite.room_id;
END;
$$;
```

3. **Flutter: invite sheet with QR.** Create `lib/features/rooms/invite_sheet.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class InviteSheet extends StatefulWidget {
  const InviteSheet({super.key, required this.roomId, required this.roomName});
  final String roomId;
  final String roomName;

  @override
  State<InviteSheet> createState() => _InviteSheetState();
}

class _InviteSheetState extends State<InviteSheet> {
  String? _inviteUrl;
  String? _error;
  bool _loading = false;

  Future<void> _createInvite(String invitedEmail) async {
    setState(() { _loading = true; _error = null; });
    try {
      final resp = await Supabase.instance.client.functions.invoke(
        'create-room-invite',
        body: {'room_id': widget.roomId, 'invited_email': invitedEmail},
      );
      if (resp.status >= 400) {
        setState(() => _error = resp.data?.toString() ?? 'Failed to create invite');
        return;
      }
      setState(() => _inviteUrl = (resp.data as Map)['invite_url'] as String);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_inviteUrl == null) {
      return _EmailEntry(onSubmit: _createInvite, loading: _loading, error: _error);
    }
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('Invite to ${widget.roomName}',
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        QrImageView(data: _inviteUrl!, size: 220),
        const SizedBox(height: 16),
        SelectableText(_inviteUrl!, textAlign: TextAlign.center),
        const SizedBox(height: 16),
        FilledButton.icon(
          icon: const Icon(Icons.share),
          label: const Text('Share link'),
          onPressed: () => Share.share(_inviteUrl!),
        ),
        const SizedBox(height: 8),
        Text('Expires in 7 days',
            style: Theme.of(context).textTheme.bodySmall),
      ]),
    );
  }
}
```

   (`_EmailEntry` is a standard email text field with a "Generate invite" button — implementation follows normal form conventions.)

**Validation:**
- [ ] Creator opens a room → taps "Invite" → enters a registered user's email → QR + URL appear
- [ ] `room_invites` row exists with `status='pending'` and correct `expires_at` (7 days)
- [ ] Inviting the same email twice in a row → 409 Conflict, no duplicate row
- [ ] Invited user calls `accept_room_invite(token)` → `room_members` row created, invite marked `accepted`
- [ ] Invited user tries to accept twice → second call is idempotent (no duplicate member row)
- [ ] Expired invite → SQL function raises exception; UI shows "Invite expired"
- [ ] Analytics: `room_joined` event fires on successful acceptance

---

### Step 2.6 — Deep Links: iOS Universal Links + Android App Links

**Goal:** Tapping `https://loit.app/invite/{token}` opens the app directly to the "Join Room" screen if the app is installed, or App Store / Play Store otherwise. No browser bounce.

> Requires a domain you control (`loit.app` used here). Replace with yours.

**iOS — Universal Links (associated domains):**

1. In Apple Developer Portal → Identifiers → your app ID → enable **Associated Domains** capability.
2. Host `apple-app-site-association` (no extension, Content-Type `application/json`) at `https://loit.app/.well-known/apple-app-site-association`:
```json
{
  "applinks": {
    "apps": [],
    "details": [{
      "appID": "TEAMID.com.loit",
      "paths": ["/invite/*"]
    }]
  }
}
```
3. Add to `ios/Runner/Runner.entitlements`:
```xml
<key>com.apple.developer.associated-domains</key>
<array>
  <string>applinks:loit.app</string>
</array>
```
4. Validate with Apple's tester: `https://search.developer.apple.com/appsearch-validation-tool/`

**Android — App Links (Digital Asset Links):**

1. Host `assetlinks.json` at `https://loit.app/.well-known/assetlinks.json`:
```json
[{
  "relation": ["delegate_permission/common.handle_all_urls"],
  "target": {
    "namespace": "android_app",
    "package_name": "com.loit",
    "sha256_cert_fingerprints": ["AA:BB:CC:...your release keystore fingerprint..."]
  }
}]
```

2. Add to `android/app/src/main/AndroidManifest.xml` inside `MainActivity`:
```xml
<intent-filter android:autoVerify="true">
  <action android:name="android.intent.action.VIEW" />
  <category android:name="android.intent.category.DEFAULT" />
  <category android:name="android.intent.category.BROWSABLE" />
  <data android:scheme="https" android:host="loit.app" android:pathPrefix="/invite/" />
</intent-filter>
```

3. Get your release SHA-256 fingerprint:
```bash
keytool -list -v -keystore ~/loit-release.keystore -alias loit | grep SHA256
```

4. Validate with Google's tester: `https://developers.google.com/digital-asset-links/tools/generator`

**Flutter — handle the deep link at runtime.** Create `lib/core/services/deep_link_service.dart`:

```dart
import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'deep_link_service.g.dart';

/// Emits the roomId every time the user accepts an invite via deep link.
/// Widgets can `ref.listen(pendingInviteRoomIdProvider, ...)` to navigate.
@riverpod
class DeepLinkHandler extends _$DeepLinkHandler {
  final _appLinks = AppLinks();
  StreamSubscription<Uri>? _sub;

  @override
  Stream<String> build() async* {
    final controller = StreamController<String>();
    ref.onDispose(() {
      _sub?.cancel();
      controller.close();
    });

    // Cold start: grab the launching link if the app was killed.
    final initial = await _appLinks.getInitialLink();
    if (initial != null) {
      final roomId = await _handle(initial);
      if (roomId != null) controller.add(roomId);
    }

    // Warm state: listen for subsequent links.
    _sub = _appLinks.uriLinkStream.listen((uri) async {
      final roomId = await _handle(uri);
      if (roomId != null) controller.add(roomId);
    });

    yield* controller.stream;
  }

  Future<String?> _handle(Uri uri) async {
    // Matches both https://loit.app/invite/{token} and com.loit://invite/{token}.
    if (!uri.path.startsWith('/invite/') && uri.host != 'invite') return null;
    final token = uri.pathSegments.last;
    if (token.isEmpty) return null;

    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) {
      // Store token; the sign-in screen will call accept after successful auth.
      // (Implementation: write to flutter_secure_storage under 'pending_invite'.)
      return null;
    }
    final roomId = await Supabase.instance.client
        .rpc('accept_room_invite', params: {'p_invite_token': token}) as String?;
    return roomId;
  }
}
```

Wire it up in your root widget (e.g. `app.dart`):
```dart
ref.listen<AsyncValue<String>>(deepLinkHandlerProvider, (_, next) {
  next.whenData((roomId) => context.go('/rooms/$roomId'));
});
```

**Validation:**
- [ ] Kill the app → tap `https://loit.app/invite/<valid token>` from Notes/Mail → LOIT opens directly into the joined room (not the browser)
- [ ] Same link in an incognito Chrome/Safari on Android/iOS → App/Play Store if app not installed
- [ ] App already running → tapping the link switches to the joined room in-place
- [ ] `com.loit://invite/<token>` also works (custom scheme fallback)
- [ ] Deep link test tool (Apple + Google) reports no errors

---

### Step 2.7 — Push Notifications: Firebase Messaging Setup

**Goal:** Send a push notification to every room member whenever a new transaction is added to their room. Uses Firebase Messaging on the client and FCM HTTP v1 from a Supabase Edge Function on the server.

**Why Firebase Messaging over Pusher Beams?** The FlutterFire plugins are actively maintained, integrate directly with APNs + FCM, and do **not** conflict with the Riverpod 3 codegen/lint stack. Pusher Beams currently pulls old transitive dependencies (`uuid ^3`) that break modern Riverpod projects.

**Architecture:**
1. Each signed-in device requests notification permission and fetches an FCM device token.
2. The app stores tokens in a `push_tokens` table keyed by `user_id` + device token.
3. After a room transaction is inserted, Flutter calls an Edge Function.
4. The Edge Function looks up all tokens for room members except the actor and sends one FCM HTTP v1 request per token.
5. Tapping the notification opens the app and routes to `/rooms/{room_id}` using `FirebaseMessaging.onMessageOpenedApp`.

**Actions:**

1. **Firebase project setup:**
   - Create a Firebase project.
   - Add Android app `com.loit` and iOS app `com.loit`.
   - Firebase Console → Cloud Messaging → upload your APNs auth key (`.p8`) for iOS.
   - Project Settings → Service Accounts → generate a service account JSON.
   - Base64-encode it and store it in Supabase secrets:
```bash
base64 -i service-account.json | tr -d '\n' | pbcopy
supabase secrets set FIREBASE_SERVICE_ACCOUNT_JSON_BASE64=<paste-base64-here>
```
   - Run `flutterfire configure` (already added in Step 1.1) so `firebase_options.dart`, `google-services.json`, and `GoogleService-Info.plist` are generated.

2. **Create the device-token table.** Add `supabase/migrations/20240201000003_push_tokens.sql`:
```sql
CREATE TABLE push_tokens (
  id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id    uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  token      text NOT NULL UNIQUE,
  platform   text NOT NULL CHECK (platform IN ('ios', 'android', 'web')),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_push_tokens_user_id ON push_tokens(user_id);

ALTER TABLE push_tokens ENABLE ROW LEVEL SECURITY;

CREATE POLICY "push_tokens_select_own" ON push_tokens
  FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "push_tokens_insert_own" ON push_tokens
  FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY "push_tokens_update_own" ON push_tokens
  FOR UPDATE USING (user_id = auth.uid());

CREATE POLICY "push_tokens_delete_own" ON push_tokens
  FOR DELETE USING (user_id = auth.uid());
```

3. **Flutter client — request permission and register the device token.** Create `lib/core/services/push_service.dart`:
```dart
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PushService {
  final _messaging = FirebaseMessaging.instance;
  final _supabase  = Supabase.instance.client;

  Future<void> initialize() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    if (settings.authorizationStatus == AuthorizationStatus.denied) return;

    final token = await _messaging.getToken();
    await _upsertToken(token);

    FirebaseMessaging.instance.onTokenRefresh.listen(_upsertToken);
  }

  Future<void> _upsertToken(String? token) async {
    final user = _supabase.auth.currentUser;
    if (token == null || user == null) return;

    await _supabase.from('push_tokens').upsert({
      'user_id': user.id,
      'token': token,
      'platform': Platform.isIOS ? 'ios' : 'android',
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }, onConflict: 'token');
  }

  Future<void> unregisterCurrentDevice() async {
    final user = _supabase.auth.currentUser;
    final token = await _messaging.getToken();
    if (user != null && token != null) {
      await _supabase
          .from('push_tokens')
          .delete()
          .eq('user_id', user.id)
          .eq('token', token);
    }
  }
}
```

   Call `PushService().initialize()` after login success. Call `unregisterCurrentDevice()` on sign-out.

4. **Handle push opens in Flutter.** In your root app widget, listen for notifications that opened the app:
```dart
import 'package:firebase_messaging/firebase_messaging.dart';

Future<void> wirePushNavigation(BuildContext context) async {
  final initial = await FirebaseMessaging.instance.getInitialMessage();
  final initialRoomId = initial?.data['room_id'];
  if (initialRoomId != null) context.go('/rooms/$initialRoomId');

  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    final roomId = message.data['room_id'];
    if (roomId != null) context.go('/rooms/$roomId');
  });
}
```

5. **Edge Function: room-transaction-notify.** Uses the Firebase service account secret to obtain an OAuth access token and send FCM HTTP v1 messages.

   Create `supabase/functions/room-transaction-notify/index.ts`:
```typescript
import { serve } from 'https://deno.land/std@0.224.0/http/server.ts';
import { createClient } from 'npm:@supabase/supabase-js@2.46.1';
import { JWT } from 'npm:google-auth-library@9.15.1';

const supabase = createClient(
  Deno.env.get('SUPABASE_URL')!,
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
);

const serviceAccount = JSON.parse(
  atob(Deno.env.get('FIREBASE_SERVICE_ACCOUNT_JSON_BASE64')!),
);

const jwt = new JWT({
  email: serviceAccount.client_email,
  key: serviceAccount.private_key,
  scopes: ['https://www.googleapis.com/auth/firebase.messaging'],
});

async function getAccessToken(): Promise<string> {
  const tokens = await jwt.authorize();
  if (!tokens.access_token) throw new Error('Could not obtain Firebase access token');
  return tokens.access_token;
}

serve(async (req) => {
  const { room_id, actor_id, merchant, amount, currency } = await req.json();

  const { data: members } = await supabase
    .from('room_members')
    .select('user_id')
    .eq('room_id', room_id)
    .neq('user_id', actor_id);

  const userIds = (members ?? []).map((m) => m.user_id);
  if (userIds.length === 0) return new Response('OK', { status: 200 });

  const { data: tokens } = await supabase
    .from('push_tokens')
    .select('id, token, user_id')
    .in('user_id', userIds);

  if (!tokens || tokens.length === 0) return new Response('OK', { status: 200 });

  const accessToken = await getAccessToken();
  const endpoint = `https://fcm.googleapis.com/v1/projects/${serviceAccount.project_id}/messages:send`;

  for (const row of tokens) {
    const res = await fetch(endpoint, {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${accessToken}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        message: {
          token: row.token,
          notification: {
            title: merchant ?? 'New expense',
            body: `${amount} ${currency}`,
          },
          data: {
            room_id,
            type: 'room_transaction',
          },
          android: {
            priority: 'high',
            notification: { channel_id: 'room_activity' },
          },
          apns: {
            payload: { aps: { sound: 'default' } },
          },
        },
      }),
    });

    if (!res.ok) {
      const errText = await res.text();
      console.error('FCM send failed:', errText);
      if (errText.includes('UNREGISTERED') || errText.includes('registration-token-not-registered')) {
        await supabase.from('push_tokens').delete().eq('id', row.id);
      }
    }
  }

  return new Response('OK', { status: 200 });
});
```

   Call from Flutter after a successful insert into a room:
```dart
await Supabase.instance.client.functions.invoke('room-transaction-notify', body: {
  'room_id': roomId,
  'actor_id': Supabase.instance.client.auth.currentUser!.id,
  'merchant': merchant,
  'amount': amount,
  'currency': currency,
});
```

**Validation:**
- [ ] Two real devices signed in as two different members of the same room
- [ ] Device A adds a transaction → Device B receives a push within ~2 seconds
- [ ] Device A does NOT get a push for its own action (`actor_id` filter)
- [ ] Sign out on Device B → token row deleted from `push_tokens` → Device A adds transaction → no push arrives on the logged-out device
- [ ] Rotating the FCM token (clear app data / reinstall app) updates `push_tokens` via `onTokenRefresh`
- [ ] Opening the push deep-links into the correct room feed (`message.data['room_id']`)

---

### Step 2.8 — Phase 2 Deliverables Checklist

- [ ] Room creation with invite link and QR code
- [ ] Join flow via deep link (iOS Universal Link + Android App Link configured in respective platform files)
- [ ] Per-invitee expiry: 7 days from link click, tracked in `room_invites`
- [ ] **Partial index confirmed:** marking old invite `expired` then re-inviting same user succeeds
- [ ] Real-time feed: INSERT, UPDATE, DELETE all handled and reflected immediately on all member devices
- [ ] Room feed empty state with CTA shown on new rooms
- [ ] Room budget goals visible and updating live for all members
- [ ] Room budget monthly auto-reset working when enabled by creator
- [ ] Room reports (combined spend view) rendering correctly
- [ ] No-connection state shown on all room screens when offline
- [ ] Personal finance tab remains accessible while rooms show no-connection state
- [ ] Firebase Messaging push notifications working on iOS and Android (real device required)
- [ ] Room archiving by creator — members retain read-only access after archive
- [ ] RLS confirmed: room data only visible to members of that room
- [ ] PostHog: `room_created`, `room_joined`, `room_transaction_added` events firing

---

## Phase 3 — Pro Layer (Weeks 14–17)

**Goal:** Gate premium features behind Stripe/Xendit subscriptions. Activate full monetization.

---

### Step 3.1 — Stripe Products Setup

**Goal:** Create all subscription and one-time payment products in Stripe Dashboard.

Create these exact products in Stripe Dashboard → Products. **Critical:** when creating each Price, set the **Lookup key** field to the value in the "Lookup Key" column. Lookup keys are stable, human-readable identifiers you can use in code instead of `price_xxx` IDs — and they are what the webhook uses to identify which tier a subscription belongs to.

| Lookup Key | Name | Type | USD Price | IDR Price |
|---|---|---|---|---|
| `loit_pro_monthly` | LOIT Pro Monthly | Recurring | $4.99/mo | Rp85,529 |
| `loit_pro_yearly` | LOIT Pro Yearly | Recurring | $49.99/yr | Rp856,680 |
| `loit_team_monthly` | LOIT Team Monthly | Recurring | $9.99/mo | Rp171,169 |
| `loit_team_yearly` | LOIT Team Yearly | Recurring | $99.99/yr | Rp1,713,360 |
| `loit_scan_topup` | Scan Top-Up (10 scans) | One-time | $0.99 | Rp16,969 |
| `loit_storage_ext` | Receipt Storage Extension | One-time | $0.99 | Rp16,969 |

**How Stripe identifiers map:**
- **Product ID** (`prod_XXX`) — auto-generated by Stripe, not stable across test/live.
- **Price ID** (`price_XXX`) — auto-generated per pricing row, not portable across environments.
- **Lookup Key** — what you set, what you use. `loit_pro_monthly`, etc.

When creating Prices via the Dashboard, each Product can have multiple Prices (e.g. USD + IDR variants). Set a **separate Lookup Key per currency**: `loit_pro_monthly_usd` and `loit_pro_monthly_idr`. The checkout function picks the right one based on the user's locale.

**Annual plan display rule:** In the paywall UI, always show annual plans alongside monthly with a **"Save 17%"** badge. Calculate dynamically: `savings = 100 - (annual_price / (monthly_price * 12)) * 100`.

**Xendit (Indonesian market):**
- Mirror the same 6 SKUs in Xendit
- Auto-detect Indonesian users by locale `id_ID` and route checkout to Xendit
- Xendit supports: GoPay, OVO, DANA, virtual bank accounts (BCA, Mandiri, BNI)

**Stripe Webhook setup:**
```
Endpoint URL: ${SUPABASE_URL}/functions/v1/stripe-webhook
Events to listen for:
  - customer.subscription.created
  - customer.subscription.updated
  - customer.subscription.deleted
  - checkout.session.completed
```

Save the webhook signing secret as a Supabase secret:
```bash
supabase secrets set STRIPE_WEBHOOK_SECRET=whsec_...
supabase secrets set STRIPE_SECRET_KEY=sk_...
```

**Validation:**
- [ ] All 6 products exist in Stripe Dashboard
- [ ] Webhook endpoint registered with correct events
- [ ] Webhook signing secret stored in Supabase secrets
- [ ] Xendit products mirrored correctly

---

### Step 3.2 — Edge Function: stripe-webhook

Create `supabase/functions/stripe-webhook/index.ts`:

```typescript
import { serve } from 'https://deno.land/std@0.224.0/http/server.ts';
import Stripe from 'npm:stripe@17.3.1';
import { createClient } from 'npm:@supabase/supabase-js@2.46.1';

const stripe = new Stripe(Deno.env.get('STRIPE_SECRET_KEY')!);
const supabase = createClient(
  Deno.env.get('SUPABASE_URL')!,
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
);

// Maps lookup_key → tier. The `_usd`/`_idr` suffix is stripped so both
// currency variants of the same plan map to the same tier.
function tierFromLookupKey(lookupKey: string | null | undefined): string | null {
  if (!lookupKey) return null;
  const base = lookupKey.replace(/_(usd|idr)$/, '');
  return {
    loit_pro_monthly:  'pro',
    loit_pro_yearly:   'pro',
    loit_team_monthly: 'team',
    loit_team_yearly:  'team',
  }[base] ?? null;
}

serve(async (req) => {
  const body      = await req.text();
  const signature = req.headers.get('stripe-signature')!;

  let event: Stripe.Event;
  try {
    event = await stripe.webhooks.constructEventAsync(
      body, signature, Deno.env.get('STRIPE_WEBHOOK_SECRET')!,
    );
  } catch {
    return new Response('Invalid signature', { status: 400 });
  }

  // `user_id` is set in the Checkout Session `metadata` AND propagated to the
  // Subscription via `subscription_data.metadata` (see create-checkout-session).
  // For subscription.* events, metadata lives on the Subscription object.
  const obj    = event.data.object as Record<string, unknown>;
  const userId = (obj.metadata as Record<string, string> | undefined)?.user_id;
  if (!userId) return new Response('No user_id in metadata', { status: 400 });

  switch (event.type) {
    case 'customer.subscription.created':
    case 'customer.subscription.updated': {
      const sub = event.data.object as Stripe.Subscription;
      // `price.lookup_key` is our canonical product key — stable across
      // dashboards and environments. Falls back to null if not set.
      const lookupKey = sub.items.data[0]?.price.lookup_key;
      const tier      = tierFromLookupKey(lookupKey);
      if (tier) {
        await supabase.from('users').update({ tier }).eq('id', userId);
      } else {
        console.warn('Unknown lookup_key on subscription update:', lookupKey);
      }
      break;
    }
    case 'customer.subscription.deleted':
      await supabase.from('users').update({ tier: 'free' }).eq('id', userId);
      break;

    case 'checkout.session.completed': {
      // Subscription checkouts are already handled by subscription.created above.
      // Only handle one-time payment top-ups here.
      const session = event.data.object as Stripe.CheckoutSession;
      if (session.mode !== 'payment') break;

      const type = session.metadata?.type;
      if (type === 'scan_topup') {
        await supabase.rpc('add_scan_topup', { p_user_id: userId, p_amount: 10 });
      } else if (type === 'storage_ext') {
        await supabase.rpc('extend_receipt_expiry', { p_user_id: userId });
      }
      break;
    }
  }

  return new Response('OK', { status: 200 });
});
```

Deploy:
```bash
supabase functions deploy stripe-webhook
```

**Validation:**
- [ ] Stripe CLI: `stripe trigger customer.subscription.created` → `users.tier` updates to `'pro'`
- [ ] Stripe CLI: `stripe trigger customer.subscription.deleted` → `users.tier` reverts to `'free'`
- [ ] Invalid webhook signature → 400
- [ ] Missing `user_id` in metadata → 400
- [ ] One-time `scan_topup` checkout → extra scans visible to user within 1 second (`add_scan_topup` RPC)
- [ ] One-time `storage_ext` checkout → `receipt_expires_at` on all user receipts extended by 6 months

---

### Step 3.3 — SQL: Top-Up and Storage Extension Functions

**Goal:** Define the RPC functions that the `stripe-webhook` Edge Function calls on successful one-time payments. These are split from subscription updates because they don't change tier, just credit additional usage.

Create `supabase/migrations/20240301000000_topup_functions.sql`:

```sql
-- ================================================================
-- ADD SCAN TOP-UP (called after successful `loit_scan_topup` checkout)
-- Credits `p_amount` extra scans by REDUCING the used counter.
-- Using subtraction (rather than raising the cap) keeps the tier
-- limit logic in Edge Function simple and unified.
-- ================================================================
CREATE OR REPLACE FUNCTION add_scan_topup(p_user_id uuid, p_amount int)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  UPDATE users
  SET scans_used_this_month = GREATEST(0, scans_used_this_month - p_amount)
  WHERE id = p_user_id;
END;
$$;

-- ================================================================
-- EXTEND RECEIPT EXPIRY (called after successful `loit_storage_ext` checkout)
-- Adds 6 months to `receipt_expires_at` on every receipt the user owns
-- that still has a non-null receipt_url.
-- ================================================================
CREATE OR REPLACE FUNCTION extend_receipt_expiry(p_user_id uuid)
RETURNS int LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  affected int;
BEGIN
  UPDATE transactions
  SET receipt_expires_at = receipt_expires_at + interval '6 months'
  WHERE user_id = p_user_id
    AND receipt_url IS NOT NULL
    AND receipt_expires_at IS NOT NULL;
  GET DIAGNOSTICS affected = ROW_COUNT;
  RETURN affected;
END;
$$;
```

Apply:
```bash
supabase db push
```

**Validation:**
- [ ] `SELECT add_scan_topup('<uuid>', 10);` → `users.scans_used_this_month` decreases by 10 (or floors to 0)
- [ ] `SELECT extend_receipt_expiry('<uuid>');` → all the user's receipts have their `receipt_expires_at` pushed forward by 6 months
- [ ] Both functions execute under `SECURITY DEFINER` (safe because only called from the service-role Edge Function)

---

### Step 3.4 — Flutter: Subscription Checkout (Stripe + Xendit)

**Goal:** Show the paywall, route to the correct provider based on locale, and kick off checkout. Stripe (non-IDR) uses `flutter_stripe` PaymentSheet for a native experience. Xendit (IDR) opens a hosted checkout URL in the system browser.

**Routing logic:**
```
locale.countryCode == 'ID'  →  Xendit (server creates an invoice URL, client launches it)
otherwise                    →  Stripe PaymentSheet (server creates PaymentIntent or Subscription, client confirms)
```

**Actions:**

1. **Edge Function `create-checkout-session`** — creates Stripe Checkout Session OR Xendit Invoice based on the `provider` field:
```typescript
// supabase/functions/create-checkout-session/index.ts
import { serve } from 'https://deno.land/std@0.224.0/http/server.ts';
import Stripe from 'npm:stripe@17.3.1';
import { createClient } from 'npm:@supabase/supabase-js@2.46.1';

const stripe = new Stripe(Deno.env.get('STRIPE_SECRET_KEY')!);
const supabase = createClient(
  Deno.env.get('SUPABASE_URL')!,
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
);

serve(async (req) => {
  const auth = req.headers.get('Authorization')!;
  const { data: { user } } = await supabase.auth.getUser(auth.replace('Bearer ', ''));
  if (!user) return new Response('Unauthorized', { status: 401 });

  const { provider, product_key } = await req.json();

  if (provider === 'stripe') {
    // Resolve the Price ID from the lookup_key. This is the supported way
    // to reference Prices portably across environments.
    const prices = await stripe.prices.list({
      lookup_keys: [`${product_key}_usd`],
      active: true,
      limit: 1,
    });
    const priceId = prices.data[0]?.id;
    if (!priceId) return new Response('Price not found for lookup_key', { status: 404 });

    const isOneTime = product_key === 'loit_scan_topup' || product_key === 'loit_storage_ext';

    const session = await stripe.checkout.sessions.create({
      mode: isOneTime ? 'payment' : 'subscription',
      line_items: [{ price: priceId, quantity: 1 }],
      // Top-level metadata shows up on the CheckoutSession event.
      metadata: {
        user_id: user.id,
        type: product_key === 'loit_scan_topup' ? 'scan_topup'
            : product_key === 'loit_storage_ext' ? 'storage_ext'
            : 'subscription',
      },
      // For subscriptions, also copy metadata onto the Subscription object
      // so customer.subscription.* events can identify the user.
      subscription_data: isOneTime ? undefined : { metadata: { user_id: user.id } },
      success_url: 'com.loit://checkout/success',
      cancel_url:  'com.loit://checkout/cancel',
    });
    return Response.json({ provider: 'stripe', url: session.url });
  }

  if (provider === 'xendit') {
    // Xendit Invoice API — creates a hosted checkout URL
    const res = await fetch('https://api.xendit.co/v2/invoices', {
      method: 'POST',
      headers: {
        Authorization: 'Basic ' + btoa(Deno.env.get('XENDIT_SECRET_KEY')! + ':'),
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        external_id: `${user.id}:${product_key}:${Date.now()}`,
        amount: XENDIT_PRICES[product_key],
        payer_email: user.email,
        success_redirect_url: 'com.loit://checkout/success',
        failure_redirect_url: 'com.loit://checkout/cancel',
        items: [{ name: product_key, quantity: 1, price: XENDIT_PRICES[product_key] }],
      }),
    });
    const invoice = await res.json();
    return Response.json({ provider: 'xendit', url: invoice.invoice_url });
  }

  return new Response('Unknown provider', { status: 400 });
});

const XENDIT_PRICES: Record<string, number> = {
  'loit_pro_monthly':  85529,
  'loit_pro_yearly':   856680,
  'loit_team_monthly': 171169,
  'loit_team_yearly':  1713360,
  'loit_scan_topup':   16969,
  'loit_storage_ext':  16969,
};
```

2. **Flutter checkout launcher** (`lib/features/paywall/checkout_service.dart`):
```dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class CheckoutService {
  /// Starts checkout for the given product and returns once the browser/native
  /// sheet is dismissed. The actual tier upgrade happens asynchronously via
  /// the stripe-webhook Edge Function — the UI should listen to the user's
  /// tier change and update reactively.
  Future<void> startCheckout({
    required BuildContext context,
    required String productKey,
    required String localeCountryCode,
  }) async {
    final provider = localeCountryCode == 'ID' ? 'xendit' : 'stripe';

    final resp = await Supabase.instance.client.functions.invoke(
      'create-checkout-session',
      body: {'provider': provider, 'product_key': productKey},
    );
    if (resp.status >= 400) {
      throw Exception('Checkout init failed: ${resp.data}');
    }
    final url = (resp.data as Map)['url'] as String;

    // Both providers redirect to `com.loit://checkout/success` on completion,
    // which our deep link handler catches to refresh the tier.
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }
}
```

3. **Paywall gating** — use a Riverpod provider that reads the user's tier and composes feature flags:
```dart
// lib/features/paywall/feature_gate.dart
@riverpod
class FeatureGate extends _$FeatureGate {
  @override
  Stream<FeatureFlags> build() {
    return Supabase.instance.client
        .from('users')
        .stream(primaryKey: ['id'])
        .eq('id', Supabase.instance.client.auth.currentUser!.id)
        .map((rows) {
          final tier = rows.first['tier'] as String;
          return FeatureFlags.forTier(tier);
        });
  }
}

class FeatureFlags {
  final bool unlimitedBudgets;
  final bool customCategories;
  final bool csvExport;
  final bool pdfExport;
  final bool receiptStorage;
  final bool fullHistory;
  final int  scanLimitPerMonth;
  final int  budgetCategoryLimit;

  const FeatureFlags({
    required this.unlimitedBudgets,
    required this.customCategories,
    required this.csvExport,
    required this.pdfExport,
    required this.receiptStorage,
    required this.fullHistory,
    required this.scanLimitPerMonth,
    required this.budgetCategoryLimit,
  });

  factory FeatureFlags.forTier(String tier) => switch (tier) {
    'pro' || 'team' => const FeatureFlags(
      unlimitedBudgets: true, customCategories: true, csvExport: true,
      pdfExport: true, receiptStorage: true, fullHistory: true,
      scanLimitPerMonth: 50, budgetCategoryLimit: 1 << 30,
    ),
    _ => const FeatureFlags(
      unlimitedBudgets: false, customCategories: false, csvExport: false,
      pdfExport: false, receiptStorage: false, fullHistory: false,
      scanLimitPerMonth: 8, budgetCategoryLimit: 3,
    ),
  };
}
```

Use in UI:
```dart
final flags = ref.watch(featureGateProvider).valueOrNull ?? FeatureFlags.forTier('free');
if (!flags.csvExport) {
  Analytics.paywallSeen('export');
  showPaywallSheet(context, feature: 'export');
  return;
}
```

**Validation:**
- [ ] Device locale `en_US` → checkout routes to Stripe, native PaymentSheet appears
- [ ] Device locale `id_ID` → checkout routes to Xendit, browser opens to GoPay/OVO/DANA options
- [ ] After successful checkout, deep link returns to the app and the `FeatureGate` stream emits the new tier within 2 seconds (driven by the webhook updating `users.tier`)
- [ ] Tapping a gated feature while on Free shows the paywall AND fires `Analytics.paywallSeen(feature)`
- [ ] Cancel from the payment sheet returns the user to the paywall without error

---

### Step 3.5 — Receipt Storage (Pro/Team)

**Goal:** Upload compressed receipt images to Supabase Storage for Pro/Team users. Store the path (not a signed URL) in the database. Enforce per-user isolation via Storage RLS so a user can never read another user's receipts.

**Storage RLS — required first.** Supabase Storage uses the `storage.objects` table under the hood; without these policies, uploads to `receipts/{user_id}/...` will fail with `new row violates row-level security policy`. Run in SQL Editor:

```sql
-- ================================================================
-- RECEIPTS BUCKET — per-user folder isolation.
-- Path convention: `{user_id}/{transaction_id}.jpg`
-- `(storage.foldername(name))[1]` returns the first path segment
-- (the user_id), which we compare to auth.uid().
-- ================================================================
CREATE POLICY "receipts_select_own" ON storage.objects
  FOR SELECT
  USING (
    bucket_id = 'receipts'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

CREATE POLICY "receipts_insert_own" ON storage.objects
  FOR INSERT
  WITH CHECK (
    bucket_id = 'receipts'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

CREATE POLICY "receipts_update_own" ON storage.objects
  FOR UPDATE
  USING (
    bucket_id = 'receipts'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

CREATE POLICY "receipts_delete_own" ON storage.objects
  FOR DELETE
  USING (
    bucket_id = 'receipts'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );
```

Tier enforcement is **client-side gated** (`FeatureFlags.receiptStorage`). The server additionally refuses the upload for Free users because `compressTo720p`'s caller in the scanner flow short-circuits before `uploadReceipt` for Free. If you want server-side tier enforcement too, add a `WITH CHECK` clause that joins on the `users` table — but that requires an extra cross-schema query per upload.

Create `lib/core/services/receipt_service.dart`:

```dart
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';

class ReceiptService {
  final _supabase = Supabase.instance.client;
  static const _bucket = 'receipts';

  /// Upload receipt for Pro/Team users.
  /// Free tier: call this function only for Pro/Team. Discard the photo otherwise.
  /// Returns the storage path (not a signed URL — re-sign on each view).
  Future<String> uploadReceipt({
    required String userId,
    required String transactionId,
    required Uint8List imageBytes,
  }) async {
    final path = '$userId/$transactionId.jpg';

    await _supabase.storage.from(_bucket).uploadBinary(
      path, imageBytes,
      fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: true),
    );

    final expiresAt = DateTime.now().toUtc().add(const Duration(days: 365));
    await _supabase.from('transactions').update({
      'receipt_url':        path,  // Store path, NOT signed URL
      'receipt_expires_at': expiresAt.toIso8601String(),
    }).eq('id', transactionId);

    return path;
  }

  /// Generate a fresh signed URL for viewing a receipt.
  /// Signed URLs expire after 1 hour — always regenerate on view.
  Future<String> getSignedUrl(String storagePath) async {
    return await _supabase.storage
        .from(_bucket)
        .createSignedUrl(storagePath, 3600); // 1 hour
  }
}
```

**Validation:**
- [ ] Pro user scans receipt → file appears in Supabase Storage at `{user_id}/{txn_id}.jpg`
- [ ] `transactions.receipt_url` stores the path (not a full URL)
- [ ] `transactions.receipt_expires_at` = upload time + 365 days
- [ ] Free user: `receipt_url` is null, no file in Storage
- [ ] Signed URL expires correctly after 1 hour (verify in Storage signed URL test)

---

### Step 3.6 — Receipt Expiry Cron

Create `supabase/functions/receipt-expiry-cron/index.ts`:

```typescript
import { serve } from 'https://deno.land/std@0.224.0/http/server.ts';
import { createClient } from 'npm:@supabase/supabase-js@2.46.1';

const supabase = createClient(
  Deno.env.get('SUPABASE_URL')!,
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
);

serve(async () => {
  const now = new Date();

  // Day 365: delete expired receipts (receipt_expires_at is in the past)
  const { data: expired } = await supabase
    .from('transactions')
    .select('id, user_id, receipt_url')
    .lte('receipt_expires_at', now.toISOString())
    .not('receipt_url', 'is', null);

  for (const txn of expired ?? []) {
    await supabase.storage.from('receipts').remove([txn.receipt_url]);
    await supabase.from('transactions')
      .update({ receipt_url: null, receipt_expires_at: null })
      .eq('id', txn.id);
    // Transaction record is preserved forever — only the photo is deleted
  }

  // Day 335 warning: in-app banner (expires within 30 days)
  const thirtyDaysOut = new Date(now.getTime() + 30 * 24 * 60 * 60 * 1000);
  await triggerInAppBanner(now, thirtyDaysOut);

  // Day 350 warning: push + email (expires within 15 days)
  const fifteenDaysOut = new Date(now.getTime() + 15 * 24 * 60 * 60 * 1000);
  await triggerPushAndEmail(now, fifteenDaysOut, 15);

  // Day 360 warning: final push + email (expires within 5 days)
  const fiveDaysOut = new Date(now.getTime() + 5 * 24 * 60 * 60 * 1000);
  await triggerPushAndEmail(now, fiveDaysOut, 5);

  return new Response('Receipt expiry cron done', { status: 200 });
});

async function triggerInAppBanner(from: Date, to: Date) {
  // Query transactions expiring between now and thirtyDaysOut
  // Mark them for in-app banner display (e.g. set a flag or store in a notifications table)
  // Implementation depends on your in-app notification system
}

async function triggerPushAndEmail(from: Date, to: Date, daysRemaining: number) {
  const { data: expiring } = await supabase
    .from('transactions')
    .select('user_id, receipt_expires_at')
    .gt('receipt_expires_at', from.toISOString())
    .lte('receipt_expires_at', to.toISOString())
    .not('receipt_url', 'is', null);

  const uniqueUserIds = [...new Set((expiring ?? []).map(t => t.user_id))];
  for (const userId of uniqueUserIds) {
    // Send push via Firebase Messaging + email via Resend
    // Message: "Receipts expiring in ${daysRemaining} days. Extend for Rp16,969."
  }
}
```

Schedule in `supabase/config.toml`:
```toml
[functions.receipt-expiry-cron]
schedule = "0 2 * * *"   # Daily at 2:00 AM UTC
```

**Validation:**
- [ ] Set a receipt's `receipt_expires_at` to 1 minute in the past → trigger cron manually → file deleted from Storage, `receipt_url` nulled, transaction record intact
- [ ] Day 335/350/360 warnings fire at correct intervals (test with artificially early dates)
- [ ] Cron appears in Edge Function logs daily

---

### Step 3.7 — CSV and PDF Export

**Goal:** Export personal transactions as CSV or PDF. Both generated client-side in Flutter.

> ⚠️ **Memory note:** PDF export is client-side. For users with large histories on low-end Android devices common in Indonesia, generating a PDF for 2+ years of data can cause memory pressure or crashes. Enforce a maximum of **12 months per PDF export**. Show a date-range picker if the user's history exceeds 12 months before generating.

Create `lib/features/reports/export_service.dart`:

```dart
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;

class ExportService {
  static const int _maxPdfMonths = 12;

  Future<File> exportCsv(List<Map<String, dynamic>> transactions) async {
    final rows = [
      ['Date', 'Merchant', 'Amount', 'Currency', 'Category', 'Notes'],
      ...transactions.map((t) => [
        t['created_at'], t['merchant'] ?? '',
        t['amount'], t['currency'],
        t['category'] ?? '', t['notes'] ?? '',
      ]),
    ];
    final csvString = const ListToCsvConverter().convert(rows);
    final dir  = await getTemporaryDirectory();
    final file = File('${dir.path}/loit_export_${DateTime.now().millisecondsSinceEpoch}.csv');
    return file.writeAsString(csvString);
  }

  /// [transactions] must span at most 12 months — enforce in the UI before calling.
  Future<File> exportPdf(
    List<Map<String, dynamic>> transactions,
    String homeCurrency,
    double totalAmount,
  ) async {
    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        build: (ctx) => [
          pw.Header(level: 0, text: 'LOIT — Expense Report'),
          pw.Text('Total: $totalAmount $homeCurrency'),
          pw.SizedBox(height: 16),
          pw.Table.fromTextArray(
            headers: ['Date', 'Merchant', 'Amount', 'Category'],
            data: transactions.map((t) => [
              t['created_at']?.toString().substring(0, 10) ?? '',
              t['merchant'] ?? '',
              '${t['amount']} ${t['currency']}',
              t['category'] ?? '',
            ]).toList(),
          ),
        ],
      ),
    );
    final dir  = await getTemporaryDirectory();
    final file = File('${dir.path}/loit_report_${DateTime.now().millisecondsSinceEpoch}.pdf');
    return file.writeAsBytes(await doc.save());
  }
}
```

**Validation:**
- [ ] CSV export downloads with all columns and correct data
- [ ] PDF export renders with header, total, and transaction table
- [ ] Attempting to export > 12 months of PDF shows date-range picker before generating
- [ ] Export is behind paywall for Free tier — `paywall_seen` event fires with `feature: 'export'`

---

### Step 3.8 — Phase 3 Deliverables Checklist

- [ ] Stripe subscription checkout working on iOS and Android (test cards)
- [ ] Xendit checkout working for GoPay, OVO, DANA (sandbox mode)
- [ ] Annual pricing visible in paywall with "Save 17%" badge
- [ ] Webhook correctly updates `users.tier` on subscription create/update/delete
- [ ] `paywall_seen` PostHog event fires with correct `feature` for every gated feature
- [ ] `subscriptionStarted` PostHog event fires after successful checkout
- [ ] Open Exchange Rates serving 180+ currencies for Pro/Team (35-minute cache)
- [ ] Free tier currency picker limited to 10 major currencies
- [ ] Receipt upload working for Pro/Team — file in Storage, path in `transactions.receipt_url`
- [ ] Signed URLs regenerated fresh on each receipt view
- [ ] Receipt expiry cron running daily — tested with accelerated dates
- [ ] Day 365: file deleted, transaction record preserved
- [ ] CSV export correct format and content
- [ ] PDF export renders correctly; 12-month guard prevents memory issues
- [ ] Scan top-up pack purchase end-to-end (buy → `scans_used_this_month` credits added)
- [ ] Storage extension purchase end-to-end (buy → `receipt_expires_at` extended by 6 months)
- [ ] Custom categories working for Pro/Team
- [ ] Unlimited budget categories working for Pro/Team
- [ ] Tier downgrade (subscription cancelled → free): features degrade gracefully without crash

---

## Phase 4 — Polish & Launch (Weeks 18–20)

**Goal:** Localization, offline hardening, keep-alive, QA, and App Store submission.

---

### Step 4.1 — Localization (EN + Bahasa Indonesia)

**Goal:** Full EN + ID localization for all UI strings, error messages, push notification copy, and locale-aware number/date/currency formatting. Uses Flutter's official `flutter_gen` / `gen_l10n` pipeline (no code generator packages required — it's built into the Flutter SDK).

**Actions:**

1. **Configure code generation.** Create `l10n.yaml` in the project root:
```yaml
arb-dir: lib/l10n
template-arb-file: app_en.arb
output-localization-file: app_localizations.dart
output-class: AppLocalizations
output-dir: lib/l10n/generated
synthetic-package: false        # generated file lives in your source tree (not a hidden package)
nullable-getter: false
preferred-supported-locales:
  - en
  - id
```

   Confirm `pubspec.yaml` already has `generate: true` under the `flutter:` section (set in Step 1.1) and that `flutter_localizations` is a dependency.

2. **Create the English source** at `lib/l10n/app_en.arb`:
```json
{
  "@@locale": "en",
  "scanButton": "Scan Receipt",
  "scanLimitLabel": "{used} of {total} scans used · Resets {date}",
  "@scanLimitLabel": {
    "placeholders": {
      "used": {"type": "int"},
      "total": {"type": "int"},
      "date": {"type": "String"}
    }
  },
  "ratesOutdated": "Rates may be outdated",
  "roomsRequireInternet": "Rooms require an internet connection",
  "noExpensesYet": "No expenses yet",
  "addExpensePrompt": "Be the first to log an expense",
  "receiptExpiryWarning": "Your oldest receipts expire in {days} days. Extend to keep them.",
  "@receiptExpiryWarning": {
    "placeholders": {"days": {"type": "int"}}
  }
}
```

3. **Create the Indonesian translation** at `lib/l10n/app_id.arb` with the same keys. Every key in `app_en.arb` must be translated — `flutter gen-l10n` will warn about missing keys at build time.

4. **Generate the `AppLocalizations` class**. This runs automatically on `flutter pub get` (because `generate: true`) but you can force it:
```bash
flutter gen-l10n
```

5. **Wire it into `MaterialApp`** (typically in `app.dart`):
```dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/generated/app_localizations.dart';

MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales:       AppLocalizations.supportedLocales,
  // Flutter automatically picks the best locale from the device.
  // To override (e.g. user-chosen language in Settings), set `locale:`.
  // ...
)
```

6. **Locale-aware number/date/currency formatting** — `intl` is already a dependency. The locale is read from `Localizations.localeOf(context)` so formatting matches the app's current language:
```dart
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

String formatMoney(BuildContext ctx, num amount, String currencyCode) {
  final locale = Localizations.localeOf(ctx).toString(); // 'en' or 'id'
  // For IDR specifically, use 'Rp' symbol and no decimals (Indonesian convention).
  if (currencyCode == 'IDR') {
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0)
        .format(amount);
  }
  return NumberFormat.simpleCurrency(locale: locale, name: currencyCode).format(amount);
}

String formatDate(BuildContext ctx, DateTime date) =>
    DateFormat.yMMMd(Localizations.localeOf(ctx).toString()).format(date);
```

7. **Ensure ICU plural/select cases compile.** Run with a missing Indonesian key to verify `gen-l10n` errors out rather than silently falling back — catches drift early.

**Validation:**
- [ ] `flutter gen-l10n` runs clean (no missing-key warnings)
- [ ] Switch device language to Indonesian → all UI strings appear in Bahasa Indonesia (no English fallbacks)
- [ ] IDR amounts format as `Rp1.000` with no decimals (Indonesian convention)
- [ ] USD amounts format as `$1,000.00`
- [ ] Push notification body text is localized in both languages (set on server based on the user's `users.home_currency`/locale preference)
- [ ] Date formats: `id_ID` → `20 Apr 2026`, `en_US` → `Apr 20, 2026` (via `DateFormat.yMMMd`)
- [ ] ICU plural placeholder in `scanLimitLabel` resolves for `used = 1` vs `used = 5` correctly

---

### Step 4.2 — Offline Mode Hardening

**Goal:** Finalize and harden offline behavior for personal finance. Shared rooms must always show no-connection state when offline.

Go through every personal finance screen and verify the following:

```
Personal Finance — Offline Behavior:
  [x] Dashboard loads from Drift/local cache (last synced data)
  [x] Transaction log readable from local cache
  [x] Budget progress readable from local cache
  [x] Manual transaction entry works → queued in Drift, synced on reconnect
  [x] Scanner shows "Scanning requires an internet connection" when offline
  [x] FX rates show "Last updated [date]" label when using cached rates (isStale: true)

  Connection restored:
  [x] Queued transactions sync in insertion order (oldest first)
  [x] Conflict resolution: client_updated_at vs server updated_at — newer timestamp wins
  [x] UI refreshes from Supabase after sync completes
  [x] In-app notification shown: "Your offline transactions have been synced"

Shared Rooms — Offline Behavior:
  [x] Full-screen no-connection state shown on all room screens
  [x] "Rooms require an internet connection" message + retry button
  [x] No room data is cached or shown offline
  [x] Personal finance tab remains fully accessible while rooms are unavailable
```

**Validation:**
- [ ] Enable airplane mode → open app → dashboard shows cached data
- [ ] Add transaction offline → turn off airplane mode → transaction appears in Supabase
- [ ] Open any room screen offline → full-screen no-connection state
- [ ] Tap retry button in room → waits for connection, resumes automatically

---

### Step 4.3 — Keep-Alive Cron

**Goal:** Prevent Supabase Free project from auto-pausing after 7 days of inactivity.

**Prerequisite check:** Confirm `receipts/.keep` file exists in Storage (created in Step 1.2). If it doesn't exist, create it now:
```bash
echo "" > /tmp/.keep
supabase storage cp /tmp/.keep "supabase://receipts/.keep"
```

Create `supabase/functions/keep-alive/index.ts`:
```typescript
import { serve } from 'https://deno.land/std@0.224.0/http/server.ts';
import { createClient } from 'npm:@supabase/supabase-js@2.46.1';

const supabase = createClient(
  Deno.env.get('SUPABASE_URL')!,
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
);

serve(async () => {
  // 1. Keep database active — lightweight no-op query (0 tokens)
  const { error: dbError } = await supabase
    .from('fx_rates')
    .select('base_currency')
    .limit(1);

  // 2. Keep Storage active — HEAD on known placeholder file
  const { error: storageError } = await supabase.storage
    .from('receipts')
    .download('.keep');

  if (dbError) console.error('Keep-alive DB error:', dbError);
  if (storageError) console.error('Keep-alive Storage error:', storageError);

  return new Response(
    `Keep-alive OK | db: ${dbError ? 'error' : 'ok'} | storage: ${storageError ? 'error' : 'ok'}`,
    { status: 200 },
  );
});
```

Schedule in `supabase/config.toml`:
```toml
[functions.keep-alive]
schedule = "0 12 */3 * *"   # Every 3 days at noon UTC (well within the 7-day pause window)
```

Deploy:
```bash
supabase functions deploy keep-alive
```

**Validation:**
- [ ] `receipts/.keep` confirmed to exist in Storage before deploying cron
- [ ] Trigger function manually → response is `200 OK` with `db: ok | storage: ok`
- [ ] Check Edge Function logs 3 days later — confirm it fired automatically
- [ ] Simulate 7-day inactivity (if on Free tier dev project) — project does not pause

---

### Step 4.4 — App Store Submission Checklist

**iOS (Apple App Store):**
- [ ] App icons at all required sizes (generate from 1024×1024 master using Asset Catalog)
- [ ] Launch screen / splash screen
- [ ] Screenshots for iPhone 6.7", 6.5", 5.5" and iPad Pro 12.9"
- [ ] App Store description in English and Indonesian (Bahasa Indonesia)
- [ ] Privacy policy URL live (must cover: receipt image usage, data deletion, no AI training on receipts)
- [ ] Terms of service URL live
- [ ] GDPR data deletion: Settings → Delete My Account → deletes all user data from Supabase
- [ ] In-app purchase products submitted and approved in App Store Connect
- [ ] Sign in with Apple implemented and working on device
- [ ] TestFlight beta distributed to at least 10 real testers
- [ ] All TestFlight feedback addressed before production submission

**Android (Google Play Store):**
- [ ] Adaptive icon (foreground layer + background layer as separate assets)
- [ ] Feature graphic (1024×500 pixels)
- [ ] Screenshots for phone and 7" tablet
- [ ] Play Store description in English and Indonesian
- [ ] Privacy policy URL in Play Console (same URL as iOS)
- [ ] In-app purchases configured in Google Play Billing
- [ ] `compileSdkVersion 35` and `targetSdkVersion 34` or higher in `android/app/build.gradle` (required by Google Play as of Aug 2024)
- [ ] 64-bit compliance: Flutter defaults to `arm64-v8a` + `x86_64` for release builds — verify the release AAB contains only 64-bit native libs (`unzip -l app-release.aab | grep .so`)
- [ ] `android.useAndroidX=true` and `android.enableJetifier=true` in `gradle.properties`
- [ ] Internal testing → Closed testing → Production rollout (phased 10% → 50% → 100%)

---

### Step 4.5 — Final QA Pass

Execute every test in the table below before submitting to either store.

| Area | Test Cases |
|---|---|
| Auth | Sign up via email, Google, Apple; login; logout; password reset; SSO token refresh |
| Scanner | Happy path scan; blurry image → 422 → manual entry with partial_fields pre-filled; connection error → retry screen; 720p cap verified on large photo; scanner disabled offline |
| Scan quota | Free tier caps at 8; Pro caps at 50; top-up adds 10; demo scan excluded from count; monthly reset on the 1st |
| Offline | Add transaction offline; reconnect → syncs correctly; conflict resolution (newer timestamp wins); cache readable offline; budget progress readable offline |
| Rooms — online | Feed live updates (INSERT/UPDATE/DELETE); budget bar updates live; new member join event shown |
| Rooms — offline | Full-screen no-connection shown; retry button works; personal tab accessible |
| Empty room | New room shows empty state with CTA; first transaction dismisses empty state |
| Payments | Stripe test card checkout; Xendit sandbox checkout; webhook upgrades tier; scan top-up end-to-end; storage extension end-to-end |
| Annual pricing | Annual plan visible in paywall alongside monthly; "Save 17%" badge shown |
| Re-invite | Mark invite expired → re-invite same user to same room → succeeds |
| Receipt expiry | Accelerated test (back-date `receipt_expires_at`): file deleted on expiry, transaction record preserved |
| FX staleness | Free tier: stale after 25h shows "outdated" label; Pro: stale after 35min |
| Export | CSV downloads with correct columns; PDF renders (12-month guard enforced) |
| Localization | All strings render in EN and ID; currency/number formatting correct per locale |
| Performance | Cold start < 3 seconds; room feed loads < 1 second |
| Analytics | All PostHog events fire in PostHog dashboard (verify in Live Events view) |
| Security | `apktool` or `strings` on release APK — Anthropic API key absent from binary |

---

### Step 4.6 — Phase 4 Final Deliverables Checklist

- [ ] Offline mode for personal finance complete and tested end-to-end
- [ ] No-connection handling for rooms working correctly on real devices
- [ ] Full EN + ID localization — all strings, all screens
- [ ] Keep-alive cron running and confirmed via Edge Function logs
- [ ] `receipts/.keep` placeholder confirmed in Storage
- [ ] Both apps submitted to App Store and Google Play
- [ ] Privacy policy and Terms of Service pages live at public URLs
- [ ] All QA tests passing on real devices (iOS and Android)
- [ ] All PostHog events instrumented and verified in PostHog dashboard
- [ ] Phased Android rollout configured (10% → 50% → 100%)
- [ ] **LOIT is live 🚀**

---

*LOIT — Split bills, not friendships.*
