-- ================================================================
-- Allow the room creator to delete any transaction inside their
-- room. Existing personal `transactions_delete_own` policy stays —
-- this is an additive policy.
-- ================================================================

DROP POLICY IF EXISTS "transactions_delete_room_creator" ON transactions;

CREATE POLICY "transactions_delete_room_creator" ON transactions
  FOR DELETE USING (
    room_id IS NOT NULL
    AND EXISTS (
      SELECT 1 FROM rooms r
      WHERE r.id = room_id
        AND r.created_by = auth.uid()
    )
  );
