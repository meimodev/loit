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

**Room catch-all category**:
The two fallback categories — `other` (expense) and `income_other` (income) —
**guaranteed present in every Room** so any **Room-account movement** always has
a category to land in. Seeded into `room_categories` at room creation (and
backfilled into existing Rooms) **independently** of the creator's personal
categories, under the namespaced keys `room:<room_id>:other` /
`room:<room_id>:income_other`. Guaranteed at creation **only** — the creator may
later rename or delete them (not pinned). Their **Category display label** is
localized by key suffix, so `id` locale shows "Lainnya" / "Pemasukan lain"
despite the stored English name.
_Avoid_: default category, uncategorized, fallback bucket.

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
of a personal **Account**. Its **kind** (asset/liability) is **derived from its
balance**, not chosen: a Room account is a *liability* while its balance is
negative and an *asset* otherwise — maintained automatically (see ADR 0008), so
the admin add/edit form has no kind switch. (Personal **Account**s keep a manual
kind.) Its **opening balance** is **0 at creation** — the admin sets a starting
figure only by editing afterwards, where a negative value marks a debt. A Room
account's currency is fixed to the Room's `base_currency`. A Room may have **multiple**.
Room accounts give a Room its own balance sheet (shared cash pools, shared
debts) — distinct from **Room budgets**, which only cap shared *spending*.
_Avoid_: shared account, group wallet, room wallet.
A **Room account** lives in the same `accounts` table as a personal **Account**;
exactly one of `user_id` / `room_id` is set. Personal screens must filter
`room_id IS NULL` so room accounts never leak into a user's own balance sheet.

**Room transaction**:
The umbrella for **any** transaction carrying a `room_id` — it shows in the
room feed and counts toward **Room budgets** / room spend. Two species,
distinguished only by which account funds them: a **Room-account movement**
(pool-funded) or an **Out-of-pocket room expense** (personal-funded). All Room
transactions are **online-only** (any `room_id` row is shared; offline-queuing
one makes it invisible in every room surface — which read the DB by `room_id` —
until sync). _Avoid_: room movement (when meaning the umbrella), shared txn.

**Room-account movement**:
The **pool-funded** species of **Room transaction** — it moves a **Room
account** only, never a personal **Account** (the pool model). One-sided
expense/income on a Room account (pool pays an outside bill, pool earns
interest) or a transfer between two Room accounts of the same room. There is
**no** personal-money leg. (A member paying a shared cost from their own pocket
is the sibling **Out-of-pocket room expense**, not this.) _Avoid_: personal
mirror, sync to personal, room transaction sheet.

**Out-of-pocket room expense**:
The **personal-funded** species of **Room transaction** (ADR 0011, superseding
the pool-only stance of ADR 0007) — a row with `room_id` set whose `account_id`
is the **payer's own personal Account**. It **counts in room spend/budget**
(keyed off `room_id`) and **debits the payer's personal cash balance** (keyed
off `account_id` membership), but touches **no Room account**, so the room
**balance sheet** is unaffected. It is **account-only**, not a settlement: the
room implicitly owes the payer, but that debt is **not tracked** (no
who-owes-whom, no settle-up — that would be a separate Settlement ledger). The
UI surfaces it as **Paid from: Room pool | My money** on the add form,
quick-add, scanner, and transaction detail; default is **Room pool** (My money
when the room has no Room account yet). _Avoid_: personal mirror (the dead
dual-write transfer), split, reimbursement.

**Out-of-pocket invariant** (spend vs balance):
The same rupiah of an **Out-of-pocket room expense** is the **room's** spend,
not the payer's. Personal **spend aggregates must exclude `room_id != null`**;
personal **account balance** must include the leg (the cash left the wallet).
Counting it in both ledgers' *spend* is the double-count ADR 0007 warned of.
Mutating such a row moves the payer's real cash, so it is **payer-editable
only** — the room-admin override on Room transactions applies to Room-account
movements, never to Out-of-pocket room expenses.

**Payer**:
The room **member** who logged a given **Room-account movement** — surfaced on
each row in the room's **Transactions** tab as that member's avatar (badge on
the category icon) and name. Distinguishes a shared room's rows from the
personal transaction list, where authorship is implicit. _Avoid_: owner (means
the room creator), author.

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
