-- ============================================================================
-- Midtrans orders — one row per Snap transaction we create.
--
-- Lifecycle:
--   1. `midtrans-checkout` Edge Function inserts with status='pending'.
--   2. `midtrans-notification` webhook updates status on every HTTP POST
--      from Midtrans (settlement, deny, cancel, expire, etc.).
--   3. The paywall UI polls this table (or watches via Realtime) to show
--      the user a live payment status while Snap is open.
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.midtrans_orders (
  order_id                    text        PRIMARY KEY,
  user_id                     uuid        NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  product_key                 text        NOT NULL,
  amount_idr                  bigint      NOT NULL CHECK (amount_idr > 0),
  status                      text        NOT NULL DEFAULT 'pending'
    CHECK (status IN ('pending', 'succeeded', 'failed', 'cancelled', 'expired', 'init_failed')),
  midtrans_transaction_status text,
  midtrans_fraud_status       text,
  failure_reason              text,
  paid_at                     timestamptz,
  created_at                  timestamptz NOT NULL DEFAULT now(),
  updated_at                  timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_midtrans_orders_user_id
  ON public.midtrans_orders(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_midtrans_orders_status
  ON public.midtrans_orders(status)
  WHERE status = 'pending';

-- Keep updated_at honest.
CREATE OR REPLACE FUNCTION public.touch_midtrans_orders_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  NEW.updated_at := now();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_touch_midtrans_orders ON public.midtrans_orders;
CREATE TRIGGER trg_touch_midtrans_orders
  BEFORE UPDATE ON public.midtrans_orders
  FOR EACH ROW EXECUTE FUNCTION public.touch_midtrans_orders_updated_at();

-- ============================================================================
-- RLS — users can only see their own orders. Writes are performed by the
-- Edge Functions using the service role, which bypasses RLS.
-- ============================================================================
ALTER TABLE public.midtrans_orders ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "midtrans_orders_select_own" ON public.midtrans_orders;
CREATE POLICY "midtrans_orders_select_own" ON public.midtrans_orders
  FOR SELECT USING (user_id = auth.uid());
