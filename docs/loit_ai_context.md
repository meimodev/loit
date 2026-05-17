# LOIT — AI Context

> **Read this before touching code.** This file is the source of truth for what LOIT is, how it's structured, and the rules you must follow when modifying it. If anything you're about to do contradicts this file, stop and ask.

---

## 1. Product, in 60 seconds

LOIT is a personal finance app for Indonesia, Android-first (iOS later), currently in Google Play Closed Testing at version 1.0.4+5. Offline-first, AI-powered scanning, real-time collaborative rooms, IDR-native pricing. Bootstrap-funded.

The three pillars: **offline reliability** (spotty regional networks), **AI scanning** (extract + categorize + match account in one Claude call), and **collaborative rooms** (shared expense pools for households, kos-kosan splits, arisan, family pools).

Three tiers: Free, Lite (Rp 29k/mo), Pro (Rp 39k/mo). Top-up at Rp 9k for 15 scans, free tier only.

---

## 2. Domain glossary

Use these terms exactly as defined. Don't invent synonyms.

| Term | Meaning |
|------|---------|
| **Room** | A shared expense pool with multiple members. Has its own transactions, budgets, base currency. |
| **Room creator** | The user who created the room. Acts as manager. Counts against their creation quota permanently — archiving doesn't free the slot. |
| **Room member** | A user invited to a room. Can log transactions in it regardless of tier. |
| **Scan** | One execution of the scan pipeline. Consumes one scan from the user's monthly quota on successful completion. Failures refund quota. |
| **Top-up** | One-time IAP that grants extra scans to free-tier users. Rp 9k for 15 scans. |
| **Tier** | Free, Lite, or Pro. Determines scan quota, room creation limit, FX provider, feature gates. |
| **Quota** | Monthly scan limit (5 / 30 / 150 by tier) plus permanent room-creation limit (1 / 1 / unlimited). |
| **FX provider** | Currency exchange rate source. Frankfurter for free/lite, Open Exchange Rates for pro. |
| **Receipt** | Common name for any scanned document. Pipeline actually accepts 10 document types (merchant receipt, invoice, payslip, bank transfer slips, ATM slips, e-wallet confirmations, etc.). |
| **UU PDP** | Indonesia's data protection law (Undang-Undang Perlindungan Data Pribadi). Compliance affects data handling code. |

---

## 3. Tech stack — exact versions

### Client
- Flutter **3.24+**, Dart **3.8+**
- State: **Riverpod 3 with codegen** (Notifier/AsyncNotifier). **No legacy `StateNotifier`.**
- Navigation: **go_router 14.6**
- Local DB: **Drift 2.22**
- Backend SDK: **Supabase Flutter 2.8**
- Payments: **RevenueCat Purchases 10.0.1**
- Push: **Firebase Cloud Messaging 16.2**
- Charts: **fl_chart 0.69**
- Analytics: **PostHog Flutter 5.0**
- Errors: **Sentry Flutter 8.10**

### Backend
- Supabase (Postgres 15+, Auth, Realtime, Storage)
- **Row-Level Security enabled on all user-scoped tables**
- Edge Functions in **Deno** (TypeScript)
- Claude **Haiku 4.5** via Anthropic API (model id `claude-haiku-4-5-20251001`)

### Build & Distribution
- CI/CD: **Codemagic** (tag-driven releases)
- Channel: Google Play Closed Testing → Production
- Version format: `1.0.4+5` — build number is `unix_timestamp / 60`

### File system layout
```
lib/
├── main.dart                 # Firebase → Supabase → PostHog → Sentry init
├── app.dart                  # Integration hub
├── core/
│   ├── config/               # env, pricing_constants, categories
│   ├── routing/              # go_router config
│   ├── theme/                # design tokens, theme composition
│   └── services/             # payment, scanner, sync, push, etc.
├── features/                 # 15 feature areas, ~230 screens
├── shared/
│   ├── providers/            # Riverpod 3 async notifiers
│   ├── widgets/              # loit_* design primitives
│   └── utils/                # amount input, invite tokens, etc.
└── l10n/                     # arb files, codegen output
```

