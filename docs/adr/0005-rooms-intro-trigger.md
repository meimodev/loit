# Rooms intro fires on engagement, not sign-in

The **Rooms intro** sheet (educating solo users about shared Rooms) previously
fired on every successful sign-in, gated only by a per-session bool — so it
re-nagged returning users, and the `has_seen_rooms_intro` column shipped but
was never read or written. We moved discovery to a once-ever **engagement
trigger**: the sheet shows a single time, when a zero-room user has felt
personal value (≥3 logged transactions OR their day-2 session, whichever
first), and persists `has_seen_rooms_intro` so it never returns. The sheet now
offers a direct "Create a room" CTA into `/rooms/new`.

## Considered options

- **Home card** — rejected: permanently clutters a dense personal dashboard to
  serve the minority of users who will adopt Rooms.
- **Rooms as the default landing screen** — rejected: LOIT is personal-first
  (Phase 1 core); a shared-feature front door taxes the solo majority on every
  cold open, and lands zero-room users (the discovery target) on an empty
  screen that reads as a broken app, hurting D1 retention.
- **Engagement-triggered intro sheet (chosen)** — reuses the existing sheet,
  DB column, and analytics event; smallest surface; also fixes the
  every-login re-show bug.

## Consequences

- `has_seen_rooms_intro` becomes load-bearing: it is the persistence authority
  for the once-ever contract. A per-session bool still guards double-show
  within a session if the DB write is delayed/offline.
- The trigger reads the loaded transaction list length (cap 200) as a cheap
  proxy for "≥3 transactions" rather than a dedicated count query.
