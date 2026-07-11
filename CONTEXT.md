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

**Capture kind**:
*What* the user supplied: **text**, **image**, or **voice**. Every **Capture**
has exactly one kind. Kind drives which parser runs; it does not by itself
determine cost (see **AI Credit**).
_Avoid_: capture type, scan type.

**Capture channel**:
*Where* the input entered LOIT: **in-app** or **Telegram**. Orthogonal to
**Capture kind** — the same kind arrives through either channel and meters
identically. Channel is not a billing concept; only the **Rate limit** is
channel-specific (Telegram only).
_Avoid_: source (that is the persisted pair), platform, origin.

**Transaction source**:
The persisted origin of a transaction: a (**Capture channel**, **Capture kind**)
pair, or **Manual** when no Capture occurred. Six values — in-app image, in-app
voice, Telegram text, Telegram image, Telegram voice, Manual. Typing *in-app* is
**Manual**, not a Capture: it crosses no AI boundary and charges no **AI Credit**.
Typing *in Telegram* is a **Text parse** and is charged. That asymmetry is why the
grid has an empty cell, not a sixth Capture.
Source is fixed **at creation** and never changes: editing a transaction's amount,
category, or note does not alter where it came from. A restored (undeleted)
transaction keeps its original source.
_Avoid_: scanned (the pre-ADR-0029 stored spelling of image; the constraint still
accepts it during the client rollout, but nothing writes it), bot chat, entry
method.

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

**High trust**:
A parse the model is confident enough in to skip review — the `high`
**confidence bucket** (`confidence ≥ 0.80`) with no reconciliation mismatch and
no computed total. For **voice Capture** only, a High-trust parse is committed
straight to a **Transaction** with no review step (the `autoConfirmEnabled`
scan setting does not gate voice). Scan still shows a cancelable review even at
High trust. A High-trust **Transaction** always uses the **current server/client
time** as its timestamp, never the AI's parsed date (a receipt's printed date is
ignored on the auto-commit path).
_Avoid_: high confidence (the bucket), auto-confirm (the scan-only setting).

### Notes & item breakdown

**Note** (_Catatan_):
The user's free-text remark on a transaction — its purpose or context ("buat
meeting kantor"), never a restatement of merchant, amounts, or items. Sourced
per Capture kind: AI-extracted from the message/transcript (text, voice),
the photo caption (Telegram image), or typed in the scan-review note field
(in-app image). Since ADR 0025 it **is** the `notes` column — stored pure,
with no structural encoding.
_Avoid_: description, caption (a Telegram-only source, not the concept),
canonical notes (the legacy encoding).

**Item breakdown**:
The structured line items of one Capture — per line: name and whichever of
qty / unit price / total price are known. Stored as `transaction_items` rows
(ADR 0025) — the AI extracts them server-side; the app only renders. One
Capture yields at most one Transaction regardless of item count.
_Avoid_: items list, receipt lines, sub-transactions, notes breakdown (the
legacy string form).

**Canonical notes text** (legacy):
The **superseded** string encoding (ADR 0024 → 0025) that packed merchant,
item bullets, `Total:`, and a `Catatan:` note line into `transactions.notes`.
**Read-only**: `parseBreakdown` still recognises it so pre-pivot rows render,
but nothing writes it anymore — new rows store merchant / items / Note in
their own columns. Editing a legacy row re-saves it structured.
_Avoid_: writing it, extending it, treating a parse failure as an error (it
just renders as plain text).

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

### Church rooms

**Org type**:
A **Room**'s flavour, stored in `rooms.org_type` (`general` | `church`; `family`
/ `community` reserved, unused). `general` is the default and unchanged. The
flavour selects an onboarding flow and a denomination-aware report; it does
**not** fork the underlying room model — accounts, budgets, transactions,
balance, and the catch-all categories behave identically across org types.
_Avoid_: room kind, room category (means a `room_categories` row), room mode.

