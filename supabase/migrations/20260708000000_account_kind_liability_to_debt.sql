-- ============================================================
-- Rename account kind value 'liability' -> 'debt' (ADR-0028).
-- User-facing copy became "Debt" / "Hutang"; the stored kind value follows
-- so the whole stack speaks one vocabulary. Personal accounts carry a manual
-- kind; room accounts derive it from balance via the triggers below.
--
-- Order matters: the CHECK constraint only permits the old value, so drop it
-- before backfilling, replace the derived-kind trigger functions to write the
-- new value, then re-add the CHECK. Runs in one transaction (Supabase wraps
-- each migration), so readers never see a half-renamed table.
-- ============================================================

-- 1. Drop the old CHECK (inline unnamed check ⇒ Postgres default name).
ALTER TABLE accounts DROP CONSTRAINT IF EXISTS accounts_kind_check;

-- 2. Backfill every existing row (personal + room).
UPDATE accounts SET kind = 'debt' WHERE kind = 'liability';

-- 3. Replace the derived-kind trigger functions to emit 'debt'.
--    Bodies are identical to 20260612000000 except the negative-balance value.
CREATE OR REPLACE FUNCTION accounts_set_room_kind()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = public
AS $$
BEGIN
  IF NEW.room_id IS NOT NULL THEN
    NEW.kind := CASE
      WHEN room_account_balance(NEW.id, NEW.initial_balance) < 0 THEN 'debt'
      ELSE 'asset'
    END;
  END IF;
  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION transactions_refresh_room_kind()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = public
AS $$
DECLARE
  v_id uuid;
BEGIN
  FOREACH v_id IN ARRAY ARRAY(
    SELECT DISTINCT x FROM unnest(ARRAY[
      NEW.account_id, NEW.to_account_id, OLD.account_id, OLD.to_account_id
    ]) AS x WHERE x IS NOT NULL
  ) LOOP
    UPDATE accounts a
      SET kind = CASE
        WHEN room_account_balance(a.id, a.initial_balance) < 0 THEN 'debt'
        ELSE 'asset'
      END
      WHERE a.id = v_id AND a.room_id IS NOT NULL;
  END LOOP;
  RETURN NULL;
END;
$$;

-- 4. Re-add the CHECK with the new vocabulary.
ALTER TABLE accounts ADD CONSTRAINT accounts_kind_check CHECK (kind IN ('asset', 'debt'));
