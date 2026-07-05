# 24. The Note rides the canonical notes text, not a new column

Date: 2026-07-05

## Status

Superseded by [0025](0025-structured-capture-storage.md) — the canonical
notes text is now a legacy read-only format; new rows store merchant, items,
and the Note in structured columns.

Builds on the canonical notes-breakdown encoding introduced for Telegram image
saves (`notes_breakdown.dart` / `notes_breakdown.ts`) and the capture pipeline
of [0016](0016-all-ai-through-openrouter.md) /
[0022](0022-in-app-voice-capture.md) /
[0023](0023-ai-room-captures-default-to-pool.md).

## Context

The text/voice parser already extracts both a free-text **Note** ("buat
meeting kantor") and an **Item breakdown** (`items[]`). But both compete for
the single `transactions.notes` column: `stampCanonicalNotes` in the Telegram
bot **overwrote** the AI's Note with the breakdown text whenever items
existed, and itemless captures merged the Note into a `merchant — note` string
the app cannot split back apart. A transaction could therefore show its Note
or its breakdown, never both, and no surface could render the Note as a
distinct element.

Two ways to hold both:

1. **Structured columns** — a `transactions.items` JSONB column, `notes`
   becomes the pure Note. Clean model, but touches a migration, the Drift
   offline schema + sync queue, every save path (manual form, scan review,
   in-app voice, three Telegram flows, `transaction_saver.ts`), and forces
   dual-read forever because old rows keep breakdown-in-notes.
2. **Extend the canonical notes text** — append a `Catatan:` line after
   `Total:`; `parseBreakdown` learns one line type. No migration, no offline
   changes, old rows and Telegram work instantly.

## Decision

Extend the canonical notes text (option 2).

- The stored shape becomes: merchant line, item bullet lines, `Total:` line,
  trailing `Catatan: <note>` line. Every segment optional except the first
  line.
- The shape is canonical **whenever a Note or items exist** — an itemless
  capture with a Note stores `merchant\nCatatan: …`, replacing the legacy
  `merchant — note` merge, so the Note is structurally recognizable on every
  AI capture. A lone `Catatan:` line counts as canonical for
  `looksLikeCanonicalBreakdown` / `parseBreakdown`.
- Writers emit the Indonesian `Catatan:` marker; parsers accept `Catatan:` /
  `Note:` / `Notes:` case-insensitively. (Precedent: the `Total:` marker is
  already a locale-independent stored literal.)
- `stampCanonicalNotes` appends the Note instead of dropping it. Parser
  prompts instruct the model that `notes` is the remark only — never a
  restatement of items, amounts, or merchant.
- Note sources per surface: AI extraction (text, voice), photo caption
  (Telegram image), and a new optional note field on the in-app scan review
  screen.
- Editing stays **text-first**: the form edits the canonical text in a plain
  notes field with a live re-parsed preview. No structured item editor.

## Consequences

- Both Note and Item breakdown survive every capture path and render
  distinctly (receipt-style card + note block in detail; merchant title +
  note subtitle on list rows).
- The `notes` column remains the single source — hand-editing can break the
  canonical shape, in which case rendering degrades to plain text (already
  true today for breakdowns; accepted).
- Old `merchant — note` rows stay as-is and render as plain text (no
  backfill).
- If a structured item editor or item-level analytics ever land, this
  string encoding becomes the bottleneck and option 1 (JSONB column) gets
  revisited; until then the encoding stays authoritative.
