-- ================================================================
-- transactions: replace per-row scalar fx fields with a frozen jsonb
-- snapshot of rates from txn currency to all supported currencies.
-- ================================================================
-- Shape: {"USD": 15800.0, "EUR": 17200.0, ..., "<txn currency>": 1.0}
-- Frozen at create time. Home-currency switch reads snapshot, no refetch.
-- Existing transactions were deleted in the prior migration, so the new
-- NOT NULL column applies cleanly.
-- ================================================================

ALTER TABLE transactions ADD COLUMN fx_snapshot jsonb NOT NULL DEFAULT '{}'::jsonb;
ALTER TABLE transactions ALTER COLUMN fx_snapshot DROP DEFAULT;

ALTER TABLE transactions DROP COLUMN fx_rate;
ALTER TABLE transactions DROP COLUMN amount_home_currency;

COMMENT ON COLUMN transactions.fx_snapshot IS
  'Frozen FX rates from txn currency to all supported currencies at create time. Keys = ISO code, values = 1 unit txn currency in target.';
