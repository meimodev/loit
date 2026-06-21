-- ============================================================
-- Live transaction feed via Broadcast-from-database (ADR-0018)
-- ============================================================
-- Postgres Changes never delivered bot-originated INSERTs to the app
-- socket (silent per-row RLS / token fragility). Replace it with a DB
-- trigger that broadcasts a lightweight {op, id} signal to the owner's
-- private topic `txns:user:<user_id>`. The app, joined to its own topic,
-- refetches over REST on receipt. Authorization is a single RLS check on
-- realtime.messages at JOIN time, not per event.
-- ============================================================

BEGIN;

-- ---------------------------------------------------------------
-- 1. Trigger function: signal the owner's topic on any row change.
--    SECURITY DEFINER so it can write to realtime.messages regardless
--    of the writer's role (service-role bot inserts + authenticated
--    user inserts alike). Empty search_path; everything schema-qualified.
-- ---------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.broadcast_transaction_change()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_user_id uuid;
  v_id      uuid;
BEGIN
  IF (TG_OP = 'DELETE') THEN
    v_user_id := OLD.user_id;
    v_id      := OLD.id;
  ELSE
    v_user_id := NEW.user_id;
    v_id      := NEW.id;
  END IF;

  -- user_id is nullable in principle on some legacy rows; skip if absent.
  IF v_user_id IS NOT NULL THEN
    PERFORM realtime.send(
      jsonb_build_object('op', lower(TG_OP), 'id', v_id),  -- payload
      'tx',                                                -- event
      'txns:user:' || v_user_id::text,                     -- topic
      true                                                 -- private
    );
  END IF;

  IF (TG_OP = 'DELETE') THEN
    RETURN OLD;
  END IF;
  RETURN NEW;
END;
$$;

-- ---------------------------------------------------------------
-- 2. Trigger: fire on insert/update/delete, after the row is durable.
-- ---------------------------------------------------------------
DROP TRIGGER IF EXISTS transactions_broadcast ON public.transactions;
CREATE TRIGGER transactions_broadcast
  AFTER INSERT OR UPDATE OR DELETE ON public.transactions
  FOR EACH ROW EXECUTE FUNCTION public.broadcast_transaction_change();

-- ---------------------------------------------------------------
-- 3. Private-channel join authorization: a user may RECEIVE broadcasts
--    on its own topic only. realtime.messages already has RLS enabled on
--    Supabase; this policy is additive (permissive).
-- ---------------------------------------------------------------
DROP POLICY IF EXISTS "tx feed: receive own broadcasts" ON realtime.messages;
CREATE POLICY "tx feed: receive own broadcasts"
  ON realtime.messages
  FOR SELECT
  TO authenticated
  USING (
    realtime.messages.extension = 'broadcast'
    AND realtime.topic() = 'txns:user:' || auth.uid()::text
  );

COMMIT;
