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
  - `scan-receipt` — Claude vision OCR via OpenRouter (ADR-0016). Token-metered AI Credits (ADR-0017): all AI captures cost `max(1, ceil(completion_tokens/1024))` credits; per-tier caps free 5 / lite 30 / pro 150 (unknown tier = unlimited). Reserves 1 credit before the call, charges overshoot after (soft cap), refunds on no usable parse.
  - `revenuecat-webhook` — only place flipping `users.tier` / `tier_expires_at` for live purchases. Auths via shared `REVENUECAT_WEBHOOK_AUTH` bearer. Idempotent on `payment_receipts.purchase_token` (RC `event.id`). Grant: `INITIAL_PURCHASE`, `RENEWAL`, `PRODUCT_CHANGE`, `NON_RENEWING_PURCHASE`, `UNCANCELLATION`. Revoke: `EXPIRATION`, `BILLING_ISSUE`, `REFUND`, post-grace `CANCELLATION`.
  - `dummy-grant` — stub mirror of webhook, server-gated by `STUB_MODE=true`. Used while `Env.paymentStub=true` and Play Console SKUs not provisioned.
  - `classify-taxonomy` — generic AI classifier: maps caller-supplied items (ADR-0025 txn signals) onto a caller-supplied code list. Powers **Laporan Realisasi Mata Anggaran** (ADR-0026) — projects a church room's period txns onto GMIM's ~300-code chart (client sends the chart; fn is denomination-agnostic). Metered as one Capture via shared `gatedCapture` (ADR-0017), charged to the generating treasurer.
  - `create-room-invite`, `room-transaction-notify` (FCM fan-out), `recurring-bills-cron`, `receipt-expiry-cron`, `subscription-downgrade-cron`.

### Payment flow invariants
- `PaymentService` only payment surface for feature code. No direct `purchases_flutter` imports outside `revenuecat_payment_service.dart`.
- `FeatureFlags.scanLimitPerMonth` + `UserProfile.scanQuota` are `int?`; `null` ⇒ unlimited. UI renders "Unlimited", never decrement. Internal field/column/RPC names keep `scan` for back-compat; user-facing copy says "AI Credits" / "Kredit AI" (ADR-0017). A capture can cost >1 credit, so UI shows credits charged + remaining, not a fixed per-scan decrement.
- Annual = 8× monthly ("4 months free / Save 33%"). Scan top-up + storage extension surface only for free tier.
- Stub + live branches share same `payment_receipts` idempotency path — analytics/DB state identical.

## Conventions
- Riverpod 3 codegen (`@riverpod`) — regen via `dart run build_runner` after provider edits.
- Drift codegen — same command regens `offline_database.g.dart`.
- Lints: `package:flutter_lints/flutter.yaml` + `riverpod_lint` / `custom_lint` (run `dart run custom_lint`).
- No `print` — use `Log` from `core/services/log_service.dart` (lifecycle/info/error categories, Sentry integration).
- Sentry release uploads (`sentry_dart_plugin`) run on release builds; debug symbols + source maps required.

## CI/CD

Codemagic builds release AABs and ships to Google Play Closed Testing. Config at `codemagic.yaml` (workflow `android-closed-testing`).

- **Trigger:** tag push matching `v*` (e.g. `git tag v1.0.3 && git push origin v1.0.3`). No PR/main builds — keep tag history clean.
- **Track:** Play Console `internal` by default; flip to `alpha`/closed-testing track name in `codemagic.yaml` `publishing.google_play.track`.
- **Secrets** (Codemagic env var groups, all marked Secure):
  - `loit_signing` — `CM_KEYSTORE` (base64 of release `.jks`), `CM_KEYSTORE_PASSWORD`, `CM_KEY_ALIAS`, `CM_KEY_PASSWORD`. Decoded into `android/app/loit-release.keystore` + generated `android/key.properties` at build time.
  - `loit_env_prod` — `ENV_PRODUCTION_JSON` (base64 of `env.production.json`). Decoded back to repo root; `flutter build appbundle` consumes via `--dart-define-from-file`. POSTHOG key re-extracted and passed as Gradle `-PPOSTHOG_API_KEY` (matches `manifestPlaceholders` reader in `android/app/build.gradle.kts`).
  - `loit_google` — `GOOGLE_SERVICES_JSON` (base64) restored to `android/app/google-services.json`; `GCLOUD_SERVICE_ACCOUNT_CREDENTIALS` raw JSON of Play service account (Releases Admin + Store presence Edit, scoped to app).
  - `loit_sentry` — `SENTRY_AUTH_TOKEN` for `sentry_dart_plugin` release upload during build.
  - `loit_other` — `SUPABASE_GATE_URL` + `SUPABASE_GATE_SERVICE_KEY` (service-role). The post-build step parses the release tag and upserts `app_release_gate` (Update gate, ADR-0015): `v1.2.0`→`latest`, `-recommended`→`recommended`+`latest`, `-breaking`→`min`+`recommended`+`latest` (cascade up). Service-role key never ships in `env*.json`.
- **Build number:** monotonic `$(date +%s)/60` injected via `--build-number`; pubspec `+N` ignored on CI to avoid versionCode collisions.
- **First publish gotcha:** Play Publishing API rejects first upload — initial AAB for the app must be uploaded manually through Play Console before CI publishes work.
- **Gitignored locally:** `android/key.properties`, `android/app/*.jks`, `env.production.json`, `android/app/google-services.json`. Never commit; CI restores from base64 secrets.
- **Manual setup procedure:** see README §CI/CD for first-time Codemagic + Play service account wiring.

## Agent skills

### Issue tracker

Issues live in GitHub Issues. See `docs/agents/issue-tracker.md`.

### Triage labels

Default label vocabulary (needs-triage, needs-info, ready-for-agent, ready-for-human, wontfix). See `docs/agents/triage-labels.md`.

### Domain docs

Single-context layout — `CONTEXT.md` + `docs/adr/` at repo root. See `docs/agents/domain.md`.

## graphify

This project has a graphify knowledge graph at graphify-out/.

Rules:
- Before answering architecture or codebase questions, read graphify-out/GRAPH_REPORT.md for god nodes and community structure
- If graphify-out/wiki/index.md exists, navigate it instead of reading raw files
- For cross-module "how does X relate to Y" questions, prefer `graphify query "<question>"`, `graphify path "<A>" "<B>"`, or `graphify explain "<concept>"` over grep — these traverse the graph's EXTRACTED + INFERRED edges instead of scanning files
- After modifying code files in this session, run `graphify update .` to keep the graph current (AST-only, no API cost)
