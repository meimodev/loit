# LOIT — Executive Summary (Investor Edition)

## One-Liner
A fintech application for Indonesian personal finance management with AI receipt scanning, offline-first sync, collaborative rooms, and a tiered subscription model (Free/Pro/Team).

---

## The Opportunity

**Market:** Indonesia's digital finance adoption is accelerating. 77M internet users (27% penetration, 2025), rising smartphone ownership (70%+), and growing fintech ecosystem. Personal finance (budgeting, expense tracking) remains underserved, with incumbent solutions fragmented, outdated, or locked to banks.

**User Problem:** Indonesian households manage cash-heavy finances across multiple accounts, informal lending, and group expenses (roommates, family, events). Existing solutions lack: offline capability (unreliable connectivity in regions), AI-powered receipt parsing, collaborative tracking, and localization.

**LOIT's Positioning:** Native Android app (India/SEA region first). Focuses on accuracy (Claude AI scanning), reliability (offline-first), and collaboration (rooms). Monetization through premium tiers (Pro/Team at $5–11/month IDR-priced).

---

## Business Model & Traction

**Revenue Streams:**
1. **Subscriptions (Pro/Team):** Rp99k/mo (Pro) + Rp199k/mo (Team). Annual discount = 8× monthly (4 months free).
2. **One-Time Add-ons:** Scan top-ups (Rp19k × 10 scans), storage extension (Rp19k × 6 mo) for free users.
3. **Future (Phase 4):** iOS App Store (15–20% regional premium), recurring bill automations, advanced analytics (freemium upsell).

**Traction:**
- Version 1.0.4+5 currently in **Google Play Closed Testing** (beta phase, not yet public).
- 39 database migrations (~1,700 SQL lines) indicate mature schema design.
- Completed Phases 1–2 (personal core + rooms); Phase 3 (payments via RevenueCat) nearing completion.
- Design system established (loit_* tokens, 15+ feature areas, 230+ screens).
- No public usage data yet (pre-launch).

---

## Product Architecture & Technical Moat

**Tech Stack Strengths:**
- **Offline-First (Drift SQLite):** Transactions queued locally, synced on reconnect. Removes connectivity friction common in emerging markets.
- **AI Scanning (Claude OCR):** Receipts parsed to merchant + line items (not just metadata). Differentiator vs. manual entry or basic OCR.
- **Collaborative Rooms:** Real-time multiplayer (Supabase Realtime) with presence, member invites via deep links, room-scoped budgets. Enables household/group use cases.
- **Tier-Aware Design:** Scan limits, feature gating, FX provider choice (free=Frankfurter, pro/team=Open Exchange Rates) all pluggable. Supports upsell funnels.
- **Modern Stack:** Riverpod 3 (codegen, type-safe state), go_router (deep links), Supabase RLS (granular auth), RevenueCat abstraction (testable payments).

**Security & Compliance:**
- Row-level security (RLS) enforced at database layer; no token leakage between users/rooms.
- Biometric lock (Face/Touch ID) + Hide Amounts for privacy.
- Payment processing via RevenueCat (PCI-DSS compliant, signed webhook only source of truth for tier flips).
- Sentry + PostHog for error tracking and analytics (no invasive tracking).

---

## Go-to-Market & Roadmap

**Phase 1–2 (✓ Complete):** Personal core (auth, accounts, transactions, scanning, budgets, charts) + rooms (invite, members, shared expenses).

**Phase 3 (🔄 Current):** RevenueCat payments, paywall, tier-gated features, billing history. Expected completion: May 2026.

**Phase 4 (📋 Planned, 2026–2027):**
- iOS App Store launch (StoreKit integration, 15–20% regional pricing premium).
- Recurring transactions, advanced budgeting, data export (GDPR compliance).
- Multi-language (Hindi, Tagalog, Vietnamese, Thai).
- Emerging markets expansion (India, Philippines, Southeast Asia).

**Marketing & Acquisition (TBD):**
- Closed testing phase: gather product feedback, refine paywall, measure conversion metrics.
- Soft launch to curated user cohorts (trusted communities, early adopters).
- Primary channels: app store optimization (ASO), word-of-mouth (rooms are viral), community partnerships (financial education platforms).

---

## Financial Projections (Conservative)

**Assumptions:**
- Launch: June 2026 (Phase 3 complete).
- DAU ramp: 1k → 10k → 100k over 18 months (conservative, assume 1–2% CTR on ASO + organic).
- Free/Pro/Team split: 90% free, 8% pro, 2% team (typical SaaS conversion).
- ARPU: $1.20/mo (blended, ~$5.99 pro + $11.99 team, weighted by cohort).
- Churn: 5% monthly (high for consumer; improved by retention features like rooms, daily habits).

| Metric | Month 6 | Month 12 | Month 18 | Notes |
|--------|---------|----------|----------|-------|
| DAU | 1,000 | 5,000 | 10,000 | Conservative ramp |
| MAU | 4,000 | 18,000 | 36,000 | ~4× DAU |
| Paying subs | ~400 | ~1,800 | ~3,600 | ~10% convert to Pro/Team |
| MRR | $480 | $2,160 | $4,320 | At $1.20 ARPU |
| Annual Revenue (Year 2) | ~$50k | — | — | Placeholder; scales with DAU |