**Church room**:
A **Room** with **Org type** `church`, created through a dedicated
denomination-aware onboarding flow and gated to the **Pro** tier (client-side
gate only). Its `name` is the jemaat name; currency is fixed to IDR. It is an
ordinary Room in every mechanical respect — same accounts, budgets,
transactions, and balance machinery.
_Avoid_: church account, gereja mode, church ledger (when meaning the Room itself).

**Church profile** (`org_config`):
The church-specific metadata on a **Church room**, held in `rooms.org_config`
(JSONB): `denomination`, `jemaat_name`, `kota_kabupaten`, `phone_number`. The
`phone_number` is the **room owner's contact** (Kontak Pemilik Room) —
stored/displayed metadata only, it drives no app logic. It
is **profile only** — the room's **categories are NOT stored here**; they are
ordinary `room_categories` rows (ADR 0009). The profile feeds the **report
header** and the confirmation screen. The `denomination` is **metadata only** —
it no longer drives category seeding (see **Church chart of accounts**).
_Avoid_: org config categories, kategori (as a stored `org_config` field).

**Church chart of accounts**:
The single, denomination-independent **Penerimaan** / **Pengeluaran** category
set seeded into every new **Church room**, regardless of `denomination`. An
app-side Dart constant carrying each category's name, `icon_name`, and `tint`;
it only **seeds** `room_categories` at creation (income/expense `kind`),
thereafter the rows are authoritative and freely editable. The expense
"Lain-lain" line is omitted in favour of the trigger's catch-all (ADR 0009).
Supersedes the earlier per-denomination preset map — GMIM/GBI/Katolik no longer
carry distinct category lists.
_Avoid_: denomination preset, category map, denomination categories.

**Penerimaan / Pengeluaran**:
The canonical church-facing terms for **income** / **expense** in a **Church
room** (report headers, entry sections). `Penerimaan` — not `Pemasukan` — is the
accounting-standard church term; the income catch-all is shown as "Penerimaan
lain" inside the church report. The underlying rows still carry `kind` =
`income` | `expense`.
_Avoid_: Pemasukan (as the church income header).

**Dana Transit / Titipan**:
A **Penerimaan** category for funds the church holds **on behalf of others**
(clearing / liability money passing through), distinct from the church's own
income. It is a real seeded category, **not** a catch-all — do not conflate with
the auto "Penerimaan lain".
_Avoid_: titipan as catch-all, transit as Pemasukan lain.

**Export type**:
On the **Export** screen, the kind of file produced from a period of
transactions. The default everywhere is **Daftar Transaksi** — a flat
transaction listing (CSV or PDF). A **Church room** offers three more types:
**Laporan Keuangan** — the church financial statement: a category-grouped
**Penerimaan** / **Pengeluaran** report — **Laporan Realisasi
Mata Anggaran** (the only AI/credit-consuming type), and **Buku Kas Umum** —
the per-account chronological cash book with running saldo. **All four types
offer both CSV and PDF**; the format selector is shown for every church type (it
was transactions-only before). CSV of a **summary report** (Laporan Keuangan /
Realisasi) carries the report's **summary rows** — grouped category /
Mata-Anggaran-code subtotals — **not** a transaction listing; **Buku Kas Umum**
is the exception — a *listing*-style report, its CSV carries the **journal
rows** (one per movement leg, with Saldo Awal / Saldo Akhir marker rows), not
subtotals. Amounts are raw integer rupiah (no
symbol / separators, spreadsheet-summable) under Indonesian headers, preceded
by a light jemaat + period metadata block. Report-CSV respects the
**csvExport** feature flag exactly like Daftar (moot in practice — church is
Pro). The type choice is
church-only; personal and general rooms export only Daftar Transaksi. The types
share the **date-range** controls (preset Bulan Ini / Triwulan Ini /
Tahun Ini chips plus a custom range), but scope transactions differently:
Laporan Keuangan counts only pool-funded **Room account** rows and drops
transfers; **Buku Kas Umum** also scopes to Room-account rows but **keeps
transfers** (as two legs) and reads **pre-range** rows too (for carry-forward
opening saldo); Daftar Transaksi lists every dated row. Laporan Keuangan is no
longer a separate screen — it is reached as an export type, not a dedicated
menu.
_Avoid_: church report screen, Laporan Keuangan menu (it is an export type, not its own screen); financial export (use Laporan Keuangan); PDF-only report (all types now export CSV too).

