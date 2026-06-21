# LOIT

Indonesian personal-finance app. This glossary fixes the language around AI
usage metering and gating — the terms below are easy to conflate and the
distinctions are load-bearing for billing and abuse control.

## Language

### AI usage & gating

**Capture**:
A single act of turning one user input into one transaction via AI — a typed
message (**Text parse**), a voice note, or a receipt **image**. The metered
unit: every Capture consumes **AI Credits**. One Capture yields at most one
transaction; a receipt with 70 line items is still one Capture. Credits are
reserved to gate the Capture, charged after the AI responds (the count depends
on output size), and refunded only when the AI returns no usable transaction.
_Avoid_: scan (deprecated — it implied a photo and a fixed cost-of-one), OCR call.

**AI Credit** (_Kredit AI_):
The user-facing unit of monthly AI allowance. A Capture costs
`max(1, ceil(completion_tokens / 1024))` credits — larger content costs more, so
a long receipt or a huge text paste draws several credits (ADR 0017). Each tier
has a monthly **credit cap** (free 5, lite 30, pro 150; unknown tier =
unlimited); top-ups add bonus credits. The cap is **soft**: a Capture is allowed
whenever ≥1 credit remains and may overshoot, because the true cost is only known
after the AI responds. Enforced server-side; the client check is a UX pre-check,
never the authority.
_Avoid_: scan, scan quota, scan credit, scan limit.

**Text parse**:
AI interpretation of a **typed** chat message into a transaction — one kind of
**Capture**. Since ADR 0017 it **consumes AI Credits** (floor 1) exactly like
image and voice; it is additionally throttled by the **Rate limit**.
_Avoid_: text scan, free text (it is no longer free).

**Rate limit**:
A per-chat throttle on bot messages (50 / hour). Gates flooding across all
**Capture** kinds. Independent of **AI Credits** — a different concept with a
different window and a different purpose (abuse control, not billing).
_Avoid_: quota, throttle quota.

**Receipt image**:
The stored photo of a captured document, kept in the private `receipts` bucket
for non-free tiers and auto-expiring. Distinct from the **Capture** that produced
it — a Capture can occur without a Receipt image being kept (free tier, or
unstored paths).
_Avoid_: receipt, attachment.

**Pending transaction**:
A low-confidence parse held for explicit user confirmation before it becomes a
**Transaction**. The **AI Credits** that produced it are already spent;
confirming or discarding it does not change the balance.
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
room feed. Two species, distinguished only by which account funds them: a
**Room-account movement** (pool-funded) or an **Out-of-pocket room expense**
(personal-funded). Only the **pool** species counts toward **Room budgets** /
room spend / room balance; the My-money species is the *payer's* spend (ADR
0013) and is visible-but-uncounted in the room. All Room
transactions are **online-only** (any `room_id` row is shared; offline-queuing
one makes it invisible in every room surface — which read the DB by `room_id` —
until sync). _Avoid_: room movement (when meaning the umbrella), shared txn.

**Online-only room operation**:
**Any** read or write touching a `room_id` — room list/feed/detail/budget/
account reads, and every mutation (create/update/archive room, leave, kick,
invite, accept invite, room budgets, room accounts, and **all** Room
transactions including the **Out-of-pocket room expense**). Room state is
server-authoritative and shared, so the app never serves it from a local
cache and never offline-queues a room write. Offline, a room **read** shows a
clean per-surface "you're offline" state (Retry; auto-heals when connectivity
returns) and a room **write** is rejected with **Online-only rejection** —
never silently queued. The single exception that escapes by design is a
`createRoom` whose request was sent but whose response was lost: a retry may
create a duplicate room (a known, accepted limitation — every other room write
is idempotent). _Avoid_: offline room mode, room sync, queued room action.

**Online-only rejection**:
The signal that a write was refused for lack of connectivity, surfaced as a
single `OnlineOnlyActionException` regardless of op. Raised two ways: a
pre-write reachability probe that fails fast, **or** a network-class exception
(`SocketException` / `ClientException` / timeout) caught around the live call
and mapped. Non-network failures (RLS denial, validation, expired invite,
business errors from an Edge function) are **never** mapped to this — they keep
their real message, so a connected user is never told "needs internet" for a
server-side refusal. _Avoid_: offline error, save failed (when meaning this).

