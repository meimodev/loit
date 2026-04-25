-- Fix: room creator couldn't see their own room on INSERT...RETURNING
-- because the AFTER INSERT trigger (add_room_creator_as_admin) hadn't
-- fired yet, so is_room_member() returned false.
CREATE POLICY "rooms_select_creator" ON rooms
  FOR SELECT USING (created_by = auth.uid());
