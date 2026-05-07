-- ================================================================
-- Storage RLS: allow room members to SELECT receipts attached to a
-- transaction whose room they belong to. Owner policy
-- (`receipts_select_own`) remains; this is additive.
--
-- Path convention: `{user_id}/{transaction_id}.jpg`. Matching on
-- both segments (user_id == folder, txn_id == filename without .jpg)
-- prevents fishing across rooms.
-- ================================================================

DROP POLICY IF EXISTS "receipts_select_room_member" ON storage.objects;

CREATE POLICY "receipts_select_room_member" ON storage.objects
  FOR SELECT
  USING (
    bucket_id = 'receipts'
    AND EXISTS (
      SELECT 1 FROM public.transactions t
      WHERE t.user_id::text = split_part(name, '/', 1)
        AND t.id::text = regexp_replace(split_part(name, '/', 2), '\.jpg$', '')
        AND t.room_id IS NOT NULL
        AND public.is_room_member(t.room_id)
    )
  );
