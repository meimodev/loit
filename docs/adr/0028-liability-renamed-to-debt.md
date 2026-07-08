# Account "liability" kind renamed to "debt" / "Hutang"

**Status:** accepted

The "Liability / Liabilitas / Kewajiban" wording confused everyday users, who
did not connect the accounting term to their credit cards and loans. We renamed
the account kind to **Debt** (English) / **Hutang** (Indonesian) across all
surfaces — personal accounts, dashboard net-worth strip, room accounts, and PDF
exports — replacing three prior labels ("Liabilities", "Liabilitas",
"Kewajiban") with one word.

## Decisions and rejected alternatives

- **Rooms relabel too, uniformly.** A room account's `debt` kind is derived from
  a negative balance, which CONTEXT defines as a shared debt — so "Hutang" is
  coherent there. Room "Kewajiban" is gone. (Dana Transit / Titipan is a
  *category*, not the account kind, and is untouched.)
- **Full DB migration, not a wire-string alias.** The stored value changed
  `kind='liability'` → `kind='debt'`: a `CHECK` constraint swap on the prod
  `accounts` table, the three `'liability'` literals in the derived-kind triggers
  (ADR-0008), and a data backfill. Rejected the cheaper option of renaming only
  the Dart enum while keeping `'liability'` on the wire — chosen for a clean
  single vocabulary end-to-end, accepting the one-time migration risk. Contrast
  with `scan`→"AI Credits" (ADR-0017), where the internal name was deliberately
  kept.
- **Colloquial "Hutang", not KBBI "Utang".** The common spelling most users type
  and recognize, over the formal-correct form.
- **"Asset / Aset" left unchanged** — never a source of confusion.

## Consequences

The `accounts.kind` CHECK constraint and the two derived-kind triggers must be
migrated together (drop old CHECK → backfill rows → replace trigger functions
with `'debt'` → add new CHECK) so future trigger writes satisfy the constraint.
Any external consumer reading `kind='liability'` breaks.
