# LOIT
### *Split bills, not friendships.*
> **Loit** — money in Minahasan, a language of North Sulawesi, Indonesia.

---

## Table of Contents
1. [Product Overview](#1-product-overview)
2. [Target Users](#2-target-users)
3. [Core Decisions Log](#3-core-decisions-log)
4. [App Structure](#4-app-structure)
5. [Feature Specification](#5-feature-specification)
6. [AI Bill Scanner](#6-ai-bill-scanner)
7. [Shared Rooms](#7-shared-rooms)
8. [Monetization & Pricing](#8-monetization--pricing)
9. [Tech Stack](#9-tech-stack)
10. [Infrastructure & APIs](#10-infrastructure--apis)
11. [Cost & Revenue Model](#11-cost--revenue-model)
12. [Phase 1 — Personal Core](#12-phase-1--personal-core-weeks-18)
13. [Phase 2 — Shared Rooms](#13-phase-2--shared-rooms-weeks-913)
14. [Phase 3 — Pro Layer](#14-phase-3--pro-layer-weeks-1417)
15. [Phase 4 — Polish & Launch](#15-phase-4--polish--launch-weeks-1820)

---

## 1. Product Overview

**LOIT** is a mobile-first personal finance tracker with an invite-only shared expense layer. The app is built for individuals who want full control over their own financial life, with the option to collaborate privately with people they trust — friends, family, housemates, or travel companions.

| | |
|---|---|
| **App Name** | LOIT |
| **Primary Tagline** | *Split bills, not friendships.* |
| **Secondary Tagline** | *Snap, split, sorted.* |
| **Platform** | iOS + Android (Flutter) |
| **Primary Market** | Indonesia (Southeast Asia) |
| **Language (v1)** | English + Indonesian |

### Product Pillars

| Pillar | Description |
|---|---|
| **Personal First** | Every feature starts with the individual's financial life |
| **Private by Default** | Nothing is shared unless the user explicitly creates or joins a room |
| **Trusted Sharing** | Shared rooms are invite-only — no public discovery, ever |
| **AI-Assisted** | AI reduces friction in logging, categorizing, and understanding money |
| **Works Anywhere** | Multi-currency, offline-capable for personal use, international by design |


---

## 2. Target Users

| Persona | Personal Use | Shared Use |
|---|---|---|
| **Solo budgeter** | Track personal expenses, set budgets | Rarely uses shared rooms |
| **Traveler** | Log multi-currency trip expenses | Invite travel companions to a trip room |
| **Housemate** | Track personal spending | Shared household room for bills and rent |
| **Couple** | Individual finance tracking | Optional shared room for joint expenses |
| **Friend group** | Personal logs | Invite-only room for dinners, events, trips |
| **Work colleague** | Expense logging | Invite-only room for team meals and reimbursements |

---

## 3. Core Decisions Log

All product decisions are finalized. This log serves as the single source of truth.

| # | Topic | Decision |
|---|---|---|
| 1 | Settlement method | Removed entirely. LOIT no longer tracks who owes who or manages debt settlement. Rooms are for shared expense visibility and budgeting only. |
| 2 | Room archiving | Creator-controlled. Members retain read-only access to archived rooms forever. Creator can unarchive at any time. |
| 3 | Receipt storage expiry | Day 335: in-app banner. Day 350: push + email. Day 360: final warning. Day 365: photo deleted, transaction record kept forever. User can extend for Rp17,140 ($0.99) per 6-month batch. |
| 4 | AI scan failure | 1 retry allowed. On second failure, a pre-filled manual entry form opens with whatever fields AI partially detected. |
| 5 | Free scan reset | Calendar month — resets on the 1st of every month. Unused scans do not roll over. |
| 6 | Team admin visibility | Room expenses only. Admins have zero visibility into members' personal dashboards or expenses outside the room. |
| 7 | Receipt photo storage | Pro and Team tiers only. Free tier discards the photo immediately after scanning. Transaction record kept forever on all tiers. |
| 8 | AI insights | Removed entirely. Users view their own data through charts and reports — no AI-generated summaries or analysis. |
| 9 | Room invite method | Invite link and QR code only (same URL, two presentations). No username search or directory. Identical across all tiers. |
| 10 | Dual logging default | Room-level configuration set by the creator. Either auto-include all room transactions in personal tracker, or room-only. Applies to new transactions only — not retroactive. |
| 11 | Room creation limit hit | Prompt an upgrade screen. Invite link remains valid — user can join after upgrading. |
| 12 | Room limits model | Creation is tier-limited. Joining is unlimited on all tiers as long as the room has not hit its member cap. Member cap is determined by the room creator's tier. |
| 13 | Image resolution | All bill photos strictly capped at 720p (1280×720) before sending to AI API. |
| 14 | AI model | Claude Sonnet 4.6 exclusively across all tiers. All API calls are proxied through a Supabase Edge Function — the API key is never in client code. On AI parse failure (model returns unparseable or incomplete JSON), the user is prompted directly to manual input with any partially detected fields pre-filled. No retry. Connection errors and in-app errors are handled separately and do not trigger the manual input flow. |
| 15 | Infrastructure | Supabase Free + Cloudflare Free at launch. |
| 16 | Push notifications | Firebase Cloud Messaging (FCM HTTP v1), unlimited and free. Proxied through a Supabase Edge Function that holds the Firebase service account credentials server-side. |
| 17 | Scan top-up | Available for Free and Pro tiers. 10 scans for Rp16,969 ($0.99). |
| 18 | Offline capability | Personal finance only. Transactions, manual entry, and budget views work offline and sync when reconnected. Shared rooms require an active internet connection at all times — no offline room access. |
| 19 | Onboarding demo scan | The optional bill scan during onboarding is a designated demo scan that does not count against the user's monthly quota. It is a one-time event per account, tracked via a `has_used_demo_scan` boolean on the users table. |

---

## 4. App Structure

LOIT has two clearly separated layers. They are never mixed without explicit user action.

```
LOIT
├── MY FINANCES  (always private, never shared — offline capable)
│   ├── Dashboard         → spending overview, budget progress, recent transactions
│   ├── Transactions      → full personal expense log
│   ├── Budgets           → category-based monthly budget goals
│   ├── Scanner           → AI bill reader → logs to personal
│   └── Reports           → spending charts, category breakdown, trends
│
└── SHARED ROOMS  (invite-only, opt-in — internet required)
    ├── My Rooms          → list of rooms I created or joined
    ├── Room Feed         → real-time shared expense feed
    ├── Room Budget       → shared budget goals per category for the room
    └── Room Reports      → combined spending breakdown for all members
```

### Transaction Destination — At Point of Entry

When logging or scanning an expense inside a shared room, the user selects where the transaction goes. The default is set by the room creator's configuration.

```
Where should this expense go?
  ○ My Finances only
  ○ This Room only
  ○ Both My Finances + This Room   ← default if creator enabled sync
```

---

## 5. Feature Specification

### 5.1 Personal Dashboard
- Total spending this month vs last month (amount + percentage delta)
- Budget progress bars per category (green → yellow → red)
- Recent transactions list (last 5, tap to see full log)
- Net spending trend sparkline (7-day)
- Quick-add button and scan shortcut

### 5.2 Transaction Log
- Full chronological list of all personal expenses
- Filter by: date range, category, currency, amount range
- Search by merchant name or keyword
- Edit or delete any transaction
- Manually re-tag category if AI miscategorized
- Tap any transaction to view full detail including receipt photo (Pro/Team)

### 5.3 Budget System
- Set a monthly spending limit per category
- Visual ring or bar progress indicator
- Push notification alert at 80% of limit reached
- Push notification alert when limit is exceeded (overage: shows amount over budget)
- End-of-month summary card: over/under per category
- Free tier: 3 budget categories
- Pro and Team: unlimited categories + custom categories

### 5.4 Spending Reports
No AI interpretation — clean user-driven data views only.

- Category breakdown (pie chart + bar chart)
- Month-over-month spending comparison
- Top merchants by total spend
- Daily spend heatmap (calendar view)
- Filter by date range, category, and currency
- Free tier: last 3 months of data
- Pro and Team: full history

### 5.5 Multi-Currency Personal Wallet
- Log expenses in any supported currency at time of purchase
- All amounts displayed in user's home currency using rate at time of transaction
- Historical FX rates preserved — past entries never change value retroactively
- Currency breakdown view: "This month you spent in 4 currencies"
- Free tier: 10 major currencies
- Pro and Team: 180+ currencies with live FX rates updated every 30 minutes

---

## 6. AI Bill Scanner

### 6.1 Scan Flow

```
User taps Scan
  → Camera opens
  → User captures receipt photo
  → App compresses and enforces 720p cap (1280×720)
  → Image sent to Supabase Edge Function (scan-receipt)
  → Edge Function forwards to Claude Sonnet 4.6 API as base64
  → AI returns structured JSON

[AI Success]
  → Parsed result shown for user confirmation
  → User reviews: merchant, date, items, total, category
  → User edits any field if needed
  → User selects destination (My Finances / Room / Both)
  → Transaction saved

[AI Failure — model returned unparseable or incomplete JSON]
  → No retry
  → Manual entry form opens immediately
  → Any fields AI did partially detect are pre-filled
  → User completes the remaining fields
  → Saved as a manual transaction (is_manual_fallback = true)

[Connection error — no internet]
  → "Scanning requires an internet connection"
  → Retry connection button — does not open manual entry form
  → User can navigate to manual entry separately via the + button if they choose

[In-app error — Edge Function error, timeout, unexpected response]
  → "Something went wrong. Please try again."
  → Retry scan button — does not open manual entry form
  → Error logged to Sentry
```

### 6.2 Claude Sonnet 4.6 Prompt

```
You are a receipt parsing assistant. Analyze the receipt image and return ONLY valid JSON.
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

If any field cannot be determined, use null. Never guess — use null if unsure.
```

### 6.3 Token Count at 720p

| Component | Tokens |
|---|---|
| Image (1280×720 via width×height/750) | 1,229 |
| Prompt text | 300 |
| **Total input** | **1,529** |
| Output JSON | 300 |

### 6.4 Cost Per Scan

| Component | Calculation | Cost (USD) | Cost (IDR) |
|---|---|---|---|
| Input | 1,529 × $3.00/1M | $0.004587 | Rp78.7 |
| Output | 300 × $15.00/1M | $0.004500 | Rp77.1 |
| **Total per scan** | | **$0.00909** | **Rp156** |

### 6.5 Scan Limits & Top-Up

| Tier | Monthly Scans | Reset | Top-Up Available |
|---|---|---|---|
| Free | 8 scans | 1st of every calendar month | ✅ Rp16,969 / 10 scans |
| Pro | 50 scans | 1st of every calendar month | ✅ Rp16,969 / 10 scans |
| Team | Unlimited | N/A | ❌ Not needed |

Free tier counter display: **"7 of 8 scans used · Resets Dec 1"**

---

## 7. Shared Rooms

### 7.1 What is a Room

A closed, private space shared between a specific group of people for shared financial visibility and budgeting. Examples: "Bali Trip June", "Apartment 4B", "James's Birthday Dinner".

Rooms are not for tracking who owes who. They are for seeing a group's combined expenses in real-time, setting shared spending targets, and staying financially aligned without any debt or payment coordination. Internet connection is mandatory for all room features.

Rooms are not discoverable. The only way to join is via a direct invite from the room creator.

### 7.2 Room Creation Limits (by Creator Tier)

| Tier | Rooms Can Create | Max Members Per Created Room |
|---|---|---|
| Free | 3 rooms | 3 members |
| Pro | 10 rooms | 7 members |
| Team | 25 rooms | 15 members |

**Joining rooms is unlimited on all tiers** — any user can be a member of as many rooms as they are invited to, as long as the room has not hit its member cap. The cap is determined by the creator's tier, not the joiner's.

### 7.3 Invite System

- Each room has one active invite link
- The same link renders as a QR code for in-person sharing
- Creator can regenerate the link at any time — old link invalidated immediately
- Invitee must have a LOIT account to join
- Each pending join is tracked in the `room_invites` table with its own `expires_at` (7 days from invite creation). Per-invitee expiry — not room-level.
- Revoked members cannot rejoin via old links

### 7.4 Room Configuration (Creator Only)

```
Personal Tracker Sync
  ○ Auto-include  → room transactions automatically logged to My Finances
  ○ Room only     → transactions stay in room only

(Applies to new transactions. Not retroactive. Members cannot override.)
```

### 7.5 Real-Time Room Feed

Powered by Supabase Realtime WebSocket channels. Internet is required — no offline fallback for room features.

| Event | Who Sees It | UI Behavior |
|---|---|---|
| New transaction added | All room members | Animated card slides into feed |
| Room budget updated | All room members | Budget bar refreshes live |
| New member joined | All members | System message in feed |
| Room budget at 80% | All room members | Alert banner in feed |

Presence indicators:
- Subtle avatar row showing who is currently viewing the room
- "Maria is adding an expense..." indicator

### 7.6 Room Budget

Each room can have an optional shared budget per category, set by the creator or a Team admin.

- Budget limit set per category (e.g., "Food: Rp500,000 for this trip")
- All member transactions in that category count toward the shared limit
- Visual progress bar visible to all members in real-time
- Alert sent to all members when room budget reaches 80%
- Alert sent to all members when room budget is exceeded (with overage amount)
- No personal budget data is ever shared — only room-scoped transactions count
- **Auto-reset option (optional):** Creator can enable monthly auto-reset at room creation. When enabled, budgets reset on the 1st of every calendar month — useful for recurring rooms like household splits. Default: off (manual reset only, suited for one-time trips and events).

### 7.7 Room Reports

A combined spending view for all transactions logged to the room.

- Total room spend to date
- Spend per category (bar chart)
- Spend per member (who contributed most transactions)
- Daily spending timeline
- Filter by date range and category
- Available to all room members
- Team tier: exportable as CSV or PDF

### 7.8 Room Lifecycle

```
Active
  → Creator taps "Archive Room" in settings
  → Room becomes Read-Only
  → All members retain read access forever
  → Creator can unarchive at any time → Active again
```

---

## 8. Monetization & Pricing

### 8.1 Tier Comparison

| Feature | Free | Pro (Rp85,529 / $4.99 /mo) | Team (Rp171,169 / $9.99 /mo) |
|---|---|---|---|
| Personal expense tracking | ✅ Unlimited | ✅ Unlimited | ✅ Unlimited |
| Bill scans | 8 / calendar mo | 50 / calendar mo | Unlimited |
| Scan top-up packs | ✅ Rp16,969 / 10 scans | ✅ Rp16,969 / 10 scans | ❌ |
| Receipt photo storage | ❌ | ✅ 1 year | ✅ 1 year |
| Transaction records | Forever | Forever | Forever |
| Currencies | 10 major | 180+ | 180+ |
| Spending reports | 3 months history | Full history | Full history |
| Custom categories | ❌ | ✅ | ✅ |
| Budget goals | 3 categories | Unlimited | Unlimited |
| CSV / PDF export | ❌ | ✅ | ✅ |
| Recurring bills | ❌ | ✅ | ✅ |
| Rooms you can create | 3 rooms | 10 rooms | 25 rooms |
| Members per created room | 3 members | 7 members | 15 members |
| Rooms you can join | Unlimited | Unlimited | Unlimited |
| Room personal tracker sync | ✅ | ✅ | ✅ |
| Room invite (link / QR) | ✅ | ✅ | ✅ |
| Room admin controls | ❌ | ❌ | ✅ |
| Team spending reports | ❌ | ❌ | ✅ |
| Priority support | ❌ | ❌ | ✅ |
| Annual billing | — | Rp856,680 / $49.99 /yr | Rp1,713,360 / $99.99 /yr |

### 8.2 Receipt Photo Storage — Expiry Policy

| Tier | Storage | Policy |
|---|---|---|
| Free | ❌ None | Photo discarded immediately after scan |
| Pro | ✅ 1 year per photo | See expiry flow below |
| Team | ✅ 1 year per photo | See expiry flow below |

Expiry flow:
```
Day 335 → In-app banner: "Your oldest receipts expire in 30 days"
Day 350 → Push notification + email with extend option
Day 360 → Final warning push + email
Day 365 → Photo deleted permanently
           Transaction record (amount, merchant, items, category) kept forever
           OR user pays Rp16,969 ($0.99) → extends all photos expiring within the next 30 days by +6 months each (one payment covers the entire expiring batch — no per-photo charges)
```

### 8.3 Additional Revenue
- Annual billing discount: 2 months free
- Scan top-up packs: Rp16,969 / 10 scans (Free and Pro)
- Receipt storage extension: Rp16,969 / 6 months (Pro and Team)

---

## 9. Tech Stack

| Layer | Technology | Purpose |
|---|---|---|
| Mobile Frontend | Flutter (Dart) | iOS + Android from one codebase |
| Local Storage | drift (SQLite) | Offline queue for personal finance transactions |
| Database | Supabase PostgreSQL | All app data |
| Auth | Supabase Auth | Email, Google SSO, Apple SSO |
| Realtime | Supabase Realtime (WebSocket) | Live room feeds, presence |
| File Storage | Supabase Storage | Receipt photo uploads |
| Edge Functions | Supabase Edge Functions | Midtrans webhooks (signed SHA-512 notification), scan quotas, expiry jobs |
| AI / OCR | Claude Sonnet 4.6 (Anthropic) | Bill scanning and categorization — proxied via Supabase Edge Function |
| Exchange Rates | Frankfurter API | Free daily ECB rates (upgrade to Open Exchange Rates at scale) |
| Payments | Midtrans | Pro and Team subscriptions + one-time packs (credit card, GoPay, OVO, DANA, QRIS, virtual account, BCA KlikPay) |
| Push Notifications | Firebase Cloud Messaging (FCM) | iOS (APNs) and Android push via `firebase_messaging` + FCM HTTP v1 |
| Email | Resend | Transactional emails (expiry warnings, invites) |
| Error Tracking | Sentry | Crash and error monitoring |
| Analytics | PostHog | Feature usage, funnel, retention |
| DNS / CDN | Cloudflare Free | DNS, DDoS protection |

### 9.1 Flutter Project Structure

```
lib/
├── main.dart                       # App entry — initializes Firebase, Supabase, Sentry, PostHog (Midtrans is lazy-init in core/services/midtrans_service.dart)
├── app.dart                        # Root widget, routing, deep link wiring
├── core/
│   ├── config/env.dart             # Compile-time env via --dart-define-from-file
│   ├── routing/                    # go_router routes
│   ├── theme/                      # Design tokens, colors, typography
│   └── services/
│       ├── scanner_service.dart    # Compresses to 720p, calls scan-receipt Edge Function
│       ├── currency_service.dart   # Tier-aware FX fetch + cache (Frankfurter / OXR)
│       ├── offline_database.dart   # Drift SQLite for offline queue
│       ├── sync_service.dart       # Drains offline queue on reconnect
│       ├── receipt_service.dart    # Uploads to Storage, resolves signed URLs (Pro/Team)
│       ├── push_service.dart       # FCM token registration + refresh
│       ├── deep_link_service.dart  # app_links + invite acceptance
│       └── analytics_service.dart  # PostHog event taxonomy (see Build Guide Step 1.10)
├── features/
│   ├── auth/                       # Login, signup, onboarding
│   ├── dashboard/                  # Personal spending overview
│   ├── transactions/               # Full personal transaction log
│   ├── budgets/                    # Personal category budgets and alerts
│   ├── reports/                    # Personal spending charts, export (CSV/PDF)
│   ├── scanner/                    # Camera + AI bill reader
│   ├── rooms/                      # Shared rooms list and creation
│   ├── room_detail/                # Room feed, room budget, room reports
│   ├── paywall/                    # Paywall sheets + checkout service
│   └── settings/                   # Profile, currency, subscription
├── shared/
│   ├── widgets/                    # Reusable UI components
│   ├── models/                     # Data models
│   └── providers/                  # Cross-feature Riverpod providers (e.g. FeatureGate)
└── l10n/                           # ARB files + generated AppLocalizations
```

### 9.2 Supabase Realtime Channel Design

```dart
// Room feed — live transaction updates (insert, edit, delete)
supabase
  .channel('room:$roomId')
  .onPostgresChanges(
    event: PostgresChangeEvent.insert,
    schema: 'public',
    table: 'transactions',
    filter: PostgresChangeFilter(
      type: FilterType.eq,
      column: 'room_id',
      value: roomId,
    ),
    callback: (payload) {
      setState(() => transactions.insert(0, payload.newRecord));
    },
  )
  .onPostgresChanges(
    event: PostgresChangeEvent.update,
    schema: 'public',
    table: 'transactions',
    filter: PostgresChangeFilter(
      type: FilterType.eq,
      column: 'room_id',
      value: roomId,
    ),
    callback: (payload) {
      setState(() {
        final idx = transactions.indexWhere((t) => t['id'] == payload.newRecord['id']);
        if (idx != -1) transactions[idx] = payload.newRecord;
      });
    },
  )
  .onPostgresChanges(
    event: PostgresChangeEvent.delete,
    schema: 'public',
    table: 'transactions',
    filter: PostgresChangeFilter(
      type: FilterType.eq,
      column: 'room_id',
      value: roomId,
    ),
    callback: (payload) {
      setState(() => transactions.removeWhere((t) => t['id'] == payload.oldRecord['id']));
    },
  )
  .subscribe();
```

---

## 10. Infrastructure & APIs

### 10.1 Supabase Free Tier — Constraints

| Limit | Cap | Risk Level |
|---|---|---|
| Database size | 500MB | Low at launch |
| File storage | 1GB | Low (Free users don't store photos) |
| Bandwidth | 2GB/mo | Medium — monitor realtime traffic |
| Realtime concurrent connections | 200 | Medium — upgrade trigger at ~150 DAU |
| Edge Function invocations | 500K/mo | Low at launch |
| Daily backups | ❌ None | High — implement manual backup strategy |
| Project inactivity pause | After 1 week | Critical — schedule a keep-alive ping every 3 days |

Upgrade to Supabase Pro (Rp428,500 / $25/mo) when daily active users regularly approach 150 or realtime connections approach 200.

### 10.2 Third-Party API Summary

| Service | Plan at Launch | Cost | Upgrade Trigger |
|---|---|---|---|
| Supabase | Free | Rp0 | 150+ DAU or 200 concurrent connections |
| Cloudflare | Free | Rp0 | Never for this scale |
| Claude API (Anthropic) | Pay-per-use | Rp156/scan | N/A |
| Frankfurter (FX rates) | Free | Rp0 | Switch to Open Exchange Rates (Rp205,680 / $12/mo) when hourly rates needed |
| Midtrans | 0.7–2.9% per txn (channel-dependent) | Per transaction | N/A |
| Firebase Cloud Messaging | Free (unlimited) | Rp0 | N/A — FCM HTTP v1 is free at any volume |
| Resend | Free (3,000/mo) | Rp0 | Pro (Rp342,800 / $20/mo) at 3,000+ emails/mo |
| Sentry | Free (5,000 errors/mo) | Rp0 | Team (Rp445,640 / $26/mo) at scale |
| PostHog | Free (1M events/mo) | Rp0 | Paid tier beyond 1M events |
| Apple Developer | Annual | Rp1,696,860 / $99/yr | Recurring |
| Google Play | One-time | Rp428,500 / $25 | Year 1 only |

---

## 11. Cost & Revenue Model

**Exchange Rate: $1 = Rp17,140**
**Scenario: 500 users, 5% paid (25 users)**
**Paid split: 70% Pro (17 users) / 30% Team (8 users)**

### 11.1 Monthly Revenue

| Source | Price (IDR) | Volume | Total (IDR) |
|---|---|---|---|
| Pro subscriptions | Rp85,529 | 17 users | Rp1,453,993 |
| Team subscriptions | Rp171,169 | 8 users | Rp1,369,352 |
| Scan top-up — Free | Rp16,969 | ~24 packs | Rp407,256 |
| Scan top-up — Pro | Rp16,969 | ~2 packs | Rp33,938 |
| **Total MRR** | | | **Rp3,264,539** |

### 11.2 Monthly Costs

| Category | IDR/mo | Notes |
|---|---|---|
| Supabase Free | Rp0 | |
| Cloudflare Free | Rp0 | |
| Claude API (2,760 scans × Rp156) | Rp430,560 | All tiers on Sonnet 4.6 |
| Frankfurter FX | Rp0 | |
| Firebase Cloud Messaging | Rp0 | Free at any volume |
| Midtrans fees | Rp311,227 | 51 transactions (blended ~2% across cards, e-wallets, VA) |
| Resend | Rp0 | Under 3,000 emails/mo |
| Sentry | Rp0 | Under 5,000 errors/mo |
| PostHog | Rp0 | Under 1M events/mo |
| App Store (annualized) | Rp177,113 | Drops to Rp141,405 from year 2 |
| **Total Operating Cost** | **Rp918,900** | |

### 11.3 Bottom Line

| Metric | IDR |
|---|---|
| Total MRR | Rp3,264,539 |
| Total Operating Cost | Rp918,900 |
| **Net Profit** | **Rp2,345,639** |
| **Profit Margin** | **71.8%** |

### 11.4 Scenario Analysis

| Scenario | MRR (IDR) | Cost (IDR) | Profit (IDR) | Margin |
|---|---|---|---|---|
| Base case | Rp3,264,539 | Rp918,900 | Rp2,345,639 | 71.8% |
| + All Free users hit 8-scan cap | Rp3,264,539 | Rp1,021,500 | Rp2,243,039 | 68.7% |
| + All Pro users hit 50-scan cap | Rp3,264,539 | Rp1,125,300 | Rp2,139,239 | 65.5% |
| + Supabase Pro upgrade (at 150+ DAU) | Rp3,264,539 | Rp1,347,400 | Rp1,917,139 | 58.7% |
| **Worst case (all risks combined)** | **Rp3,264,539** | **Rp1,453,700** | **Rp1,810,839** | **55.5%** |

> Even in the worst-case scenario, LOIT remains profitable. The margin cushion is healthy enough to absorb early volatility.

### 11.5 Infrastructure Upgrade Triggers

| Trigger | Action | Added Cost (IDR/mo) |
|---|---|---|
| 150+ DAU or 200 concurrent Supabase connections | Upgrade to Supabase Pro | +Rp428,500 |
| 3,000+ emails/mo | Upgrade Resend to Pro | +Rp342,800 |
| Hourly FX rates needed | Switch to Open Exchange Rates Startup | +Rp205,680 |

---

## 12. Phase 1 — Personal Core (Weeks 1–8)

This phase delivers a fully working personal finance tracker. No shared features. The goal is a polished, self-contained app that is valuable even if a user never creates or joins a room.

### 12.1 Scope

- User authentication
- Personal dashboard
- Manual transaction entry (works offline)
- AI bill scanner with retry and manual fallback (requires internet for scan; manual entry works offline)
- Smart categorization with user correction
- Budget goals (3 categories on Free)
- 10 currencies with Frankfurter FX rates
- Basic spending reports (3-month history)
- Offline queue: personal transactions queued locally and synced on reconnect

### 12.2 Database Tables

```sql
-- Users
create table users (
  id uuid primary key default gen_random_uuid(),
  email text unique not null,
  name text not null,
  avatar_url text,
  home_currency text default 'IDR',
  tier text default 'free' check (tier in ('free', 'pro', 'team')),
  scans_used_this_month int default 0,
  scan_reset_date date default date_trunc('month', now()),
  has_used_demo_scan boolean default false,
  created_at timestamptz default now()
);

-- Transactions (personal)
-- Note: room_id FK to rooms table is added via ALTER TABLE in Phase 2 migration.
-- Phase 1 creates this table without the FK; Phase 2 adds: ALTER TABLE transactions ADD CONSTRAINT fk_room FOREIGN KEY (room_id) REFERENCES rooms(id) ON DELETE SET NULL;
create table transactions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references users(id) on delete cascade,
  room_id uuid,  -- FK added in Phase 2 migration
  merchant text,
  amount numeric not null,
  currency text not null,
  amount_home_currency numeric,
  fx_rate numeric,
  category text,
  notes text,
  receipt_url text,
  receipt_expires_at timestamptz,
  ai_parsed boolean default false,
  is_manual_fallback boolean default false,
  client_updated_at timestamptz,           -- set by client at save time; used for offline conflict resolution
  updated_at timestamptz default now(),    -- server-managed via moddatetime trigger
  created_at timestamptz default now()
);

-- Budgets
create table budgets (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references users(id) on delete cascade,
  category text not null,
  monthly_limit numeric not null,
  created_at timestamptz default now(),
  unique(user_id, category)
);

-- FX rate cache (tier-aware staleness)
--   Free tier (Frankfurter):            stale after 25 hours
--   Pro/Team tier (Open Exchange Rates): stale after 35 minutes
-- currency_service.dart picks the correct threshold per user's tier.
-- If the provider is unreachable, the cached rate is returned with a
-- "Rates may be outdated" label shown in UI.
create table fx_rates (
  base_currency text not null,
  target_currency text not null,
  rate numeric not null,
  fetched_at timestamptz default now(),
  primary key (base_currency, target_currency)
);
```

### 12.3 Auth Flow

```
Onboarding screen
  → Sign up with email / Google / Apple
  → Set display name
  → Select home currency (default: IDR)
  → Optional: scan a bill (live demo moment before paywall)
  → Land on personal dashboard
```

Row Level Security enforced: users can only read and write their own data.

### 12.4 AI Scanner Service (Flutter)

The Flutter client never calls the Claude API directly. All scan requests are proxied through a Supabase Edge Function (`scan-receipt`) which holds the API key server-side and enforces quota atomically.

```dart
class ScannerService {
  // Step 1: Enforce 720p cap before sending
  Future<Uint8List> compressTo720p(File imageFile) async {
    final image = await decodeImageFromList(await imageFile.readAsBytes());
    // Resize if larger than 1280x720
    // Return compressed JPEG bytes
  }

  // Step 2: Send to Edge Function proxy (not directly to Claude API)
  Future<ScanResult> scanReceipt(File imageFile) async {
    final imageBytes = await compressTo720p(imageFile);
    final base64Image = base64Encode(imageBytes);

    final session = supabase.auth.currentSession;
    final response = await http.post(
      Uri.parse('${Env.supabaseUrl}/functions/v1/scan-receipt'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${session?.accessToken}',
      },
      body: jsonEncode({ 'image': base64Image }),
    ).timeout(const Duration(seconds: 30));

    return ScanResult.fromResponse(response);
  }
}
```

**Edge Function: `scan-receipt`** (runs server-side, holds API key)

```typescript
// supabase/functions/scan-receipt/index.ts
import { serve } from 'https://deno.land/std/http/server.ts';
import Anthropic from 'npm:@anthropic-ai/sdk';

const anthropic = new Anthropic({ apiKey: Deno.env.get('ANTHROPIC_API_KEY') });

serve(async (req) => {
  const user = await getUserFromJWT(req);
  if (!user) return new Response('Unauthorized', { status: 401 });

  // Atomically check + increment quota; returns null if exceeded
  const allowed = await incrementQuotaIfAllowed(user.id, user.tier);
  if (!allowed) return new Response('Quota exceeded', { status: 402 });

  const { image } = await req.json();

  const result = await anthropic.messages.create({
    model: 'claude-sonnet-4-6',
    max_tokens: 1000,
    messages: [{
      role: 'user',
      content: [
        { type: 'image', source: { type: 'base64', media_type: 'image/jpeg', data: image } },
        { type: 'text', text: scannerPrompt },
      ],
    }],
  });

  const text = result.content[0].text;

  // Validate JSON is parseable before returning — if not, signal AI failure
  // so the client can open the manual entry form (not a generic error screen)
  try {
    JSON.parse(text);
    return new Response(text, { status: 200 });
  } catch {
    // Return partial text so client can pre-fill whatever fields were detected
    return new Response(JSON.stringify({ ai_failure: true, partial: text }), { status: 422 });
  }
});
```

**Flutter client error handling:**

```dart
final response = await http.post(...);

switch (response.statusCode) {
  case 200:
    // AI success — show confirmation screen
    final parsed = jsonDecode(response.body);
    navigator.push(ConfirmScanScreen(data: parsed));

  case 422:
    // AI failure — go straight to manual entry, pre-fill what we have
    final partial = jsonDecode(response.body)['partial'];
    navigator.push(ManualEntryScreen(prefill: extractPartialFields(partial)));

  case 402:
    // Quota exceeded — show upgrade / top-up prompt
    showQuotaExceededSheet();

  default:
    // In-app / server error — show retry screen, log to Sentry
    showErrorScreen(message: 'Something went wrong. Please try again.');
    Sentry.captureException(response);
}

### 12.5 Scan Quota Logic (Supabase Edge Function)

Quota is enforced atomically using a single `UPDATE ... RETURNING` statement to eliminate the race condition that would otherwise allow two simultaneous requests to both pass a read-then-check flow. The year-boundary bug (December → January) is fixed by comparing both year and month.

```typescript
// Atomic quota increment — returns true if allowed, false if exceeded
// Called inside scan-receipt Edge Function before forwarding to Claude API
async function incrementQuotaIfAllowed(userId: string, tier: string): Promise<boolean> {
  const limits: Record<string, number> = { free: 8, pro: 50, team: 999999 };
  const limit = limits[tier] ?? 8;

  // Reset scan count if we're in a new calendar month (year-safe comparison)
  // Done as a separate guarded update so the increment below always sees fresh data
  await supabase.rpc('reset_scan_quota_if_new_month', { p_user_id: userId });

  // Atomic increment: only succeeds if current count is below the limit
  // No row returned → quota already at limit
  const { data, error } = await supabase.rpc('increment_scan_quota', {
    p_user_id: userId,
    p_limit: limit,
  });

  return !!data && !error;
}
```

**Supporting SQL functions (run once in migration):**

```sql
-- Safe monthly reset: compares year + month to avoid year-boundary bug
create or replace function reset_scan_quota_if_new_month(p_user_id uuid)
returns void language plpgsql as $$
begin
  update users
  set scans_used_this_month = 0,
      scan_reset_date = date_trunc('month', now())
  where id = p_user_id
    and (
      extract(year  from now()) != extract(year  from scan_reset_date) or
      extract(month from now()) != extract(month from scan_reset_date)
    );
end;
$$;

-- Atomic increment: only fires if under the limit, returns new count or null
create or replace function increment_scan_quota(p_user_id uuid, p_limit int)
returns int language plpgsql as $$
declare
  new_count int;
begin
  update users
  set scans_used_this_month = scans_used_this_month + 1
  where id = p_user_id
    and scans_used_this_month < p_limit
  returning scans_used_this_month into new_count;
  return new_count; -- null if quota exceeded (no row updated)
end;
$$;
```

### 12.6 Deliverables at End of Phase 1
- Auth (email + Google + Apple SSO) working
- Personal dashboard rendering real data
- Manual transaction entry with category selection
- AI bill scanner (scan → Edge Function proxy → Sonnet → parse → confirm → save)
- AI parse failure goes directly to manual entry form with partial fields pre-filled (no retry)
- Connection errors and in-app errors show distinct retry screens — do not trigger manual entry
- Onboarding demo scan does not count against monthly quota (`has_used_demo_scan` flag)
- Budget goals (3 categories) with 80% and 100% overage alerts
- Frankfurter FX integration with 10 currencies + staleness label when cache is stale
- Basic spending reports (3-month)
- Offline queue: manual transactions saved locally and synced on reconnect
- Conflict resolution on sync: `client_updated_at` timestamp compared; newer record wins
- Cached dashboard and transaction list readable while offline
- Supabase RLS enforced on all tables
- Atomic scan quota enforced via SQL functions (race-condition-safe)
- API key never present in Flutter client binary
- App runs on iOS simulator and Android emulator

---

## 13. Phase 2 — Shared Rooms (Weeks 9–13)

This phase adds the entire shared layer on top of the working personal app. Rooms are focused on shared expense visibility and group budgeting — not debt or payment coordination. Internet is required for all room features.

### 13.1 Scope

- Create and join invite-only rooms
- Real-time room transaction feed via Supabase WebSocket
- Room budget goals per category
- Room reports (combined spend view for all members)
- Push notifications via Firebase Cloud Messaging (FCM HTTP v1), proxied through a Supabase Edge Function
- No-connection handling for room screens

### 13.2 Additional Database Tables

```sql
-- Rooms
create table rooms (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  description text,
  base_currency text default 'IDR',
  created_by uuid references users(id),
  sync_to_personal boolean default false,
  invite_token text unique default gen_random_uuid()::text,
  is_archived boolean default false,
  archived_at timestamptz,
  budget_auto_reset boolean default false,  -- if true, room budgets reset on 1st of each month
  created_at timestamptz default now()
);

-- Room invites (per-invitee expiry — distinct from the room's invite_token)
-- A new row is created each time someone clicks the invite link before joining.
-- Expires 7 days after creation. Joining the room marks status = 'accepted'.
create table room_invites (
  id uuid primary key default gen_random_uuid(),
  room_id uuid references rooms(id) on delete cascade,
  invited_user_id uuid references users(id) on delete cascade,
  invite_token text not null,             -- snapshot of token at time of click
  status text default 'pending' check (status in ('pending', 'accepted', 'expired')),
  created_at timestamptz default now(),
  expires_at timestamptz default now() + interval '7 days',
  unique(room_id, invited_user_id)
);

-- Room members
create table room_members (
  id uuid primary key default gen_random_uuid(),
  room_id uuid references rooms(id) on delete cascade,
  user_id uuid references users(id) on delete cascade,
  role text default 'member' check (role in ('admin', 'member')),
  joined_at timestamptz default now(),
  unique(room_id, user_id)
);

-- Room budgets
create table room_budgets (
  id uuid primary key default gen_random_uuid(),
  room_id uuid references rooms(id) on delete cascade,
  category text not null,
  budget_limit numeric not null,
  currency text not null,
  created_by uuid references users(id),
  created_at timestamptz default now(),
  unique(room_id, category)
);

-- Phase 2 migration: add rooms FK to transactions (created without it in Phase 1)
alter table transactions
  add constraint fk_room
  foreign key (room_id) references rooms(id) on delete set null;
```

> Note: `splits` and `settlements` tables are not created. Debt and settlement tracking is not part of LOIT.

### 13.3 Room Creation Flow

```
User taps "Create Room"
  → Enter room name and optional description
  → Select base currency
  → Set personal tracker sync (auto-include / room only)
  → Set budget reset mode: "Reset budgets monthly?" (toggle — default off)
  → Optionally set room budget goals per category
  → Room created → invite link generated
  → Share link or show QR code
```

### 13.4 Invite Link Flow

```
Creator shares link → Invitee opens link on mobile
  → If LOIT installed: deep link opens app → join confirmation screen
  → If LOIT not installed: App Store / Play Store link shown
  → Invitee confirms join → added to room_members
  → Room feed loads immediately (requires internet)
```

Invite token regeneration invalidates the previous token instantly. Pending joins via the old token are blocked.

### 13.5 No-Connection Handling for Rooms

```
User opens a room screen with no internet
  → Full-screen "No connection" state shown
  → "Rooms require an internet connection" message
  → Retry button — auto-resumes when connection restored
  → Personal finance features remain available offline
```

### 13.6 Firebase Cloud Messaging Integration

FCM is used for all push notifications. The Firebase service account key lives in Supabase Secrets — never in the Flutter client.

```dart
// On app launch, after login success
import 'package:firebase_messaging/firebase_messaging.dart';

final settings = await FirebaseMessaging.instance.requestPermission();
if (settings.authorizationStatus != AuthorizationStatus.denied) {
  final token = await FirebaseMessaging.instance.getToken();
  // Upsert token into the `push_tokens` table (keyed by user_id + token).
  // See Build Guide Step 2.7 for the full implementation.
}

FirebaseMessaging.instance.onTokenRefresh.listen(_upsertToken);
FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage msg) {
  final roomId = msg.data['room_id'];
  if (roomId != null) context.go('/rooms/$roomId');
});
```

On the server, a Supabase Edge Function (`room-transaction-notify`) looks up every FCM token for the room's members (excluding the actor) and sends one FCM HTTP v1 request per token. Unregistered tokens are pruned automatically when FCM returns `UNREGISTERED`.

Notification triggers (sent from Supabase Edge Functions):

| Trigger | Audience |
|---|---|
| New transaction added to a room | All room members |
| Room budget reached 80% | All room members |
| New member joined the room | All room members |
| Personal budget at 80% | That user only |
| Receipt photo expiring in 30 days | That user only |

### 13.7 Deliverables at End of Phase 2
- Room creation with invite link and QR code
- Join flow via deep link
- Per-invitee expiry tracked in `room_invites` table (7 days from link click)
- Real-time feed (Supabase WebSocket) working on device — INSERT, UPDATE, DELETE all handled
- Room budget goals visible and updating live; optional monthly auto-reset working
- Room reports (combined spend view) rendering correctly
- No-connection state shown correctly on room screens
- FCM push notifications working on iOS (APNs bridged) and Android
- Room archiving by creator
- RLS enforced: room data only visible to members
- Phase 1 `transactions` table FK to `rooms` added via migration

---

## 14. Phase 3 — Pro Layer (Weeks 14–17)

This phase gates premium features behind Midtrans subscriptions and activates the full monetization model.

### 14.1 Scope

- Midtrans Snap integration + paywall screens (in-app UI, no browser redirect)
- 180+ currencies + live FX rates (30-minute cache)
- Receipt photo storage for Pro and Team (Supabase Storage)
- Receipt expiry warning system (Day 335 / 350 / 360 / 365)
- Full spending reports (unlimited history)
- CSV and PDF export
- Recurring bills
- Scan top-up pack purchases
- Custom categories (Pro and Team)
- Unlimited budget goals (Pro and Team)

### 14.2 Midtrans Setup

```
Midtrans products (IDR-denominated; Snap handles currency conversion for cards):
  - loit_pro_monthly:   $4.99/mo  → Rp85,529
  - loit_pro_yearly:    $49.99/yr → Rp856,680
  - loit_team_monthly:  $9.99/mo  → Rp171,169
  - loit_team_yearly:   $99.99/yr → Rp1,713,360
  - loit_scan_topup:    $0.99     → Rp16,969 (one-time)
  - loit_storage_ext:   $0.99     → Rp16,969 (one-time)

Snap payment channels (all enabled by default in sandbox):
  - Credit card (Visa / Mastercard / JCB / Amex) — 3DS always on
  - GoPay, OVO, DANA, ShopeePay, LinkAja
  - QRIS (any BI-QRIS-compliant wallet)
  - Bank Transfer / Virtual Account (BCA, Mandiri, BNI, BRI, Permata)
  - BCA KlikPay, CIMB Clicks, Mandiri ClickPay
  - Akulaku / Kredivo (BNPL)
```

Supabase Edge Function `midtrans-notification` handles the Midtrans webhook (signed with SHA-512 of `order_id + status_code + gross_amount + server_key`) and updates `users.tier` / scan top-up / storage extension on `settlement`.

### 14.3 Receipt Storage Flow

```
Pro/Team user confirms scanned transaction
  → Image compressed to 720p JPEG
  → Uploaded to Supabase Storage: receipts/{user_id}/{transaction_id}.jpg
  → receipt_url saved to transactions table
  → receipt_expires_at set to now() + 365 days

Expiry job (runs daily via Supabase Edge Function cron):
  → Query transactions WHERE receipt_expires_at <= now() + 30 days
  → Day 335: trigger in-app banner notification
  → Day 350: send push + email via Resend
  → Day 360: send final push + email
  → Day 365: delete file from Supabase Storage
              set receipt_url = null on transaction
              transaction record preserved forever
```

### 14.4 CSV / PDF Export

- CSV: raw transaction data, all columns, filtered by date range and category
- PDF: formatted expense report with LOIT branding, totals, category summary
- Both generated client-side in Flutter
- Pro and Team tiers only
- Available from Reports screen → Export button

### 14.5 Recurring Bills

- User marks a transaction as recurring (weekly / monthly / yearly)
- App creates a recurring_bills table entry
- Supabase Edge Function cron checks daily
- On due date: creates a draft transaction, sends reminder push notification
- User confirms or edits before finalizing

### 14.6 Deliverables at End of Phase 3
- Midtrans Snap in-app checkout working on iOS and Android for all payment channels (card / GoPay / OVO / DANA / QRIS / VA)
- Paywall screens on all gated features
- 180+ currencies loading from Open Exchange Rates with 30-minute cache
- Receipt photo upload and storage working for Pro/Team
- Expiry warning system firing correctly (tested with accelerated dates)
- CSV export downloading correctly
- PDF export rendering correctly
- Recurring bills creating transactions on schedule
- Scan top-up pack purchase flowing end to end
- Custom categories working for Pro/Team
- Unlimited budgets working for Pro/Team

---

## 15. Phase 4 — Polish & Launch (Weeks 18–20)

This phase focuses on quality, localization, and getting the app across the finish line to both app stores.

### 15.1 Scope

- Full localization: English (default) + Indonesian (Bahasa Indonesia)
- Offline mode for personal finance (finalize and harden)
- No-connection handling for shared rooms
- Keep-alive strategy for Supabase free tier
- App Store and Play Store submission
- Final QA pass

### 15.2 Offline Mode — Personal Finance Only

Personal finance features work fully without an internet connection. Shared rooms require connectivity.

```
Personal Finance — Offline Behavior:
  User opens app with no internet
  → Dashboard loads from local cache (last synced data)
  → Transaction log readable from cache
  → Budget progress readable from cache
  → Manual transaction entry works → queued in local SQLite (drift package)
  → Scanner shows "Scanning requires internet" — disabled while offline
  → FX rates show "Last updated [date]" label when using cached rates

  Connection restored
  → Queued transactions sync to Supabase in insertion order
  → Conflict resolution: each transaction carries a `client_updated_at` timestamp set at the moment the user saves it. On sync, the server compares `client_updated_at` against the server record's `updated_at` — the newer timestamp wins. This prevents a stale server record from silently overwriting a legitimate offline edit.
  → All data refreshes from Supabase automatically

Shared Rooms — Offline Behavior:
  User taps into a room with no internet
  → Full-screen "No connection" state
  → "Rooms require an internet connection" message + retry button
  → No room data cached or accessible offline
  → Personal finance tab remains usable
```

### 15.3 Localization

Localization via Flutter's `intl` and `flutter_localizations` packages.

| String Type | Notes |
|---|---|
| UI labels and buttons | Full EN + ID |
| Error messages | Full EN + ID |
| Push notification copy | Full EN + ID |
| Currency formatting | Auto by locale (Rp1.000,00 vs $1,000.00) |
| Date formatting | Auto by locale (DD/MM/YYYY vs MM/DD/YYYY) |
| Number formatting | Auto by locale |


### 15.4 Supabase Keep-Alive

Supabase Free pauses projects after 1 week of no requests. Both the database and Storage service must be kept active independently.

Mitigation: Supabase Edge Function scheduled cron (every 3 days) that performs two lightweight no-op operations:
1. A dummy `SELECT 1` query against the database.
2. A `HEAD` request on a known placeholder object in the Storage bucket (`receipts/.keep`).

Both cost 0 tokens, negligible bandwidth, and keep the full project active.

### 15.5 App Store Submission Checklist

**iOS (Apple App Store)**
- [ ] App icons at all required sizes
- [ ] Launch screen / splash screen
- [ ] Screenshots for iPhone 6.7", 6.5", 5.5" and iPad Pro
- [ ] App Store description (EN + ID)
- [ ] Privacy policy URL live
- [ ] Terms of service URL live
- [ ] GDPR data deletion flow working
- [ ] In-app purchase products submitted to App Store Connect
- [ ] Sign in with Apple implemented
- [ ] TestFlight beta distributed and tested

**Android (Google Play Store)**
- [ ] App icons (adaptive icon with foreground + background)
- [ ] Feature graphic (1024×500)
- [ ] Screenshots for phone and 7" tablet
- [ ] Play Store description (EN + ID)
- [ ] Privacy policy URL in Play Console
- [ ] In-app purchases configured in Play Console
- [ ] Target API level 34 or higher
- [ ] 64-bit compliance
- [ ] Internal testing → closed testing → production rollout

### 15.6 Final QA Pass

| Area | Tests |
|---|---|
| Auth | Sign up, login, logout, password reset, Google SSO, Apple SSO |
| Scanner | Happy path, blur fail, retry, manual fallback, 720p enforcement, scanner disabled offline |
| Personal offline | Add transaction offline, sync on reconnect, cache readable offline |
| Rooms — connection | Room feed live, budget updates live, new member join event |
| Rooms — no connection | No-connection screen shown, personal tab still accessible |
| Payments | Midtrans Snap checkout across every channel, webhook tier upgrade, scan top-up, storage extension |
| Expiry | Accelerated test: receipt expires on day 365, record preserved |
| Localization | All strings render correctly in EN and ID |
| Performance | App cold start under 3 seconds, feed loads under 1 second |

### 15.7 Deliverables at End of Phase 4
- Offline mode for personal finance working end to end (queue, sync, cache)
- No-connection handling for rooms working correctly
- Full EN + ID localization
- Keep-alive cron running on Supabase
- Both apps submitted to App Store and Play Store
- Privacy policy and terms of service pages live
- All QA tests passing
- **LOIT is live 🚀**

---

## Appendix A — Notification Reference

| Trigger | Copy (EN) | Channel |
|---|---|---|
| New room transaction | "Alex just added Rp85,000 to Bali Trip 🧾" | Push |
| Room budget at 80% | "Bali Trip's Food budget is 80% used ⚠️" | Push |
| Room budget exceeded | "Bali Trip's Food budget is over by Rp45,000 🔴" | Push |
| New member joined room | "Sarah joined Apartment 4B" | Feed system message |
| Personal budget at 80% | "You've used 80% of your Dining budget this month ⚠️" | Push |
| Personal budget exceeded | "You're Rp45,000 over your Dining budget this month 🔴" | Push |
| Receipt expiry — Day 335 | "Your oldest receipts expire in 30 days. Extend to keep them." | In-app banner |
| Receipt expiry — Day 350 | "Receipts expiring in 15 days. Extend for Rp16,969." | Push + Email |
| Receipt expiry — Day 360 | "Final warning: receipts expire in 5 days. Extend now." | Push + Email |
| Scan top-up depleted | "You've used all your bonus scans. Top up for Rp16,969." | In-app |
| Offline sync completed | "Your transactions while offline have been synced." | In-app |

---

## Appendix B — Security & Privacy

| Area | Implementation |
|---|---|
| Database access | Supabase Row Level Security on all tables |
| Receipt images | Stored in private Supabase Storage bucket, accessed via signed URLs |
| Receipt image usage | Never used for AI model training (stated in ToS and privacy policy) |
| Room data | Only visible to room members — RLS enforced |
| Personal data | Never visible to room admins or other members |
| App lock | Optional PIN or biometric lock |
| Data deletion | GDPR-compliant: user can delete all their data from settings |
| Auth tokens | Managed by Supabase Auth, short-lived JWTs with refresh |
| API keys | Anthropic API key stored as Supabase Edge Function secret — never compiled into the Flutter client binary |

---

*LOIT — Split bills, not friendships.*
