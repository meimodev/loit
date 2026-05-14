-- ================================================================
-- Adds users.has_seen_rooms_intro flag + extends the new-user trigger
-- to seed 3 default monthly budgets (Dining/Transport/Shopping)
-- at IDR 1,000,000 each, period=monthly, reset_day=1.
-- Category seeding stays in seed_default_categories() (unchanged).
-- ================================================================

ALTER TABLE public.users
  ADD COLUMN IF NOT EXISTS has_seen_rooms_intro boolean NOT NULL DEFAULT false;

CREATE OR REPLACE FUNCTION seed_default_budgets()
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.budgets (
    user_id, category, monthly_limit, currency,
    period, reset_day, rollover_amount
  )
  VALUES
    (NEW.id, 'dining',    1000000, 'IDR', 'monthly', 1, 0),
    (NEW.id, 'transport', 1000000, 'IDR', 'monthly', 1, 0),
    (NEW.id, 'shopping',  1000000, 'IDR', 'monthly', 1, 0)
  ON CONFLICT (user_id, category) DO NOTHING;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_seed_default_budgets ON public.users;
CREATE TRIGGER trg_seed_default_budgets
  AFTER INSERT ON public.users
  FOR EACH ROW
  EXECUTE FUNCTION seed_default_budgets();
