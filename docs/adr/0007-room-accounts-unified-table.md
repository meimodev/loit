# Room accounts share the accounts table; room transactions are pool-only

> **Partially superseded by [ADR 0011](0011-out-of-pocket-room-expenses.md).**
> The unified-`accounts`-table model stands. The **pool-only** stance does not:
> ADR 0011 reintroduces the personal-paid room expense as a first-class
> **Out-of-pocket room expense**, with the edit/delete/leave-room hazards cited
> below explicitly closed.

Rooms need their own balance sheet — shared cash pools and shared debts a
**Room account** carries a balance, distinct from **Room budgets**, which only
cap shared spending. A room may have many; each is fixed to the room's
`base_currency`.

We model **Room accounts as rows in the existing `accounts` table** rather than a
new `room_accounts` table: `user_id` becomes nullable, a nullable `room_id` is
added, and a CHECK enforces exactly one of the two is set. This reuses the whole
transaction machinery (`account_id`, `to_account_id`, `fx_snapshot`, balance
providers, the account picker) for room accounts. No new column on
`transactions`; the existing `room_id` marks a row for the room feed.

**Room transactions are pool-only.** A transaction logged inside a room moves a
Room account *only* — a one-sided `expense`/`income` on one Room account, or a
`transfer` between two Room accounts of the same room. There is no personal-money
leg. They are entered through the **usual add-transaction form** and the scanner;
when either is opened from a room, its account **and** category pickers are
scoped to that room alone.

> **Superseded:** an earlier revision of this ADR added a per-transaction
> *Personal mirror* — a transfer between the logger's personal account and a Room
> account ("this also moved my own money"). It was dropped before release in
> favour of the pool-only model above: a single room-only picker is simpler and
> the cross-ledger row created edit/delete/leave-room hazards. The migration's
> ownership trigger still *permits* a cross-ledger transfer leg, but no UI path
> creates one.

## Considered options

- **Separate `room_accounts` table (rejected)** — cleaner isolation, but
  `transactions.to_account_id` can't cross tables, forcing a separate balance
  provider and account picker. Large surface for no semantic gain.
- **Single dual-affect row double-counted into two ledgers (rejected)** — fewest
  rows, but every balance, report, export, budget, and offline path must
  special-case it; breaks the invariant that each ledger is a sum of its own rows.
- **Unified `accounts` table, pool-only room transactions (chosen)** — reuses
  the existing transaction machinery; each ledger stays a plain sum of its own
  rows; the room entry surface is the same form users already know.

## Consequences

- `user_id` is nullable on `accounts`. **Every personal query must add
  `room_id IS NULL`** (or use a view) so room accounts never leak into personal
  net worth, dashboard, pickers, or CSV export. Likewise the room-scoped form and
  scanner must pick **only** that room's accounts — a personal account on a row
  with `room_id` set would silently recreate the old personal-paid-shared-expense
  model we removed.
- The old personal-paid room expense (`account_id`=personal + `room_id`=room) is
  gone for new entries; historical rows remain, read-only, in the feed.
- **RLS** on room-`accounts` rows: SELECT = any room member; INSERT/UPDATE/DELETE
  = room admin. Movements: SELECT = member; INSERT = member; UPDATE/DELETE =
  admin or original logger.
- **Archive-only — room accounts are never hard-deleted.** Reuse `archived_at`;
  archiving a room archives its room accounts.
- **All transactions touching a room account are online-only** — the write path
  detects a room-owned `account_id`/`to_account_id` and refuses to enqueue
  offline. No overdraft guard in v1. Scan-from-room is blocked when the room has
  no account yet.
- Room balance-sheet totals render in `base_currency` only; `base_currency` is
  frozen once a room account exists.
- The vestigial `rooms.sync_to_personal` column (referenced nowhere) was dropped.
