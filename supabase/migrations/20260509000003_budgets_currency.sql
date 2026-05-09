-- ================================================================
-- budgets.currency: budgets are denominated in their own currency,
-- independent of the user's current home currency.
-- ================================================================
-- Without this, switching home currency would silently reinterpret a
-- budget's monthly_limit value (confusing UX). With it, budget UI shows
-- the limit in its native currency plus an "≈ X home" converted line.
-- room_budgets already has a currency column.
-- ================================================================

ALTER TABLE budgets ADD COLUMN currency text NOT NULL DEFAULT 'IDR';

UPDATE budgets b
   SET currency = u.home_currency
  FROM users u
 WHERE b.user_id = u.id
   AND u.home_currency IS NOT NULL;

ALTER TABLE budgets ALTER COLUMN currency DROP DEFAULT;
