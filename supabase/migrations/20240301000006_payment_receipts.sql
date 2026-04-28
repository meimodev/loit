-- Idempotency log for `revenuecat-webhook` Edge Function.
-- Each Google Play purchase token is stored exactly once. Re-verifying
-- the same token short-circuits and never double-grants entitlement.

CREATE TABLE IF NOT EXISTS public.payment_receipts (
  purchase_token text PRIMARY KEY,
  user_id        uuid NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  product_id     text NOT NULL,
  raw            jsonb NOT NULL,
  created_at     timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS payment_receipts_user_idx
  ON public.payment_receipts (user_id, created_at DESC);

ALTER TABLE public.payment_receipts ENABLE ROW LEVEL SECURITY;

-- Only the service role (used by `revenuecat-webhook`) can read/write this
-- table. The Flutter client never touches it directly.
CREATE POLICY payment_receipts_service_only
  ON public.payment_receipts
  FOR ALL
  USING (false)
  WITH CHECK (false);
