# My-money room expense is personal spend, not room spend

**Supersedes the spend-ownership stance of [ADR 0011](0011-out-of-pocket-room-expenses.md)
and the `rooms`-lens / spend-aggregate rules of [ADR 0012](0012-personal-cash-flow-vs-spend-aggregate.md).**

ADR 0011 said an **Out-of-pocket room expense** (My money) "counts in room
spend/budget" because the rupiah was "the room's spend, not the payer's." ADR
0012 built on that: the dashboard **Personal spend aggregate** excluded **all**
`room_id` rows (My money included), and the room Feed / `rooms`-lens triple
summed **both** species. This ADR reverses that ownership: the room owns only
**pool** money; a My-money expense belongs to the **payer**.

## Context

A member paying a shared cost from their own pocket created a rupiah claimed by
**two** ledgers' spend totals at once — it counted as room spend (Feed, budget)
*and* was deliberately kept out of the payer's personal spend so the two
wouldn't double-count. Members reading the room's "Expenses this month" saw a
number inflated by money that never touched the room's pool, and the room
**balance** was already (correctly) unaffected by it — so the Feed expense total
and the balance sheet told two different stories about the same room.

The owner's mental model: the room's totals should reflect the **shared pool**
only. A member paying from their own pocket is doing the room a favour with
**their own** money — the room should *show* it (so everyone knows Alice fronted
100k) but not *count* it as the room's own spend or let it move the room balance.
That spend is Alice's.

## Decision

**Funding decides ownership.** A **Room transaction**'s species (pool vs My
money) now determines which ledger counts it:

- **Room-account movement (pool)** — counts toward room expense/income, room
  budget, and room balance. Unchanged.
- **Out-of-pocket room expense (My money)** — counts toward **none** of the
  room's totals (expense, income, budget, balance). It is **visible** in the
  room Feed so members see who fronted the cash, but renders **de-emphasised**:
  amount in `contentDisabled` with a leading sign (`-` expense, `+` income),
  carrying a **My money** chip. Pool rows carry a **Room pool** chip.

**The spend follows to the payer.** The **Out-of-pocket invariant** is flipped:

- The dashboard **Personal spend aggregate** now **includes** My-money room rows
  (excludes only pool). The payer owns the spend the room gave up.
- My-money room rows now count toward the **payer's personal budget** for that
  category. Room budgets count **pool only**.
- The **Personal cash-flow total** (Tx tab) is unchanged — it already kept the
  My-money leg (real cash left the wallet).

A My-money expense therefore lands in exactly one spend aggregate (the payer's
dashboard) and one budget (the payer's), never the room's — no double-count, no
vanish.

## Considered options

- **Keep ADR 0011/0012 ownership (rejected)** — room Feed expense stays inflated
  by money that never moved the pool; Feed total and balance sheet disagree.
- **Remove My money from room totals AND leave it out of personal spend
  (rejected)** — the spend would count in no aggregate anywhere; the room's real
  outlay disappears from every "what was spent" view.
- **Funding decides ownership; flip the invariant (chosen)** — each rupiah of
  spend has exactly one owner (pool → room, My money → payer); room totals,
  budget, and balance all reconcile to pool-only; visibility of who-fronted-cash
  is preserved via the de-emphasised row + chip.

## Consequences

- **Symmetry across surfaces.** On the room Feed, **My-money** rows are
  de-emphasised; on the personal Tx tab `all` lens (ADR 0012), **pool** rows are
  de-emphasised. A row's styling depends on whose money the *current surface*
  cares about.
- **Budget cap moves with the money.** Paying a shared cost out-of-pocket leaves
  the room pool budget untouched and consumes the payer's personal budget. This
  is correct ownership, not a dodge — the pool genuinely did not spend.
- **Reconciliation restored room-side, shifted person-side.** The room Feed
  expense total now reconciles with the room budget and balance (all pool). The
  two personal totals (cash-flow vs spend aggregate) now **agree** on My-money
  rows (both include them); they still differ only on pool rows (cash-flow
  excludes, aggregate excludes — both exclude pool, so they actually align on
  pool too). ADR 0012's "two numbers that must not be reconciled" tension is
  largely dissolved.
- **All room-level spend surfaces are pool-only** — Feed triple, room budgets,
  room reports. Any new room aggregate must filter to pool (Room-account
  movements) and never sum My-money rows.
- **Personal-budget counting is nominal today.** A My-money room row carries a
  **room-namespaced** category key (`room:<room_id>:…`), which never matches a
  personal budget's category key, so in practice such rows do not land in a
  personal budget. The dashboard **spend aggregate** flip (the headline number)
  is implemented; full personal-budget attribution would need a room→personal
  category mapping and is deferred. Documented so code and ADR agree.
</content>
</invoke>
