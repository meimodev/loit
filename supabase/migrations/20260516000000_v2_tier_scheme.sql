-- v2 scanner pipeline tier scheme: Free 5 / Lite 30 / Pro 150 scans/month.
--
-- Drops `team` tier entirely. Existing `team` users land on `pro` (with the
-- new 150 cap). Adds `lite` tier between free and pro. Pro is no longer
-- unlimited — the new client enforces 150/mo via FeatureFlags.scanLimitPerMonth.
--
-- The Drop-team-add-Lite decision was made explicitly with the user; Pro cap
-- rollout is immediate (no grandfathering).

BEGIN;

-- Migrate any Team users to Pro before relaxing/tightening the CHECK constraint.
UPDATE users SET tier = 'pro' WHERE tier = 'team';

-- Swap CHECK constraint. Postgres uses a name like `users_tier_check` for
-- inline column-level CHECKs; drop by name and recreate.
ALTER TABLE users DROP CONSTRAINT IF EXISTS users_tier_check;
ALTER TABLE users
  ADD CONSTRAINT users_tier_check
  CHECK (tier IN ('free', 'lite', 'pro'));

COMMIT;
