-- Phase 3 Step 3.3: Top-Up and Storage Extension RPCs.
-- Called by `midtrans-notification` (or `midtrans-checkout-stub` in stub mode)
-- after a successful one-time payment.

ALTER TABLE public.users
  ADD COLUMN IF NOT EXISTS tier_expires_at timestamptz;

CREATE OR REPLACE FUNCTION public.add_scan_topup(p_user_id uuid, p_amount int)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  UPDATE public.users
  SET scans_used_this_month = GREATEST(0, scans_used_this_month - p_amount)
  WHERE id = p_user_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.extend_receipt_expiry(p_user_id uuid)
RETURNS int LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  affected int;
BEGIN
  UPDATE public.transactions
  SET receipt_expires_at = receipt_expires_at + interval '6 months'
  WHERE user_id = p_user_id
    AND receipt_url IS NOT NULL
    AND receipt_expires_at IS NOT NULL
    AND receipt_expires_at <= now() + interval '30 days';
  GET DIAGNOSTICS affected = ROW_COUNT;
  RETURN affected;
END;
$$;
