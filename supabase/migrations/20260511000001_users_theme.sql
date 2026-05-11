-- Add theme preference column to users table for multi-device sync.
ALTER TABLE public.users
  ADD COLUMN IF NOT EXISTS theme text NOT NULL DEFAULT 'system'
  CHECK (theme IN ('system', 'light', 'dark'));
