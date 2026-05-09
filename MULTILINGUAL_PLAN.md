# Multilingual Support Plan (LOIT)

End-to-end plan for shipping a user-switchable language toggle (Settings → Preferences → App language) backed by Flutter `gen_l10n`. Initial locales: **English (`en`)** and **Bahasa Indonesia (`id`)**. The system is designed so a third locale can be added later by dropping in a single `.arb` file.

---

## 0. Current State (as of branch `main`, 2026-05-10)

What already exists:
- `pubspec.yaml`: `flutter_localizations` SDK dep present; `flutter: generate: true` flag set.
- `l10n.yaml` configured (`arb-dir: lib/l10n`, template `app_en.arb`, output dir `lib/l10n/gen`, output class `AppLocalizations`).
- `lib/l10n/app_en.arb` and `lib/l10n/app_id.arb` exist but contain **only ~10 paywall/FX strings** (24 lines each).
- Generated files at `lib/l10n/gen/{app_localizations,app_localizations_en,app_localizations_id}.dart`.
- `AppPreferences.language` field (`'en' | 'id' | 'system'`) persisted in `SharedPreferences` via `PreferencesNotifier.setLanguage`.
- `PreferencesScreen` exposes a language picker that writes `prefs.language`.

What is **missing**:
- `MaterialApp.router` in `lib/app.dart` does **not** set `locale`, `localizationsDelegates`, or `supportedLocales`. The picked language never takes effect.
- ~130 Dart files, of which ~68 use `Text(...)` with hardcoded English strings (settings labels, screen titles, snackbars, error text, empty states, etc.).
- Default category labels (`CategoryDefaults.expenseKeys` / `incomeKeys`) are stored as keys but rendered via ad-hoc maps in widgets — not yet routed through `.arb`.
- No locale-aware date/number formatting strategy (currency formatting partially in `currency_service.dart` but not locale-driven).
- Server-emitted strings (push notifications via `room-transaction-notify`, scheduled crons) are English-only.
- No CI/lint guard against unlocalized strings.

Phase 1 of this plan closes the wiring gap. Phases 2-5 migrate code surfaces incrementally.

---

## 1. Architectural Decisions

### 1.1 Stack
- **`flutter_localizations` + `gen_l10n`** (Flutter SDK, already wired). No runtime-fetched translations, no third-party libs (`easy_localization`, `slang`, etc.) — keeps the build hermetic and avoids extra deps.
- **ARB files** (`app_en.arb`, `app_id.arb`) under `lib/l10n/`. Generated `AppLocalizations` class consumed via `AppLocalizations.of(context)` (we will add a `context.l10n` extension for ergonomics).
- **`intl`** package (transitive via `flutter_localizations`) for `DateFormat`, `NumberFormat`. Already locale-aware once `Localizations.localeOf(context)` is correct.

### 1.2 Locale source of truth
- `AppPreferences.language` keeps three values:
  - `'system'` → follow device locale, falling back to `'en'` if device locale is not in `supportedLocales`.
  - `'en'` → force English.
  - `'id'` → force Bahasa Indonesia.
- `MaterialApp.router` reads a derived `Locale?` via a new synchronous provider `localePrefProvider` (mirrors the existing `themeModePrefProvider` pattern in `preferences_provider.dart`). When `language == 'system'`, the provider returns `null` so Flutter delegates to the device locale resolver.
- `localeResolutionCallback` clamps unknown device locales to `'en'`.

### 1.3 Key naming convention
- **`<area><Element>`** camelCase. Examples: `settingsTitle`, `preferencesAppLanguage`, `txFormAmountLabel`, `roomDetailEmptyState`.
- **Plurals/placeholders** use ICU syntax with explicit `@key` metadata blocks.
- **Domain keys stay stable**: category keys (`dining`, `income_salary`) become ARB keys prefixed `category_` (e.g. `category_dining`, `category_income_salary`). Migration data is unaffected.
- **No string concatenation across keys.** A sentence is one key; placeholders use `{name}`.

### 1.4 Ergonomics helper
Add `lib/l10n/l10n_x.dart`:
```dart
import 'package:flutter/widgets.dart';
import 'gen/app_localizations.dart';

extension L10nX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this)!;
}
```
Call sites become `context.l10n.settingsTitle` instead of `AppLocalizations.of(context)!.settingsTitle`.

