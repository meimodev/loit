-- Replace accept_room_invite with rooms.invite_token-based flow.
-- Enforces tier cap, archived check, idempotent rejoin, audit row.
-- Adds regenerate_room_invite_token RPC for creator-only token rotation.

DROP FUNCTION IF EXISTS public.accept_room_invite(text);

CREATE OR REPLACE FUNCTION public.accept_room_invite(p_invite_token text)
RETURNS uuid LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public AS $$
DECLARE
  v_room          rooms%ROWTYPE;
  v_creator_tier  text;
  v_member_cap    int;
  v_current_count int;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  SELECT * INTO v_room FROM rooms
    WHERE invite_token = p_invite_token
      AND is_archived = false;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Invalid or expired invite link';
  END IF;

  IF EXISTS (
    SELECT 1 FROM room_members
    WHERE room_id = v_room.id AND user_id = auth.uid()
  ) THEN
    RETURN v_room.id;
  END IF;

  SELECT tier INTO v_creator_tier FROM users WHERE id = v_room.created_by;
  v_member_cap := CASE v_creator_tier
    WHEN 'team' THEN 15
    WHEN 'pro'  THEN 7
    ELSE 3
  END;

  SELECT count(*) INTO v_current_count
    FROM room_members WHERE room_id = v_room.id;

  IF v_current_count >= v_member_cap THEN
    RAISE EXCEPTION 'Room is full (% / % members)', v_current_count, v_member_cap;
  END IF;

  INSERT INTO room_members (room_id, user_id, role)
  VALUES (v_room.id, auth.uid(), 'member');

  INSERT INTO room_invites (room_id, invited_user_id, invite_token, status)
  VALUES (v_room.id, auth.uid(), p_invite_token, 'accepted');

  RETURN v_room.id;
END;
$$;

REVOKE ALL ON FUNCTION public.accept_room_invite(text) FROM public;
GRANT EXECUTE ON FUNCTION public.accept_room_invite(text) TO authenticated;

-- Creator-only rotation: returns new token, invalidates old link.
CREATE OR REPLACE FUNCTION public.regenerate_room_invite_token(p_room_id uuid)
RETURNS text LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public AS $$
DECLARE
  v_new_token text;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM rooms
    WHERE id = p_room_id AND created_by = auth.uid()
  ) THEN
    RAISE EXCEPTION 'Only the room creator can regenerate the invite link';
  END IF;

  v_new_token := gen_random_uuid()::text;

  UPDATE rooms SET invite_token = v_new_token WHERE id = p_room_id;

  RETURN v_new_token;
END;
$$;

REVOKE ALL ON FUNCTION public.regenerate_room_invite_token(uuid) FROM public;
GRANT EXECUTE ON FUNCTION public.regenerate_room_invite_token(uuid) TO authenticated;
