# The GMIM Mata Anggaran report is a stateless, AI-classified projection — not a second chart of accounts

A **Church room** needs a report in GMIM's official **Mata Anggaran** format —
a fixed, denomination-specific chart of ~300 income + expense budget-line codes
(`gmim_mata_anggaran.md`). This looks like it contradicts ADR-0021, which
deliberately made a church room's categories a *single denomination-independent*
chart of 5 Penerimaan + 6 Pengeluaran. It does not: those 5+6 stay the room's
**working categories** for entry; the Mata Anggaran chart is a **report-time
projection target** that AI maps transactions onto at generation time. The room
model is untouched — no new seed, no migration, no per-denomination categories
resurrected (ADR-0019/0021 stand).

## Decision

- **Projection, not categories.** The universal working chart (ADR-0021) is what
  treasurers file transactions under. **Laporan Realisasi Mata Anggaran** is a
  third **Export type** that re-maps a period's transactions onto GMIM's
  ~300-code chart. Because one working category (e.g. "Persembahan &
  Persepuluhan") fans out to many Mata Anggaran lines (Subuh / Pagi / Malam /
  Persepuluhan / …), the mapping needs each transaction's text — a lookup can't
  do it, so it is AI-classified.

- **Per-transaction classification, most-specific-code-you're-sure-of.** AI
  receives the full transaction payload (Note, merchant, item breakdown,
  category, amount, type, date — ADR-0025 columns) and returns one code per
  transaction. Group nodes (`1.3.50.00`) are themselves valid targets, so "leaf
  when sure, else parent" needs no confidence float: the model returns the
  deepest code the text justifies, and an explicit `UNCLASSIFIED` when nothing
  fits. Unclassified rows are listed in a **Belum Terklasifikasi** section of the
  PDF so the treasurer can see exactly what to fix. Income and expense codes are
  separate trees; a row maps only within its own `kind`.

- **Stateless — recompute every generation.** No classification is persisted; no
  side table, no RLS, no offline plumbing. A wrong code is corrected by improving
  the *source transaction's Note* and regenerating, so corrections live on
  canonical data. The trade-off (every regenerate re-charges credits; codes may
  shift between runs) is accepted; a "regenerate this period? (~N credits)"
  confirm guards against accidental double-charge.

- **Token-metered credits, charged to the generating treasurer.** The
  classification is one server call (ADR-0016: all AI through OpenRouter; credit
  metering is server-authoritative). It reuses ADR-0017 verbatim —
  `credits = max(1, ceil(completion_tokens / 1024))`, soft-cap gate,
  reserve-before / charge-after / refund-on-fail, via `_shared/quota.ts` against
  the authenticated caller (`increment_scan_quota(p_user_id)`). Whoever taps
  generate pays from their own AI Credits; no owner-resolution is built. Cost
  scales with transaction count, so it "depends on the report" as intended.

- **Taxonomy is a client Dart constant sent to a generic edge function.** The
  ~300 codes live in one Dart constant (single source of truth; renders the tree
  and labels client-side). The client sends the flattened code list with the
  transactions; the edge function only prompts "classify into this provided
  taxonomy" and returns a code per row. Input tokens are unmetered (ADR-0017), so
  shipping the full list each call is free. The function is denomination-agnostic
  — a GBI/Katolik chart slots in later with no redeploy.

- **PDF straight to share; actuals only.** Generate runs AI, then the client
  builds the PDF exactly as `ChurchReportService` does today (client-side pdf/
  printing), grouped as the Mata Anggaran tree with amounts rolled up per node,
  grand totals, saldo, and the Belum Terklasifikasi section. No budget column
  (rooms hold no per-line anggaran) and no on-screen review step.

## Alternatives considered

- **Seed the 300-code chart as `room_categories`.** Makes the report a trivial
  group-by, but reintroduces the per-denomination chart ADR-0021 killed, bloats
  the add-transaction picker to 300 lines, and forces a migration. Rejected.

- **Persist AI classifications (incremental + correctable side table).**
  Cheaper re-runs, deterministic output, manual overrides. Rejected for v1 in
  favour of the zero-schema stateless path; corrections via editing the source
  Note cover the workflow without a table. Revisit if re-charge cost becomes a
  support burden.

- **Taxonomy owned by the edge function (TS constant).** Hardwires the function
  to GMIM and duplicates a Dart copy for rendering (drift). Rejected.

- **Budget-vs-actual (full Realisasi Anggaran).** The complete official format,
  but requires a whole per-line annual-budget entry feature first. Out of scope;
  this report is actuals-only.

## Consequences

- New edge function (generic classifier) + new Dart taxonomy constant + a third
  church **Export type**. `ChurchReportService`'s PDF-build pattern is reused; the
  only new runtime piece is the mid-flow AI call.

- The report is **non-deterministic and re-charges on every run** — surfaced to
  the user via the pre-generation credit-cost confirm and the visible Belum
  Terklasifikasi section, the same "make the cost legible" mitigation ADR-0017
  relies on.

- Church rooms are already Pro-gated (ADR-0019); generation additionally blocks
  at zero AI Credits under the ADR-0017 soft cap. A denomination other than GMIM
  can reuse the entire pipeline by supplying a different taxonomy constant.
