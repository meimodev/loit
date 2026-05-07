-- ================================================================
-- Computed relationships so PostgREST can embed room_member_profiles
-- under room_members and transactions via the resource embedding
-- syntax. The view has no foreign key, so without these functions
-- PostgREST returns PGRST200 ("Couldn't find a relationship...").
-- ================================================================

CREATE OR REPLACE FUNCTION public.room_member_profile(public.room_members)
RETURNS SETOF public.room_member_profiles
ROWS 1
LANGUAGE sql
STABLE
AS $$
  SELECT *
  FROM public.room_member_profiles
  WHERE id = $1.user_id;
$$;

CREATE OR REPLACE FUNCTION public.room_member_profile(public.transactions)
RETURNS SETOF public.room_member_profiles
ROWS 1
LANGUAGE sql
STABLE
AS $$
  SELECT *
  FROM public.room_member_profiles
  WHERE id = $1.user_id;
$$;

GRANT EXECUTE ON FUNCTION public.room_member_profile(public.room_members) TO authenticated;
GRANT EXECUTE ON FUNCTION public.room_member_profile(public.transactions) TO authenticated;

NOTIFY pgrst, 'reload schema';
