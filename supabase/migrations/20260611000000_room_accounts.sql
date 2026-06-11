-- ============================================================
-- Room accounts: a Room's own balance sheet (shared assets /
-- liabilities), modelled as rows in the existing `accounts` table.
-- See docs/adr/0007-room-accounts-unified-table.md.
-- ============================================================

-- 1. Relax accounts for room ownership: exactly one of user_id / room_id.
ALTER TABLE accounts ALTER COLUMN user_id DROP NOT NULL;
ALTER TABLE accounts
  ADD COLUMN IF NOT EXISTS room_id uuid REFERENCES rooms(id) ON DELETE CASCADE;
ALTER TABLE accounts
  ADD CONSTRAINT accounts_owner_xor
    CHECK ((user_id IS NULL) <> (room_id IS NULL));

-- Room-scoped name uniqueness + active lookup (personal indexes already exist).
CREATE UNIQUE INDEX accounts_name_lower_room_idx
  ON accounts (room_id, lower(name)) WHERE room_id IS NOT NULL;
CREATE INDEX accounts_room_active_idx
  ON accounts (room_id) WHERE archived_at IS NULL;

-- 2. Room-admin helper (SECURITY DEFINER — mirrors is_room_member, breaks RLS recursion).
CREATE OR REPLACE FUNCTION is_room_admin(p_room_id uuid)
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM room_members
    WHERE room_id = p_room_id AND user_id = auth.uid() AND role = 'admin'
  );
$$;

REVOKE ALL ON FUNCTION is_room_admin(uuid) FROM public;
GRANT EXECUTE ON FUNCTION is_room_admin(uuid) TO authenticated;

-- 3. RLS for room accounts (additive to the existing personal own-row policies).
-- SELECT = any room member; INSERT/UPDATE/DELETE = room admin.
CREATE POLICY accounts_select_room ON accounts
  FOR SELECT USING (room_id IS NOT NULL AND is_room_member(room_id));

CREATE POLICY accounts_insert_room ON accounts
  FOR INSERT WITH CHECK (room_id IS NOT NULL AND is_room_admin(room_id));

CREATE POLICY accounts_update_room ON accounts
  FOR UPDATE USING (room_id IS NOT NULL AND is_room_admin(room_id));

CREATE POLICY accounts_delete_room ON accounts
  FOR DELETE USING (room_id IS NOT NULL AND is_room_admin(room_id));

-- 4. Cross-ledger transfer ownership. A leg is allowed when it is either the
-- caller's own personal account OR a room account of a room they belong to.
-- When a leg is a room account, the transaction's room_id must match it (so the
-- row lands in the room feed and budgets). SECURITY DEFINER bypasses accounts RLS.
CREATE OR REPLACE FUNCTION enforce_transaction_account_ownership()
RETURNS trigger LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_user_id uuid;
  v_room_id uuid;
BEGIN
  -- account_id leg (always present)
  SELECT user_id, room_id INTO v_user_id, v_room_id
    FROM accounts WHERE id = NEW.account_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'account_id does not exist';
  END IF;
  IF v_room_id IS NOT NULL THEN
    IF NOT is_room_member(v_room_id) THEN
      RAISE EXCEPTION 'account_id is a room account the user cannot access';
    END IF;
    IF NEW.room_id IS DISTINCT FROM v_room_id THEN
      RAISE EXCEPTION 'transaction room_id must match the room account';
    END IF;
  ELSIF v_user_id <> NEW.user_id THEN
    RAISE EXCEPTION 'account_id does not belong to user';
  END IF;

  -- to_account_id leg (transfers only)
  IF NEW.to_account_id IS NOT NULL THEN
    SELECT user_id, room_id INTO v_user_id, v_room_id
      FROM accounts WHERE id = NEW.to_account_id;
    IF NOT FOUND THEN
      RAISE EXCEPTION 'to_account_id does not exist';
    END IF;
    IF v_room_id IS NOT NULL THEN
      IF NOT is_room_member(v_room_id) THEN
        RAISE EXCEPTION 'to_account_id is a room account the user cannot access';
      END IF;
      IF NEW.room_id IS DISTINCT FROM v_room_id THEN
        RAISE EXCEPTION 'transaction room_id must match the room account';
      END IF;
    ELSIF v_user_id <> NEW.user_id THEN
      RAISE EXCEPTION 'to_account_id does not belong to user';
    END IF;
  END IF;

  RETURN NEW;
END;
$$;

-- 5. Admin may also edit/delete movements logged by other members in their room.
DROP POLICY IF EXISTS "transactions_update_own" ON transactions;
DROP POLICY IF EXISTS "transactions_delete_own" ON transactions;

CREATE POLICY transactions_update_own_or_admin ON transactions
  FOR UPDATE USING (
    auth.uid() = user_id
    OR (room_id IS NOT NULL AND is_room_admin(room_id))
  );

CREATE POLICY transactions_delete_own_or_admin ON transactions
  FOR DELETE USING (
    auth.uid() = user_id
    OR (room_id IS NOT NULL AND is_room_admin(room_id))
  );

-- 6. Drop the vestigial room-level sync flag — superseded by the per-transaction
-- Personal mirror (a transfer). Referenced nowhere in client or functions.
ALTER TABLE rooms DROP COLUMN IF EXISTS sync_to_personal;
