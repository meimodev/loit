-- ============================================================
-- Live user-row feed via Broadcast-from-database (ADR-0018)
-- ============================================================
-- The app listened for server-side tier/credit mutations (RevenueCat
-- webhook grant/revoke, downgrade cron, admin) via Postgres Changes on
-- public.users — same fragile per-row-RLS path that silently dropped
-- transaction events. Migrate it to the same Broadcast mechanism: a DB
-- trigger broadcasts a {op, id} signal to the owner's private topic
-- `user:<id>`; the app, joined to its own topic, invalidates the user
-- profile on receipt. Mirrors 20260621000000_transactions_broadcast_feed.
-- ============================================================

BEGIN;

-- ---------------------------------------------------------------
-- 1. Trigger function: signal the owner on any change to their row.
--    Fires on UPDATE only (the app's sole interest — tier/credit flips);
--    INSERT is signup, DELETE is account teardown, neither needs a live
--    profile refresh. SECURITY DEFINER so it can write realtime.messages.
-- ---------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.broadcast_user_change()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  PERFORM realtime.send(
    jsonb_build_object('op', 'update', 'id', NEW.id),  -- payload
    'profile',                                         -- event
    'user:' || NEW.id::text,                           -- topic
    true                                               -- private
  );
  RETURN NEW;
END;
$$;

-- ---------------------------------------------------------------
-- 2. Trigger: after any update to a user row.
-- ---------------------------------------------------------------
DROP TRIGGER IF EXISTS users_broadcast ON public.users;
CREATE TRIGGER users_broadcast
  AFTER UPDATE ON public.users
  FOR EACH ROW EXECUTE FUNCTION public.broadcast_user_change();

-- ---------------------------------------------------------------
-- 3. Private-channel join authorization for the user's own topic.
--    Additive to the tx-feed policy already on realtime.messages.
-- ---------------------------------------------------------------
DROP POLICY IF EXISTS "user feed: receive own broadcasts" ON realtime.messages;
CREATE POLICY "user feed: receive own broadcasts"
  ON realtime.messages
  FOR SELECT
  TO authenticated
  USING (
    realtime.messages.extension = 'broadcast'
    AND realtime.topic() = 'user:' || auth.uid()::text
  );

COMMIT;