**Mata Anggaran** (GMIM budget-line code):
A node in GMIM's fixed, denomination-specific chart of ~300 income + expense
codes (`gmim_mata_anggaran.md`) — a three-level hierarchy: group (`1.0.00.00`) ›
line (`1.3.50.00`) › leaf (`1.3.50.01`). It is a **report-time projection
target only**, never a room's working category: a **Church room** keeps its
universal **Church chart of accounts** for entry, and **Laporan Realisasi Mata
Anggaran** re-maps that room's transactions onto Mata Anggaran codes at
generation time (ADR 0026). Income and expense codes are separate trees; a
transaction maps only within its own `kind`.
_Avoid_: kategori / room category (a `room_categories` row), Church chart of
accounts (means the universal working seed), denomination preset.

**Laporan Realisasi Mata Anggaran**:
The AI-generated **Church room** report — the canonical name for what a user may
call "financial condition" — that projects a period's transactions onto the
**Mata Anggaran** chart and totals realized amounts per code. A third **Export
type**, and the **only** one that consumes **AI Credits** (token-metered per
ADR 0017, charged to the treasurer who generates it). Exports as **CSV or PDF**
— the format is chosen **before** generation, so a single classify call (one
credit charge) backs either output; the CSV walks the same code tree as the PDF
(rows where subtotal ≠ 0) and appends **Belum Terklasifikasi** as one lump total
row. **Stateless**:
re-generating re-classifies and re-charges — there is no stored classification;
a wrong code is corrected by improving the source transaction's **Note** and
regenerating, not by an override. Transactions the AI cannot place land in a
**Belum Terklasifikasi** section of the PDF. **Actuals only** — no
anggaran/budget column.
_Avoid_: Laporan Keuangan (the free, non-AI statement grouped by working
categories), realisasi anggaran (implies a budget column), financial condition
report (use this term), GMIM report (over-narrow — the mechanism is
denomination-agnostic).

**Buku Kas Umum** (BKU — the general cash book):
The chronological **Export type** for a **Church room**: a treasurer's cash
book that lists every **Room account** movement in date order with a **running
saldo**, one section **per Room account**. Each section opens with a **Saldo
Awal** (carry-forward: the account's `initial_balance` plus all its movements
**before** the range) and closes with a **Saldo Akhir** equal to the account's
real balance at range-end. Unlike **Laporan Keuangan**, it **keeps transfers** —
a room-account transfer renders as two legs, an outgoing (Pengeluaran) row in
the source account and an incoming (Penerimaan) row in the destination — and it
reads **pre-range** rows to seed the opening saldo. Scoped to **Room-account
rows only**: an **Out-of-pocket room expense** (personal-funded) touches no Room
account and never appears. A section is emitted only when the account has
in-range movement, a nonzero opening, or a nonzero closing (archived accounts
included for history; never-funded seeded accounts omitted). Rows are terse —
Tanggal / Uraian (merchant-or-category, or "Transfer ke/dari X") / Penerimaan /
Pengeluaran / Saldo — **no payer, no category grouping**. **Mechanical, not
AI** — consumes **no AI Credits** (only **Laporan Realisasi Mata Anggaran**
does). English internal gloss: *General Cash Journal*.
_Avoid_: General Cash Journal (as the user-facing name — it is Buku Kas Umum),
Jurnal Kas, buku bank (a single-account view), Laporan Keuangan (the
category-grouped statement that drops transfers).

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
**Room creation cap** it does not create — for Free/Lite it opens the
upgrade-to-Pro paywall; for Pro it opens the buy-a-**Room slot** purchase. The
create affordance doubles as the upgrade/expand path. Distinct from the **Rooms
intro** (discovery for users with no rooms) and the **Rooms tab empty state**
(the zero-rooms entry point).
_Avoid_: add-room button, new-room icon.

### Feature discovery (coach marks)

