-- ================================================================
-- Limited shared-room profile access + room_budgets delete RLS
--
-- Shared-room members must see each other's display profile
-- (id, name, email, avatar_url) so the room feed and member list
-- can render names and avatars. We expose this through a narrowed
-- view rather than a broad RLS policy on `users` so subscription
-- tier, scan quotas, and other private columns stay restricted to
-- `users_select_own`.
-- ================================================================

CREATE OR REPLACE VIEW public.room_member_profiles
WITH (security_barrier = true)
AS
  SELECT u.id, u.name, u.email, u.avatar_url
  FROM users u
  WHERE u.id = auth.uid()
     OR EXISTS (
       SELECT 1
       FROM room_members rm_self
       JOIN room_members rm_other
         ON rm_other.room_id = rm_self.room_id
       WHERE rm_self.user_id = auth.uid()
         AND rm_other.user_id = u.id
     );

REVOKE ALL ON public.room_member_profiles FROM public;
GRANT SELECT ON public.room_member_profiles TO authenticated;

-- room_budgets: members can delete budgets in their rooms.
CREATE POLICY "room_budgets_delete" ON room_budgets
  FOR DELETE USING (is_room_member(room_id));
