-- Room creation cap (ADR-0020).
--
-- Rooms become a metered, paid resource. The cap counts rooms a user has ever
-- *created* (created_by), NOT rooms they belong to — joining is free. The
-- counter is monotonic and lifetime: archiving/deleting a created room does NOT
-- free capacity. Base caps Free 1 / Lite 3 / Pro 7; effective cap =
-- base + room_slots_purchased. Pro buys extra rooms one at a time via the
-- loit_room_slot consumable (RevenueCat webhook / dummy-grant -> add_room_slot).
--
-- Server-authoritative: a BEFORE INSERT trigger on rooms rejects over-cap
-- creates. The Flutter client gate is a UX pre-check only.

ALTER TABLE public.users
  ADD COLUMN IF NOT EXISTS rooms_created_total int NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS room_slots_purchased int NOT NULL DEFAULT 0;

-- Backfill the lifetime counter to each user's current created-room count.
-- Pre-migration deletions are unrecoverable, so create-then-deleted history is
-- silently forgiven (ADR-0020). Existing Pro users over 7 keep their rooms but
-- must buy slots to create more.
UPDATE public.users u
SET rooms_created_total = (
  SELECT count(*) FROM public.rooms r WHERE r.created_by = u.id
);

-- Per-tier base cap. Keep in sync with PricingConstants.roomCap* and
-- UserProfile.baseRoomCap on the Dart side (the client is the source of truth;
-- this mirrors it server-side).
CREATE OR REPLACE FUNCTION public.room_base_cap(p_tier text)
RETURNS int LANGUAGE sql IMMUTABLE AS $$
  SELECT CASE p_tier
    WHEN 'pro'  THEN 7
    WHEN 'lite' THEN 3
    ELSE 1
  END;
$$;

-- Grant N permanent room slots (called by the webhook / stub after a
-- loit_room_slot purchase). Monotonic — slots never expire.
CREATE OR REPLACE FUNCTION public.add_room_slot(p_user_id uuid, p_amount int DEFAULT 1)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  UPDATE public.users
  SET room_slots_purchased = room_slots_purchased + p_amount
  WHERE id = p_user_id;
END;
$$;

-- Enforce the cap and bump the counter atomically. The conditional UPDATE
-- (... WHERE rooms_created_total < cap RETURNING) is the race-safe gate: two
-- concurrent inserts can't both pass because each locks the user row. Runs
-- SECURITY DEFINER so it can read/write users past RLS. Counts all org_types.
CREATE OR REPLACE FUNCTION public.enforce_room_creation_cap()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_cap int;
  v_total int;
BEGIN
  SELECT public.room_base_cap(tier) + room_slots_purchased
    INTO v_cap
  FROM public.users
  WHERE id = NEW.created_by;

  IF v_cap IS NULL THEN
    RAISE EXCEPTION 'room creator % not found', NEW.created_by;
  END IF;

  UPDATE public.users
  SET rooms_created_total = rooms_created_total + 1
  WHERE id = NEW.created_by
    AND rooms_created_total < v_cap
  RETURNING rooms_created_total INTO v_total;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'room_creation_cap_reached'
      USING ERRCODE = 'check_violation';
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS enforce_room_creation_cap_trigger ON public.rooms;
CREATE TRIGGER enforce_room_creation_cap_trigger
  BEFORE INSERT ON public.rooms
  FOR EACH ROW
  EXECUTE FUNCTION public.enforce_room_creation_cap();
