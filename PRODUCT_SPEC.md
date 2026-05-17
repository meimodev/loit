# LOIT Product Specification

## 1. Product Positioning & Value Prop

**LOIT** is a personal finance application designed for Indonesian users, enabling comprehensive expense and income tracking with support for multi-currency and multi-account management. Core offering: budget monitoring, receipt scanning with AI OCR, transaction categorization, spending insights via charts/reports, and collaborative finance tracking via shared rooms (multiplayer mode).

**Target User:** Individual Indonesian personal finance managers (adults 18-55) with recurring expenses, savings goals, and potential household/group spending scenarios. Secondary: small teams needing shared expense pools (roommates, small businesses, event splitting).

**Key Differentiators:**
- AI-powered receipt scanning (via Claude) with OCR extraction to line items
- Offline-first with automatic sync-on-reconnect via Drift SQLite queue
- Multi-account & multi-currency support (FX rates cached, tier-aware staleness)
- Collaborative rooms with real-time presence, member invites, and room-scoped budgets
- Biometric app lock (Face/Touch ID) + Hide Amounts mode for privacy
- Native Android implementation; iOS deferred to later phase

---

## 2. Target Market & Monetization

**Tiers & Pricing (Android/Google Play, IDR):**

| Tier | Monthly | Annual | Key Features | Scan Limit |
|------|---------|--------|--------------|-----------|
| **Free** | — | — | Personal accounts, basic categories, 8 scans/month, limited dashboard | 8/month |
| **Pro** | Rp99,000 | Rp792,000 | Unlimited scans, all personal features, basic reports | Unlimited |
| **Team** | Rp199,000 | Rp1,592,000 | All Pro + shared rooms, multi-member collaboration | Unlimited |

**Monetization Strategy:**
- Annual = 8× monthly (4 months free, 33% discount messaging)
- In-app one-time purchases for free-tier top-ups: Scan Top-Up (10 scans × Rp19,000), Storage Extension (6 months × Rp19,000)
- Payment processing: Google Play Billing → RevenueCat SDK → RevenueCat webhook (only authoritative tier flip location)
- No in-app ads; subscription revenue model
- USD equivalents: Pro $5.99/mo, Team $11.99/mo (display-only on App Store; primary pricing in IDR)

**iOS Pricing (future, ~15-20% premium):**
- Pro monthly: Rp115,000 | Pro annual: Rp920,000
- Team monthly: Rp229,000 | Team annual: Rp1,832,000

---

## 3. Feature Inventory

### Phase 1: Personal Core (✓ Shipped)
- **Auth:** Google Sign-In + Supabase PKCE, email + OTP fallback, region selection
- **Accounts & Transfers:** Multi-account CRUD (savings, checking, credit, liabilities), account balances, transfer between accounts
- **Transactions:** Manual add/edit, categorization (9 expense + 7 income defaults), notes, currency per transaction, FX rate snapshot
- **Receipt Scanning:** Claude AI OCR, parse merchant + line items, attach to transaction, expiry tracking (free-tier quota 8/month)
- **Dashboard:** Daily/monthly transaction feed, stat triple (income/expenses/net), account picker, currency selection
- **Categories:** Default seeds + user-defined categories, category-based budget caps
- **Budgets & Alerts:** Monthly per-category limits, rollover, budget-exceeded alerts
- **Charts & Reports:** Spending by category (pie), time series (line), export CSV/PDF with breakdown
- **Settings:** Theme (light/dark), locale (ID/EN), currency, biometric lock, Hide Amounts
- **Push Notifications:** FCM for important alerts (budget exceeded, room invites, etc.)
- **Offline Mode:** Drift SQLite write queue, auto-sync on reconnect

### Phase 2: Rooms (✓ Shipped)
- **Rooms:** Create shared expense pools, invite members via deep link (invite tokens), accept/reject invites
- **Room Members:** Creator + member list with role (creator = manager), presence tracking, real-time updates
- **Room Transactions:** Members add transactions to room, visible to all, FX conversion to room base currency
- **Room Budgets:** Category budgets scoped to room, shared limit tracking
- **Room-Scoped Features:** Notifications for room activity, room-specific charts and reports
- **Notifications Feed:** Central feed for room invites, budget alerts, room activity (created, updated, etc.)