### 1.5 Non-context surfaces
For places without a `BuildContext` (services, providers, edge function payloads), use one of two patterns:
1. **Pass `AppLocalizations` in.** The widget reads `context.l10n` and forwards what it needs (preferred).
2. **Return locale-neutral data** (enums, error codes, keys) and translate at the render site (preferred for `*_service.dart`, providers, repository layer).

We will not store locale globally in a service singleton — that path historically leads to stale strings after a language switch.

### 1.6 Server-emitted strings (push notifications, emails, exports)
- The `users` table already exists. Add a column `users.language text default 'en'` (migration in Phase 4) populated whenever the client calls `setLanguage`.
- Edge functions that emit user-facing strings (`room-transaction-notify`, `recurring-bills-cron`, `receipt-expiry-cron`) read `users.language` and template against a small server-side dictionary in `supabase/functions/_shared/i18n.ts`.
- **In scope for v1**: `room-transaction-notify` push body. Other edge functions can defer to Phase 5.

---

## 2. Phased Rollout

Each phase is independently shippable. Phase boundaries map to PRs that can land separately.

### Phase 1 — Plumbing (no user-visible string changes)

Goal: MaterialApp consumes the language preference; existing 10 strings continue to work; nothing else regresses.

Steps:
1. **Add `localePrefProvider`** in `lib/shared/providers/preferences_provider.dart`:
   ```dart
   final localePrefProvider = Provider<Locale?>((ref) {
     final lang = ref.watch(preferencesProvider).maybeWhen(
           data: (p) => p.language,
           orElse: () => 'system',
         );
     return switch (lang) {
       'en' => const Locale('en'),
       'id' => const Locale('id'),
       _ => null,
     };
   });
   ```
2. **Wire `MaterialApp.router`** in `lib/app.dart`:
   ```dart
   import 'l10n/gen/app_localizations.dart';
   ...
   return MaterialApp.router(
     ...
     locale: ref.watch(localePrefProvider),
     supportedLocales: AppLocalizations.supportedLocales,
     localizationsDelegates: AppLocalizations.localizationsDelegates,
     localeResolutionCallback: (device, supported) {
       if (device == null) return const Locale('en');
       for (final s in supported) {
         if (s.languageCode == device.languageCode) return s;
       }
       return const Locale('en');
     },
     ...
   );
   ```
3. **Add `context.l10n` extension** at `lib/l10n/l10n_x.dart`.
4. **Run codegen**: `flutter pub get && dart run build_runner build --delete-conflicting-outputs` (codegen also rebuilds `lib/l10n/gen/`). Verify `flutter analyze` is clean.
5. **Smoke test**:
   - Cold-start with device set to `id-ID` → app uses Indonesian for the existing 10 paywall strings.
   - Toggle Settings → Preferences → App language between English (US) / Bahasa Indonesia → strings flip live (Riverpod rebuild).
   - Set `'system'` → matches device.

Acceptance criteria: switching language in settings flips the existing translated strings without restarting; theme toggle still works; no analyzer regressions; `flutter test` green.

Files touched: `lib/app.dart`, `lib/shared/providers/preferences_provider.dart`, `lib/l10n/l10n_x.dart` (new). No `.arb` content changes.

### Phase 2 — Settings & Preferences surface (high-trust translation island)

Why first: the user picks language here. The settings screens must be translated so the toggle is discoverable in either locale. Also small surface (`lib/features/settings/`, ~7 files) that exercises the full pipeline.

Steps:
1. Inventory hardcoded strings in `lib/features/settings/{settings_screen,preferences_screen,profile_screen,security_screen,notifications_screen,about_screen,_widgets}.dart`.
2. Add ARB keys with `settings*` / `prefs*` / `notif*` / `security*` / `about*` prefixes. Examples:
   - `settingsTitle`, `settingsAccount`, `settingsPreferences`, `settingsSecurity`, `settingsNotifications`, `settingsAbout`, `settingsSignOut`.
   - `prefsTitle`, `prefsLanguage`, `prefsAppLanguage`, `prefsCurrency`, `prefsRegion`, `prefsTheme`, `prefsThemeSystem`, `prefsThemeLight`, `prefsThemeDark`, `prefsCategoriesManage`, `prefsSyncFooter`.
   - Language option *labels* themselves (`prefsLanguageEnglish`, `prefsLanguageIndonesian`) live in the ARB so the picker shows native-language names regardless of current locale (or always shows endonyms — see §3.4).
