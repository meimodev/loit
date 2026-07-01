# 22. In-app voice Capture reuses the STT+parse pipeline and discards audio

Date: 2026-06-27

## Status

Accepted

Builds on [0016](0016-all-ai-through-openrouter.md) (all AI on OpenRouter,
including Whisper STT), [0017](0017-token-metered-ai-credits.md) (token-metered
AI Credits), [0004](0004-server-side-scan-gating.md) (server-authoritative
gating), and [0014](0014-rooms-online-only.md) (rooms are online-only).

## Context

Voice transactions previously existed **only** through the Telegram bot: a voice
note is downloaded, transcribed by Whisper (`transcribeAudio`), and the
transcript flows through `parseTransactionText`
(`parseTransactionFromAudio` in `_shared/text_parser.ts`). The in-app capture
surfaces were text and **receipt image** — image goes through the `scan-receipt`
edge function (`gatedScan`) and lands in the transaction form for review.

The owner wants the same voice convenience **in the app**, not only via
Telegram. The backend STT+parse pipeline already exists; what is missing is an
in-app capture surface and an edge function entry point.

Two questions had non-obvious answers:

1. **Do we store the recorded audio?** The receipt-image precedent *persists*
   the artifact (private `receipts` bucket, signed URLs, expiry cron —
   [0003](0003-image-caching-signed-urls.md)) because a receipt is a financial
   document users re-reference.
2. **How is the AI gate shared?** `gatedScan` is image-shaped; its
   reserve→charge→remaining block already carries a `ponytail:` comment inviting
   extraction into a generic `gatedCapture` "when the 4th capture surface
   lands."

## Decision

Add in-app voice Capture that **reuses the existing pipeline** and **discards
the audio**.

- **New `parse-voice` edge function.** Auth → read tier → transcribe + parse via
  `parseTransactionFromAudio` → return the parsed transaction in the **same JSON
  shape as `scan-receipt`** (`{...parsed, credits_charged, credits_remaining}`,
  402 on quota, 422 on `not_a_transaction`/`ai_failure`). The client review path
  is therefore identical to scan.
- **Extract `gatedCapture(parse)`.** Factor the reserve→charge→remaining block
  out of `gatedScan` into a shared helper used by both `scan-receipt` and
  `parse-voice` — paying down the documented ponytail TODO. Credit metering is
  unchanged: floor 1, charged on the **text-parse completion tokens** (Whisper
  has no meaningful completion count), soft cap per [0017].
- **Discard the audio after transcription.** No bucket, no RLS, no signed URLs,
  no expiry cron. A voice note is transient input whose value is fully captured
  once parsed; the Telegram bot already transcribes and throws it away. The
  transcript's gist survives in the transaction `notes` field (the parser
  already emits "original phrasing if useful"), so traceability does not require
  the audio.
- **Client: `record` package, m4a/AAC, hold-to-talk, 60s cap.** Reached from a
  capture-mode chooser sheet on the center FAB (Scan receipt / Voice note /
  Manual). Online-only; all tiers, bounded by AI Credits. Full **room parity**:
  `roomId` + room categories/accounts are passed exactly as scan does. The
  result reuses `ScanResult` and the existing quota/top-up/ai-failure handlers.

### High-trust commit (amendment, 2026-06-27)

A **High-trust** voice parse skips the review form and commits straight to a
**Transaction**. High trust is the `high` confidence bucket (`bucketFor` ≥ 0.80)
with no reconciliation mismatch and no computed total — the same predicate
scan's auto-confirm uses, **minus** the `autoConfirmEnabled` setting. Voice
ignores that toggle and always auto-commits when High trust; there is no image
to second-guess and the transcript survives in `notes`, so the detail screen is
the review.

- **Direct save reuses scan's path**, not the form. The voice screen builds the
  `addTransaction` payload the way `scan_review_screen._save` does (resolve
  account name → id, fold merchant/items into the notes breakdown) and
  additionally carries the parser's raw `notes` (voice often has only `notes`,
  no items/merchant, so dropping it would lose the original phrasing).
  `source = 'voice'`.
- **Auto-commit requires High trust *and* a resolvable account.** If no account
  resolves (no name match, no default), divert to the form — same fallback as
  scan — rather than guess or create an account-less row. Medium/low confidence
  is unchanged: prefill the `/transactions/new` form.
- **Land on detail, back reveals where it lives.** On success: `go` the
  context-aware list (`/transactions?highlight=$id`, or `/rooms/$roomId?…` for a
  room) to replace the voice screen, then `push` the detail route on top. System
  back from detail pops to the flashed row — the same destinations the manual
  form already uses post-save. Personal rows are present in `transactionsProvider`
  synchronously (optimistic prepend before `addTransaction` returns), so
  detail-by-id resolves with no flash; room rows arrive via Broadcast (ADR-0018)
  and the detail screen handles the brief `AsyncValue.loading`.
- **Offline null-id race.** Voice is online-only, but a personal `addTransaction`
  can still queue and return null if the network drops post-parse — then skip the
  detail push and `go('/transactions')`. Rooms (`requireOnline`) throw and route
  to the form.

### Full text-pipeline parity + speech room routing (amendment, 2026-06-27)

