-- ============================================================
-- Accounts table + transfer support for transactions
-- ============================================================

-- 1. accounts table
CREATE TABLE accounts (
  id                uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id           uuid        NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  name              text        NOT NULL,
  kind              text        NOT NULL CHECK (kind IN ('asset', 'liability')),
  currency          text        NOT NULL DEFAULT 'IDR',
  initial_balance   numeric     NOT NULL DEFAULT 0,
  icon              text,
  color             text,
  archived_at       timestamptz,
  client_updated_at timestamptz,
  updated_at        timestamptz NOT NULL DEFAULT now(),
  created_at        timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX accounts_user_active_idx ON accounts (user_id) WHERE archived_at IS NULL;
-- Case-insensitive uniqueness: 'Cash' and 'cash' are the same account name for a user.
CREATE UNIQUE INDEX accounts_name_lower_user_idx ON accounts (user_id, lower(name));

-- moddatetime trigger
CREATE TRIGGER accounts_updated_at
  BEFORE UPDATE ON accounts
  FOR EACH ROW EXECUTE FUNCTION moddatetime(updated_at);

-- RLS
ALTER TABLE accounts ENABLE ROW LEVEL SECURITY;

CREATE POLICY accounts_select_own ON accounts
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY accounts_insert_own ON accounts
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY accounts_update_own ON accounts
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY accounts_delete_own ON accounts
  FOR DELETE USING (auth.uid() = user_id);

-- 2. Backfill: create a default "Cash" account per existing user
INSERT INTO accounts (user_id, name, kind, currency, initial_balance)
SELECT id, 'Cash', 'asset', COALESCE(home_currency, 'IDR'), 0
FROM users
ON CONFLICT DO NOTHING;

-- 3. Add new columns to transactions
ALTER TABLE transactions
  ADD COLUMN IF NOT EXISTS type        text CHECK (type IN ('expense', 'income', 'transfer')) NOT NULL DEFAULT 'expense',
  ADD COLUMN IF NOT EXISTS account_id  uuid REFERENCES accounts(id) ON DELETE RESTRICT,
  ADD COLUMN IF NOT EXISTS to_account_id uuid REFERENCES accounts(id) ON DELETE RESTRICT;

-- Backfill type from amount sign for existing rows
UPDATE transactions
SET type = CASE WHEN amount < 0 THEN 'income' ELSE 'expense' END
WHERE type = 'expense';

-- Backfill account_id to the default Cash account for each user's existing rows
UPDATE transactions t
SET account_id = a.id
FROM accounts a
WHERE a.user_id = t.user_id
  AND a.name = 'Cash'
  AND t.account_id IS NULL;

-- Now enforce account_id NOT NULL (all rows are backfilled)
ALTER TABLE transactions ALTER COLUMN account_id SET NOT NULL;

-- Check constraints for transfer integrity
ALTER TABLE transactions
  ADD CONSTRAINT transactions_transfer_to_account_check
    CHECK ((type = 'transfer') = (to_account_id IS NOT NULL)),
  ADD CONSTRAINT transactions_no_self_transfer_check
    CHECK (account_id <> to_account_id OR to_account_id IS NULL);

-- 4. Indexes
CREATE INDEX transactions_user_account_idx ON transactions (user_id, account_id, created_at DESC);
CREATE INDEX transactions_account_created_idx ON transactions (account_id, created_at DESC);

-- 5. Extend handle_new_user to also create a default Cash account for new signups.
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
  INSERT INTO public.accounts (user_id, name, kind, currency, initial_balance)
  VALUES (NEW.id, 'Cash', 'asset', COALESCE(NEW.raw_user_meta_data->>'home_currency', 'IDR'), 0)
  ON CONFLICT DO NOTHING;
  RETURN NEW;
END;
$$;

-- 6. Trigger: enforce that account_id and to_account_id belong to the same user.
-- SECURITY DEFINER so the check bypasses RLS on accounts, allowing service-role
-- inserts (e.g. migrations, admin tools) to validate ownership correctly.
CREATE OR REPLACE FUNCTION enforce_transaction_account_ownership()
RETURNS trigger LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
  -- Verify account_id belongs to the transaction's user
  IF NOT EXISTS (
    SELECT 1 FROM accounts WHERE id = NEW.account_id AND user_id = NEW.user_id
  ) THEN
    RAISE EXCEPTION 'account_id does not belong to user';
  END IF;
  -- Verify to_account_id (when present) belongs to the same user
  IF NEW.to_account_id IS NOT NULL AND NOT EXISTS (
    SELECT 1 FROM accounts WHERE id = NEW.to_account_id AND user_id = NEW.user_id
  ) THEN
    RAISE EXCEPTION 'to_account_id does not belong to user';
  END IF;
  RETURN NEW;
END;
$$;

CREATE TRIGGER transactions_account_ownership
  BEFORE INSERT OR UPDATE ON transactions
  FOR EACH ROW EXECUTE FUNCTION enforce_transaction_account_ownership();
