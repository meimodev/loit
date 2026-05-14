-- Harden the new-user seed triggers: qualify every reference with the
-- public schema and pin search_path. Triggers fire inside handle_new_user
-- (SECURITY DEFINER), and Supabase enforces an empty search_path on
-- SECURITY DEFINER paths, so unqualified names fail with "relation does
-- not exist".

CREATE OR REPLACE FUNCTION public.seed_default_categories()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.user_categories (user_id, key, name, kind, icon_name, tint, sort_order)
  SELECT NEW.id, d.key, d.name, d.kind, d.icon_name, d.tint, d.sort_order
  FROM (VALUES
    ('dining', 'Dining', 'expense', 'restaurant_outlined', '#F2A85C', 0),
    ('groceries', 'Groceries', 'expense', 'shopping_basket_outlined', '#2F8F5E', 1),
    ('transport', 'Transport', 'expense', 'directions_car_outlined', '#3E7AC5', 2),
    ('shopping', 'Shopping', 'expense', 'shopping_bag_outlined', '#B15FC0', 3),
    ('entertainment', 'Entertainment', 'expense', 'local_activity_outlined', '#E06B8A', 4),
    ('utilities', 'Utilities', 'expense', 'power_outlined', '#5A6160', 5),
    ('health', 'Health', 'expense', 'favorite_border', '#C5443E', 6),
    ('travel', 'Travel', 'expense', 'flight_outlined', '#188268', 7),
    ('other', 'Other', 'expense', 'more_horiz', '#9AA09E', 8),
    ('income_salary', 'Salary', 'income', 'work_outline', '#2F8F5E', 0),
    ('income_bonus', 'Bonus', 'income', 'card_giftcard', '#3CA876', 1),
    ('income_freelance', 'Freelance', 'income', 'handyman_outlined', '#188268', 2),
    ('income_investment', 'Investment', 'income', 'trending_up', '#4FA88B', 3),
    ('income_gift', 'Gift', 'income', 'redeem', '#B7CF8C', 4),
    ('income_refund', 'Refund', 'income', 'assignment_return_outlined', '#6EAA92', 5),
    ('income_other', 'Other income', 'income', 'savings_outlined', '#8FB7A6', 6)
  ) d(key, name, kind, icon_name, tint, sort_order)
  ON CONFLICT (user_id, key) DO NOTHING;
  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION public.seed_default_budgets()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = public
AS $$
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
$$;
