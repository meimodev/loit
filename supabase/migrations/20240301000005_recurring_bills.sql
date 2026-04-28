-- Phase 3 Step 3.7: recurring bills (Pro/Team).
-- Daily cron `recurring-bills-cron` materializes a draft transaction on
-- each row's next_due_date and advances it by the chosen frequency.
CREATE TABLE IF NOT EXISTS public.recurring_bills (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id       uuid NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  merchant      text,
  amount        numeric NOT NULL CHECK (amount > 0),
  currency      text NOT NULL,
  category      text,
  frequency     text NOT NULL CHECK (frequency IN ('weekly','monthly','yearly')),
  next_due_date date NOT NULL,
  is_active     boolean NOT NULL DEFAULT true,
  created_at    timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_recurring_bills_due
  ON public.recurring_bills (next_due_date)
  WHERE is_active = true;

CREATE INDEX IF NOT EXISTS idx_recurring_bills_user
  ON public.recurring_bills (user_id);

ALTER TABLE public.recurring_bills ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "recurring_bills_select_own" ON public.recurring_bills;
CREATE POLICY "recurring_bills_select_own" ON public.recurring_bills
  FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "recurring_bills_insert_own" ON public.recurring_bills;
CREATE POLICY "recurring_bills_insert_own" ON public.recurring_bills
  FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "recurring_bills_update_own" ON public.recurring_bills;
CREATE POLICY "recurring_bills_update_own" ON public.recurring_bills
  FOR UPDATE USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "recurring_bills_delete_own" ON public.recurring_bills;
CREATE POLICY "recurring_bills_delete_own" ON public.recurring_bills
  FOR DELETE USING (auth.uid() = user_id);
