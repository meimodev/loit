-- ADR-0029 (revised): rename the stored transaction-source vocabulary to match
-- the domain language in CONTEXT.md. Step 1 of 2.
--
-- The constraint is WIDENED to accept both the legacy and the new spellings,
-- not swapped. Shipped clients still write 'scanned' (scan_review_screen) and
-- drain offline queues writing 'scanned' (sync_service); rejecting it here
-- would fail their inserts and lose captures. The narrowing migration lives in
-- supabase/migrations_pending/ and may only be applied after a `-breaking`
-- release (ADR-0015) has locked out clients that write the old spellings.

alter table transactions
  drop constraint if exists transactions_source_check;

alter table transactions
  add constraint transactions_source_check
  check (source in (
    -- canonical
    'manual', 'image', 'voice', 'telegram_text', 'telegram_image', 'telegram_voice',
    -- legacy, accepted only during the client rollout window
    'scanned', 'bot_chat', 'bot_image', 'bot_voice'
  ));

-- A source rename is not a domain event. Suppress the row triggers for it:
-- `transactions_account_ownership` raises (auth.uid() is null in a migration),
-- `set_transactions_updated_at` would bump updated_at, `transactions_broadcast`
-- would fan realtime events to live clients, and `transactions_refresh_room_kind`
-- would recompute balances that did not move. Transactional — a failure below
-- restores every trigger.
alter table transactions disable trigger user;

update transactions set source = 'image'          where source = 'scanned';
update transactions set source = 'telegram_text'  where source = 'bot_chat';
update transactions set source = 'telegram_image' where source = 'bot_image';
update transactions set source = 'telegram_voice' where source = 'bot_voice';

alter table transactions enable trigger user;

alter table transactions alter column source set default 'manual';