---

## 4. Architectural rules — non-negotiable

These rules cannot be violated. If a feature seems to require violating one, raise it as a question instead of working around it.

### 4.1 Tier state is webhook-controlled

The RevenueCat webhook is the **only authoritative source** for tier mutations. Client-side code reads tier state from the user row but cannot write to it. Never add code that flips a user's tier from the client.

### 4.2 Offline-first

Every user-initiated write must succeed locally first (Drift), then queue for sync. UI must never block waiting for a network round-trip on a write operation. Reads can show stale local data with a soft refresh indicator while syncing.

### 4.3 RLS at the database layer

Row-level security policies on Supabase tables are the security boundary. Never assume client-side filtering is sufficient. Every new table that holds user-scoped data must ship with RLS policies in the migration.

### 4.4 Design tokens only

UI components must consume `loit_colors`, `loit_spacing`, `loit_radius`, `loit_typography`, `loit_motion`, `loit_elevation`. **No inline styling.** No raw hex colors. No magic numbers for padding. If a needed token doesn't exist, add it to the system formally rather than patching around it.

### 4.5 No PII in observability

PostHog events and Sentry error reports must never contain:
- Transaction amounts (in rupiah or any currency)
- Merchant names from scanned receipts
- User-entered notes
- Payment method details
- Account numbers (we don't store these anyway, but defense in depth)

Track *which* fields users edited, not *what they changed them to*.

### 4.6 Localization required

Every user-facing string goes through the existing arb files. **Both EN and ID translations required before merge.** No hardcoded user-facing strings, even temporarily.

### 4.7 Lints enforced

`flutter_lints` + `custom_lint` + `riverpod_lint`. **No `print` statements** — use the `Log` service. Code that doesn't pass lint doesn't merge.

---

## 5. Tier model — feature gating logic

When implementing feature gates, use this matrix as the source of truth:

| Feature | Free | Lite | Pro |
|---------|------|------|-----|
| Personal transactions & budgets | ✓ | ✓ | ✓ |
| Manual entry, account management | ✓ | ✓ | ✓ |
| Basic reports & charts | ✓ | ✓ | ✓ |
| Full reports & charts | — | — | ✓ |
| Scan quota (per month) | 5 | 30 | 150 |
| Top-up purchases | ✓ | — | — |
| Room creation (lifetime, archive doesn't refund) | 1 | 1 | ∞ |
| Join + log in rooms | ✓ | ✓ | ✓ |
| FX provider | Frankfurter | Frankfurter | Open Exchange Rates |
| Offline mode | ✓ | ✓ | ✓ |
| Biometric lock, Hide Amounts | ✓ | ✓ | ✓ |

**Pricing:** Lite Rp 29,000/mo or Rp 232,000/yr · Pro Rp 39,000/mo or Rp 312,000/yr. Annual = 8× monthly.

**Top-up:** Rp 9,000 for 15 scans, free tier only.

---

## 6. Scan pipeline — the contract

The scan pipeline is 10 deterministic steps. **Do not collapse, reorder, or skip steps without explicit approval.** Each step has clear responsibilities and side-effect rules.

### 6.1 Pipeline summary

1. **Camera capture** — accept all 10 document types, not just receipts
2. **Client-side preprocessing** — 1600px long-edge, JPEG q85, deskew, CLAHE, grayscale
3. **Pre-flight quality gate** — blur/brightness/aspect checks, retake on fail, no quota consumed
4. **Quota check** — verify allowance, present paywall/top-up on cap, throttle on abuse
5. **Claude API call** — single round-trip, returns full extraction + matches + confidence
6. **Arithmetic reconciliation** — verify line items sum to total, soft warning on mismatch
7. **Confidence-driven UX branching** — auto-confirm high, normal medium, warning low
8. **Review screen** — pre-filled, user edits, saves or cancels
9. **Commit & sync** — local Drift write, background sync to Supabase, increment quota counter
10. **Failure handling** — quota refunds atomically on any Step 5 failure path

### 6.2 Claude API contract (DO NOT MODIFY)

**Valid transaction response:**

```json
{
  "is_transaction": true,
  "transaction_kind": "merchant_receipt | invoice | bank_transfer_out | bank_transfer_in | payslip | refund_slip | deposit_confirmation | atm_withdrawal | ewallet_transaction | other",
  "type": "expense | income",
  "merchant": "string | null",
  "currency": "ISO 4217 code | null",
  "items": [{"name": "string", "qty": 1, "unit_price": 0.00, "total_price": 0.00}],
  "total": 0.00,
  "category": "exact key from user's category list",
  "account": "exact name from user's account list",
  "confidence": 0.92
}
```

**Invalid response:**

```json
{
  "is_transaction": false,
  "transaction_kind": null,
  "reason": "short human-readable reason"
}
```

**Rules:**
- `total` is always positive; `type` conveys sign
- `category` must be an exact key from the user's category lists (passed in prompt)
- `account` must be an exact name from the user's account list (passed in prompt)
- `confidence` is a single overall scalar 0.0–1.0
- Names only in the prompt — no descriptions for categories or accounts

### 6.3 Confidence thresholds

| Confidence | UX behavior |
|------------|-------------|
| ≥ 0.90 | Green check, optional 3-sec auto-confirm (user-toggleable, default on) |
| 0.70 – 0.89 | Normal review screen, no special treatment |
| < 0.70 | Soft warning at top, no flow block |

### 6.4 Quota refund rules

Refund on:
- Malformed JSON from Claude (after one retry)
- `is_transaction: false` (with friendly reason to user)
- Network/API timeout (after one retry with backoff)
- Any uncaught exception in Step 5

**Refund is atomic with the failure**, local first, server sync follows. Increment in Step 9 happens only on successful save.

### 6.5 Single API call rule

The Claude call in Step 5 handles **all four responsibilities in one round-trip**: extraction, category matching, account matching, confidence scoring. **Do not split into multiple calls.** Per-scan cost depends on this single-call architecture.

---

## 7. Code conventions

### 7.1 Riverpod patterns

Use codegen everywhere:

```dart
@riverpod
class ScanController extends _$ScanController {
  @override
  Future<ScanState> build() async { ... }

  Future<void> startScan() async { ... }
}
```

Not:
```dart
// DO NOT USE
final scanProvider = StateNotifierProvider<...>((ref) => ...);
```

### 7.2 Naming

- Files: `snake_case.dart`
- Classes: `PascalCase`
- Variables/functions: `camelCase`
- Constants: `lowerCamelCase` (Dart convention, not `SCREAMING_CASE`)
- Riverpod providers: `nounController` or `nounProvider` (codegen produces the suffix)

### 7.3 Localization keys

Format: `featureArea.subArea.purpose`

Examples:
- `scanner.qualityGate.blurryRetake`
- `paywall.topUp.confirmPurchase`
- `room.invite.acceptPrompt`

Both EN and ID arb files updated in the same commit.

### 7.4 Logging

Use the `Log` service, never `print`:

```dart
Log.info('Scan started', extra: {'tier': tier, 'scansThisMonth': count});
Log.error('Scan API failure', error: e, stack: stack);
```

### 7.5 Testing

Test hooks via `flutter_test`, `build_runner`, `drift_dev`, `sentry_dart_plugin`. Mock the Claude API in scanner tests using the `PaymentService`-style abstraction pattern (interface + dummy implementation).

---

## 8. Things to NEVER do

A non-exhaustive list of patterns that have been considered and rejected. If you find yourself implementing one of these, stop.

1. **Never flip a user's tier from the client.** Only the RevenueCat webhook can. The client reads tier state; it doesn't write it.
2. **Never bypass RLS by using a service-role key from the client.** Service-role keys belong in Edge Functions only.
3. **Never store payment credentials.** Card numbers, bank account numbers, CVVs — none of these enter the codebase. Payment flows go through RevenueCat → Google Play / StoreKit.
4. **Never block the UI on network writes.** Local DB first, sync second.
5. **Never split the scan pipeline into multiple Claude calls.** Single round-trip is a cost decision and a UX decision.
6. **Never add `print` statements.** Use `Log`.
7. **Never hardcode user-facing strings.** Always through l10n arb files.
8. **Never include user financial amounts in PostHog or Sentry payloads.**
9. **Never use inline styling.** Always through `loit_*` design tokens.
10. **Never bypass the scan quota check** (Step 4) for "internal" or "testing" scans. Use the admin grant flow if testing needs more quota.
11. **Never reuse a Supabase Edge Function for unrelated purposes.** Each function has a single responsibility.
12. **Never assume connectivity.** Code paths must handle offline gracefully.

---

## 9. Things to ALWAYS verify before implementing

When asked to add a feature, work through this checklist:

1. **Does it affect tier gating?** Update the matrix in Section 5. Verify both free and paid behavior.
2. **Does it write data?** Verify offline behavior — does it queue correctly?
3. **Does it read user-scoped data?** Verify RLS policy exists.
4. **Does it add a user-facing string?** Add both EN and ID translations.
5. **Does it add a UI component?** Use design tokens. No inline styling.
6. **Does it touch the scan pipeline?** Re-read Section 6. Verify single-call rule.
7. **Does it touch payment flows?** Verify RevenueCat webhook is still the source of truth.
8. **Does it add a Riverpod provider?** Use codegen syntax.
9. **Does it add observability?** No PII. Verify event names follow `featureArea.action` format.
10. **Does it require a database change?** Add migration. Include RLS policies.

---

## 10. When to ask before doing

Some things look like simple code changes but are actually product decisions in disguise. Ask before doing any of these:

- Changing tier capabilities, pricing, or quota numbers
- Adding new tier or removing existing one
- Modifying the Claude API contract (Section 6.2)
- Changing confidence thresholds (Section 6.3)
- Adding a new payment-related capability
- Changing what counts as a "scan" (e.g., should bulk imports consume scans?)
- Changing the room model (creation rules, member roles, archive behavior)
- Adding analytics events that could touch PII
- Changing localization strategy or adding new languages
- Removing the offline-first guarantee for any code path

---

## 11. Compliance touchpoints

When code touches any of these areas, flag for human review:

- **UU PDP** (Indonesia data protection): user data collection, retention, deletion, export
- **Google Play policies**: subscription management, in-app purchase flow, refunds
- **OJK boundary**: LOIT is a tracker, not a payment processor or lender. Don't add features that cross this line without explicit legal review.
- **Anthropic API usage policies**: prompt content, output handling
- **Supabase data residency**: where user data is stored matters for UU PDP

---

## 12. Quick reference

**Per-scan cost target:** Rp 74 (Haiku 4.5, USD/IDR @ 18,000, all optimizations on).
**Image preprocessing target:** long edge exactly 1600px, JPEG quality 85.
**API model:** `claude-haiku-4-5-20251001`.
**Scan API caching:** prompt caching on static portion of system prompt; image and user lists not cached.
**Failure retry policy:** one retry with backoff, then refund quota and surface error to user.
**Sync conflict resolution:** server wins; local pending writes retry until server accepts or rejects.
**Auth flow:** Supabase Auth with PKCE; Google OAuth + email/OTP fallback.
**Push token:** FCM, refreshed on app start; stored in user row.

---

*Update this file when any rule changes. Keep it dense — every line is loaded as context for AI work.*