**Coach mark**:
A one-time spotlight overlay that dims the screen, cuts a hole over one live
on-screen target, and floats a short label pointing at it — teaching what an
existing control does, in place, the first time its screen is seen. Distinct
from the **Rooms intro** (a full educational sheet with its own value pitch and
create CTA): a coach mark points at a control that is already there, adds no new
navigation, and never blocks use. Fires on **first render** of its host screen,
not after a value moment. Its "already seen" memory is **per device install**
(local), **not** the once-per-user-ever server contract the **Rooms intro**
uses — reappearing after a reinstall is acceptable for a hint.
_Avoid_: tooltip (the passive long-press kind), tutorial, walkthrough, onboarding
(implies a multi-screen flow), rooms intro (the sheet, a different contract).

**Capture coach mark**:
The **Coach mark** on the center capture **FAB**, shown once per install on the
first main-shell render. It teaches that the FAB opens AI **Capture** — that a
transaction can be snapped from a receipt (**image Capture**) or spoken (**voice
Capture**), not only typed. One spotlight covers both capture kinds; the labelled
rows of the capture sheet distinguish them once opened. Fires early (at launch)
so it never contends with the later-firing **Rooms intro**.
_Avoid_: scan coach, FAB tooltip, capture tutorial.

**Nav coach mark**:
The two-step **Coach mark** shown once per install on the main shell,
sequenced immediately after the **Capture coach mark** — spotlighting the
**Transactions** nav tab (the personal ledger: search, review, edit history),
then the **Rooms** nav tab (shared spaces for splitting with a group). Its
"seen" memory is a **separate** per-install flag from the **Capture coach
mark**, so a user who already saw only the FAB spotlight on an earlier build
still gets the nav spotlights once. For a first-time user the FAB and both nav
steps run as one uninterrupted sequence.
_Avoid_: bottom-bar tutorial, tab tooltip, nav walkthrough.

**Room tabs coach mark**:
The two-step **Coach mark** shown once per install on the first **room detail**
open — spotlighting the **Account** tab (the room's shared balance sheet: **Room
accounts**), then the **Budget** tab (shared spending caps: **Room budgets**) —
so a member who lives in the Feed discovers a room has its own accounts and
budgets. Not per-room and not gated by admin role or **Org type**: it fires on
the first room a user opens, whichever that is.
_Avoid_: room onboarding, balance tab tooltip, budget walkthrough.

### Room creation cap

**Room creation cap**:
The maximum number of rooms a user may ever **create**. Counts rooms where
`created_by` is the user — **not** membership; joining others' rooms is always
free and uncapped. The cap is **lifetime and monotonic**: the count never
decrements, so archiving or deleting a created room does **not** free capacity
(a destroyed room still counts against you forever). Base cap by tier: **Free 1,
Lite 3, Pro 7**. Effective cap = base + **Room slots** purchased (Pro only).
**Server-authoritative**: a `BEFORE INSERT` trigger on `rooms` rejects creation
past the cap and increments the **Lifetime room count**; the client gate is a UX
pre-check, never the authority. All **Org types** (general, church) count.
_Avoid_: room limit (old meaning was membership count — now obsolete),
rooms-I-belong-to, active room cap.

**Lifetime room count** (`rooms_created_total`):
The monotonic per-user counter of rooms ever created — the authority behind the
**Room creation cap**. Incremented by the room-insert trigger on every create;
**never decremented**, even on archive/delete. Backfilled at migration to each
user's current created-room count (pre-migration deletes are unrecoverable and
so are silently forgiven). Existing Pro users already over 7 keep their rooms but
cannot create more without buying **Room slots** (no grandfathering).
_Avoid_: active room count, rooms owned, room membership count.

