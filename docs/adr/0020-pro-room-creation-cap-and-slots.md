# Room creation is capped per tier and counted for life; Pro buys more rooms one at a time

Rooms used to be capped by **membership** count (free 1, lite 3) with **Pro
unlimited**, enforced **client-side only** (the FAB routed to a paywall). We are
turning room creation into a metered, paid resource on Pro and moving the gate
server-side.

**Decision.**

- **The cap counts rooms you *created*, not rooms you belong to.** Joining
  someone else's room is always free and uncapped. The authority is a single
  per-user counter `users.rooms_created_total`.

- **The counter is monotonic and lifetime.** A `BEFORE INSERT` trigger on
  `rooms` increments it on every create and it is **never decremented** —
  archiving or deleting a created room does **not** free capacity. A created
  room "spends" a unit forever. This is the **consumed-on-creation** model: it
  is what makes "charge per room created" literally true, and it keeps the
  server logic a single comparison (`total < cap`) with no need to recount live
  rooms (which can't see hard-deleted history anyway).

- **Base caps: Free 1, Lite 3, Pro 7.** Effective cap =
  `base + users.room_slots_purchased`.

- **Pro buys extra rooms one at a time.** A **Room slot** is a one-time,
  permanent consumable SKU (`loit_room_slot`, Rp 19,000) that increments
  `room_slots_purchased`. Because both the slot count and `rooms_created_total`
  are monotonic, each slot pays for exactly one more room (buy a slot → the next
  create consumes the headroom → buy again for the next). Slots survive Pro
  renewal/lapse. **Pro-only** — Free/Lite must upgrade to Pro to raise their cap.

- **Server is the authority.** The trigger rejects any over-cap insert with a
  `room_creation_cap_reached` exception; the client gate (FAB, membership card)
  is a UX pre-check only. This is non-negotiable now that real money gates a
  slot — a tampered client could otherwise mint paid rooms for free. The slot
  grant lands via the RevenueCat webhook (and `dummy-grant` stub mirror) calling
  `add_room_slot`, idempotent on `payment_receipts.purchase_token`, exactly like
  the scan top-up.

## Considered alternatives

- **Cap = live count of active created rooms (delete frees a slot).** Friendlier
  — a Free user who deletes their one room could make another. Rejected: it
  needs a second "paid-consumed" counter alongside the active count to keep paid
  Pro rooms from being re-minted free after deletion, and it makes "charge per
  room created" leaky. We chose the single monotonic counter for simplicity and
  honesty of the charge.

- **Grandfather existing Pro users (keep them unlimited, or grant free slots
  equal to their overage).** Rejected: hard cap at 7 for everyone. Existing Pro
  users **keep** every room they already have (we never delete), but to create
  the next one they must buy slots. `rooms_created_total` is backfilled to each
  user's current created-room count at migration.

- **Recurring per-room subscription / tie slots to the Pro subscription.**
  Rejected: not supported by the existing one-time-SKU billing model, and adds
  downgrade-cron coupling. Slots are permanent one-time purchases.

## Consequences

- **Pro went from unlimited to 7.** This is a takeaway from existing paying
  users — surfaced as "keep what you have, buy to add more."

- **Monotonic-everything can lock a Free user out of rooms.** A Free user
  (cap 1) who creates then deletes their only room has **zero** lifetime
  creations left and cannot create another without upgrading to Pro. There is no
  recovery path by design. Expect support load; revisit if it bites.

- Pre-migration deletions are unrecoverable, so the backfill under-counts users
  who created-then-deleted before the migration — they get those creations back
  for free. Accepted.
