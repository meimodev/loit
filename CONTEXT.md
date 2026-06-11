# LOIT

Indonesian personal-finance app. This glossary fixes the language around AI
usage metering and gating — the terms below are easy to conflate and the
distinctions are load-bearing for billing and abuse control.

## Language

### AI usage & gating

**Scan**:
A single metered AI extraction of one transaction from an **image** or **voice
note**. The billable unit. A Scan is consumed at AI-call time and refunded only
when the AI returns no usable transaction.
_Avoid_: credit, OCR call, scan credit.

**Scan quota**:
The per-tier monthly cap on **Scans** (free 5, lite 30, pro 150; `null` =
unlimited). Enforced server-side; the client cap check is a UX pre-check only,
never the authority.
_Avoid_: scan credit, scan limit (when referring to the running balance).

**Text parse**:
AI interpretation of a **typed** chat message into a transaction. Gated by the
**Rate limit** only; never drawn from the **Scan quota**.
_Avoid_: text scan.

**Rate limit**:
A per-chat throttle on bot messages (50 / hour). Gates **Text parse** and
flooding. Independent of **Scan quota** — a different concept with a different
window and a different purpose (abuse control, not billing).
_Avoid_: quota, throttle quota.

**Receipt image**:
The stored photo of a scanned document, kept in the private `receipts` bucket
for non-free tiers and auto-expiring. Distinct from the **Scan** that produced
it — a Scan can occur without a Receipt image being kept (free tier, or
unstored paths).
_Avoid_: receipt, attachment.

**Pending transaction**:
A low-confidence parse held for explicit user confirmation before it becomes a
**Transaction**. The **Scan** that produced it is already spent; confirming or
discarding it does not change the **Scan quota**.
_Avoid_: draft, unconfirmed scan.

### Categories

**Category style**:
The *visual* identity of a category — tint colour, icon, and a canonical
**English** name. Sourced from `categoryStyleProvider`. The English name is for
internal/visual use; it is **not** the string to render to the user.
_Avoid_: category label, category name (when meaning the visible text).

**Category display label**:
The *locale-aware* user-facing name of a category. Sourced from
`categoryLabelProvider` / `_localizeDefault`, which substitutes Indonesian
defaults for `id` locale. Always the correct source for visible category text.
Conflating it with the **Category style** name leaks English into Indonesian UI.
_Avoid_: category style label.

### Rooms discovery

**Rooms intro**:
The one-time educational sheet that sells the value of **Rooms** (shared
expense spaces) to a user who has none. Shown **once per user, ever** — gated
on the persistent `has_seen_rooms_intro` flag, not per sign-in. Fires when the
user has felt personal value (after ~3 logged transactions or their day-2
session, whichever first), then offers a direct path to create a first room.
Distinct from the **Rooms tab empty state**, which is the always-available
fallback entry seen only if the user opens the Rooms tab themselves.
_Avoid_: rooms nudge, rooms onboarding, intro dialog (when meaning the once-ever contract).

**Rooms tab empty state**:
The zero-rooms placeholder rendered inside the Rooms tab itself. A permanent,
reactive entry point (the user navigated there). Does not drive discovery —
the **Rooms intro** does that for users who never tap the tab.
_Avoid_: rooms intro, empty rooms screen.

**Rooms create FAB**:
The persistent "New room" floating action button in the Rooms tab, shown only
once the user already has at least one room (the **Rooms tab empty state**
carries its own create CTA, so the FAB does not appear there). It is the
primary create affordance for an existing member and is always visible. At the
tier **room limit** it does not create — tapping opens the upgrade paywall
instead, making the create affordance double as the upgrade path. Distinct from
the **Rooms intro** (discovery for users with no rooms) and the **Rooms tab
empty state** (the zero-rooms entry point).
_Avoid_: add-room button, new-room icon.

### Room balance sheet

**Room account**:
A balance-bearing account **owned by a Room**, not a user — the shared analogue
of a personal **Account**. Has a kind (asset/liability), an **initial balance**,
and a currency fixed to the Room's `base_currency`. A Room may have **multiple**.
Room accounts give a Room its own balance sheet (shared cash pools, shared
debts) — distinct from **Room budgets**, which only cap shared *spending*.
_Avoid_: shared account, group wallet, room wallet.
A **Room account** lives in the same `accounts` table as a personal **Account**;
exactly one of `user_id` / `room_id` is set. Personal screens must filter
`room_id IS NULL` so room accounts never leak into a user's own balance sheet.

**Room-account movement**:
A transaction logged **inside a room** — it moves a **Room account** only, never
a personal **Account** (the pool model). One-sided expense/income on a Room
account (pool pays an outside bill, pool earns interest) or a transfer between
two Room accounts of the same room. Entered through the **usual add-transaction
form** and the scanner, both of which — when opened from a room — scope their
account and category pickers to that room alone. There is **no** personal-money
leg: a member paying a shared cost from their own pocket is not a Room-account
movement. Room-account movements are **online-only** (shared-state divergence).
_Avoid_: personal mirror, sync to personal, room transaction sheet.

## Example dialogue

> **Dev:** A free user sends three text messages and one photo to the bot. What
> gets charged?
> **Domain:** The photo is one **Scan** against their **Scan quota** (free cap
> 5). The three texts are **Text parses** — they cost no Scans; they only count
> toward the **Rate limit**.
> **Dev:** The photo came back low-confidence, so it's a **Pending
> transaction**. If they ignore it, do they get the Scan back?
> **Domain:** No. The Scan was spent the moment the image hit the AI. A refund
> only happens when the AI returns nothing usable — not when the user declines a
> usable result.
