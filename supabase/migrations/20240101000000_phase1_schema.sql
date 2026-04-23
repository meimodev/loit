-- ================================================================
-- USERS TABLE
-- ================================================================
CREATE TABLE users (
  id                    uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  email                 text UNIQUE NOT NULL,
  name                  text NOT NULL,
  avatar_url            text,
  home_currency         text DEFAULT 'IDR',
  tier                  text DEFAULT 'free' CHECK (tier IN ('free', 'pro', 'team')),
  scans_used_this_month int DEFAULT 0,
  -- Use timestamptz (not date) to avoid timezone edge cases at month boundary
  -- (e.g. Dec 31 23:59 UTC+7 is Jan 1 in UTC — date type would mishandle this)
  scan_reset_date       timestamptz DEFAULT date_trunc('month', now()),
  has_used_demo_scan    boolean DEFAULT false,
  created_at            timestamptz DEFAULT now()
);

-- ================================================================
-- TRANSACTIONS TABLE
-- ================================================================
CREATE TABLE transactions (
  id                   uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id              uuid REFERENCES users(id) ON DELETE CASCADE,
  room_id              uuid,  -- FK to rooms added via ALTER TABLE in Phase 2 migration
  merchant             text,
  amount               numeric NOT NULL,
  currency             text NOT NULL,
  amount_home_currency numeric,
  fx_rate              numeric,
  category             text,
  notes                text,
  receipt_url          text,    -- Stores storage path (not signed URL); re-sign on each view
  receipt_expires_at   timestamptz,
  ai_parsed            boolean DEFAULT false,
  is_manual_fallback   boolean DEFAULT false,
  -- Set by Flutter client at moment of save; used for offline conflict resolution
  client_updated_at    timestamptz,
  -- Managed by moddatetime trigger; server-side conflict resolution wins over older client_updated_at
  updated_at           timestamptz DEFAULT now(),
  created_at           timestamptz DEFAULT now()
);

-- Auto-update updated_at on every row UPDATE
CREATE TRIGGER set_transactions_updated_at
  BEFORE UPDATE ON transactions
  FOR EACH ROW
  EXECUTE FUNCTION moddatetime(updated_at);

-- ================================================================
-- TRANSACTION ITEMS TABLE
-- Line items extracted by AI scanner (name, qty, unit_price, total_price).
-- Stored alongside each scanned transaction for future feature use.
-- ================================================================
CREATE TABLE transaction_items (
  id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  transaction_id uuid REFERENCES transactions(id) ON DELETE CASCADE NOT NULL,
  name           text NOT NULL,
  qty            numeric DEFAULT 1,
  unit_price     numeric,
  total_price    numeric,
  created_at     timestamptz DEFAULT now()
);

-- ================================================================
-- BUDGETS TABLE
-- ================================================================
CREATE TABLE budgets (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id       uuid REFERENCES users(id) ON DELETE CASCADE,
  category      text NOT NULL,
  monthly_limit numeric NOT NULL,
  created_at    timestamptz DEFAULT now(),
  UNIQUE(user_id, category)
);

-- ================================================================
-- FX RATES CACHE TABLE
-- Staleness is tier-aware (checked in currency_service.dart):
--   Free tier (Frankfurter):          stale after 25 hours
--   Pro/Team tier (Open Exchange Rates): stale after 35 minutes
-- If provider is unreachable, stale cached rate is used with
-- "Rates may be outdated" label shown in UI.
-- ================================================================
CREATE TABLE fx_rates (
  base_currency   text NOT NULL,
  target_currency text NOT NULL,
  rate            numeric NOT NULL,
  fetched_at      timestamptz DEFAULT now(),
  PRIMARY KEY (base_currency, target_currency)
);

-- ================================================================
-- AUTO-CREATE PUBLIC USER ROW ON AUTH SIGNUP
-- Mirrors auth.users → public.users automatically.
-- ================================================================
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  INSERT INTO public.users (id, email, name, avatar_url)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'full_name', split_part(NEW.email, '@', 1)),
    NEW.raw_user_meta_data->>'avatar_url'
  );
  RETURN NEW;
END;
$$;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION handle_new_user();

-- ================================================================
-- PERFORMANCE INDEXES
-- The most common query patterns are:
--   1. "list my transactions, newest first"            → (user_id, created_at DESC)
--   2. "list transactions in a room, newest first"     → (room_id, created_at DESC)
--   3. "find transaction by id with items"             → FK on transaction_items already covers it
--   4. "my budget for a category"                      → UNIQUE(user_id, category) already covers it
-- Partial index on room_id skips the ~90% of rows that have room_id = NULL
-- (personal-only transactions), keeping the room index small and fast.
-- ================================================================
CREATE INDEX idx_transactions_user_created
  ON transactions (user_id, created_at DESC);

CREATE INDEX idx_transactions_room_created
  ON transactions (room_id, created_at DESC)
  WHERE room_id IS NOT NULL;

CREATE INDEX idx_transactions_receipt_expiry
  ON transactions (receipt_expires_at)
  WHERE receipt_url IS NOT NULL;  -- used by receipt-expiry-cron (Phase 3)

CREATE INDEX idx_transaction_items_txn
  ON transaction_items (transaction_id);
