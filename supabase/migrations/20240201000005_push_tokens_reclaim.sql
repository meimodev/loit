-- Allow a signed-in user to take over an existing push_tokens row keyed by
-- the device's FCM token. Without this, a device that previously signed in
-- as user A cannot register the same FCM token under user B because the
-- UPDATE policy's USING clause still resolves against user A's row.
DROP POLICY IF EXISTS "push_tokens_update_own" ON public.push_tokens;
CREATE POLICY "push_tokens_update_own" ON public.push_tokens
  FOR UPDATE
  USING (true)
  WITH CHECK (user_id = auth.uid());
