-- ================================================================
-- RESET SCAN QUOTA (safe month boundary — year-safe comparison)
-- Compares both year AND month to handle December → January correctly.
-- ================================================================
CREATE OR REPLACE FUNCTION reset_scan_quota_if_new_month(p_user_id uuid)
RETURNS void LANGUAGE plpgsql AS $$
BEGIN
  UPDATE users
  SET
    scans_used_this_month = 0,
    scan_reset_date       = date_trunc('month', now())
  WHERE id = p_user_id
    AND (
      EXTRACT(YEAR  FROM now()) != EXTRACT(YEAR  FROM scan_reset_date) OR
      EXTRACT(MONTH FROM now()) != EXTRACT(MONTH FROM scan_reset_date)
    );
END;
$$;

-- ================================================================
-- ATOMIC QUOTA INCREMENT
-- Only increments if current count < limit.
-- Returns new count, or NULL if quota is already at limit.
-- Single UPDATE...RETURNING eliminates the race condition of
-- a read-then-check flow allowing two simultaneous requests through.
-- ================================================================
CREATE OR REPLACE FUNCTION increment_scan_quota(p_user_id uuid, p_limit int)
RETURNS int LANGUAGE plpgsql AS $$
DECLARE
  new_count int;
BEGIN
  UPDATE users
  SET scans_used_this_month = scans_used_this_month + 1
  WHERE id = p_user_id
    AND scans_used_this_month < p_limit
  RETURNING scans_used_this_month INTO new_count;

  RETURN new_count; -- NULL means quota was already at limit (no row updated)
END;
$$;