3. Replace literal strings with `context.l10n.<key>`.
4. Translate to Indonesian in `app_id.arb`.
5. Manual QA pass on every settings sub-screen in both locales (long-string overflow check on `id`, since Indonesian phrasing is often 10-30% longer).

Acceptance: every visible string under `/settings/**` flips on toggle; pickers (theme, language, region) remain functional; no layout overflow on a 360-px-wide test device.

### Phase 3 — Core user flows

Translate the screens users hit on every session. Order is by traffic, highest first:
1. **Dashboard** (`lib/features/dashboard/`) — balances, monthly summary, empty states.
2. **Transactions list & detail** (`lib/features/transactions/`).
3. **Transaction form** (`lib/features/transactions/transaction_form_screen.dart`) — labels, validators, snackbars.
4. **Categories** (`lib/features/categories/` + `core/config/categories.dart`):
   - Add ARB keys `category_<key>` for every default key.
   - Add a single helper `String localizeCategory(BuildContext context, String key)` in `lib/core/config/categories.dart` that maps `key → context.l10n.category_<key>` with a fallback to the raw key for user-defined categories (which are user-typed text and must NOT be translated).
   - Update every render site (`category_picker_sheet.dart`, transaction rows, budget rows, dashboard chart legends) to call the helper.
5. **Budgets** (`lib/features/budgets/`).
6. **Accounts** (`lib/features/accounts/`).
7. **Scanner** (`lib/features/scanner/`) — scan FAB, camera prompts, receipt review screen, error states.
8. **Receipts** (`lib/features/receipts/`).
9. **Rooms list + detail + invite** (`lib/features/rooms/`, `lib/features/room_detail/`).
10. **Reports + export** (`lib/features/reports/`).
11. **Paywall + billing** (`lib/features/paywall/`, `lib/features/billing/`) — already has FX/paywall strings; expand coverage. Pricing values stay hardcoded (regulatory + RC alignment) but surrounding copy is translated.
12. **Auth** (`lib/features/auth/`) — sign-in, OTP, errors. Surface Supabase errors via `error_codes` mapped to translated strings (do not show raw Supabase `AuthException.message` to the user).
13. **System** (`lib/features/system/lock_screen.dart`).

Per-screen workflow (run as one PR per screen or one per feature folder):
1. Grep for `Text(` and string literals in screen files.
2. Add ARB keys, translate.
3. Replace call sites.
4. Add a widget test that pumps the screen with `Locale('id')` and asserts at least one Indonesian string is present (cheap regression guard).
5. Manual pass on overflow / wrapping.

### Phase 4 — Locale-aware formatting

1. **Dates**: replace any direct `DateFormat('...')` with `DateFormat.yMMMd(Localizations.localeOf(context).toLanguageTag())` (or task-appropriate skeleton). Common cases: transactions list grouped headers, dashboard "This month", reports date pickers.
2. **Numbers**: locale-aware grouping/decimal separators via `NumberFormat.decimalPattern(locale)`.
3. **Currency**:
   - `lib/core/services/currency_service.dart` already formats by ISO code. Update `formatAmount` to accept a `Locale` (or read it from the call site) so `Rp1,234,567` renders with `.` separators on `id` and `,` on `en`.
   - Audit every `LoitAmountText` / `Text('Rp...')` call site.
4. **Pluralization & gender**: introduce ICU `{count, plural, ...}` patterns where strings depend on counts (e.g. "1 transaction" vs "5 transactions" vs Indonesian "1 transaksi" / "5 transaksi" — same plural form, but the ICU markup keeps future locales clean).
5. **`users.language` DB column**:
   - Migration `supabase/migrations/<ts>_users_language.sql`: `alter table users add column language text not null default 'en' check (language in ('en','id'));`
   - `setLanguage` write-through in `PreferencesNotifier` (mirror `setCurrency` pattern: best-effort `update users set language = ? where id = ?`).
   - Realtime sync in `app.dart` (`users` row listener already exists; mirror DB → SharedPreferences via a new `syncLanguageFromDb`).

