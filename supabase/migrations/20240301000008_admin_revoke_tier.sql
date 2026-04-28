-- Admin-only RPC for manual tier revocation. Used while RevenueCat runs in
-- "limited mode" (no Play Developer API service account on RC's side):
-- when a user refunds via Play Console, we can't auto-detect it, so an
-- operator runs this RPC to flip the user back to free.
--
-- Usage from Supabase SQL editor (must be authenticated as admin):
--   SELECT public.admin_revoke_tier('<user-uuid>'::uuid, 'refund via Play Console');
--
-- Audit trail goes to `admin_actions`. Once Path A (service account)
-- is in place, this becomes purely break-glass.

-- Add is_admin flag if missing. Default false. Flip manually for ops accounts.
ALTER TABLE public.users
  ADD COLUMN IF NOT EXISTS is_admin boolean NOT NULL DEFAULT false;

CREATE TABLE IF NOT EXISTS public.admin_actions (
  id          bigserial PRIMARY KEY,
  acted_by    uuid NOT NULL,
  target_user uuid NOT NULL,
  action      text NOT NULL,
  reason      text,
  created_at  timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.admin_actions ENABLE ROW LEVEL SECURITY;
CREATE POLICY admin_actions_service_only
  ON public.admin_actions FOR ALL USING (false) WITH CHECK (false);

CREATE OR REPLACE FUNCTION public.admin_revoke_tier(
  p_target_user uuid,
  p_reason      text DEFAULT NULL
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  caller uuid := auth.uid();
BEGIN
  -- Caller must be flagged as admin in `users.is_admin`. Adjust the
  -- column name if your schema uses a separate admins table.
  IF NOT EXISTS (
    SELECT 1 FROM public.users WHERE id = caller AND is_admin = true
  ) THEN
    RAISE EXCEPTION 'Not authorized: caller % is not an admin', caller;
  END IF;

  UPDATE public.users
  SET tier = 'free', tier_expires_at = NULL
  WHERE id = p_target_user;

  INSERT INTO public.admin_actions(acted_by, target_user, action, reason)
  VALUES (caller, p_target_user, 'revoke_tier', p_reason);
END;
$$;

REVOKE ALL ON FUNCTION public.admin_revoke_tier(uuid, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.admin_revoke_tier(uuid, text) TO authenticated;
