# Out-of-pocket room expenses: a personal-funded species of room transaction

**Supersedes the pool-only stance of [ADR 0007](0007-room-accounts-unified-table.md).**
ADR 0007 declared room transactions *pool-only* and called the personal-paid
room expense "gone for new entries." We are bringing it back, deliberately, as a
first-class **Out-of-pocket room expense** — but only with the hazards ADR 0007
named explicitly closed.

## Context

Members routinely pay a shared cost from their own pocket. The pool-only model
forces them either to log nothing personal (the room budget is right but their
cash balance is wrong) or to fake a pool account. Users want a **Paid from: Room
pool | My money** toggle on a room expense.

This is the *account-attribution* version (which account funded it), **not** a
settlement ledger. There is no who-owes-whom, no split, no settle-up. The room
implicitly owes the payer; we do **not** track that debt. (A real Settlement
ledger remains a possible future ADR.)

## Decision

A **Room transaction** is any row with `room_id` set. It has two species,
distinguished only by funding account:

- **Room-account movement** — `account_id` is a Room account (pool model, ADR 0007).
- **Out-of-pocket room expense** — `account_id` is the **payer's own personal
  Account**. Counts in room spend/budget (keyed off `room_id`); debits the
  payer's personal cash (keyed off `account_id` membership); touches **no** Room
  account, so the room balance sheet is unaffected.

Surfaced as a **Paid from: Room pool | My money** segmented control on the
add-transaction form, quick-add, the scanner, and the transaction detail screen.
Default **Room pool**; **My money** when the room has no Room account yet (Room
pool disabled with a hint until one exists).

### Why this is safe now (the hazards ADR 0007 named)

1. **No migration needed to permit the row shape.** The ownership trigger
   `enforce_transaction_account_ownership` already allows `room_id` set +
   personal `account_id` (it only forces a *room* account's `room_id` to match,
   and a *personal* account to belong to the user). The gate was always purely
   product/UI.
2. **Room-delete / leave-room is safe.** `transactions.room_id` is `ON DELETE
   SET NULL`. On room delete an Out-of-pocket row degrades into a plain personal
   expense from the payer's own account — balance preserved, it just stops
   counting in the (gone) room. Leaving a room touches no rows. This is *better*
   than pool-only rows, which orphan when their Room account cascades.
3. **Admin-override hazard closed in RLS.** The room-admin override on
   `transactions_update_own_or_admin` / `_delete_own_or_admin` is tightened so it
   applies **only when the row's `account_id` is a Room account** (or the admin's
   own row). An Out-of-pocket row is editable/deletable by its **payer only** —
   an admin can never move another member's personal cash. Matches the
   detail screen's existing `canEdit = isPayer` gate.

### Spend-vs-balance invariant

The same rupiah is the **room's** spend, not the payer's. Personal **spend
aggregates exclude `room_id != null`**; personal **account balance** includes the
leg. (Personal budgets are already shielded by the `room:<id>:…` category
namespace; the dashboard month-to-date spend summary is **not** and must add the
`room_id` filter — closing a latent leak where today's pool rows already inflate
it.)

### Online-only

Unchanged from ADR 0007 and extended to cover Out-of-pocket rows: **every**
`room_id` row is online-only. The room feed, totals, and budgets read the DB by
`room_id`; an offline-queued room row is invisible in every room surface (even to
its author) until sync. `addTransaction(requireOnline: roomId != null)` already
enforces this.

## Considered options

- **Keep pool-only (ADR 0007 status quo, rejected)** — leaves the payer's cash
  balance wrong whenever they front a shared cost; the common case is unmodelled.
- **Settlement ledger / split + settle-up (deferred)** — records "Andi paid"
  with no cross-ledger row, sidestepping every hazard, but is a whole subsystem
  (new tables, RLS, split rules, settlement transactions, notifications). Out of
  scope here; a candidate future ADR.
- **Out-of-pocket room expense with hazards closed (chosen)** — reuses the
  existing transaction machinery and the row shape the DB already permits; each
  ledger stays a plain sum of its own rows; the three hazards ADR 0007 cited are
  each closed (no-op / SET NULL / RLS tightening).

## Consequences

- **New RLS migration** tightening the admin override to exclude Out-of-pocket
  rows (join `accounts`, test the leg owner).
- **Dashboard MTD spend** gains a `room_id IS NULL` filter (also fixes a latent
  pre-existing leak).
- **Three create surfaces** (form, quick-add, scanner) gain the Paid-from
  segment; the scanner's "blocked without a Room account" gate is replaced by
  "My money default, Room pool disabled until an account exists."
- ADR 0007's blanket "every personal query must add `room_id IS NULL`" is now
  **precise**: personal *spend* excludes `room_id`; personal *balance* keys off
  `account_id` membership and so includes the Out-of-pocket leg by design.
- No reimbursement/settlement is tracked; the room's implicit debt to the payer
  is invisible in v1.
