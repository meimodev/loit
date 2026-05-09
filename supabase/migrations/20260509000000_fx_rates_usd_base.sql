-- ================================================================
-- FX rates: refactor from (base, target) pair table to USD-base only
-- ================================================================
-- Strategy: store only USD->X rates (one row per supported currency).
-- Cross-rates derived client-side: from->to = rate_per_usd[to] / rate_per_usd[from].
-- Refreshed every 3h by fx-rate-refresh edge fn (single OXR call returns all 63).
-- All existing transactions are test data; fx_rates rows are stale anyway.
-- ================================================================

DELETE FROM transactions;
TRUNCATE fx_rates;

ALTER TABLE fx_rates DROP CONSTRAINT fx_rates_pkey;
ALTER TABLE fx_rates DROP COLUMN base_currency;
ALTER TABLE fx_rates RENAME COLUMN target_currency TO currency;
ALTER TABLE fx_rates RENAME COLUMN rate TO rate_per_usd;
ALTER TABLE fx_rates ADD PRIMARY KEY (currency);
