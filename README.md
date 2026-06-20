# LOIT

Indonesian personal finance app. Flutter + Supabase. Android-only v1; iOS deferred.

See `LOIT_Build_Guide.md` and `LOIT_Product_Blueprint.md` for full spec. `CLAUDE.md` has architecture and conventions.

## Quick start

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run --dart-define-from-file=env.json
```

Release build:
```bash
flutter build appbundle --dart-define-from-file=env.production.json
```

## Local secrets (gitignored)

- `env.json` / `env.production.json` — client-safe keys (`SUPABASE_URL`, `SUPABASE_ANON_KEY`, `POSTHOG_API_KEY`, `SENTRY_DSN`, `REVENUECAT_ANDROID_KEY`, `GOOGLE_WEB_CLIENT_ID`).
- `android/key.properties` — release signing pointers.
- `android/app/<release>.jks` — release keystore.
- `android/app/google-services.json` — Firebase config.

Server-only secrets (service-role, Anthropic, RevenueCat REST, webhook bearer) → `supabase secrets set`, never in `env*.json`.

## CI/CD

Codemagic builds tagged releases and ships to Google Play **Closed Testing**.

### Decisions

| Decision | Value | Why |
|---|---|---|
| Provider | Codemagic | Native Flutter support, M2 mac instances, free tier covers low release cadence |
| Config | `codemagic.yaml` in repo root | Version-controlled, reviewable, reproducible |
| Trigger | Tag push `v*` only | No noise from main/PR builds; explicit release intent |
| Distribution | Google Play closed-testing track | Manual promote to production from Play Console |
| Signing | Upload key in Codemagic env vars (base64) | Google Play App Signing handles distribution key |
| Build number | `$(date +%s)/60` injected at build | Monotonic, no manual bumping, avoids versionCode collisions |

### First-time setup (manual, one-time)

#### 1. Codemagic account
1. Sign up at codemagic.io with GitHub. Authorize the `loit` repo.
2. Add application → select repo → Codemagic detects `codemagic.yaml`.

#### 2. Base64 the secret files locally
```bash
base64 -i android/app/<keystore>.jks | pbcopy        # → CM_KEYSTORE
base64 -i env.production.json | pbcopy               # → ENV_PRODUCTION_JSON
base64 -i android/app/google-services.json | pbcopy  # → GOOGLE_SERVICES_JSON
```

#### 3. Create Codemagic environment groups
**Teams → Integrations → Environment variables.** All vars marked **Secure**.

| Group | Variable | Source |
|---|---|---|
| `loit_signing` | `CM_KEYSTORE` | base64 keystore |
| `loit_signing` | `CM_KEYSTORE_PASSWORD` | from local `android/key.properties` |
| `loit_signing` | `CM_KEY_ALIAS` | from local `android/key.properties` |
| `loit_signing` | `CM_KEY_PASSWORD` | from local `android/key.properties` |
| `loit_env_prod` | `ENV_PRODUCTION_JSON` | base64 of `env.production.json` |
| `loit_google` | `GOOGLE_SERVICES_JSON` | base64 of `google-services.json` |
| `loit_google` | `GCLOUD_SERVICE_ACCOUNT_CREDENTIALS` | raw JSON (step 4) |
| `loit_sentry` | `SENTRY_AUTH_TOKEN` | sentry.io → Settings → Auth Tokens (scopes: `project:releases`, `org:read`) |
| `loit_other` | `SUPABASE_GATE_URL` | `https://<project-ref>.supabase.co` (no trailing slash) |
| `loit_other` | `SUPABASE_GATE_SERVICE_KEY` | Supabase → Project Settings → API → **service_role** secret |

#### 4. Google Play service account
1. **Play Console → Setup → API access → Create new service account** → link Google Cloud project.
2. **Google Cloud Console → IAM → Service Accounts → Keys → Add key → JSON** → download.
3. Back in Play Console → grant permissions: **Releases (Admin)** + **Store presence (Edit)**, restricted to LOIT app only.
4. Paste full JSON content into `GCLOUD_SERVICE_ACCOUNT_CREDENTIALS` (raw JSON, **not** base64).

