# Transaction detail is one room-aware screen with inline edit; the full edit form is gone

Personal and room transactions had **two** detail screens (`TransactionDetailScreen`
over typed `Txn` + offline queue; `RoomTransactionDetailScreen` over a raw `Map` with
**Payer** join), and editing meant pushing the full add-transaction form at
`/transactions/new`. We collapse both into **one room-aware detail screen** that
branches on `roomId`, and make that screen the **complete edit surface** via per-field
inline editors — removing the full-form edit route entirely.

**Decision.**

- **One screen, two read adapters.** The screen branches on `roomId`: room rows via
  `roomTransactionProvider`, personal via `transactionsProvider` / an offline `Txn`.
  `Txn` gains an optional **Payer** (name / email / avatar); `Txn.fromRow` parses the
  `users` join so a single type serves both contexts. The Payer row renders only in
  room context.
- **Inline, per-field, immediate.** `category`, `account`, `amount`, `date`, `notes`
  each edit in place and write immediately through `updateTransaction` (already
  room-safe — **Room-account movements never queue offline**), mirroring the existing
  `_AccountRow` invalidation pattern. No global edit mode.
  - Category / account use the existing pickers scoped to the room
    (`activeRoomId` / `roomId`); amount, date and notes use small sheets/pickers.
  - **Type is not inline-editable.** Transfers expose **amount only**; their From/To
    legs stay read-only.
  - **Any row carrying an item breakdown** (notes that `parseBreakdown` accepts —
    scanned, bot, or manually entered) gets the breakdown editor as the **single
    owner of amount** (its Total), so the standalone amount row and the separate
    date row are hidden for it. The gate is **breakdown presence, not origin**:
    `aiParsed` is provenance only and never gates editing. The editor self-gates its
    edit affordance on `canEdit`, so a non-Payer (or unsynced) viewer sees it
    read-only — one widget renders both states (the old read-only `_BreakdownView`
    is gone). A scanned row with *no* parseable items falls back to plain notes +
    standalone amount/date rows.
- **Edit rights.** One gate guards both inline edit and delete: the **Payer of a
  synced row** (`isPayer && !isUnsynced`). Rooms never queue offline, so the sync
  half is always satisfied there and the rule reduces to Payer-only; synced personal
  rows are always the user's own, so it reduces to synced-only. A null `me` (pre-auth)
  is not the Payer and is locked. Offline/unsynced personal rows stay read-only behind
  the existing warning banner.
- **No full edit form.** The AppBar "Edit → `/transactions/new`" route is removed. Any
  field once edited only through the form (type, transfer legs) is now either inline or
  fixed after creation.

## Alternatives considered

- **Keep two screens.** Rejected: duplicated layout/label/source logic already drifting
  between the two files; every future field touches both.
- **Keep the full form as an escape hatch.** Rejected: it reintroduces a second,
  divergent edit surface and a route that must stay room-aware; inline rows for date and
  notes close the only real gaps it covered.
- **Normalize both reads to `Map` / a separate view-model.** Rejected in favour of
  extending `Txn`, keeping the type safety the rest of the app relies on.

## Consequences

- `type` can no longer be changed post-create, and a non-transfer cannot be converted to
  a transfer (or vice-versa) after creation. Accepted — rare, and re-create covers it.
- `Txn` carries optional Payer fields that are null for personal rows; readers must treat
  them as room-only.
- Each inline save is its own write/invalidation; a multi-field correction is several
  round-trips rather than one transactional save. Accepted for the "quick" UX.
