-- ================================================================
-- Room catch-all categories (ADR 0009)
--
-- Every room must carry the two fallback categories — `other` (expense)
-- and `income_other` (income) — so a room-account movement always has a
-- category to land in. Previously a room only inherited the creator's
-- personal categories, so a creator lacking a personal "Other" / "Income
-- other" produced a room with no catch-all.
--
-- This migration:
--   1. extends seed_room_categories_from_creator() to always insert the
--      two catch-all rows for a new room, independent of the creator's
--      personal categories, and
--   2. backfills the same two rows into every existing room.
--
-- Keys obey room_categories_key_format: ^room:<room_id>:[a-z0-9_]+$.
-- icon_name / tint are left NULL so the client renders the default
-- "other" style (LoitCategories.defaultOther). Display label is localized
-- client-side by key suffix, so the stored English name is never shown
-- directly for the `id` locale ("Lainnya" / "Pemasukan lain").
-- ================================================================

CREATE OR REPLACE FUNCTION seed_room_categories_from_creator()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public AS $$
BEGIN
  -- Inherited: the creator's personal categories.
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

  -- Guaranteed: the two catch-all categories, regardless of the above.
  INSERT INTO room_categories (
    room_id, key, name, kind, icon_name, tint, sort_order, created_by
  )
  VALUES
    (NEW.id, 'room:' || NEW.id || ':other',
     'Other', 'expense', NULL, NULL, 1000, NEW.created_by),
    (NEW.id, 'room:' || NEW.id || ':income_other',
     'Income other', 'income', NULL, NULL, 1001, NEW.created_by)
  ON CONFLICT (room_id, key) DO NOTHING;

  RETURN NEW;
END;
$$;

-- ================================================================
-- Backfill: catch-all rows for every existing room.
-- ================================================================
INSERT INTO room_categories (
  room_id, key, name, kind, icon_name, tint, sort_order, created_by
)
SELECT
  r.id, 'room:' || r.id || ':other',
  'Other', 'expense', NULL, NULL, 1000, r.created_by
FROM rooms r
ON CONFLICT (room_id, key) DO NOTHING;

INSERT INTO room_categories (
  room_id, key, name, kind, icon_name, tint, sort_order, created_by
)
SELECT
  r.id, 'room:' || r.id || ':income_other',
  'Income other', 'income', NULL, NULL, 1001, r.created_by
FROM rooms r
ON CONFLICT (room_id, key) DO NOTHING;