This amendment **reverses** the original "Full room parity: `roomId` + room
categories/accounts are passed exactly as scan does … the destination is already
fixed by where the user tapped" stance above.

**Symptom that forced it.** Speaking a transaction in the app returned
*not a transaction*, but typing the **same heard transcript** into the Telegram
chat created the transaction. Root cause: `parse-voice` built a **narrow
synthetic context** — `rooms: []` and only the *client-sent, scope-filtered*
categories/accounts — whereas the bot's text flow uses `loadUserContext(userId)`
(all personal categories, **all** member rooms, all room categories). The same
`parseTransactionText` therefore rejected, in voice, messages it accepts in
Telegram: a personal-screen note naming a room had no matching room/category, and
the deterministic rescues (`tryRoomTargetedRescue`) need `ctx.rooms`, which voice
zeroed out. A cold client provider (`userCategoriesProvider.value ?? []`) could
also ship an **empty** category list, guaranteeing a reject.

**Decision.**

- **`parse-voice` uses `loadUserContext(userId)`** — the bot's full context — and
  **stops trusting client-sent** categories/accounts. Voice parses with the same
  brain as Telegram text; the empty-client-list reject disappears and the two
  surfaces stop drifting.
- **Speech routes the destination; speech always wins.** The parser's
  `destination_room` (already emitted) is now **honored client-side** and
  **overrides the screen's `roomId`**. A note recorded *inside* room X that says
  "untuk Y" lands in **Y**; saying nothing keeps the screen context (personal
  stays personal, inside X stays X). Non-member room names never match (the parser
  only sees member rooms) and silently fall back to the screen context.
- **Routed room transactions are Out-of-pocket room expenses.**
  `loadUserContext` only knows **personal** accounts, so the parser picks a
  personal account; the client resolves it against the personal list it already
  holds and commits with `room_id` set + a personal `account_id`. This is the
  **My money** species (CONTEXT.md *Out-of-pocket room expense*) — the exact shape
  the bot produces, which has no pool-funding path. No `paid_from` decision is
  made for an auto-committed voice row.
- **Warning is mandatory when speech re-routes to a room, but never blocks the
  fast path.**
  - **High trust + routed to a room:** still **skips the review form**
    (auto-commits), navigates into the room, and shows a snackbar
    *"Saved to {room} · Undo"*; **Undo** calls
    `deleteTransaction(id, requireOnline: true)`.
  - **Medium/low trust + routed:** the review form opens with `_room_id` =
    routed room and a **"Routed to {room}"** banner.
  - **Personal (no `destination_room`):** unchanged — high trust auto-commits,
    else the form.
- **Room-not-found parity (strict, inform-only).** When the parse **rejects**
  *and* the transcript addressed a room name that is not a member room, mirror
  the bot: `parse-voice` runs `extractIntendedRoomName(transcript)` +
  `findRoomByName` server-side and returns a distinct `422`
  (`{ room_not_found: true, room }`, still refunded by `gatedCapture` like any
  reject). The client adds one `ScanErrorType.roomNotFound`; the error view shows
  *"Room ‘{X}’ not found"* plus the user's rooms (listed from the client's own
  rooms provider) and the transcript, with a single **OK**. **No** "log as
  personal" escape — matching Telegram 1:1 was chosen over the original
  proceed-anyway impulse. The check lives **only** in the reject branch: a parse
  that still succeeds silently drops an unmatched room name (logs to the screen
  context), exactly as the bot does.

## Consequences

- Voice capture ships by adding one edge function + one screen; almost all
  backend logic (STT, parse, gating, credit metering) is reused, not rebuilt.
- **A personal-screen voice note that names a room now creates a Room
  transaction** — broadcast to members (ADR-0018), and for High trust *before*
  the user reviews. Mitigated by the snackbar **Undo** and the detail-screen
  delete; this is the same misparse-before-broadcast risk the base ADR already
  accepted, now reachable from a personal capture too.
- **`parse-voice` no longer trusts the client.** Categories/accounts are loaded
  server-side; the client's scoped lists become advisory at most. This removes a
  whole reject class (cold provider → empty list) and the voice/Telegram parse
  drift, at the cost of one `loadUserContext` read per capture.
- `gatedScan` and `parse-voice` no longer drift on the charge rule — one
  `gatedCapture` owns it.
- Users **cannot re-listen** to a voice note after capture; if that is ever
  wanted, it reverses this ADR's discard decision and pulls in the full
  bucket/RLS/expiry plumbing that [0003] describes for images.
- A misheard recording still costs ≥1 AI Credit (hold-to-talk auto-uploads on
  release; there is no pre-send playback step). Too-short releases are discarded
  client-side before any upload, so they cost nothing.
- **Voice is more aggressive than scan.** Scan keeps a cancelable review even at
  high confidence; voice does not, and ignores `autoConfirmEnabled`. The safety
  net is post-hoc: the detail screen's inline edit + delete. A High-trust
  *misparse* therefore becomes a real Transaction — and for a room, it is
  broadcast to other members (ADR-0018) before the user can correct it. Accepted:
  the detail screen lands immediately with delete one tap away. Reversing this
  (room countdown, or routing rooms through the form) is the obvious lever if
  misparse-before-broadcast proves painful in practice.
