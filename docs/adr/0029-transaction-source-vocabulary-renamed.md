# Transaction source vocabulary renamed to match the domain

**Status:** accepted (supersedes this ADR's own first draft, which froze the
stored spellings — see *Rejected alternatives*)

In-app voice captures were displayed as "Scanned". ADR-0022 added
`transactions.source = 'voice'` and a migration to permit it, but
`_txnSourceFromString` switches over a `String?` — which Dart cannot check for
exhaustiveness — so the new value fell through to a fallback
(`aiParsed ? scanned : manual`) and was confidently relabelled. The bug was
invisible: no crash, no null, a plausible wrong answer.

Fixing the label surfaced the larger question. **Transaction source**
(see CONTEXT.md) is a (Capture channel, Capture kind) pair, or Manual — six
values. Four of the six stored spellings predated that vocabulary, and Telegram
voice had no value at all: `telegram-bot/index.ts` knew the `sourceType` was
`"voice"` and discarded it into `bot_chat`.

The stored vocabulary is now the domain vocabulary:

| was | is |
|---|---|
| `scanned` | `image` |
| `bot_chat` | `telegram_text` |
| `bot_image` | `telegram_image` |
| *(absent)* | `telegram_voice` |

`manual` and `voice` were already right.

## Decisions and rejected alternatives

- **Rename in Postgres, not only in the client.** `source` is read by no
  migration, view, RPC, or Edge Function — only written. Nothing branches on it
  server-side, so a rename cannot break server logic, and the client's single
  parse point absorbs the transition. Contrast ADR-0028 (`accounts.kind`), where
  the stored value *is* server logic: two derived-kind triggers (ADR-0008) branch
  on `'liability'`. There the migration was obligatory and risky; here it is
  optional and cheap.

- **Rejected: freeze the stored spellings, rename only the Dart enum.** This
  ADR originally chose that, justified partly on `transactions` being the largest
  table. That was asserted, not measured. It holds 143 rows; the backfill touched
  42. A cost that does not exist cannot outweigh anything. The lesson is the
  decision-record one: *check the number before you cite it.* The remaining
  argument — that only raw-SQL readers benefit — is true and is why this was a
  close call rather than an obvious one.

- **Widen, then narrow — never swap.** Shipped clients write `'scanned'`
  (`scan_review_screen`, and `sync_service` when self-healing offline rows).
  Narrowing the CHECK constraint in one step would reject their inserts, losing
  captures — including offline rows draining days after the release. So the
  applied migration accepts *both* vocabularies, and the narrowing migration sits
  unapplied in `supabase/migrations_pending/`, gated on a `-breaking` release
  (ADR-0015) locking out clients that write the old spellings. Deliberately not
  in `migrations/`, where `db push` would fire it early.

  This is the "two spellings, one concept" state that an earlier draft of this
  ADR called strictly worse than either alternative. It is — *as a resting
  place*. As a bounded window with a forcing function at the end, it is the only
  safe path. The distinction is whether someone owns closing it.

- **The backfill suppresses row triggers.** `transactions` carries four: an
  ownership check that raises when `auth.uid()` is null (i.e. in any migration),
  `moddatetime` on `updated_at`, a realtime broadcast (ADR-0018), and a room-kind
  refresh. A vocabulary rename is not a domain event and must fire none of them.
  `disable trigger user` inside the migration's transaction; a failure restores
  them.

- **`sync_service` rewrites legacy spellings as it drains.** A row queued by a
  pre-rename build carries `'scanned'` and drains through a post-rename build
  after the user updates. Normalising at drain means the update gate alone is
  sufficient to guarantee no client can write a legacy spelling — without it, the
  narrowing migration would race against every stale offline queue.

- **`sourceRaw` carried alongside the enum.** `Txn` stores the verbatim string;
  serialisation writes `sourceRaw`, not the enum. Edge Functions deploy
  independently of Play Store rollout, so there is always a window where the
  server writes values the client has never heard of. Without this, undo-delete
  (the only path that writes a whole transaction back) would restore an
  unrecognised source as `manual` — trading a display bug for silent data loss.
  Rejected a bare `TxnSource.unknown` for exactly that reason: it has no honest
  serialisation.

- **`null` and unknown are different, and must stay different.** `null` means a
  row queued locally before the column existed; the `ai_parsed` guess is correct
  there, and matches the original backfill rule. A non-null string this build
  does not recognise means *the server answered and we cannot read it* — guessing
  overwrites a known-good fact with a plausible fiction. Collapsing these two
  into one fallback branch is the original defect.

- **CSV export gets canonical English labels**, not stored tokens and not
  localised copy. The export is pivoted, filtered, and shared: it wants one
  stable spelling. `ai_parsed` already occupies its own column, so `source` is
  free to be prose.

## Consequences

Three representations, three jobs, none overloaded: `sourceRaw` (wire),
`TxnSource` (logic), `_sourceLabel` (localised copy) plus a canonical English
label for export. The enum is exhaustive, so the next member added makes the
label switch a compile error — the safety net absent when `voice` shipped.

Adding a seventh source server-side never again requires a client release to
stay *correct*; only to label it. Old clients render it neutrally and round-trip
it intact.

**Open until closed:** `supabase/migrations_pending/transactions_source_narrow.sql`
must be applied once a `-breaking` release has rolled out. Until then the
constraint accepts four dead spellings and cannot catch a bug that writes one.
The client's legacy read-map and `sync_service`'s drain rewrite are removable at
the same time.

Historical Telegram voice captures are unrecoverable: they were stored as
`bot_chat` alongside genuine text captures, `ai_parsed` is true for both, and
nothing else distinguishes them. They now read as `telegram_text` — wrong, and
permanently so. Only captures after the v36 bot deploy are correct.