### Phase 3: Pro/Team Tiers & Payments (Current Phase)
- **RevenueCat Integration:** Live subscription purchase, refund/expiration handling, annual discount, dummy-grant stub for testing
- **Paywall:** Present Pro/Team options, scan top-ups, storage extensions (free-tier-only), manage subscription
- **Feature Gates:** Scan limit per tier (free=8/mo, pro/team=unlimited), room creation gated to team+ (via tier check)
- **Billing History:** View payment receipts, refund status, active subscription details
- **Webhook Sync:** RevenueCat webhook authoritative source for tier mutations (no polling), idempotent on purchase_token
- **Admin Actions:** Tier revocation/grant via supabase admin panel (for support / testing)
- **Quote Management:** Tier-aware FX rate provider (Frankfurter free, Open Exchange Rates pro/team)

### Phase 4: Polish (Future)
- **Recurring Transactions:** Templates for monthly/weekly expenses
- **Analytics Dashboard:** Trends, spending velocity, savings rate, category insights
- **iOS Support:** Build for App Store with native payment (StoreKit)
- **Multi-language Expansion:** Hindi, Tagalog, Vietnamese, Thai
- **Advanced Budgeting:** Alerts, rollover rules, envelope method, goal tracking
- **Data Export:** Full user data export (GDPR/privacy compliance)

---

## 4. Tech Stack Snapshot

**Client (Flutter 3.24+, Dart 3.8+):**
- **State:** Riverpod 3 (Notifier/AsyncNotifier code-gen, no StateNotifier)
- **Navigation:** go_router 14.6 (deep links, auth gating)
- **Backend Sync:** Supabase Flutter 2.8 (Auth PKCE, PostgREST, Realtime, Storage, Functions)
- **Offline:** Drift 2.22 (SQLite ORM with code-gen)
- **Payments:** RevenueCat Purchases 10.0.1 (wraps Google Play Billing)
- **Push:** Firebase Cloud Messaging 16.2
- **Scanning:** Google ML Kit Barcode, camera, image_picker, flutter_image_compress
- **Analytics:** PostHog Flutter 5.0 (product events), Sentry Flutter 8.10 (error monitoring)
- **Design:** Custom design system (loit_colors, loit_spacing, loit_radius, loit_typography, loit_motion, loit_elevation)
- **Localization:** flutter_localizations, intl, arb files (EN + ID)
- **Charts:** fl_chart 0.69
- **Export:** csv, pdf, printing, share_plus

**Backend (Supabase, Node.js/Deno):**
- **Database:** PostgreSQL 15+, RLS enabled
- **Auth:** Supabase Auth (email+OTP, Google OAuth, JWT)
- **APIs:** PostgREST (auto-generated), Realtime (channels + row-level subscriptions)
- **Storage:** S3-compatible (receipts bucket)
- **Edge Functions (Deno):** scan-receipt (Claude OCR), revenuecat-webhook (idempotent tier sync), dummy-grant (test mode), room invites, FCM broadcast, crons (receipt expiry, subscription downgrade)

**Deployment:**
- **Android:** Google Play Closed Testing (via Codemagic), manual promotion to production
- **CI/CD:** Codemagic (tag-driven releases, signing, Play Publishing API)
- **Version:** 1.0.4+5 (pubspec), build number = unix timestamp / 60

---

## 5. Architecture Map

