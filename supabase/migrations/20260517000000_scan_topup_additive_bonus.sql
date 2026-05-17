-- Scan top-up: switch from "subtract from used" to "additive bonus pool".
--
-- Before: `add_scan_topup` reduced `scans_used_this_month`, floored at 0 — a
-- no-op when the user hadn't scanned yet, which surprised users who expected
-- top-up to increase their monthly ceiling.
--
-- After: a dedicated `scan_topup_bonus_this_month` column accumulates extra
-- scans purchased this month. The effective cap surfaced to the client is
-- `tier_base_cap + scan_topup_bonus_this_month`. Both reset on the same
-- monthly boundary as `scans_used_this_month`.

ALTER TABLE public.users
  ADD COLUMN IF NOT EXISTS scan_topup_bonus_this_month int NOT NULL DEFAULT 0;

-- Top-up grant: now increments bonus instead of decrementing used.
CREATE OR REPLACE FUNCTION public.add_scan_topup(p_user_id uuid, p_amount int)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  UPDATE public.users
  SET scan_topup_bonus_this_month = scan_topup_bonus_this_month + p_amount
  WHERE id = p_user_id;
END;
$$;

-- Monthly reset: zero both counters when crossing a calendar month.
CREATE OR REPLACE FUNCTION public.reset_scan_quota_if_new_month(p_user_id uuid)
RETURNS void LANGUAGE plpgsql AS $$
BEGIN
  UPDATE public.users
  SET
    scans_used_this_month        = 0,
    scan_topup_bonus_this_month  = 0,
    scan_reset_date              = date_trunc('month', now())
  WHERE id = p_user_id
    AND (
      EXTRACT(YEAR  FROM now()) != EXTRACT(YEAR  FROM scan_reset_date) OR
      EXTRACT(MONTH FROM now()) != EXTRACT(MONTH FROM scan_reset_date)
    );
END;
$$;