**Room slot**:
A one-time, **permanent** purchase (consumable SKU `loit_room_slot`, Rp 19,000)
that raises a **Pro** user's **Room creation cap** by one
(`room_slots_purchased++`). **Pro-only** — Free/Lite must upgrade to Pro to raise
their cap, they cannot buy slots. Because both the slot count and the **Lifetime
room count** are monotonic, each slot pays for exactly **one** additional room
creation (buy a slot → the next create consumes the headroom → buy again for the
next). Granted by the RevenueCat webhook, idempotent on
`payment_receipts.purchase_token`, and survives Pro renewal or lapse.
_Avoid_: room credit, extra-room subscription, storage extension (a different
add-on), AI Credit (unrelated).

### Room invites

**Room invite QR**:
The **only** way into a room you didn't create (ADR 0031): the room's rotating
**Invite token** rendered as a QR code on the "Undang anggota" screen, scanned
**live** by the joiner's Capture camera. Requires co-presence — there is no
link to send, no email invite, no paste-a-token flow.
_Avoid_: invite link / tautan undangan (removed surface), email invite
(never shipped, deleted), join code.

**Invite token**:
The room-level secret behind the **Room invite QR**. One per room, rotated by
the creator via "Buat kode baru" (regenerate) — rotation immediately
invalidates every previously displayed QR, which is the revocation mechanism
for leaked codes or departed members.
_Avoid_: invite link, per-user invite (the old email path's token — gone).

### Room balance sheet

**Room account**:
A balance-bearing account **owned by a Room**, not a user — the shared analogue
of a personal **Account**. Its **kind** (asset/debt) is **derived from its
balance**, not chosen: a Room account is a *debt* while its balance is
negative and an *asset* otherwise — maintained automatically (see ADR 0008), so
the admin add/edit form has no kind switch. (Personal **Account**s keep a manual
kind.) Its **opening balance** is **0 at creation** — the admin sets a starting
figure only by editing afterwards, where a negative value marks a debt. A Room
account's currency is fixed to the Room's `base_currency`. A Room may have **multiple**.
Room accounts give a Room its own balance sheet (shared cash pools, shared
debts) — distinct from **Room budgets**, which only cap shared *spending*.
The **debt** kind is labeled **Debt** / **Hutang** in the UI (personal and room
alike) and stored as `kind='debt'` (renamed from `liability`, see ADR 0028).
_Avoid_: shared account, group wallet, room wallet; Liability / Liabilitas /
Kewajiban / Utang (the debt kind is *Debt* / *Hutang*, never these).
A **Room account** lives in the same `accounts` table as a personal **Account**;
exactly one of `user_id` / `room_id` is set. Personal screens must filter
`room_id IS NULL` so room accounts never leak into a user's own balance sheet.

**Default room account**:
The three convenience **Room accounts** — "Tunai", "Bank 1", "Bank 2" —
seeded into every new Room at creation so the room has an immediate funding
source for **Room-account movements**. Created client-side, best-effort; a
seeding failure leaves the room usable (the admin can add accounts manually).
"Tunai" is inserted first so it becomes the **first active Room account** and
the default funding source for **AI Captures** routed to the room. Guaranteed
at creation **only** — the admin may later rename, archive, or add more. Not
pinned, not backfilled to existing rooms.
_Avoid_: starter account, auto-account, required account.

**Room transaction**:
The umbrella for **any** transaction carrying a `room_id` — it shows in the
room feed. Two species, distinguished only by which account funds them: a
**Room-account movement** (pool-funded) or an **Out-of-pocket room expense**
(personal-funded). Only the **pool** species counts toward **Room budgets** /
room spend / room balance; the Personal-money species is the *payer's* spend (ADR
0013) and is visible-but-uncounted in the room. All Room
transactions are **online-only** (any `room_id` row is shared; offline-queuing
one makes it invisible in every room surface — which read the DB by `room_id` —
until sync). _Avoid_: room movement (when meaning the umbrella), shared txn.

