-- ================================================================
-- Restrict room transaction deletion to the transaction owner.
-- Drops the room-creator delete policy added in
-- 20260507000002_room_creator_delete_transactions.sql. The original
-- `transactions_delete_own` policy (auth.uid() = user_id) remains
-- the sole DELETE path, applying to both personal and room rows.
-- ================================================================

DROP POLICY IF EXISTS "transactions_delete_room_creator" ON transactions;