**Room-account movement**:
The **pool-funded** species of **Room transaction** — it moves a **Room
account** only, never a personal **Account** (the pool model). One-sided
expense/income on a Room account (pool pays an outside bill, pool earns
interest) or a transfer between two Room accounts of the same room. There is
**no** personal-money leg. (A member paying a shared cost from their own pocket
is the sibling **Out-of-pocket room expense**, not this.) _Avoid_: personal
mirror, sync to personal, room transaction sheet.

**Out-of-pocket room expense**:
The **personal-funded** species of **Room transaction** (ADR 0011; ownership
reversed by ADR 0013) — a row with `room_id` set whose `account_id` is the
**payer's own personal Account**. It is the **payer's** spend, not the room's:
it counts in the payer's **Personal spend aggregate** and **personal budget**
and **debits the payer's personal cash balance** (keyed off `account_id`
membership), but counts toward **none** of the room's totals — not room
expense/income, not **Room budgets**, not the **balance sheet** (it touches no
Room account). It stays **visible** in the room Feed (members see who fronted
the cash) but renders **de-emphasised** there: amount in `contentDisabled` with
a leading sign, carrying a **My money** chip. It is **account-only**, not a
settlement: the room implicitly owes the payer, but that debt is **not tracked**
(no who-owes-whom, no settle-up — that would be a separate Settlement ledger).
The UI surfaces it as **Paid from: Room pool | My money** on the add form,
quick-add, scanner, and transaction detail; default is **Room pool** (My money
when the room has no Room account yet). _Avoid_: personal mirror (the dead
dual-write transfer), split, reimbursement.

**Personal cash-flow total**:
The income / expense / net summary on the **Transactions** tab. Sums **what
moved through the user's own wallet** — every personal row, plus the **My money**
leg of an **Out-of-pocket room expense** (real cash left the wallet). A
**Room-account movement** (pool) has **no personal leg** and so contributes
**nothing**, even when shown in the list under the *all* lens. Close to the
**Personal spend aggregate** (dashboard MTD) since ADR 0013 — both now include
**My money** out-of-pocket rows and exclude **pool**. They still differ in
scope: cash-flow is the Tx-tab triple over the selected lens; the aggregate is
the dashboard MTD spend metric.
_Avoid_: spend total, monthly spend (when meaning the tx-tab triple).

**Personal spend aggregate**:
A "what I spent on my own life" total (dashboard month-to-date). Excludes
**pool** rows (Room-account movements) but **includes** **My money**
out-of-pocket room rows (ADR 0013 flipped this — that spend is the payer's).
_Avoid_: cash flow, wallet total.

**Out-of-pocket invariant** (funding decides ownership):
A rupiah of spend has exactly **one** owner, set by funding. **Pool** money is
the **room's** spend (room totals, room budget, room balance). **My money** is
the **payer's** spend (personal spend aggregate, personal budget, personal cash
balance) — and counts toward **none** of the room's totals, though it stays
visible (de-emphasised) in the room Feed. Counting one rupiah in both ledgers'
*spend* is the double-count ADR 0007 warned of; ADR 0013 resolves it by giving
each rupiah a single owner. Mutating a My-money row moves the payer's real cash,
so it is **payer-editable only** — the room-admin override on Room transactions
applies to Room-account movements, never to Out-of-pocket room expenses.

**Payer**:
The room **member** who logged a given **Room-account movement** — surfaced on
each row in the room's **Transactions** tab as that member's avatar (badge on
the category icon) and name. Distinguishes a shared room's rows from the
personal transaction list, where authorship is implicit. _Avoid_: owner (means
the room creator), author.

### Update gating

