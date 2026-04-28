-- Phase 3 Step 3.6 support: surface a warning when a user has any
-- receipt expiring within the next 30 days. Populated by the
-- receipt-expiry-cron Edge Function. Flutter dashboard reads this
-- column to render a banner.
ALTER TABLE public.users
  ADD COLUMN IF NOT EXISTS next_receipt_expiry_at timestamptz;
