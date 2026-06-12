# A Room's catch-all categories are seeded in the database, not injected client-side

Every **Room** needs the two **Room catch-all categories** — `other` (expense)
and `income_other` (income) — so any **Room-account movement** always has a
category to land in. Today a Room's categories are seeded from the creator's
*personal* categories by the `seed_room_categories_from_creator()` trigger
(ADR-less; see `20260507000000_room_categories.sql`). A creator who has deleted
their own personal "Other" / "Income other" gets a Room with **no catch-all** —
the add-transaction form, whose category picker is scoped to the Room alone, then
offers no fallback bucket.

**Decision.** The two catch-all categories are **guaranteed by the database**, not
by the client:

- The seed trigger always `INSERT`s `room:<room_id>:other` (expense) and
  `room:<room_id>:income_other` (income) for a new Room, **independently** of the
  creator's personal categories, `ON CONFLICT (room_id, key) DO NOTHING`. Keys
  obey the existing `room_categories_key_format` CHECK (`^room:<room_id>:[a-z0-9_]+$`).
- A **backfill** migration adds the same two rows to every existing Room.
- They are guaranteed **at creation only** — normal rows the creator may later
  rename or delete. Not pinned; no delete guard.
- Display label is **localized by key suffix**: `categoryLabelProvider` /
  `UserCategory.displayLabel` route a room key ending `:other` / `:income_other`
  through `_localizeDefault`, so `id` locale shows "Lainnya" / "Pemasukan lain"
  despite the stored English name.

## Alternatives considered

- **Client-side virtual injection.** Synthesize the two rows in `_CategoriesTab`
  and the category picker when absent. Rejected: they would not be real
  `room_categories` rows, so every consumer (picker, budgets, reports, the
  Telegram bot) must replicate the inject logic, and a selected synthetic
  category has no stable id to store on a transaction. The DB seed makes them
  ordinary rows that all readers already handle.
- **Pin them undeletable.** A delete-guard trigger plus hidden swipe-to-delete.
  Rejected as over-built: "always added" is satisfied by guaranteeing them at
  creation; a creator who deliberately removes a catch-all is making a choice we
  need not block.

## Consequences

- The seed trigger now emits a fixed minimum set regardless of the creator's
  personal categories; the creator's own "Other" categories may still seed
  alongside under different slugs, deduped by the `ON CONFLICT` key.
- Label logic gains a room-key-suffix special case. Any future rename of the
  catch-all keys must update that suffix match, or `id`-locale labels silently
  fall back to the stored English name.
- The catch-all is not protected: a Room can still end up with no fallback bucket
  if the creator deletes it. Accepted trade-off.
