-- Update gate (ADR-0015): a single public-read row holding three semantic-version
-- thresholds the client compares against its own versionName. The client keys on
-- the semver string, NOT the build number (CI overrides versionCode with a
-- timestamp, so the build number is unknowable ahead of a release).
--
--   versionName < min          -> Blocked    (non-dismissible, breaking releases)
--   min <= versionName < rec   -> Recommended (nag every launch, dismissible)
--   rec <= versionName < latest -> Optional   (prompt once, then passive marker)
--   versionName >= latest      -> Current     (no prompt)
--
-- Thresholds are set by CI from the release git tag (ADR-0015): a plain `v*` tag
-- bumps `latest`, `-recommended` cascades `recommended`+`latest`, `-breaking`
-- cascades `min`+`recommended`+`latest`. The CI step upserts via PostgREST with
-- the service-role key; the invariant min <= recommended <= latest is preserved
-- by the cascade, not enforced here.

CREATE TABLE IF NOT EXISTS app_release_gate (
  id                   smallint PRIMARY KEY DEFAULT 1,
  -- Lowest version still allowed to run. Below this => Blocked.
  min_version          text NOT NULL DEFAULT '0.0.0',
  -- At/above min but below this => Recommended (nag every launch).
  recommended_version  text NOT NULL DEFAULT '0.0.0',
  -- Newest shipped version. Below this (but at/above recommended) => Optional.
  latest_version       text NOT NULL DEFAULT '0.0.0',
  -- Play Store deep link used as the fallback when the in-app update flow
  -- reports nothing available on-device.
  store_url            text NOT NULL
                         DEFAULT 'https://play.google.com/store/apps/details?id=id.activid.loit',
  updated_at           timestamptz NOT NULL DEFAULT now(),
  -- Pin to a single row: id is always 1.
  CONSTRAINT app_release_gate_singleton CHECK (id = 1)
);

-- Seed the singleton row. Defaults of 0.0.0 mean "gate open" (every client is
-- Current) until CI or an operator sets real thresholds.
INSERT INTO app_release_gate (id) VALUES (1)
  ON CONFLICT (id) DO NOTHING;

-- Public read: the gate must be checkable before sign-in (the Blocked overlay
-- can sit above the auth flow). No client ever writes it.
ALTER TABLE app_release_gate ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS app_release_gate_read ON app_release_gate;
CREATE POLICY app_release_gate_read ON app_release_gate
  FOR SELECT USING (true);

GRANT SELECT ON app_release_gate TO anon, authenticated;