**Notes:**
- All pricing in IDR; USD equivalents shown for reference.
- Conservative: assumes no viral effect from rooms, no press, organic discovery only.
- Upside: rooms feature can drive 2–3× network effects; early partnerships (banks, fintech platforms) could accelerate.

---

## Competitive Landscape & Differentiation

| Product | Market | Strengths | Weaknesses vs. LOIT |
|---------|--------|-----------|-------------------|
| **GCash/GrabPay** | Philippines, SEA | Payments, large user base | No budgeting, no offline, no AI scanning |
| **YNAB** | Global (US-first) | Powerful budgeting, sync | Expensive ($15/mo), no offline, no AI, Western-focused |
| **Money Lover** | SEA | Multi-currency, UI | No offline, AI scanning limited, no rooms |
| **Spendee** | Global | Analytics, reports | No offline, no AI scanning, limited rooms/collab |
| **LOIT** | Indonesia, SEA | Offline, AI scanning, rooms, localized pricing | Early stage, no iOS yet, limited brand awareness |

**Key Differentiators:**
1. **Offline-first:** Most competitors assume always-on connectivity; LOIT handles spotty coverage.
2. **AI scanning:** Line-item extraction (not just merchant); reduces manual data entry friction.
3. **Collaborative rooms:** Enables household/group use cases; improves retention and DAU.
4. **Regional pricing:** IDR-first, not USD-priced; respects local purchasing power.

---

## Risks & Mitigation

| Risk | Severity | Mitigation |
|------|----------|-----------|
| **Pre-revenue, early-stage:** No user data, product-market fit unproven. | High | Closed testing phase gathers feedback; pivot room feature if needed; ship to India/Philippines early for validation. |
| **iOS deferred:** AppStore revenue locked until Phase 4 (2026–2027). | Medium | Android dominates SEA (75%+ market share). iOS can wait; prioritize Android penetration. |
| **RevenueCat dependency:** Payment abstraction adds vendor lock. | Low | RevenueCat is industry standard, transparent pricing, audited. Can migrate if needed. |
| **Schema complexity:** 39 migrations suggest rapid iteration; maintenance burden grows. | Low–Medium | Codebase well-documented (CLAUDE.md). Consider periodic migration consolidation post-launch. |
| **Competitive response:** Incumbents (GCash, banks) launch AI scanning + rooms. | Medium | First-mover advantage in offline + rooms. Focus on user delight + community; differentiate on UX, not features alone. |

---

## Team & Execution

**Current State:**
- Solo or small team; codebase suggests sustained, disciplined engineering.
- Architecture is modern, well-organized (Riverpod 3, Supabase RLS, design system).
- CI/CD automated (Codemagic, tag-driven releases, Play Console integration).
- No hiring signal yet; feasible as solo project through Phase 3.

**Phase 4 Headcount:** Est. 2–3 eng (iOS + analytics + ops), 1 product/design, 1 growth/marketing.

---

## Investment Thesis

**Why now?**
- Indonesia's mobile-first fintech moment: 200M+ population, rising digital wallet adoption, unmet demand for consumer tools.
- Offline-first + AI scanning + rooms = rare combination. Defensible via UX + community.
- RevenueCat + Supabase reduce go-to-market friction; launch to production in weeks, not months.

**Why LOIT?**
- Proven execution (Phases 1–2 complete, near-ship Phase 3).
- Differentiated product (offline, AI, rooms).
- Regional tailoring (IDR pricing, Indonesian UX, localization).
- B2C fintech is high-TAM, high-growth; successful plays scale 100M+ users.

**Milestones (Next 18 Months):**
1. Phase 3 complete; Launch to Android (June 2026).
2. Reach 10k DAU, measure retention + paywall conversion (Dec 2026).
3. Phase 4 (iOS, India/Philippines soft launch; Jun 2027).
4. 100k DAU, regional expansion (Dec 2027).

---

## Ask

**Series Seed (Target: $500k–$1.5M):**
- **Runway:** 18–24 months (team of 4–5, SEA ops costs ~$3–5k/mo per engineer, low marketing spend initially).
- **Use of Funds:**
  - 70% — Engineering (iOS, advanced features, scaling infrastructure).
  - 15% — Growth/marketing (ASO, community partnerships, regional expansion).
  - 15% — Operations & contingency.

**Success Metrics (Series A readiness):**
- 100k+ DAU, 10%+ Pro/Team conversion, $50k+ MRR.
- Expansion to India/Philippines with 20k+ DAU each.
- Team of 5–6, repeatable unit economics.

---

## Appendix: Tech Stack Summary

- **Client:** Flutter 3.24, Dart 3.8, Riverpod 3 (state), go_router (navigation), Drift (offline).
- **Backend:** Supabase (Postgres, Realtime, RLS), Edge Functions (Deno + Claude API for OCR).
- **Payments:** Google Play Billing via RevenueCat SDK (webhook-driven, idempotent).
- **Analytics:** PostHog (events), Sentry (errors).
- **Deployment:** Codemagic (CI/CD), Google Play Closed Testing → Production.
- **Version:** 1.0.4+5 (pubspec).

---

*Prepared: 2026-05-16 | Codebase: 197 files, ~162k words, mature architecture.*

