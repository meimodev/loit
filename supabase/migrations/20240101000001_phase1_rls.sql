-- Enable RLS on all Phase 1 tables
ALTER TABLE users             ENABLE ROW LEVEL SECURITY;
ALTER TABLE transactions      ENABLE ROW LEVEL SECURITY;
ALTER TABLE transaction_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE budgets           ENABLE ROW LEVEL SECURITY;
ALTER TABLE fx_rates          ENABLE ROW LEVEL SECURITY;

-- ----------------------------------------------------------------
-- USERS
-- ----------------------------------------------------------------
CREATE POLICY "users_select_own" ON users
  FOR SELECT USING (auth.uid() = id);

CREATE POLICY "users_update_own" ON users
  FOR UPDATE USING (auth.uid() = id);

-- ----------------------------------------------------------------
-- TRANSACTIONS (personal only — extended in Phase 2 for rooms)
-- ----------------------------------------------------------------
CREATE POLICY "transactions_select_own" ON transactions
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "transactions_insert_own" ON transactions
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "transactions_update_own" ON transactions
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "transactions_delete_own" ON transactions
  FOR DELETE USING (auth.uid() = user_id);

-- ----------------------------------------------------------------
-- TRANSACTION ITEMS (accessible if parent transaction is owned by user)
-- ----------------------------------------------------------------
CREATE POLICY "items_select_own" ON transaction_items
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM transactions t
      WHERE t.id = transaction_id AND t.user_id = auth.uid()
    )
  );

CREATE POLICY "items_insert_own" ON transaction_items
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM transactions t
      WHERE t.id = transaction_id AND t.user_id = auth.uid()
    )
  );

CREATE POLICY "items_delete_own" ON transaction_items
  FOR DELETE USING (
    EXISTS (
      SELECT 1 FROM transactions t
      WHERE t.id = transaction_id AND t.user_id = auth.uid()
    )
  );

-- ----------------------------------------------------------------
-- BUDGETS
-- ----------------------------------------------------------------
CREATE POLICY "budgets_select_own" ON budgets
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "budgets_insert_own" ON budgets
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "budgets_update_own" ON budgets
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "budgets_delete_own" ON budgets
  FOR DELETE USING (auth.uid() = user_id);

-- ----------------------------------------------------------------
-- FX RATES (all authenticated users can read; only service role writes)
-- ----------------------------------------------------------------
CREATE POLICY "fx_rates_select_all" ON fx_rates
  FOR SELECT USING (auth.role() = 'authenticated');
