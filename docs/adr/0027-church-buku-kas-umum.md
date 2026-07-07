# Buku Kas Umum is a per-account carry-forward cash book — it keeps transfers and reads pre-range rows

A **Church room** treasurer needs the classic **Buku Kas Umum** (BKU) — the
general cash book: every cash movement in date order, per account, with a
**running saldo**. LOIT already has two mechanical church reports
(**Laporan Keuangan**, ADR-0019; **Laporan Realisasi Mata Anggaran**, ADR-0026)
and a flat **Daftar Transaksi**. BKU is a fourth **Export type**. It looks like
it could reuse Laporan Keuangan's transaction scoping, but it cannot: a cash
book has two hard requirements the statement deliberately drops.

## Decision

- **Fourth Export type, per-account sections.** `_ExportType.cashJournal`,
  user-facing **Buku Kas Umum** (English internal gloss: *General Cash
  Journal*). The PDF/CSV renders **one section per Room account**, each opening
  with **Saldo Awal**, listing that account's movements chronologically with a
  running **Saldo** column, and closing with **Saldo Akhir**. A room-wide
  summary card row totals across accounts.

- **Keeps transfers, as two legs.** Laporan Keuangan `continue`s past
  `isTransfer`; BKU must not. A room-account transfer is a real Pengeluaran on
  the source account and a real Penerimaan on the destination — drop it and both
  accounts' running saldo desync from reality. The single `type='transfer'` row
  (`account_id` = source, `to_account_id` = dest) is rendered as **two legs**:
  an outgoing row under the source ("Transfer ke <dest>") and an incoming row
  under the dest ("Transfer dari <source>"). They move saldo within their
  sections and net to zero room-wide.

- **True carry-forward opening saldo.** A running saldo is meaningless without a
  starting number. **Saldo Awal** = the account's `initial_balance` (a fixed,
  non-dated seed column) **plus** the sum of all its movements dated **before**
  the range. **Saldo Akhir** then equals the account's real balance at
  range-end. This forces BKU to read **pre-range** rows — unlike every other
  church report, which is handed a set already filtered to `[start, end]`.

- **Room-account rows only; out-of-pocket excluded.** The per-leg movement rule
  (mirrors `roomAccountBalancesProvider` / the `room_account_balance` SQL
  function) only matches rows whose `account_id` or `to_account_id` is a Room
  account, so an **Out-of-pocket room expense** (personal-funded) never appears —
  it moved no room cash. Consistent with the Out-of-pocket invariant (ADR-0013).

- **Mechanical, no AI Credits.** Pure sum + running total, like Laporan Keuangan
  and Daftar. Only Laporan Realisasi Mata Anggaran (ADR-0026) meters credits.
  No pre-generation confirm; instant generate.

- **Zero backend.** `roomTransactionsProvider` already holds the room's full,
  date-unfiltered txn set in memory, and `roomAccountsProvider` already includes
  archived accounts with `initial_balance`. A new client-only
  `ChurchCashJournalService` splits the txn set on `createdAt` (before-range →
  opening, in-range → rows) per account and mirrors the canonical balance CASE.
  No RPC, no migration, no edge function.

- **Section-emission rule.** A section appears iff the account has in-range
  movement, a nonzero opening, or a nonzero closing. Archived accounts are
  included (BKU is history, and their cash is real); never-funded seeded
  accounts (zero movement, zero saldo) are omitted as noise.

- **CSV carries journal rows, not summary rows.** Laporan Keuangan / Realisasi
  CSV carry grouped subtotals; BKU is a *listing* report, so its CSV carries the
  actual journal rows under an `Akun` grouping column with Saldo Awal / Saldo
  Akhir marker rows — raw integer rupiah, Indonesian headers, jemaat + period
  metadata block, same conventions as the other church CSVs.

## Alternatives considered

- **Reuse Laporan Keuangan scoping (`statementScopedTxns`).** Would drop
  transfers and see only the period window — producing per-account saldi that
  neither balance nor match the account's real balance. Rejected: it defeats the
  entire purpose of a cash book.

- **One combined cash book (single saldo across all accounts).** Simpler, but a
  running saldo mixing Tunai + two bank accounts matches no real ledger and makes
  transfers nonsensical (both legs in one stream, netting to noise). Rejected in
  favour of per-account sections — how a treasurer actually keeps the book.

- **Start every range from zero saldo.** No pre-range read needed, but Saldo
  Akhir would be wrong for any range that isn't since-inception. Rejected — a
  cash book whose closing figure doesn't match the account is useless.

- **A DB aggregate / RPC for opening balances.** Unnecessary: the full room txn
  set is already client-side and church rooms are low-volume, so the pre-range
  split is a cheap in-memory pass. Rejected as premature backend work.

## Consequences

- A new client-only service + a fourth church Export type + one l10n label. No
  schema, no edge function, no credit plumbing.

- BKU is the **only** church report that keeps transfers and reads pre-range
  rows. A future reader touching the export scoping must not "unify" it with
  Laporan Keuangan's period-filtered, transfer-dropping path — the divergence is
  intentional and load-bearing (this ADR).

- Correctness hinges on the running-saldo pass staying in lockstep with the
  canonical balance rule (`roomAccountBalancesProvider` / `room_account_balance`).
  If that rule changes (e.g. a new movement type), BKU must change with it.
