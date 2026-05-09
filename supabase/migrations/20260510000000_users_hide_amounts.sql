ALTER TABLE public.users
  ADD COLUMN IF NOT EXISTS hide_amounts boolean NOT NULL DEFAULT false;