**Archived room**:
A **Room** soft-retired via `rooms.is_archived` (`archived_at` stamped). Archive
is a **target** block, not a hide: the room still appears in the rooms list (with
an "ARCHIVED" badge), its history, balances, and existing **Room transaction**s
render unchanged. In the rooms list screen, archived rooms are grouped in a
collapsed section at the bottom to minimize visual prominence. What archiving forbids
is being chosen as the destination of a **new** transaction — manual or AI (image /
voice / text), client picker or server-side resolver. Mirrors the **Room account**
archive (`archived_at`), which already drops out of every active picker. _Avoid_:
deleted room, closed room, hidden room.

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
a leading sign, carrying a **Personal money** chip. It is **account-only**, not a
settlement: the room implicitly owes the payer, but that debt is **not tracked**
(no who-owes-whom, no settle-up — that would be a separate Settlement ledger).
The UI surfaces it as **Paid from: Room pool | Personal money** on the add form,
quick-add, scanner, and transaction detail; default is **Room pool** (Personal money
when the room has no Room account yet). Every **AI Capture** routed to a room
(any **Capture kind**, in either **Capture channel**) follows the same default: it funds the room's
**Room account** (a **Room-account movement**) when one exists, and only books a
Personal-money **Out-of-pocket room expense** when the room has none. (ADR 0023
reversed the earlier ADR-0022 stance that voice/bot room captures were always
Out-of-pocket.) The room's funding account is the **first active Room account**. _Avoid_: personal mirror (the dead
dual-write transfer), split, reimbursement.

**Personal cash-flow total**:
The income / expense / net summary on the **Transactions** tab. Sums **what
moved through the user's own wallet** — every personal row, plus the **Personal money**
leg of an **Out-of-pocket room expense** (real cash left the wallet). A
**Room-account movement** (pool) has **no personal leg** and so contributes
**nothing**, even when shown in the list under the *all* lens. Close to the
**Personal spend aggregate** (dashboard MTD) since ADR 0013 — both now include
**Personal money** out-of-pocket rows and exclude **pool**. They still differ in
scope: cash-flow is the Tx-tab triple over the selected lens; the aggregate is
the dashboard MTD spend metric. Distinct from the **Report period total**, which
is the Reports-screen triple and, in a room, counts **pool** rather than
personal money.
_Avoid_: spend total, monthly spend (when meaning the tx-tab triple).

**Report period total**:
The income / expense / net summary at the head of the **Reports** screen, over
the selected month. Personal scope sums the user's own rows. Room scope sums the
**pool** only — the room's **Room accounts** — so it is the mirror image of the
**Personal cash-flow total**, not an instance of it: what one counts, the other
excludes (ADR 0013). Converted to the viewer's home currency, unlike the room
balance section beneath it, which stays in the room's base currency (ADR 0007).
Since the Reports tabs are expense-only, this triple is the **only** place income
appears in the client; income never breaks down by category there. A church
treasurer reads **Penerimaan** per **Mata anggaran** through the **Laporan
Realisasi Mata Anggaran** export instead (ADR 0026).
_Avoid_: cash-flow total, monthly summary, insights.

**Personal spend aggregate**:
A "what I spent on my own life" total (dashboard month-to-date). Excludes
**pool** rows (Room-account movements) but **includes** **Personal money**
out-of-pocket room rows (ADR 0013 flipped this — that spend is the payer's).
_Avoid_: cash flow, wallet total.

**Out-of-pocket invariant** (funding decides ownership):
A rupiah of spend has exactly **one** owner, set by funding. **Pool** money is
the **room's** spend (room totals, room budget, room balance). **Personal money** is
the **payer's** spend (personal spend aggregate, personal budget, personal cash
balance) — and counts toward **none** of the room's totals, though it stays
visible (de-emphasised) in the room Feed. Counting one rupiah in both ledgers'
*spend* is the double-count ADR 0007 warned of; ADR 0013 resolves it by giving
each rupiah a single owner. Mutating a Personal-money row moves the payer's real cash,
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
The gate is **fail-open**: a fetch failure reuses the last cached gate, so the
*thresholds* survive going offline; a client with **no cache** (first launch, or
a reinstall) while offline resolves to **Current** — a deliberate ADR-0015 choice,
since a breaking client's backend calls fail anyway, so the backend stays the real
gate in that window. Note the cache preserves the thresholds, **not** the verdict:
an offline below-floor client remembers it is below the floor but has no **remedy**
(Play cannot install to a disconnected device), so it resolves to **Stranded**, not
**Blocked**. That is not a dodge — it reconnects into **Blocked**, and offline it
can neither sync nor corrupt anything.
_Avoid_: version check, force-update flag (the gate is five states, not a boolean);
build number (the gate ignores it).

