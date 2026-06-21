# 18. Live transaction feed via Broadcast-from-database, not Postgres Changes

Date: 2026-06-21

## Status

Accepted

Relates to the messaging pipeline (migration `20260520000000_messaging_pipeline.sql`,
[0001](0001-telegram-bot-gemini.md)/[0002](0002-telegram-bot-back-to-claude.md))
that writes bot-originated transactions server-side.

## Context

A transaction added from the Telegram bot did not appear in the app's
transaction list until the app was restarted. The row was written correctly;
only the live update was missing — restart "fixed" it because
`TransactionsNotifier.build()` re-runs the REST `.select()`, masking a dead
realtime path.

Diagnosis eliminated everything server-side on the live project:

- `public.transactions` **is** in the `supabase_realtime` publication.
- Replica identity is default (`d`) — fine for INSERT delivery.
- RLS `transactions_select_own_or_room` permits the owner to read their own
  rows, so a Postgres Changes INSERT *should* be authorized.
- The `users`-row channel in `app.dart` uses an identical `onPostgresChanges`
  shape.

Yet the realtime service logs showed only the **Broadcast** replication slot
active (`supabase_realtime_messages_publication`) and the tenant repeatedly
idle ("no connected users"). Postgres Changes was not delivering INSERT events
to the client socket. The usual culprit is the realtime JWT (expired/anon →
per-row RLS silently denies), and the per-change RLS path is fragile by design:
every event is re-authorized against a token that must stay fresh.

## Decision

Drive the live personal transaction feed with **Broadcast from the database**
instead of Postgres Changes.

- **DB trigger** on `public.transactions` for `INSERT`, `UPDATE`, `DELETE`
  sends a realtime broadcast to a **per-owner topic** `txns:user:<user_id>`
  (uses `OLD.user_id` on delete). `SECURITY DEFINER` so it can write to
  `realtime.messages` regardless of the writer's role (bot service-role inserts
  and authenticated user inserts alike).
- **Private channel.** The app joins `txns:user:<own uid>` with `private: true`.
  An RLS policy on `realtime.messages` authorizes a user to its **own** topic
  only. Auth is checked **once at join**, not per event — far more robust than
  the per-row RLS that was failing, and correct for financial data (the public
  alternative would ship tx amounts/notes unauthenticated, relying only on an
  unguessable UUID topic).
- **Lightweight signal, not the row.** The broadcast carries `{op, id}`; the app
  responds by refetching over REST. Keeps one source of truth, no `Txn.fromRow`
  duplication, RLS stays authoritative at read. The extra REST roundtrip per
  change is negligible for a personal feed. The feed provider triggers the
  refetch with `ref.invalidate(transactionsProvider)` from its **own** ref — not
  the data notifier's own `ref.refresh` self-call, which did not re-run `build()`
  (the refetch silently no-op'd; verified on-device).
- **Subscription decoupled from refetch.** The private channel is subscribed
  once and persists for the session; a broadcast triggers a data refetch
  **without** tearing down and rejoining the channel. (The old code created the
  channel inside `build()`, so each `invalidateSelf` rebuilt it — with a private
  channel that re-authorizes on join, a burst of writes could land mid-rejoin
  and be dropped.)
- **Explicit `realtime.setAuth` before join (required, not optional).** The
  private join is authorized by the `realtime.messages` RLS policy, which needs
  the user's JWT on the realtime socket. Without it the join is never acked and
  subscribe cycles `closed`/`timedOut` forever (observed on-device). The feed
  provider pushes the current access token before `subscribe()`.
- **Replace, don't stack.** The dead `onPostgresChanges` block in
  `transactions_provider.dart` is removed; broadcast is the single live
  mechanism, avoiding double-refetch if Postgres Changes ever revived.

## Consequences

- **Join-time auth still depends on the realtime token**, but a single failed
  join is observable (subscribe status) and self-heals on reconnect with a fresh
  token — unlike the silent per-event denial it replaces.
- **New surface to maintain:** a DB trigger + function and a `realtime.messages`
  RLS policy live in a migration, separate from the Flutter subscription. The
  topic string `txns:user:<uuid>` is a contract shared by both and must stay in
  sync.
- **One REST refetch per change** (vs patching state from the payload). Chosen
  for correctness/simplicity over shaving a roundtrip.
- **Scope is the personal feed only.** The trigger broadcasts to the owner's
  topic; `roomTransactionsProvider` keeps its existing reconnect-driven refetch
  and is unchanged. Other room members' personal feeds never included another
  member's row anyway (`.eq('user_id', me)`), so no cross-user broadcast is
  needed.
- The `users`-row channel (`app.dart`) still uses Postgres Changes and is **not**
  migrated here; if it shows the same staleness it is a separate follow-up.
