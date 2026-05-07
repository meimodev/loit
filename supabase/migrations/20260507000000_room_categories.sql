-- ================================================================
-- ROOM_CATEGORIES TABLE
-- Room-owned categories visible to all room members. Only the room
-- creator may add/update/delete. Members inherit them via RLS.
--
-- Stable keys are prefixed `room:<room_id>:<slug>` so they never
-- collide with personal `user_categories.key` values.
-- ================================================================

CREATE TABLE room_categories (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  room_id       uuid NOT NULL REFERENCES rooms(id) ON DELETE CASCADE,
  key           text NOT NULL UNIQUE,
  name          text NOT NULL,
  kind          text NOT NULL CHECK (kind IN ('expense', 'income')),
  icon_name     text,
  tint          text,
  sort_order    int NOT NULL DEFAULT 0,
  created_by    uuid REFERENCES users(id),
  created_at    timestamptz DEFAULT now(),
  updated_at    timestamptz DEFAULT now(),
  UNIQUE(room_id, key),
  UNIQUE(room_id, name, kind),
  CONSTRAINT room_categories_key_format CHECK (
    key ~ ('^room:' || room_id::text || ':[a-z0-9_]+$')
  )
);

CREATE INDEX idx_room_categories_room ON room_categories (room_id);

-- ================================================================
-- RLS: members read, creator writes
-- ================================================================
ALTER TABLE room_categories ENABLE ROW LEVEL SECURITY;

CREATE POLICY "room_categories_select_member" ON room_categories
  FOR SELECT USING (is_room_member(room_id));

CREATE POLICY "room_categories_insert_creator" ON room_categories
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM rooms r
      WHERE r.id = room_id AND r.created_by = auth.uid()
    )
  );

CREATE POLICY "room_categories_update_creator" ON room_categories
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM rooms r
      WHERE r.id = room_id AND r.created_by = auth.uid()
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM rooms r
      WHERE r.id = room_id AND r.created_by = auth.uid()
    )
  );

-- Immutable room_id and created_by — even if a future client tries to
-- send these fields, the row must continue pointing at the same room
-- and creator. Enforced via trigger so RLS predicates can rely on
-- room_id stability.
CREATE OR REPLACE FUNCTION room_categories_lock_immutable_fields()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  IF NEW.room_id IS DISTINCT FROM OLD.room_id THEN
    RAISE EXCEPTION 'room_categories.room_id is immutable';
  END IF;
  IF NEW.created_by IS DISTINCT FROM OLD.created_by THEN
    RAISE EXCEPTION 'room_categories.created_by is immutable';
  END IF;
  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_room_categories_immutable
  BEFORE UPDATE ON room_categories
  FOR EACH ROW
  EXECUTE FUNCTION room_categories_lock_immutable_fields();

CREATE POLICY "room_categories_delete_creator" ON room_categories
  FOR DELETE USING (
    EXISTS (
      SELECT 1 FROM rooms r
      WHERE r.id = room_id AND r.created_by = auth.uid()
    )
  );

-- ================================================================
-- Slug helper
-- ================================================================
CREATE OR REPLACE FUNCTION room_category_slug(p_name text, p_kind text)
RETURNS text LANGUAGE sql IMMUTABLE AS $$
  SELECT
    CASE WHEN p_kind = 'income' THEN 'income_' ELSE '' END
    || regexp_replace(
         regexp_replace(lower(p_name), '[^a-z0-9]+', '_', 'g'),
         '(^_+|_+$)', '', 'g'
       );
$$;

-- ================================================================
-- Backfill: copy each existing room creator's personal categories
-- as the initial room_categories set.
-- ================================================================
INSERT INTO room_categories (
  room_id, key, name, kind, icon_name, tint, sort_order, created_by
)
SELECT
  r.id,
  'room:' || r.id || ':' || room_category_slug(uc.name, uc.kind),
  uc.name,
  uc.kind,
  uc.icon_name,
  uc.tint,
  uc.sort_order,
  r.created_by
FROM rooms r
JOIN user_categories uc ON uc.user_id = r.created_by
ON CONFLICT (room_id, key) DO NOTHING;

-- ================================================================
-- Trigger: seed room_categories from creator's personal categories
-- when a new room is inserted.
-- ================================================================
CREATE OR REPLACE FUNCTION seed_room_categories_from_creator()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public AS $$
BEGIN
  INSERT INTO room_categories (
    room_id, key, name, kind, icon_name, tint, sort_order, created_by
  )
  SELECT
    NEW.id,
    'room:' || NEW.id || ':' || room_category_slug(uc.name, uc.kind),
    uc.name,
    uc.kind,
    uc.icon_name,
    uc.tint,
    uc.sort_order,
    NEW.created_by
  FROM user_categories uc
  WHERE uc.user_id = NEW.created_by
  ON CONFLICT (room_id, key) DO NOTHING;
  RETURN NEW;
END;
$$;

CREATE TRIGGER on_room_created_seed_categories
  AFTER INSERT ON rooms
  FOR EACH ROW
  EXECUTE FUNCTION seed_room_categories_from_creator();
