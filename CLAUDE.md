# CLAUDE.md

Guidance for Claude Code (claude.ai/code) in this repo.

## Project

LOIT — Indonesian personal finance app (Flutter + Supabase). Phase 1 personal core, Phase 2 shared rooms, Phase 3 Pro/Team paid (RevenueCat), Phase 4 polish. Android-only v1; iOS deferred. Spec in `LOIT_Build_Guide.md` (long; read targeted sections via `offset/limit`) and `LOIT_Product_Blueprint.md`. Phase 3 amendment at top of build guide overrides later conflicting Phase 3 detail.

## Common commands

Env split: client-safe keys in `env.json` / `env.production.json` (compiled via `--dart-define-from-file`, never `flutter_dotenv`). Server secrets via `supabase secrets set`. Service-role / Anthropic / RevenueCat REST keys never in `env*.json`.

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

`SUPABASE_URL` / `SUPABASE_SERVICE_ROLE_KEY` auto-injected into Edge Functions — no `secrets set`.

## Architecture

### Flutter client (`lib/`)
- `main.dart` boots Firebase → Supabase (PKCE) → PostHog (native init via AndroidManifest, no Dart `setup`) → Sentry, then `runApp(ProviderScope(LoitApp))`. RevenueCat init deferred to first paywall open.
- `app.dart` (`LoitApp`) integration hub: subscribes `authStateProvider`, identifies/resets PostHog + RevenueCat on sign-in/out, opens Supabase realtime channel on `public.users` for current user (catches webhook tier flips, no polling), wires deep links → router, push taps → router, on `AppLifecycleState.resumed` calls `Purchases.invalidateCustomerInfoCache()` + `getCustomerInfo()` to catch refunds during background.
- `core/config/`: `env.dart` (compile-time consts via `String.fromEnvironment`), `pricing_constants.dart` (canonical SKU/price table — single source of truth for paywall + webhook), `categories.dart`.
- `core/routing/app_router.dart`: go_router config; deep links + auth gating here.
- `core/theme/`: design tokens (`loit_colors`, `loit_spacing`, `loit_radius`, `loit_typography`, `loit_motion`, `loit_elevation`) composed by `loit_theme.dart`.
- `core/services/`: `payment_service.dart` abstraction; impls `revenuecat_payment_service.dart` (live) + `dummy_payment_service.dart` (stub, gated by `Env.paymentStub`). `offline_database.dart` is Drift (generated `.g.dart`) — SQLite write queue for offline transactions, drained by `sync_service.dart`. Other: `scanner_service` (Claude OCR via Edge Function), `room_service`, `receipt_service`, `push_service` (FCM), `deep_link_service` (app_links), `analytics_service` (PostHog), `log_service`, `currency_service`, `interaction_log_service`.
- `features/<area>/`: one folder per surface — `auth`, `dashboard`, `transactions`, `budgets`, `rooms`, `room_detail`, `scanner`, `recurring`, `reports`, `paywall`, `billing`, `settings`, `system`. Screens read providers; no direct Supabase calls in widgets.
- `shared/providers/`: Riverpod 3 + `@riverpod` codegen — `auth_providers`, `budgets_provider`, `transactions_provider`, `room_providers`, `services_providers`. `Notifier`/`AsyncNotifier` only; `StateNotifier` legacy, do not add.
- `shared/widgets/`: `loit_*` design-system primitives (`loit_input`, `loit_chip`, `loit_sheet`, `loit_amount_text`, etc.) — prefer over raw Material.
- `l10n/`: `flutter: generate: true` + `l10n.yaml`; arb files `app_en.arb` + `app_id.arb`.

### Supabase (`supabase/`)
- `migrations/` timestamp-ordered, authoritative. Phase 1 schema + RLS, Phase 2 rooms + invites + push tokens, Phase 3 payments. Note `20240301000007_drop_midtrans.sql`: Midtrans replaced by RevenueCat — never reintroduce midtrans tables.
- `functions/` (Deno):
  - `scan-receipt` — Claude OCR; skips quota for `pro`/`team` (Phase 3 amendment), enforces 8/mo for free.
  - `revenuecat-webhook` — only place flipping `users.tier` / `tier_expires_at` for live purchases. Auths via shared `REVENUECAT_WEBHOOK_AUTH` bearer. Idempotent on `payment_receipts.purchase_token` (RC `event.id`). Grant: `INITIAL_PURCHASE`, `RENEWAL`, `PRODUCT_CHANGE`, `NON_RENEWING_PURCHASE`, `UNCANCELLATION`. Revoke: `EXPIRATION`, `BILLING_ISSUE`, `REFUND`, post-grace `CANCELLATION`.
  - `dummy-grant` — stub mirror of webhook, server-gated by `STUB_MODE=true`. Used while `Env.paymentStub=true` and Play Console SKUs not provisioned.
  - `create-room-invite`, `room-transaction-notify` (FCM fan-out), `recurring-bills-cron`, `receipt-expiry-cron`, `subscription-downgrade-cron`.

### Payment flow invariants
- `PaymentService` only payment surface for feature code. No direct `purchases_flutter` imports outside `revenuecat_payment_service.dart`.
- `FeatureFlags.scanLimitPerMonth` + `UserProfile.scanQuota` are `int?`; `null` ⇒ unlimited. UI renders "Unlimited", never decrement.
- Annual = 8× monthly ("4 months free / Save 33%"). Scan top-up + storage extension surface only for free tier.
- Stub + live branches share same `payment_receipts` idempotency path — analytics/DB state identical.

## Conventions
- Riverpod 3 codegen (`@riverpod`) — regen via `dart run build_runner` after provider edits.
- Drift codegen — same command regens `offline_database.g.dart`.
- Lints: `package:flutter_lints/flutter.yaml` + `riverpod_lint` / `custom_lint` (run `dart run custom_lint`).
- No `print` — use `Log` from `core/services/log_service.dart` (lifecycle/info/error categories, Sentry integration).
- Sentry release uploads (`sentry_dart_plugin`) run on release builds; debug symbols + source maps required.

## Agent skills

### Issue tracker

Issues live in GitHub Issues. See `docs/agents/issue-tracker.md`.

### Triage labels

Default label vocabulary (needs-triage, needs-info, ready-for-agent, ready-for-human, wontfix). See `docs/agents/triage-labels.md`.

### Domain docs

Single-context layout — `CONTEXT.md` + `docs/adr/` at repo root. See `docs/agents/domain.md`.