**Remedy**:
An update this **device** can actually install **right now** — Play has reviewed,
published, rolled out to this device's cohort, and refreshed its on-device cache.
Answered per-device by `InAppUpdate.checkForUpdate()`, never by the server: Play
availability is not global (staged rollout, region, Play Store version), so no
server-side flag can know it. `min_version` rising means the floor was *declared*;
a remedy existing means the floor is *reachable*. The two are hours to days apart.
_Avoid_: "released", "live on Play" (both global; the device is what matters).

**Update state**:
The client's standing against the **Update gate**, derived by comparing the
device version to the thresholds — and, below the floor, by whether a **remedy**
exists. Exactly one of five:
- **Blocked** — `version < minimum` **and** a remedy exists. Non-dismissible; the
  app is unusable once the gate resolves (a brief post-launch window aside — the
  gate fetch is async, so frame one paints before the overlay). Used only for
  **breaking** releases, where the backend is the real gate during that window
  anyway.
- **Stranded** — `version < minimum` and **no** remedy. Below the floor with no way
  up: the release is declared but Play has not delivered it here yet. Dismissible,
  nagged **every launch**, and offers *no action* — there is nothing to tap. Resolves
  on its own when Play's on-device cache turns over; the resume-invalidate promotes
  **Stranded → Blocked** with a working update button. Writes made while Stranded are
  rejected by the backend and trap in the offline queue, then drain after the update
  (see **Breaking migration**). See ADR-0030.
- **Recommended** — `minimum <= version < recommended`. A dismissible prompt shown
  on **every launch** until updated.
- **Optional** — `recommended <= version < latest`. Prompted **once**, then
  reduced to a passive marker; not re-nagged.
- **Current** — `version >= latest`. No prompt.
_Avoid_: outdated, stale (ambiguous about which of the four lower states). Do not
say a Stranded user is "blocked" — they are still using the app.

**Breaking migration**:
A schema or backend change shipped behind a `-breaking` tag. Constrained by an
invariant that the whole Update-gate design rests on: a breaking migration must
make an old client's writes **fail loudly** (`CHECK` violation, missing RPC, RLS
denial) and must **never accept them with a changed meaning**. Rejection is safe —
the row traps in the offline queue and is repaired on a later drain. Silent
reinterpretation is corruption, and it would make **Stranded** illegal.
Corollary (the price of Stranded): every breaking migration must ship its inverse
rewrite in the drain-time self-heal ladder in `sync_service.dart`, or rows queued
by below-floor clients never drain. See ADR-0030.
_Avoid_: "breaking change" for a release that merely fixes a bad bug — that is a
`-recommended` release. `-breaking` means old writes must fail.

**Tag → threshold → state** (the whole chain in one place — it lives split
across the CI step, the migration, and `update_gate_provider.dart` otherwise):

| Release tag (ADR-0015) | Threshold it raises | State older clients land in |
|---|---|---|
| `v1.2.0` *(plain)* | `latest` | **Optional** |
| `v1.2.0-recommended` | `recommended` (+`latest`) | **Recommended** |
| `v1.2.0-breaking` | `min` (+`recommended`+`latest`) | **Stranded**, then **Blocked** once Play delivers |

_Flagged ambiguity_: the tag suffix names **neither** the threshold it sets
**nor** the state it produces. Only `-recommended` is self-consistent. A plain
tag yields **Optional** (there is deliberately **no** `-optional` suffix);
`-breaking` sets `min` and yields **Blocked** (no `-blocked` suffix). Seeing
"Blocked" in code, do **not** grep for a `-blocked` tag — it does not exist.
Note the last row is a *sequence*, not a choice: CI raises `min` at tag time,
hours before Play serves the build, so every below-floor client passes through
**Stranded** first and reaches **Blocked** only once it has a **remedy**.
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
