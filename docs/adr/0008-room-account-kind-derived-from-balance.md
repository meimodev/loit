# A Room account's kind is derived from its balance, not chosen

A **Room account** (ADR 0007) carries a kind — *asset* or *liability* — that
drives its icon, label, and which side of the room balance sheet it lands on.
Originally the admin picked the kind in the add/edit form and entered a signed
opening balance ("saldo awal"). For a shared pool this is redundant and
error-prone: whether a room account is an asset or a debt is *already* implied by
the sign of its balance. The summary card on the balance tab even computed the
asset/liability split from balance sign alone, ignoring the stored kind.

**Decision.** For **room accounts only**, `kind` is derived from balance:
*liability* while balance < 0, *asset* otherwise (0 ⇒ asset). It is kept truthful
by a **database trigger** rather than recomputed at each display site or dropped
from storage:

- The add form is **name-only**. A new room account is inserted with
  `initial_balance = 0` (kind defaults to `asset`; the trigger corrects it).
- The edit form keeps an **editable opening balance** (signed — a leading `-`
  marks a debt) but **no kind switch**.
- A trigger recomputes balance and sets `kind = (balance < 0 ? 'liability' :
  'asset')` on any change to a room account's transactions or `initial_balance`,
  `WHERE room_id IS NOT NULL`. Balance mirrors `roomAccountBalancesProvider`:
  `initial_balance` + income legs − expense/outgoing-transfer legs + incoming-
  transfer legs (room is single-currency, so no FX conversion). A migration
  backfills existing room accounts.

**Personal accounts are unaffected** — their owner still classifies them by hand
(a paid-off credit card stays a liability even at a positive balance), so the
trigger is scoped out of `room_id IS NULL`.

## Alternatives considered

- **Live-derive, never store.** Compute kind from balance at every read and stop
  maintaining the column. Rejected: other readers consume the stored column —
  notably the Telegram bot's account label — and would drift to a stale `asset`
  for a negative room account. The trigger keeps one source of truth correct for
  all readers without touching each site.
- **Fix each display site instead of the column.** Change the balance tab and the
  Telegram bot to compute kind locally. Rejected: more sites to find and keep in
  sync; the column would still lie for any future reader.
- **Apply auto-kind to all accounts.** Rejected: it would override a personal
  account owner's manual classification.

## Consequences

- The stored `kind` column stays authoritative for room accounts but is now
  trigger-owned; manual writes to it for room rows are pointless.
- The trigger's balance formula must stay in step with
  `roomAccountBalancesProvider`; divergence would mislabel accounts. A change to
  one must change the other.