#### 5. Closed testing track
1. **Play Console → Testing → Closed testing → Create track** (e.g. `alpha`).
2. Edit `codemagic.yaml`: `publishing.google_play.track: alpha` (or your track name).
3. Add tester email list / Google Group before promoting.

#### 6. First manual upload
Play Publishing API rejects the **first** AAB. Build locally and upload once via Play Console:
```bash
flutter build appbundle --dart-define-from-file=env.production.json
```
Upload `build/app/outputs/bundle/release/app-release.aab` to closed-testing track.

#### 7. Trigger CI
```bash
git tag v1.0.3
git push origin v1.0.3
```
Codemagic detects tag → builds → uploads AAB to track → emails result.

#### 8. Update gate (ADR-0015)

Forces or nudges old clients to update. CI parses the release tag and upserts a
single-row `app_release_gate` table; the client compares its own `versionName`
against three semver thresholds. One-time wiring:

1. **Apply the migration.** `app_release_gate` ships in
   `supabase/migrations/20260619000000_app_release_gate.sql`. Apply it:
   ```bash
   supabase db push          # against the linked remote project
   ```
   It seeds one row (`id = 1`) with all thresholds at `0.0.0` (gate open — every
   client is up to date) and a default `store_url`. Verify in the SQL editor:
   ```sql
   select * from app_release_gate;   -- expect exactly one row, id = 1
   ```
2. **Confirm anon read works** (the Blocked overlay must load before sign-in):
   ```bash
   curl "$SUPABASE_GATE_URL/rest/v1/app_release_gate?id=eq.1&select=*" \
     -H "apikey: <ANON_KEY>"
   # -> 200 with the single row. If 401/empty, re-check the RLS SELECT policy.
   ```
3. **Create the `loit_other` Codemagic group** (step 3 table) with:
   - `SUPABASE_GATE_URL` = `https://<project-ref>.supabase.co` (project ref is in
     the Supabase dashboard URL / Project Settings → General). **No trailing slash.**
   - `SUPABASE_GATE_SERVICE_KEY` = the **service_role** key
     (Project Settings → API → Project API keys → `service_role`, "reveal").
     This key bypasses RLS so CI can write the row — mark it **Secure**, never put
     it in `env*.json`, never expose it client-side.
4. **Optional — confirm the service key can write** before relying on CI:
   ```bash
   curl -X PATCH "$SUPABASE_GATE_URL/rest/v1/app_release_gate?id=eq.1" \
     -H "apikey: <SERVICE_ROLE_KEY>" \
     -H "Authorization: Bearer <SERVICE_ROLE_KEY>" \
     -H "Content-Type: application/json" -H "Prefer: return=representation" \
     -d '{"latest_version":"1.0.18"}'
   # -> 200 with the updated row.
   ```
5. **Release with severity** via `/push-deploy`:
   - plain `v1.2.0` → sets `latest` (no in-app prompt).
   - `v1.2.0-recommended` → dismissible "update" sheet every launch.
   - `v1.2.0-breaking` → non-dismissible block until updated.

   After CI runs, the `Update release gate` build step prints the upsert payload —
   check the log to confirm the thresholds moved.

> **Manual override / rollback.** Thresholds only ever move up via the tag
> cascade. To correct a mistaken `-breaking` tag (or roll the gate back), edit the
> row directly in the Supabase SQL editor — e.g. `update app_release_gate set
> min_version = '0.0.0' where id = 1;` to unblock everyone.

### Gotchas

- Keystore mismatch with Play App Signing upload key → upload rejected. Use the upload key registered in Play Console.
- POSTHOG key passed via Gradle `-PPOSTHOG_API_KEY` (see `android/app/build.gradle.kts`), not via `--dart-define`.
- `sentry_dart_plugin` reads `SENTRY_AUTH_TOKEN` from env during build — release + source-maps auto-uploaded.
- Cost: M2 mac mini ~$0.095/min; build ~10–15 min. Free tier covers ~500 build min/month.
