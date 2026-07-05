-- ADR-0025: AI capture output lands structured. Merchant returns as a real
-- column (reverses 20260501000002, where the tx-card title was derived from
-- notes); item breakdowns are read from transaction_items (written since
-- Phase 1, never read until now); notes carries only the user's remark
-- (Catatan). The canonical notes-text encoding (ADR-0024) is legacy-read-only.

alter table public.transactions add column if not exists merchant text;

-- Room members must see the items of room transactions, mirroring
-- transactions_select_own_or_room — items were owner-only since Phase 1.
drop policy if exists "items_select_room" on transaction_items;
create policy "items_select_room" on transaction_items
  for select using (
    exists (
      select 1 from transactions t
      where t.id = transaction_id
        and t.room_id is not null
        and is_room_member(t.room_id)
    )
  );
