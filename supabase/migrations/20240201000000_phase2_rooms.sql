-- ================================================================
-- PHASE 2: SHARED ROOMS — Schema + RLS + Functions
-- ================================================================

-- ROOMS
CREATE TABLE rooms (
  id               uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name             text NOT NULL,
  description      text,
  base_currency    text DEFAULT 'IDR',
  created_by       uuid REFERENCES users(id),
  sync_to_personal boolean DEFAULT false,
  invite_token     text UNIQUE DEFAULT gen_random_uuid()::text,
  is_archived      boolean DEFAULT false,
  archived_at      timestamptz,
  budget_auto_reset boolean DEFAULT false,
  created_at       timestamptz DEFAULT now()
);

-- ROOM MEMBERS
CREATE TABLE room_members (
  id        uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  room_id   uuid REFERENCES rooms(id) ON DELETE CASCADE,
  user_id   uuid REFERENCES users(id) ON DELETE CASCADE,
  role      text DEFAULT 'member' CHECK (role IN ('admin', 'member')),
  joined_at timestamptz DEFAULT now(),
  UNIQUE(room_id, user_id)
);

-- Auto-add creator as admin on room insert
CREATE OR REPLACE FUNCTION add_room_creator_as_admin()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public AS $$
BEGIN
  INSERT INTO room_members (room_id, user_id, role)
  VALUES (NEW.id, NEW.created_by, 'admin')
  ON CONFLICT (room_id, user_id) DO NOTHING;
  RETURN NEW;
END;
$$;

CREATE TRIGGER on_room_created_add_creator
  AFTER INSERT ON rooms
  FOR EACH ROW
  EXECUTE FUNCTION add_room_creator_as_admin();

-- ROOM INVITES — partial unique index, not table-level constraint
CREATE TABLE room_invites (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  room_id         uuid REFERENCES rooms(id) ON DELETE CASCADE,
  invited_user_id uuid REFERENCES users(id) ON DELETE CASCADE,
  invite_token    text NOT NULL,
  status          text DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'expired')),
  created_at      timestamptz DEFAULT now(),
  expires_at      timestamptz DEFAULT now() + interval '7 days'
);

CREATE UNIQUE INDEX room_invites_pending_unique
  ON room_invites(room_id, invited_user_id)
  WHERE status = 'pending';

-- ROOM BUDGETS
CREATE TABLE room_budgets (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  room_id      uuid REFERENCES rooms(id) ON DELETE CASCADE,
  category     text NOT NULL,
  budget_limit numeric NOT NULL,
  currency     text NOT NULL,
  created_by   uuid REFERENCES users(id),
  created_at   timestamptz DEFAULT now(),
  UNIQUE(room_id, category)
);

-- FK from transactions to rooms
ALTER TABLE transactions
  ADD CONSTRAINT fk_room
  FOREIGN KEY (room_id) REFERENCES rooms(id) ON DELETE SET NULL;

-- Indexes
CREATE INDEX idx_room_members_user ON room_members (user_id);
CREATE INDEX idx_room_invites_token ON room_invites (invite_token)
  WHERE status = 'pending';

-- ================================================================
-- RLS HELPER: is_room_member (SECURITY DEFINER — breaks recursion)
-- ================================================================
CREATE OR REPLACE FUNCTION is_room_member(p_room_id uuid)
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM room_members
    WHERE room_id = p_room_id AND user_id = auth.uid()
  );
$$;

REVOKE ALL ON FUNCTION is_room_member(uuid) FROM public;
GRANT EXECUTE ON FUNCTION is_room_member(uuid) TO authenticated;

-- ================================================================
-- RLS POLICIES
-- ================================================================
ALTER TABLE rooms        ENABLE ROW LEVEL SECURITY;
ALTER TABLE room_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE room_invites ENABLE ROW LEVEL SECURITY;
ALTER TABLE room_budgets ENABLE ROW LEVEL SECURITY;

-- ROOMS
CREATE POLICY "rooms_select_member" ON rooms
  FOR SELECT USING (is_room_member(id));

CREATE POLICY "rooms_insert_own" ON rooms
  FOR INSERT WITH CHECK (created_by = auth.uid());

CREATE POLICY "rooms_update_creator" ON rooms
  FOR UPDATE USING (created_by = auth.uid());

-- ROOM MEMBERS
CREATE POLICY "room_members_select" ON room_members
  FOR SELECT USING (is_room_member(room_id));

CREATE POLICY "room_members_insert_self" ON room_members
  FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY "room_members_delete" ON room_members
  FOR DELETE USING (
    user_id = auth.uid()
    OR EXISTS (SELECT 1 FROM rooms r WHERE r.id = room_id AND r.created_by = auth.uid())
  );

-- ROOM INVITES
CREATE POLICY "room_invites_select" ON room_invites
  FOR SELECT USING (
    invited_user_id = auth.uid()
    OR EXISTS (SELECT 1 FROM rooms r WHERE r.id = room_id AND r.created_by = auth.uid())
  );

-- ROOM BUDGETS
CREATE POLICY "room_budgets_select" ON room_budgets
  FOR SELECT USING (is_room_member(room_id));

CREATE POLICY "room_budgets_insert" ON room_budgets
  FOR INSERT WITH CHECK (is_room_member(room_id));

CREATE POLICY "room_budgets_update" ON room_budgets
  FOR UPDATE USING (is_room_member(room_id));

-- TRANSACTIONS: replace Phase 1 personal-only policies with room-aware
DROP POLICY IF EXISTS "transactions_select_own" ON transactions;
DROP POLICY IF EXISTS "transactions_insert_own" ON transactions;

CREATE POLICY "transactions_select_own_or_room" ON transactions
  FOR SELECT USING (
    auth.uid() = user_id
    OR (room_id IS NOT NULL AND is_room_member(room_id))
  );

CREATE POLICY "transactions_insert_own_or_room" ON transactions
  FOR INSERT WITH CHECK (
    auth.uid() = user_id
    AND (room_id IS NULL OR is_room_member(room_id))
  );

-- ================================================================
-- ACCEPT INVITE (SECURITY DEFINER — caller not yet a member)
-- ================================================================
CREATE OR REPLACE FUNCTION accept_room_invite(p_invite_token text)
RETURNS uuid LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public AS $$
DECLARE
  v_invite record;
BEGIN
  SELECT * INTO v_invite
    FROM room_invites
    WHERE invite_token = p_invite_token
      AND status = 'pending'
      AND expires_at > now()
      AND invited_user_id = auth.uid();

  IF v_invite IS NULL THEN
    RAISE EXCEPTION 'Invalid, expired, or not-yours invite';
  END IF;

  INSERT INTO room_members (room_id, user_id, role)
  VALUES (v_invite.room_id, auth.uid(), 'member')
  ON CONFLICT (room_id, user_id) DO NOTHING;

  UPDATE room_invites
    SET status = 'accepted'
    WHERE id = v_invite.id;

  RETURN v_invite.room_id;
END;
$$;
