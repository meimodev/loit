# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

LOIT — Indonesian-market personal finance app (Flutter + Supabase). Phase 1 personal core, Phase 2 shared rooms, Phase 3 Pro/Team paid layer (RevenueCat), Phase 4 polish. Android-only at v1; iOS deferred. Authoritative spec lives in `LOIT_Build_Guide.md` (long; read targeted sections via `offset/limit`) and `LOIT_Product_Blueprint.md`. The Phase 3 amendment at the top of the build guide overrides any later conflicting Phase 3 detail.

## Common commands

Env split: client-safe keys in `env.json` / `env.production.json` (compiled in via `--dart-define-from-file`, never `flutter_dotenv`). Server secrets via `supabase secrets set`. Service-role / Anthropic / RevenueCat REST keys must never appear in `env*.json`.

```bash
flutter run --dart-define-from-file=env.json                 # dev
flutter build appbundle --dart-define-from-file=env.production.json
flutter analyze
flutter test                                                  # all
flutter test test/widget_test.dart -p chrome --plain-name '<name>'  # single
dart run build_runner build --delete-conflicting-outputs      # Riverpod + Drift codegen (NOT `flutter pub run`)
dart run build_runner watch --delete-conflicting-outputs

supabase start                                                # local stack
supabase db reset                                             # apply migrations under supabase/migrations
supabase functions serve <name>                               # e.g. revenuecat-webhook, scan-receipt
supabase functions deploy <name>
supabase secrets set KEY=value
```

`SUPABASE_URL` / `SUPABASE_SERVICE_ROLE_KEY` are auto-injected into Edge Functions — do not `secrets set` them.

## Architecture

### Flutter client (`lib/`)
- `main.dart` boots Firebase → Supabase (PKCE) → PostHog (native init via AndroidManifest, no Dart `setup`) → Sentry, then `runApp(ProviderScope(LoitApp))`. RevenueCat init is deferred to first paywall open.
- `app.dart` (`LoitApp`) is the integration hub: subscribes to `authStateProvider`, identifies/resets PostHog and RevenueCat on sign-in/out, opens a Supabase realtime channel on `public.users` for the current user (catches webhook tier flips without polling), wires deep links → router, push-notification taps → router, and on `AppLifecycleState.resumed` calls `Purchases.invalidateCustomerInfoCache()` + `getCustomerInfo()` to catch refunds issued while backgrounded.
- `core/config/`: `env.dart` (compile-time consts via `String.fromEnvironment`), `pricing_constants.dart` (canonical SKU/price table — single source of truth for paywall + webhook), `categories.dart`.
- `core/routing/app_router.dart`: go_router config; deep links + auth gating live here.
- `core/theme/`: design tokens (`loit_colors`, `loit_spacing`, `loit_radius`, `loit_typography`, `loit_motion`, `loit_elevation`) composed by `loit_theme.dart`.
- `core/services/`: `payment_service.dart` is the abstraction; concrete impls are `revenuecat_payment_service.dart` (live) and `dummy_payment_service.dart` (stub, gated by `Env.paymentStub`). `offline_database.dart` is Drift (with generated `.g.dart`) — SQLite write queue for offline transactions, drained by `sync_service.dart`. Other services: `scanner_service` (Claude OCR via Edge Function), `room_service`, `receipt_service`, `push_service` (FCM), `deep_link_service` (app_links), `analytics_service` (PostHog), `log_service`, `currency_service`, `interaction_log_service`.
- `features/<area>/`: one folder per product surface — `auth`, `dashboard`, `transactions`, `budgets`, `rooms`, `room_detail`, `scanner`, `recurring`, `reports`, `paywall`, `billing`, `settings`, `system`. Screens read providers; no direct Supabase calls in widgets.
- `shared/providers/`: Riverpod 3 with `@riverpod` codegen — `auth_providers`, `budgets_provider`, `transactions_provider`, `room_providers`, `services_providers`. `Notifier`/`AsyncNotifier` only; `StateNotifier` is legacy and must not be added.
- `shared/widgets/`: `loit_*` design-system primitives (`loit_input`, `loit_chip`, `loit_sheet`, `loit_amount_text`, etc.) — prefer these over raw Material widgets.
- `l10n/`: `flutter: generate: true` + `l10n.yaml`; arb files `app_en.arb` + `app_id.arb`.

### Supabase (`supabase/`)
- `migrations/` is timestamp-ordered and authoritative. Phase 1 schema + RLS, Phase 2 rooms + invites + push tokens, Phase 3 payments. Note `20240301000007_drop_midtrans.sql`: Midtrans was replaced by RevenueCat — do not reintroduce midtrans tables.
- `functions/` (Deno):
  - `scan-receipt` — Claude OCR; skips quota for `pro`/`team` (Phase 3 amendment), enforces 8/mo for free.
  - `revenuecat-webhook` — only place that flips `users.tier` / `tier_expires_at` for live purchases. Authenticates via shared `REVENUECAT_WEBHOOK_AUTH` bearer. Idempotent on `payment_receipts.purchase_token` (RC `event.id`). Grant events: `INITIAL_PURCHASE`, `RENEWAL`, `PRODUCT_CHANGE`, `NON_RENEWING_PURCHASE`, `UNCANCELLATION`. Revoke: `EXPIRATION`, `BILLING_ISSUE`, `REFUND`, post-grace `CANCELLATION`.
  - `dummy-grant` — stub mirror of webhook, gated server-side by `STUB_MODE=true`. Used while `Env.paymentStub=true` and Play Console SKUs not yet provisioned.
  - `create-room-invite`, `room-transaction-notify` (FCM fan-out), `recurring-bills-cron`, `receipt-expiry-cron`, `subscription-downgrade-cron`.

### Payment flow invariants
- `PaymentService` is the only payment surface used by feature code. No direct `purchases_flutter` imports outside `revenuecat_payment_service.dart`.
- `FeatureFlags.scanLimitPerMonth` and `UserProfile.scanQuota` are `int?`; `null` ⇒ unlimited. UI must render "Unlimited" and never decrement.
- Annual = 8× monthly ("4 months free / Save 33%"). Scan top-up + storage extension surface only for free tier.
- Stub vs live branches share the same `payment_receipts` idempotency path so analytics/DB state are identical.

## Conventions
- Riverpod 3 codegen (`@riverpod`) — regenerate via `dart run build_runner` after provider edits.
- Drift codegen — same command regenerates `offline_database.g.dart`.
- Lints: `package:flutter_lints/flutter.yaml` plus `riverpod_lint` / `custom_lint` (run `dart run custom_lint`).
- No `print` — use `Log` from `core/services/log_service.dart` (lifecycle/info/error categories, integrates with Sentry).
- Sentry release uploads (`sentry_dart_plugin`) run on release builds; debug symbols + source maps required.
