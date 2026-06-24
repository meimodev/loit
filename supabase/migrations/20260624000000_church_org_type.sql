-- ================================================================
-- Church room — additive Org type (ADR 0019)
--
-- Adds rooms.org_type + rooms.org_config, and teaches the existing
-- category seed trigger to SKIP the creator's personal categories for a
-- church room (a treasurer's "Dining"/"Transport" must not pollute a
-- church ledger). The two catch-all rows (ADR 0009) are still seeded for
-- every org type, so a church room always has a fallback bucket; the
-- denomination preset is inserted client-side after createRoom.
--
-- Church categories are ordinary room_categories rows — they are NOT
-- stored in org_config. org_config holds the church profile only
-- (denomination, jemaat_name, kota_kabupaten, phone_number).
-- ================================================================

ALTER TABLE rooms
  ADD COLUMN IF NOT EXISTS org_type TEXT NOT NULL DEFAULT 'general'
    CHECK (org_type IN ('general', 'church', 'family', 'community')),
  ADD COLUMN IF NOT EXISTS org_config JSONB NOT NULL DEFAULT '{}'::jsonb;

-- ================================================================
-- Re-define the seed trigger: personal-category copy is gated on
-- org_type; catch-all stays unconditional (ADR 0009).
-- ================================================================
CREATE OR REPLACE FUNCTION seed_room_categories_from_creator()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public AS $$
BEGIN
  -- Inherited: the creator's personal categories — general rooms only.
  -- A church room is seeded from its denomination preset (client-side),
  -- so copying personal categories here would pollute the ledger.
  IF NEW.org_type <> 'church' THEN
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
  END IF;

  -- Guaranteed: the two catch-all categories, regardless of org type.
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
