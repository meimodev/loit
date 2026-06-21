-- ================================================================
-- AI CREDIT OVERSHOOT CHARGE (ADR-0017)
-- Adds N credits to the running monthly count WITHOUT a cap check.
-- Used to charge the credits a capture cost beyond the 1 already
-- reserved at the gate. The true cost is only known after the AI
-- responds and the tokens are already spent, so this is allowed to
-- push scans_used_this_month past the tier cap (soft cap). The next
-- capture's gated increment then blocks until the month resets.
-- Returns the new count.
-- ================================================================
CREATE OR REPLACE FUNCTION add_scan_quota(p_user_id uuid, p_amount int)
RETURNS int LANGUAGE plpgsql AS $$
DECLARE
  new_count int;
BEGIN
  UPDATE users
  SET scans_used_this_month = scans_used_this_month + GREATEST(p_amount, 0)
  WHERE id = p_user_id
  RETURNING scans_used_this_month INTO new_count;

  RETURN new_count;
END;
$$;
