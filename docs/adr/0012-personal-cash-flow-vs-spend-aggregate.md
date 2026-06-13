# Personal cash-flow total vs spend aggregate: two different personal totals

**Refines [ADR 0011](0011-out-of-pocket-room-expenses.md).** ADR 0011 stated
personal *spend aggregates* exclude **all** `room_id != null` rows. This ADR
keeps that for the dashboard but defines the **Transactions tab** income/expense
/net triple as a **different metric** — a **personal cash-flow total** — that
deliberately keeps the **My money** leg of an **Out-of-pocket room expense**.

## Context

The Transactions-tab triple sits above a list that, under the *all* lens, mixes
personal rows with room rows. We had to decide what that triple counts. Reading
it as a spend aggregate (exclude all `room_id` rows, per ADR 0011) makes it agree
with the dashboard but drops a **My money** room expense the user really paid
from their own wallet — money that *did* leave their cash. Reading it as
**cash flow** (what moved through the wallet) keeps My money and drops only
**Room-account movements** (pool), which have no personal-money leg at all.

## Decision

The Transactions-tab triple is a **personal cash-flow total**:

- **`personal` lens** — personal rows only (unchanged).
- **`all` lens** — personal rows **+ My money** out-of-pocket; **excludes pool**
  (Room-account movements). A footnote ("Excludes room-pool movements") appears
  when pool rows are present, because those rows are still listed but contribute
  nothing to the triple.
- **`rooms` lens** — **room flow**: sums **both** species (pool + My money); this
  is a room-money view, not a personal one.

The **dashboard month-to-date** total is unchanged: it remains the **spend
aggregate** of ADR 0011 (excludes **all** `room_id` rows, My money included).

**The two personal totals can differ and are not reconciled.** A My-money room
expense shows in the cash-flow total but not the spend aggregate. This is by
design: cash flow answers "what left my wallet," spend answers "what I spent on
my own life," and the room's rupiah is the *room's* spend, not the payer's.

To keep the *all*-lens list/summary mismatch from reading as a bug, **pool rows
are visually de-emphasised in the *all* lens only**: amount in `contentDisabled`
with a leading sign ("-" expense, "+" income). My-money rows keep normal
income/expense colors. Under the `rooms` lens, pool rows render normally — pool
is the relevant money there.

## Considered options

- **Triple = spend aggregate (rejected)** — agrees with dashboard, but drops a
  My-money room expense the user genuinely paid; the wallet view would understate
  real cash out.
- **Triple = cash flow, accept dashboard mismatch (chosen)** — each total answers
  a distinct, defensible question; pool rows carry no personal leg so are
  correctly absent; the mismatch is documented, not a defect.

## Consequences

- Two personal "expense this month" numbers exist (dashboard vs Transactions
  tab). The glossary entries **Personal cash-flow total** / **Personal spend
  aggregate** name them; they must not be reconciled.
- Pool-row de-emphasis is **lens-contextual** (disabled in `all`, normal in
  `rooms`) — a row's styling depends on the active lens, not just its species.
- The `rooms`-lens triple is a third meaning of the same widget (room flow); any
  future change to the triple must keep all three lens semantics straight.