### Phase 5 — Server-emitted strings & polish

1. `supabase/functions/_shared/i18n.ts` — small dictionary keyed by `(locale, messageKey)` returning a templated string. Loaded in `room-transaction-notify`, `recurring-bills-cron`, `receipt-expiry-cron`.
2. Each edge function reads `users.language` for the recipient and templates the push title/body.
3. Email/PDF export header strings (`features/reports/export_service.dart`) take a locale param.
4. Add a CI lint script `tool/check_unlocalized.dart` that greps `Text('[A-Z]` patterns in `lib/features/**` (excluding tests + design-system primitives) and fails the build above a threshold. Ratchet down the threshold over time.
5. App store listing translations (Play Console) — separate workstream, tracked but out of code scope.

---

## 3. Implementation Details

### 3.1 ARB file conventions
- One key per logical string. **Never** reuse a key for two different sentences just because the English happens to match — Indonesian phrasing may diverge.
- Always pair user-facing keys with a `@key` metadata block describing context for translators:
  ```json
  "txFormAmountLabel": "Amount",
  "@txFormAmountLabel": {
    "description": "Label above the amount input on the transaction form"
  }
  ```
- Placeholders are typed:
  ```json
  "roomMemberJoined": "{name} joined {room}",
  "@roomMemberJoined": {
    "placeholders": {
      "name": {"type": "String"},
      "room": {"type": "String"}
    }
  }
  ```
- Plurals:
  ```json
  "txCount": "{count, plural, =0{No transactions} =1{1 transaction} other{{count} transactions}}",
  "@txCount": {
    "placeholders": {"count": {"type": "int", "format": "compact"}}
  }
  ```
- Sort keys by area, alphabetical within an area, with section banner comments. ARB allows arbitrary key order; codegen does not care.

### 3.2 Provider / file layout

```
lib/
  l10n/
    app_en.arb          # canonical, source of truth
    app_id.arb          # mirrors app_en.arb keys (CI-checked)
    l10n_x.dart         # context.l10n extension
    gen/                # generated, gitignored after Phase 1
      app_localizations.dart
      app_localizations_en.dart
      app_localizations_id.dart
  shared/
    providers/
      preferences_provider.dart  # adds localePrefProvider
```

Decision: keep `lib/l10n/gen/` checked in for now (matches current repo state; trims first-clone friction) but gate via `.gitignore` once Phase 1 is stable, since regen is deterministic.

### 3.3 Categories migration plan
Default category keys are stored in DB rows. Migration:
- **No DB change** — keep `key` columns as the canonical identifier.
- Add `localizeCategory(context, key)` helper.
- User-defined categories (`user_categories.label`) are user-typed; render `label` directly (no translation lookup).
- A category whose key is missing from the ARB falls back to a Title-cased version of the key.

### 3.4 Language picker labels
The picker should always show **endonyms** ("English", "Bahasa Indonesia") so a user who accidentally switched to a language they don't read can still find their way back. Implementation: hardcode endonyms in the picker, do not run them through `context.l10n`.

### 3.5 Testing strategy
1. **Unit**: `localePrefProvider` returns expected `Locale?` for each `language` value.
2. **Widget**: pump each migrated screen with `Locale('en')` and `Locale('id')`, assert one stable Indonesian phrase per screen (e.g. settings shows "Pengaturan").
3. **Golden**: optional, only for the few screens with tight overflow risk (paywall card, dashboard hero).
4. **CI parity check**: `tool/arb_parity.dart` script that loads both ARB files and asserts the same key set; runs in `flutter analyze` step.

### 3.6 Migration safety
- ARB key renames are breaking for translators. Once a key is in `app_id.arb`, prefer adding a new key over renaming.
- Removing a key is fine — codegen drops it, no runtime impact.
- Pluralization changes (e.g. switching a `String` placeholder to `int plural`) are codegen breaking — bundle with the call-site update in one PR.

