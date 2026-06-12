-- ============================================================
-- Room-account kind is derived from balance, not chosen.
-- A room account is a `liability` while its balance is negative and an `asset`
-- otherwise. The stored `kind` column is kept truthful by triggers so every
-- reader (room balance tab, Telegram bot, …) agrees without per-site logic.
-- Personal accounts (room_id IS NULL) are untouched — owners classify by hand.
-- See docs/adr/0008-room-account-kind-derived-from-balance.md.
-- ============================================================

-- Balance of a room account given an initial_balance. Mirrors
-- roomAccountBalancesProvider: income legs add, expense + outgoing-transfer legs
-- subtract, incoming-transfer legs add. A room is single-currency, so amounts
-- are already in the account's currency (no FX conversion). ABS() matches the
-- client's absAmountIn regardless of how `amount` is signed in storage.
CREATE OR REPLACE FUNCTION room_account_balance(p_account_id uuid, p_initial numeric)
RETURNS numeric
LANGUAGE sql
STABLE
SET search_path = public
AS $$
  SELECT p_initial + COALESCE((
    SELECT SUM(
      CASE
        WHEN t.account_id = p_account_id AND t.type = 'income' THEN ABS(t.amount)
        WHEN t.account_id = p_account_id THEN -ABS(t.amount)
        ELSE 0
      END
      + CASE WHEN t.to_account_id = p_account_id THEN ABS(t.amount) ELSE 0 END
    )
    FROM transactions t
    WHERE t.account_id = p_account_id OR t.to_account_id = p_account_id
  ), 0);
$$;

-- BEFORE trigger on accounts: derive kind from the (possibly new) initial_balance
-- for room rows. On INSERT the account has no transactions yet ⇒ balance = initial.
-- Fires on INSERT and on initial_balance edits; updating `kind` alone never
-- re-triggers it (kind is not in the UPDATE OF column list), so no recursion.
CREATE OR REPLACE FUNCTION accounts_set_room_kind()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = public
AS $$
BEGIN
  IF NEW.room_id IS NOT NULL THEN
    NEW.kind := CASE
      WHEN room_account_balance(NEW.id, NEW.initial_balance) < 0 THEN 'liability'
      ELSE 'asset'
    END;
  END IF;
  RETURN NEW;
END;
$$;

CREATE TRIGGER accounts_room_kind_biu
  BEFORE INSERT OR UPDATE OF initial_balance ON accounts
  FOR EACH ROW EXECUTE FUNCTION accounts_set_room_kind();

-- AFTER trigger on transactions: recompute kind for every room account a
-- movement touches (both legs, before and after the change). Updates `kind`
-- only, so the accounts BEFORE-UPDATE trigger above is not re-fired.
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
        WHEN room_account_balance(a.id, a.initial_balance) < 0 THEN 'liability'
        ELSE 'asset'
      END
      WHERE a.id = v_id AND a.room_id IS NOT NULL;
  END LOOP;
  RETURN NULL;
END;
$$;

CREATE TRIGGER transactions_room_kind_aiud
  AFTER INSERT OR UPDATE OR DELETE ON transactions
  FOR EACH ROW EXECUTE FUNCTION transactions_refresh_room_kind();

-- Backfill existing room accounts so stored kind is truthful from day one.
UPDATE accounts a
  SET kind = CASE
    WHEN room_account_balance(a.id, a.initial_balance) < 0 THEN 'liability'
    ELSE 'asset'
  END
  WHERE a.room_id IS NOT NULL;