```
┌─────────────────────────────────────────────────────────┐
│           LOIT Flutter Client (Android)                 │
├─────────────────────────────────────────────────────────┤
│  lib/                                                   │
│  ├─ main.dart (Firebase → Supabase → PostHog → Sentry) │
│  ├─ app.dart (Integration hub, auth subscribe, push)   │
│  ├─ core/                                               │
│  │  ├─ config/ (env, pricing_constants, categories)    │
│  │  ├─ routing/ (go_router, deep links, auth gating)   │
│  │  ├─ theme/ (design tokens & composition)            │
│  │  └─ services/ (payment, scanner, sync, push, etc.)  │
│  ├─ features/ (15 screens: auth, dashboard, rooms, … ) │
│  ├─ shared/                                             │
│  │  ├─ providers/ (Riverpod 3, async notifiers)        │
│  │  ├─ widgets/ (loit_* design primitives)             │
│  │  └─ utils/ (amount input, invite tokens, etc.)      │
│  └─ l10n/ (localization, arb + code-gen)               │
└─────────────────────────────────────────────────────────┘
        ↓              ↓               ↓           ↓
   ┌────────────────────────────────────────────────────┐
   │ Supabase (PostgreSQL + Realtime + Edge Functions) │
   ├────────────────────────────────────────────────────┤
   │ Auth (PKCE):           users row (tier, tier_expires_at, scans_used_this_month)
   │ Core Tables:           transactions, accounts, budgets, fx_rates, user_categories
   │ Phase 2 (Rooms):       rooms, room_members, room_budgets, room_invites
   │ Phase 3 (Payments):    payment_receipts (idempotent on purchase_token)
   │ RLS:                   Row-level security, per-user + room-member filters
   │ Edge Functions:        scan-receipt, revenuecat-webhook, dummy-grant, crons
   │ Realtime:              user row updates (tier flips), room transactions, presence
   │ Storage:               receipts bucket (private, signed URLs)
   │ Migrations:            39 migrations, 1727 lines SQL (Phase 1→3)
   └────────────────────────────────────────────────────┘
        ↓          ↓             ↓         ↓         ↓
   [Firebase]  [RevenueCat]  [PostHog]  [Sentry]  [Claude API]
   (FCM push)  (payments)    (analytics) (errors) (OCR scanning)
```

---

## 6. Roadmap & Current Phase

**Current Status:** Phase 3 (Pro/Team Payments) near completion. Version 1.0.4+5 shipping to Google Play Closed Testing.

| Phase | Status | Highlights |
|-------|--------|-----------|
| 1 | ✓ Complete | Personal core: auth, accounts, transactions, scanning, budgets, reports |
| 2 | ✓ Complete | Rooms: invite, members, room transactions, room budgets, presence |
| 3 | 🔄 In Progress | RevenueCat integration, paywall, tier-gated features, webhook idempotency |
| 4 | 📋 Planned | iOS support, recurring transactions, advanced budgeting, data export, i18n expansion |

**Known Gaps / Deferred:**
- iOS (StoreKit) deferred to Phase 4
- Recurring transaction templates (sketched but not implemented)
- Analytics dashboard (trend graphs, savings rate)
- Multi-language support beyond EN/ID (planned for Phase 4)

---

## 7. Notable Observations

### Differentiators
1. **Offline-first:** Drift SQLite queue enables transaction capture with zero internet, auto-sync on reconnect.
2. **AI Scanning:** Claude OCR via Edge Function (line items parsed, not just merchant).
3. **Collaborative Rooms:** Real-time multiplayer with presence, member-scoped budgets, deep-link invites.
4. **Tier-Aware Design:** Free/Pro/Team differentiation clear in code; scan limits, room creation, rate provider all pluggable.

### Architecture Strengths
- **Riverpod 3 codegen:** Minimal boilerplate, type-safe providers, async notifiers throughout.
- **Design system:** Consistent theming via loit_* tokens consumed by 230+ screens.
- **Supabase RLS:** Granular row-level security prevents data leakage between users/rooms.
- **RevenueCat abstraction:** PaymentService interface + dummy impl enables testing without Play Console.

### Risks / Gaps
1. **First Play Store upload:** API rejects first upload; initial AAB must be manual — documented in CI/CD guide, low risk.
2. **Migration sprawl:** 39 migrations (1727 lines) — maintainability risk as schema grows. Consider periodic consolidation.
3. **Supabase constraints:** RLS complexity grows with rooms; room-member read filters are intricate. Monitor performance on 1000+ rooms/users.
4. **iOS deferred:** Revenue loss until StoreKit implemented; AppStore audience locked out until Phase 4.
5. **Midtrans cleanup complete:** Old payment schema removed (migration 20240301000007), but references in docs may linger.

### Code Quality
- Lints enforced (flutter_lints + custom_lint + riverpod_lint).
- Sentry integration with source maps (release builds).
- PostHog analytics hooks for key flows (auth, room join, payment).
- No direct print statements; all logs via Log service.
- Comprehensive test hooks in pubspec (flutter_test, build_runner, drift_dev, sentry_dart_plugin).

