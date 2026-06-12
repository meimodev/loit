-- ============================================================
-- Out-of-pocket room expense (ADR 0011, supersedes pool-only stance of 0007).
--
-- A Room transaction may now be funded from the payer's own personal account
-- (account_id = a personal account) while still carrying room_id. It counts in
-- room spend/budget but touches no room account.
--
-- HAZARD CLOSED: the room-admin override on UPDATE/DELETE must NOT reach an
-- out-of-pocket row, or an admin could move another member's personal cash.
-- Scope the admin override to rows whose account_id is a ROOM account; an
-- out-of-pocket row (personal account_id) is then payer-only via auth.uid().
-- ============================================================

-- SECURITY DEFINER helper: is this account a room-owned account? Bypasses
-- accounts RLS so the transactions policy never depends on the caller's
-- visibility of the account row.
CREATE OR REPLACE FUNCTION account_is_room_owned(p_account_id uuid)
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM accounts
    WHERE id = p_account_id AND room_id IS NOT NULL
  );
$$;

REVOKE ALL ON FUNCTION account_is_room_owned(uuid) FROM public;
GRANT EXECUTE ON FUNCTION account_is_room_owned(uuid) TO authenticated;

-- Re-scope the admin override: only pool-funded room rows (account_id is a room
-- account) are admin-editable/deletable. Out-of-pocket rows fall through to the
-- payer-only `auth.uid() = user_id` branch.
DROP POLICY IF EXISTS transactions_update_own_or_admin ON transactions;
DROP POLICY IF EXISTS transactions_delete_own_or_admin ON transactions;

CREATE POLICY transactions_update_own_or_admin ON transactions
  FOR UPDATE USING (
    auth.uid() = user_id
    OR (
      room_id IS NOT NULL
      AND is_room_admin(room_id)
      AND account_is_room_owned(account_id)
    )
  );

CREATE POLICY transactions_delete_own_or_admin ON transactions
  FOR DELETE USING (
    auth.uid() = user_id
    OR (
      room_id IS NOT NULL
      AND is_room_admin(room_id)
      AND account_is_room_owned(account_id)
    )
  );