### 3.7 Anti-patterns to avoid
- **No `Intl.message` strings inside services or models.** They couple non-UI code to localization.
- **No mid-sentence concatenation**: bad `"Hello, " + name + "!"`; good `context.l10n.greeting(name)` with `Hello, {name}!` in ARB.
- **No translating user-supplied content**: account names, room names, category names, transaction notes are all user-typed and must render verbatim.
- **No translating regulated/branded strings**: pricing values (`Rp99,000/mo`), brand name "LOIT", legal copy unless reviewed.
- **No locale-driven layout changes** without tests — Indonesian strings can be 30% longer; check long-form screens (paywall, billing receipt).

### 3.8 Translator workflow
- Source: edit `app_en.arb`. Each new key MUST include a `@key` description.
- Mirror keys into `app_id.arb` with the Indonesian translation. CI parity check enforces this.
- For future locales, copy `app_en.arb` to `app_<lang>.arb`, translate values, leave keys + placeholders untouched.

---

## 4. Adding a Future Locale (worked example: `ms` Malay)

1. Create `lib/l10n/app_ms.arb` (copy `app_en.arb`, translate values, keep keys).
2. Add `'ms'` to `_decodeLanguage` / `localePrefProvider` switch.
3. Add Malay endonym ("Bahasa Melayu") and code (`'ms'`) to `_kLanguageCodes` in `preferences_screen.dart`.
4. Add `'ms'` to the `users.language` CHECK constraint via migration.
5. Server dictionary entries in `supabase/functions/_shared/i18n.ts`.
6. Run codegen, verify with `flutter analyze`, ship.

No app-wide refactor required — that is the point of front-loading Phases 1-3.

---

## 5. Risks & Open Questions

- **Translator throughput**: with no dedicated translator on the team, `app_id.arb` will be machine-translated initially and reviewed by a native speaker before each release. Track this as a checklist item per PR that adds new ARB keys.
- **Currency vs language separation**: a user in Indonesia may want USD home currency, or vice versa. Confirm: the language picker only changes UI text. Currency is a separate setting (already true in `preferences_provider.dart`).
- **Server push localization timing**: Phase 5 ships ~2-3 weeks after Phase 1. Acceptable as long as in-app strings are localized first (the more visible surface).
- **`flutter_localizations` vs `intl 0.20.x`**: Flutter SDK pins `intl`. If we need a newer `intl`, may require `dependency_overrides`. Defer until a feature actually needs it.
- **iOS deferred**: localization works identically on iOS; no extra work when iOS is enabled later.
- **Tests in CI**: golden tests are flaky across machines; gate them behind `--update-goldens` locally and skip in CI for now.

---

## 6. Definition of Done (per phase)

| Phase | Done when |
|---|---|
| 1 | Toggling language in Settings flips the existing 10 paywall strings without restart. |
| 2 | All `lib/features/settings/**` strings translated; widget test asserts Indonesian copy. |
| 3 | Each high-traffic screen has zero hardcoded user-facing strings (verified by `tool/check_unlocalized.dart` per-folder allowlist). |
| 4 | Dates and numbers render with locale-correct separators in both `en` and `id`. `users.language` column populated for all active users. |
| 5 | A push notification sent to a user with `language='id'` arrives in Indonesian. |

---

## 7. Task checklist (PR-sized chunks)

- [ ] PR 1: Phase 1 plumbing — `localePrefProvider`, `MaterialApp.router` wiring, `context.l10n` extension.
- [ ] PR 2: Phase 2 settings — ARB keys, translations, swap call sites.
- [ ] PR 3: Phase 3.1 dashboard.
- [ ] PR 4: Phase 3.2-3.3 transactions list + form.
- [ ] PR 5: Phase 3.4 categories (helper + call site sweep).
- [ ] PR 6: Phase 3.5 budgets.
- [ ] PR 7: Phase 3.6 accounts.
- [ ] PR 8: Phase 3.7-3.8 scanner + receipts.
- [ ] PR 9: Phase 3.9 rooms.
- [ ] PR 10: Phase 3.10 reports + export.
- [ ] PR 11: Phase 3.11 paywall + billing.
- [ ] PR 12: Phase 3.12 auth + error code mapping.
- [ ] PR 13: Phase 4 — locale-aware date/number/currency + `users.language` migration.
- [ ] PR 14: Phase 5 — edge function dictionary + push notification localization.
- [ ] PR 15: Phase 5 — CI lint guard, ARB parity check, gitignore `lib/l10n/gen/`.
