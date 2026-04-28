-- Phase 3 amendment: payments moved from Midtrans Snap to Google Play
-- Billing. The `midtrans_orders` table and its RLS policies are no longer
-- referenced by any Edge Function or client code. Dropped here so the
-- schema stays accurate. The original `20240301000000_midtrans_orders.sql`
-- migration is preserved for installs that already applied it.

DROP TABLE IF EXISTS public.midtrans_orders CASCADE;
