# 23. AI room captures default to the Room pool, and High-trust commits use current time

Date: 2026-06-28

## Status

Accepted

Reverses the "routed room = Out-of-pocket" slice of
[0022](0022-in-app-voice-capture.md) and the bot's no-pool-path assumption it
relied on. Builds on [0011](0011-out-of-pocket-room-expense.md) /
[0013](0013-funding-decides-ownership.md) (funding decides ownership),
[0008](0008-room-account-derived-kind.md) (Room accounts), and
[0016](0016-all-ai-through-openrouter.md) (server-side parse pipeline).

## Context

Three surfaces turn an AI parse into a room **Transaction**: in-app **scan**,
in-app **voice**, and the **Telegram bot**. They disagreed on two things.

**Funding.** Scan already defaulted a room capture to the **Room pool** — it
resolves the parsed account against the room's **Room accounts** first and only
falls back to a personal account (an **Out-of-pocket room expense** /
Personal-money) when the room has none (`scan_review_screen.dart`). Voice and the
bot did **not**: ADR-0022 deliberately committed routed voice as Out-of-pocket
because the server parser's `loadUserContext` loads only **personal** accounts,
and the bot shares that saver (`transaction_saver.ts`). So the same spoken/typed
"belanja 50rb untuk Dapur Bersama" became a pool movement by photo but a
personal out-of-pocket debt by voice or chat — an inconsistency the user hit in
practice.

**Date.** A High-trust auto-commit must not inherit a receipt's printed date.
Both auto-commit paths already hardcode `now()`; the **review form** still
prefilled the AI's parsed `date`/`time`.

**Naming.** The personal-funding option read "My money" / "Uang saya"; the owner
wants "Personal money" / "Uang pribadi".

## Decision

**Room intent already exists** — the parser emits `destination_room` /
`destination_room_id` from the transcript (ADR-0022). No new keyword detection is
added. The change is what funding that detected room defaults to.

1. **All AI room captures default to the Room pool.** When a capture resolves to
   a room and that room has at least one active **Room account**, it commits as a
   **Room-account movement** funded by the **first active Room account**. Only
   when the room has **no** Room account does it fall back to a Personal-money
   **Out-of-pocket room expense**. This makes voice and the bot match scan.
   - **In-app voice** (`voice_capture_screen._commit`): for a room destination,
     resolve against `roomAccountsProvider(roomId)` first (mirroring
     `scan_review_screen`), personal accounts only as fallback.
   - **Telegram bot** (`saveTransaction` + `loadUserContext`): `loadUserContext`
     also loads active Room accounts for the member's rooms; `saveTransaction`,
     when `roomId` is set, picks the room's pool account over the parsed personal
     account, falling back to personal (Out-of-pocket) when the room has none.

2. **High-trust commits, and the review form, default the timestamp to the
   current time.** The auto-commit paths already used `now()`; the review form
   stops prefilling the AI's parsed `date`/`time` and defaults `_date` to `now()`.
   Edit-mode `created_at` is unchanged (editing a real row must keep its real
   timestamp). Net: the AI's parsed date is no longer used to set a transaction's
   time on any capture path; the user backdates manually if needed.

3. **"My money" → "Personal money" / "Uang pribadi".** User-facing copy only
   (`txFormPaidFromMyMoney` in both locales) plus the CONTEXT.md glossary term.
   Code identifiers (`PaidFrom.myMoney`, `FundingSpecies.myMoney`) keep their
   names — internal, no user benefit to churning them.

## Consequences

- **One funding rule across scan, voice, and bot.** A room-addressed capture is
  the room's spend (pool) whenever the room can pay, regardless of surface.
- **Funding ownership flips for voice/bot room captures.** Per the
  **Out-of-pocket invariant**, these rupiah now count toward **room** totals
  (room budget, room balance) instead of the payer's personal spend. Existing
  rows already committed as Out-of-pocket are **not** migrated — only new
  captures follow the new default.
- **The "payer fronted cash" case loses its fast path.** A member who genuinely
  paid a shared bill from their own pocket by voice/bot now defaults to pool;
  correcting it means editing the row (or using the in-app form's **Paid from**
  toggle). Accepted: pool is the common case, and the room has a Room account
  precisely to be the default payer.
- **"First active Room account" is an unguided pick.** A room with multiple pools
  gets the first active one with no chooser on voice/bot. Same heuristic scan
  already uses; a per-room default-pool setting is the upgrade path if it bites.
- **The bot reply does not yet distinguish pool vs personal funding** in its
  confirmation text — a cosmetic follow-up, not a correctness issue.
- One extra room-accounts read per bot capture (`loadUserContext`).
