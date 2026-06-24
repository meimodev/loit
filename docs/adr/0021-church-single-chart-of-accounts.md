# A Church room seeds one denomination-independent chart of accounts

LOIT's **Church room** (ADR-0019) seeded its `room_categories` from a
**denomination preset** — an app-side map where GMIM / GBI / Katolik each
carried a bespoke category list and every other denomination fell back to a
generic `Lainnya` preset. The denomination chosen in onboarding drove which
categories a new church ledger started with.

In practice the per-denomination divergence bought little: the lists differed
only in wording (Kolekte Minggu vs Persembahan Ibadah Raya), all mapped to the
same handful of accounting buckets, and maintaining four parallel lists meant
four places to fix every change. ADR-0019 had already deleted the
denomination → *report templates* map for the same reason; this finishes the
trend on categories.

**Decision.**

- **One universal chart of accounts seeds every Church room**, regardless of
  denomination — a fixed **5 Penerimaan** + **6 Pengeluaran** set
  (`church_presets.dart`). This **supersedes ADR-0019's denomination preset
  map**: GMIM / GBI / Katolik no longer carry distinct category lists.

  - Penerimaan: Persembahan & Persepuluhan · Usaha & Penggalangan Dana ·
    Sumbangan & Bantuan · Dana Pembangunan · **Dana Transit / Titipan** (a real
    clearing/liability bucket for funds held on behalf of others — not a
    catch-all).
  - Pengeluaran: Gaji & Tunjangan Pelayan · Program & Pelayanan · Operasional &
    Kantor · Pemeliharaan & Inventaris · Diakonia & Sosial · Pembangunan &
    Belanja Modal.

- **The expense "Lain-lain" line is omitted.** The seed's expense catch-all is
  the trigger-guaranteed `other` row ("Lainnya", ADR-0009) — the proposed
  "Tidak terduga / Lainnya" preset line is dropped to avoid a duplicate
  catch-all.

- **Denomination is demoted to metadata.** The onboarding picker stays, but its
  value now feeds only the report header and confirmation screen
  (`org_config.denomination`) — it no longer varies the seeded categories.
  `presetFor()` returns the same chart for every input.

- **`Penerimaan` is the canonical church income term** (not `Pemasukan`). The
  income catch-all (`income_other`, stored label "Pemasukan lain") is relabeled
  **"Penerimaan lain" locally in the church report** — the report owns its
  grouped Penerimaan / Pengeluaran view. The global `categoryLabelProvider` is
  **not** touched: it has no room `org_type` context, so threading church
  awareness through a shared, app-wide label path was rejected for one
  rarely-used fallback row.

- **Each category carries a curated `icon_name` + `tint`.** Now that the list is
  finite and fixed, the seed sets a deliberate icon and colour per row (valid
  `LoitCategories` icon names + `_kCategoryPalette` hex) instead of the null →
  default-grey style that was acceptable when categories were free denomination
  text. `seedChurchCategories` is extended to insert `icon_name` / `tint`.

## Alternatives considered

- **Keep per-denomination presets, make this the new generic fallback only.**
  Rejected — the universal list is a deliberate standard chart, not a
  denomination quirk; keeping four divergent lists has no payoff.

- **Relabel the income catch-all globally to "Penerimaan lain" for church
  rooms.** Requires `categoryLabelProvider` (a shared surface every transaction
  picker reads) to look up the owning room's `org_type`, which `UserCategory`
  does not carry. Rejected for one fallback row; the church report relabels
  locally instead.

- **Backfill existing church rooms with the new chart.** Rejected — existing
  ledgers may already have transactions filed under denomination categories;
  remapping would orphan real data. The change is the client-side seed only, so
  it applies to **new church rooms only**; no migration touches existing rows.

## Consequences

- `church_presets.dart` becomes a single `ChurchCategories` constant of
  `(name, icon, tint)` triples; `denominationPresets` / per-denomination lists
  are deleted. The denomination *picker* and `denominationOrder` remain.

- Creation path is unchanged in shape (ADR-0019): `createRoom(org_type='church')`
  then a best-effort batch `room_categories` insert, now carrying icon/tint. The
  trigger's catch-all rows (ADR-0009) are unchanged.

- Onboarding still lets the treasurer edit/uncheck/add categories before
  creation; they simply all start from the same chart.
