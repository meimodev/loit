-- Default to Indonesian for new users. Existing rows keep their value.
ALTER TABLE public.users
  ALTER COLUMN language SET DEFAULT 'id';
