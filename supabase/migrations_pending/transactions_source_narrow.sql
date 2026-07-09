-- ADR-0029, step 2 of 2. NOT A MIGRATION YET — DO NOT MOVE INTO migrations/
-- UNTIL THE PRECONDITION BELOW HOLDS.
--
-- This narrows `transactions.source` to the six canonical values, dropping the
-- legacy spellings the widen migration (20260709012651) still accepts.
--
-- PRECONDITION: no client in the wild writes 'scanned'. Builds at or before the
-- release that introduced the canonical spellings write 'scanned' from
-- scan_review_screen and from sync_service's offline-queue self-heal. Applying
-- this before those builds are gone makes their in-app image captures fail to
-- insert — including offline rows draining days later. That is lost user data,
-- not a display bug.
--
-- HOW TO SATISFY IT: ship the canonical-spelling client as a `-breaking` release
-- tag (ADR-0015). The tag cascades to the `min` gate, which locks out older
-- builds. Once the gate's `min` is at or above that version, no writer of the
-- old spellings can reach the database.
--
-- BEFORE APPLYING, verify both:
--   select source, count(*) from transactions group by source;
--     -- expect zero rows for scanned / bot_chat / bot_image / bot_voice
--   select min_version from app_release_gate;
--     -- expect >= the canonical-spelling client release
--
-- If any legacy rows remain, re-run the backfill from 20260709012651 first;
-- they can only come from a client that predates the gate.

alter table transactions
  drop constraint if exists transactions_source_check;

alter table transactions
  add constraint transactions_source_check
  check (source in (
    'manual', 'image', 'voice', 'telegram_text', 'telegram_image', 'telegram_voice'
  ));
