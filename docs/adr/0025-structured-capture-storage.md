# 25. AI capture output lands structured — no string round-trip

Date: 2026-07-05

## Status

Accepted

Supersedes [0024](0024-note-rides-canonical-notes-text.md) (the canonical
notes-text encoding becomes legacy-read-only) and reverses the merchant-column
drop (migration 20260501000002).

## Context

Every AI capture path already returns fully structured JSON — merchant,
`items[]`, and the user's remark — and a `transaction_items` table has existed
since Phase 1, written by every in-app save and replayed through the offline
queue. Yet nothing ever read it: display reconstructed the structure by
regex-parsing a canonical string encoded into `transactions.notes`
(merchant first line, item bullets, `Total:`, `Catatan:`). The pipeline was
AI → structure → string → frontend regex → structure → render.

The owner's verdict: detecting, extracting, and rephrasing the note and item
breakdown is the AI's job — the frontend should render, not parse.

## Decision

Store what the AI produced; render it directly.

- `transactions.merchant` returns as a real column (the 20260501000002
  rationale — "title derived from notes" — is exactly the pattern being
  removed).
- `transactions.notes` is the **pure Note** (the remark, "buat meeting
  kantor") — no structural encoding, ever again.
- Item breakdowns live in `transaction_items` only. Reads join it
  (`select('*, transaction_items(...)')`); the Telegram saver starts writing
  it; a new RLS policy lets room members read items of room transactions.
- `parseBreakdown` survives strictly as a **legacy read fallback** for
  pre-pivot rows (and their `merchant — note` ancestors). No backfill;
  editing a legacy row re-saves it structured, migrating it naturally.
- `formatBreakdown` / the edge `notes_breakdown.ts` formatter are no longer
  written to storage anywhere.

## Consequences

- Frontend heuristics (loose number parsing, item-math inference over
  strings) stop being load-bearing for new rows.
- A user editing the notes field can no longer corrupt the breakdown — the
  two are different columns.
- Reads carry a join; the offline queue already replays items, so unsynced
  rows keep their breakdown.
- Legacy rows render through the fallback until touched; the fallback can
  only be deleted after a backfill (not planned).
