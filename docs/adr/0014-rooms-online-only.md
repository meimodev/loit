# Rooms are online-only: no local cache, no offline write queue

## Context

LOIT's personal core is offline-first: a personal transaction typed with no
connectivity is written to a Drift queue and synced later (`sync_service`),
and the user sees it immediately. Rooms are different in kind. Every row a room
surface reads or writes carries a `room_id` and is **shared, server-authoritative
state** — multiple members mutate the same pool, balances, budgets, and feed.

Two forces made the old behavior wrong:

- **Reads** were live `FutureProvider`s hitting Supabase with **no** local
  persistence. Opening any room surface offline threw a raw exception that
  rendered as a red error box or an infinite spinner — never an intentional state.
- **Writes** mostly had no connectivity handling at all (`room_service.dart`
  threw whatever Supabase threw). Only the room-transaction add path was guarded
  (`requireOnline` → `OnlineOnlyActionException`). The rest could appear to fail
  ambiguously, or — worse for any path that touched the offline queue — risk a
  room write being silently queued, which makes the row invisible in every room
  surface (all of which read by `room_id`) until a later sync.

We considered making rooms genuinely offline-capable: a local room read-cache
(mirror the list/feed/accounts into Drift) plus a room write queue. That is a
large, ongoing investment — new tables, invalidation rules, conflict handling on
shared state — and it contradicts the shared-pool model: a member acting on a
stale local copy of a pool everyone else is editing is a correctness hazard, not
a convenience.

## Decision

**Rooms are online-only by design.** The app never serves room state from a
local cache and never offline-queues a room write. This applies to **every**
operation touching a `room_id` — reads and writes alike, including the
**Out-of-pocket room expense** (personal-funded, but a shared `room_id` row).

Mechanics:

- **One choke point.** A shared `runOnline<T>()` helper wraps room mutations:
  it runs a fast pre-write reachability probe (`ReachabilityService`), and wraps
  the live call so a network-class exception is mapped to a single
  `OnlineOnlyActionException` (moved to a shared location). `RoomService` and the
  existing `requireOnline` transaction path both go through it.
- **Pre-check + catch.** The probe fast-rejects when the interface is down; the
  catch is the safety net for captive portals, mid-flight drops, and an
  unreachable backend that the probe missed.
- **Only network failures are mapped.** `SocketException` / `ClientException` /
  `TimeoutException` become `OnlineOnlyActionException`. Everything else
  (`PostgrestException`, Edge-function business errors, RLS denial, expired
  invite, validation) **rethrows untouched** and keeps its real message — a
  connected user is never told "needs internet" for a server-side refusal.
- **Reads fail cleanly.** A room read that throws offline shows a tailored
  per-surface "you're offline" state with a Retry action (the same network
  whitelist classifies offline vs a generic "something went wrong"). The state
  **auto-heals**: room read providers re-fetch on the offline→online rising edge
  via `reachabilityProvider`.
- **Writes are never disabled.** Following the existing hybrid stance, room write
  CTAs stay tappable (a flaky probe must not trap the user behind a dead button).
  The global `PersistentConnectivityBanner` forewarns; the reactive
  `OnlineOnlyActionException` toast catches an offline tap.

## Consequences

- Room behavior is now consistent and intentional offline: reads degrade to a
  retry state that self-heals, writes are rejected with a clear message, nothing
  is silently queued or served stale.
- **Accepted limitation:** a `createRoom` whose request was sent but whose
  response was lost may, on retry, create a duplicate room. Every *other* room
  write is idempotent (update/delete by id, RPC accept, dedup-able invite). We
  accept the single-op dupe risk rather than add client request-ids / server
  dedup now; revisit if it bites.
- Going offline-capable for rooms later means reversing this: building a room
  read-cache and write queue with conflict handling. Code now assumes the
  online-only invariant broadly, so that reversal is deliberate, not free.

See **Online-only room operation** and **Online-only rejection** in
[CONTEXT.md](../../CONTEXT.md).
