# A Church room is an additive Org type; its categories are `room_categories` rows, not `org_config`

LOIT adds a **Church room** — a **Room** for church-treasury bookkeeping, gated
to **Pro**, created through a denomination-aware onboarding flow. The original
handoff plan modelled it as a largely self-contained feature: a new
`rooms.org_config` JSONB column would hold both the church profile *and* the
room's categories (`org_config.kategori.penerimaan` / `.pengeluaran`), with
transaction entry reading categories "from `org_config.kategori` when present."

That contradicts how a Room's categories already work. Categories are ordinary
`room_categories` rows (`20260507000000_room_categories.sql`), seeded at creation
by `seed_room_categories_from_creator()`, keyed `room:<room_id>:<slug>`, with a
`kind` of `income` | `expense`. Every consumer — the add-transaction picker
(`userCategoriesProvider`), labels (`categoryLabelProvider`), room budgets,
reports, and the messaging bot — reads those rows **by id**. Nothing reads
`org_config`. ADR-0009 already rejected the symmetric idea (synthesising room
categories outside the table) for exactly this reason: a category with no stable
row id can't be stored on a transaction, and every reader would have to replicate
the inject logic.

**Decision.**

- **`org_type` is an additive flavour, not a fork.** `rooms.org_type`
  (`general` default | `church`; `family` / `community` reserved, unused)
  selects an onboarding flow and a denomination-aware report. It does **not**
  branch the room model: accounts, budgets, transactions, balance, and the
  catch-all categories behave identically across org types. A Church room uses
  regular **Room accounts** for its balance — no church-specific account
  machinery.

- **Church categories are `room_categories` rows.** The **Denomination preset**
  (an app-side Dart constant) only **seeds** them: at end of onboarding the
  client `createRoom`s with `org_type='church'`, then **batch-inserts** the
  user-finalised penerimaan rows (`kind='income'`) and pengeluaran rows
  (`kind='expense'`). Thereafter the rows are authoritative and freely editable,
  like any room's categories.

- **`org_config` is church *profile* only** — `denomination`, `jemaat_name`,
  `kota_kabupaten`, `phone_number`. It feeds category seeding, the report
  header, and the confirmation screen. It never stores categories.
  `phone_number` is the required room owner's contact (Kontak Pemilik Room),
  displayed metadata only — no conflict-resolution logic.
  (Earlier drafts collected `wilayah` / `pendeta` / `bendahara`; `wilayah` was
  renamed to the required `kota_kabupaten`, `pendeta` / `bendahara` dropped.)

- **The seed trigger is gated on `org_type`.** `seed_room_categories_from_creator()`
  copies the creator's *personal* categories only `IF NEW.org_type <> 'church'`
  — otherwise a treasurer's "Dining" / "Transport" would pollute a church ledger.
  The two catch-all rows (`other` / `income_other`, ADR-0009) are still seeded for
  every org type, so a Church room always has a fallback bucket; preset
  "Lain-lain" lines are dropped in favour of them.

## Alternatives considered

- **Categories in `org_config.kategori` JSONB (the handoff plan).** Self-contained
  and matches the doc, but rebuilds ADR-0009's rejected pattern: transaction rows
  can't reference a JSONB entry by a stable id, and the picker / budgets / reports
  / bot would each need a JSONB read path. Rejected.

- **A church-specific category table.** A parallel store keyed to church rooms.
  Rejected as redundant — `room_categories` already carries `kind` and per-room
  scoping; the only thing church needs is a different *seed*, not a different
  table.

- **Server-side denomination → preset endpoint.** Rejected: presets are static
  content with no per-user variance; an app-side constant keeps creation offline-
  tolerant and removes a maintenance endpoint.

## Consequences

- Transaction entry, budgets, reports, and the bot need **zero** church-specific
  changes — a Church room's categories are ordinary rows they already handle.

- Creation is non-atomic: `createRoom` then a batch category insert. A lost
  category insert leaves a Church room with only the catch-all (still functional,
  per ADR-0009); the treasurer can add categories via the normal editor. No
  rollback / RPC — consistent with the `createRoom` non-idempotency already
  accepted in ADR-0014.

- The Pro gate is **client-side only**, matching existing room-limit gating. A
  user could insert `org_type='church'` directly via the API; the payoff is
  cosmetic (category presets + a report layout, no revenue-bearing data), so
  server enforcement is deliberately skipped.

- The denomination report variation is **one statement layout + a period
  selector** (category-grouped Penerimaan / Pengeluaran totals, no Saldo
  Awal/Akhir reconstruction). The handoff plan's six templates and the
  `denomination → templates` map are not built; the visible denomination list is
  GMIM / GBI / Katolik / Gereja Baptis / GKI / GPdI / GPIB / HKBP / Lainnya.
  Only GMIM / GBI / Katolik carry dedicated category presets; every other entry
  (and free-text under "Lainnya") falls back to the generic `Lainnya` preset.
