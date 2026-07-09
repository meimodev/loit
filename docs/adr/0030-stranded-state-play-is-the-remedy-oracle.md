# Stranded: the device, not the server, decides when Blocked is fair

## Context

CI raises the Update gate's `min_version` from the release tag (ADR-0015), and
that step runs *before* `publishing.google_play` uploads the AAB. Play then
reviews the build (hours to days), rolls it out in stages, and finally refreshes
each device's on-device update cache. Between the tag push and that last step,
every below-floor client resolves to **Blocked**: a non-dismissible overlay whose
only button calls `AppUpdateService.performUpdate(immediate: true)`, which finds
nothing via `InAppUpdate.checkForUpdate()` and falls back to launching the Play
page — showing the version the user already has. The app is unusable and the
escape hatch is a dead link. ADR-0015 anticipated a "brief window" here and judged
the store-URL fallback sufficient; it is not.

The fix depends entirely on what `-breaking` means. We settled it: a **breaking
migration** makes an old client's writes *fail loudly* — never accepts them with a
changed meaning. So a below-floor client is **useless, not dangerous**. Blocking
it is a courtesy (a clean overlay instead of a wall of sync errors), not a safety
mechanism. That makes it legal to let a below-floor client keep running when it
has no way to update.

## Considered Options

- **Server-side promotion** — CI writes `pending_min_version`; a cron polls the
  Play Developer API and promotes it once the release is live. Rejected: Play
  availability is not global. A staged rollout, an excluded device, an old Play
  Store build, or an unserved region all leave the device with nothing to install
  while the API cheerfully reports "live". It is a proxy for the real question.
- **Timed grace** — `min_effective_at = tag_time + 48h`. Rejected: the same proxy,
  with a worse oracle. Wrong whenever review runs long or short.
- **Client-side remedy check** (chosen) — ask the device.

## Decision

A fifth **Update state**, **Stranded**: `version < min_version` **and**
`InAppUpdate.checkForUpdate()` reports no update installable on this device.
**Blocked** now additionally requires that a **remedy** exist.

Stranded is dismissible, nagged every launch, and offers **no action button** —
every button we could show either no-ops or opens a Play page for the installed
version. The user's job is to wait, and the copy says so. It resolves without
intervention: `app.dart`'s resume-invalidate re-queries Play, and the moment the
on-device cache turns over the user is promoted **Stranded → Blocked** with a
working update button.

`checkForUpdate()` runs only when the thresholds already say blocked — never on
the happy path, where it is a needless Play IPC that throws on emulators and
sideloads. A throw, or `UpdateAvailability.unknown`, resolves to **Stranded**:
fail toward usable. This is only legal because breaking writes are rejected.

The server keeps raising `min_version` at tag time. The row is now a statement of
*intent*; the device decides when that intent is *fair*.

## Consequences

- **`min_version` no longer means "enforced floor."** It means "declared floor."
  Any future consumer of `app_release_gate` that lacks a Play oracle (a web
  client, the Telegram bot, a reporting query) must not read `min_version` as the
  set of users currently locked out.
- **A stale or mistaken `-breaking` tag now strands nobody.** ADR-0015 flags such
  tags as sticky and dangerous; with no remedy to point at, no client hard-blocks,
  and the mistake degrades from an outage to a nag.
- **The drain-time self-heal ladder in `sync_service.dart` is promoted from
  convenience to contract.** Stranded clients keep writing; their rows are rejected
  by the backend, trap in the Drift queue (unbounded retry, never evicted), and are
  repaired by whatever build later drains them. **Every breaking migration must
  therefore ship its inverse rewrite in that ladder** — as ADR-0029's
  `scanned`→`image` rewrite already does — or those rows never drain and are lost
  on reinstall. This is enforced by discipline, not machinery: no queue schema
  version, no migration registry.
- **Retries stay uncapped, deliberately.** Under the loud-failure invariant a
  rejected row is not permanently bad, only bad *until the client updates*.
  Evicting it after N attempts would convert a self-healing queue into a lossy one.
  Constraint-violation failures log at `warn`, not `error` — a stranded user with a
  full queue and a flaky connection would otherwise flood Sentry.
- **Users without Play (sideload, emulator, Play disabled) never hard-block.**
  Accepted: they cannot corrupt anything, and they will drown in rejected writes.
- **Recovery lags Play by Play's own cache TTL.** A user can remain Stranded for
  hours after the build goes live. Strictly better than the lock it replaces, and
  not worth a "Check again" button that would answer *nothing yet* on a timer.
- **The invariant is now load-bearing and must be defended.** A future migration
  that renames a column in place, or repurposes an enum value, would silently make
  Stranded a data-integrity hole rather than a UX affordance. Narrow, don't
  reinterpret; add a column rather than change what one means.