**Update gate**:
The server-side authority that decides whether a running client build is too old.
A single public-read row holds three **semantic-version** thresholds —
**minimum**, **recommended**, **latest** — compared against the device's own
version string with proper version ordering (`1.0.9 < 1.0.10`). The semver
(`versionName`, surfaced by `package_info.version`) is the load-bearing identity,
**not** the build number: CI overrides the pubspec `+N` (`versionCode`) with a
timestamp, so the build number is unknowable ahead of a release, whereas the
semver is human-controlled and bumped each release by `push-deploy`.
The gate is **fail-open**: a fetch failure reuses the last cached gate (so a
Blocked user can't dodge by going offline), but a client with **no cache**
(first launch, or a reinstall) while offline resolves to **Current** — a
deliberate ADR-0015 choice, since a breaking client's backend calls fail anyway,
so the backend stays the real gate in that window.
_Avoid_: version check, force-update flag (the gate is four states, not a boolean);
build number (the gate ignores it).

**Update state**:
The client's standing against the **Update gate**, derived by comparing the
device version to the thresholds. Exactly one of four:
- **Blocked** — `version < minimum`. Non-dismissible; the app is unusable once
  the gate resolves (a brief post-launch window aside — the gate fetch is async,
  so frame one paints before the overlay). Used only for **breaking** releases,
  where the backend is the real gate during that window anyway.
- **Recommended** — `minimum <= version < recommended`. A dismissible prompt shown
  on **every launch** until updated.
- **Optional** — `recommended <= version < latest`. Prompted **once**, then
  reduced to a passive marker; not re-nagged.
- **Current** — `version >= latest`. No prompt.
_Avoid_: outdated, stale (ambiguous about which of the three lower states).

**Tag → threshold → state** (the whole chain in one place — it lives split
across the CI step, the migration, and `update_gate_provider.dart` otherwise):

| Release tag (ADR-0015) | Threshold it raises | State older clients land in |
|---|---|---|
| `v1.2.0` *(plain)* | `latest` | **Optional** |
| `v1.2.0-recommended` | `recommended` (+`latest`) | **Recommended** |
| `v1.2.0-breaking` | `min` (+`recommended`+`latest`) | **Blocked** |

_Flagged ambiguity_: the tag suffix names **neither** the threshold it sets
**nor** the state it produces. Only `-recommended` is self-consistent. A plain
tag yields **Optional** (there is deliberately **no** `-optional` suffix);
`-breaking` sets `min` and yields **Blocked** (no `-blocked` suffix). Seeing
"Blocked" in code, do **not** grep for a `-blocked` tag — it does not exist.
Thresholds only ever rise (CI `max()`-es each field; lowering is manual SQL only).

### Realtime

**Transaction live feed**:
The mechanism that updates the app's personal transaction list the moment a row
changes — including **bot-originated** writes from the messaging pipeline. Driven
by **Broadcast from the database** (ADR 0018), **not** Postgres Changes: a DB
trigger on `transactions` (insert/update/delete) sends a lightweight `{op, id}`
broadcast to the owner's **private** topic `txns:user:<user_id>`; the app, joined
to its own topic, **refetches over REST** on receipt (the broadcast is a signal,
never the data). Authorization is a single RLS check on `realtime.messages` **at
join**, not per event — which is why this is robust where the prior per-row RLS
path silently dropped events. Distinct from a plain **REST refetch** (what
restart / pull-to-refresh / reconnect already do); the live feed is what makes
those unnecessary.
_Avoid_: realtime subscription, postgres changes, live sync (when meaning this
specific broadcast-driven path).

## Example dialogue

> **Dev:** A free user sends three text messages and one 70-item photo to the
> bot. What gets charged?
> **Domain:** Four **Captures**, all drawing **AI Credits** (free cap 5). Each
> short text is one credit (floor 1); the long photo is
> `max(1, ceil(completion_tokens / 1024))` — about 3 credits. That is 6 credits
> against a cap of 5, so the photo Capture overshoots: it is allowed because a
> credit remained when it started, and the next Capture is then blocked. All
> four also count toward the **Rate limit**.
> **Dev:** The photo came back low-confidence, so it's a **Pending
> transaction**. If they ignore it, do they get the credits back?
> **Domain:** No. The credits were spent the moment the image hit the AI. A
> refund only happens when the AI returns nothing usable — not when the user
> declines a usable result.
