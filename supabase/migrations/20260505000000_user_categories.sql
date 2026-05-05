-- ================================================================
-- USER_CATEGORIES TABLE
-- User-defined transaction categories with icon + tint customization.
-- Seeds 16 default categories per existing user.
-- Trigger seeds defaults for new users on signup.
-- ================================================================

CREATE TABLE user_categories (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id       uuid REFERENCES users(id) ON DELETE CASCADE,
  key           text NOT NULL,
  name          text NOT NULL,
  kind          text NOT NULL CHECK (kind IN ('expense', 'income')),
  icon_name     text,
  tint          text,
  sort_order    int NOT NULL DEFAULT 0,
  created_at    timestamptz DEFAULT now(),
  updated_at    timestamptz DEFAULT now(),
  UNIQUE(user_id, key),
  UNIQUE(user_id, name, kind)
);

-- RLS: users own their categories
ALTER TABLE user_categories ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users manage own categories" ON user_categories
  FOR ALL USING (auth.uid() = user_id);

-- Seed the 16 default categories for every existing user
INSERT INTO user_categories (user_id, key, name, kind, icon_name, tint, sort_order)
SELECT u.id, d.key, d.name, d.kind, d.icon_name, d.tint, d.sort_order
FROM users u
CROSS JOIN (VALUES
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
) d(key, name, kind, icon_name, tint, sort_order);

-- Trigger: seed default categories when a new user is created
CREATE OR REPLACE FUNCTION seed_default_categories()
RETURNS trigger AS $$
BEGIN
  INSERT INTO user_categories (user_id, key, name, kind, icon_name, tint, sort_order)
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
  ) d(key, name, kind, icon_name, tint, sort_order);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_seed_default_categories
  AFTER INSERT ON users
  FOR EACH ROW
  EXECUTE FUNCTION seed_default_categories();
