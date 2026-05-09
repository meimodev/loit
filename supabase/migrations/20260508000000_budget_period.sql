-- Budget period + reset anchor.
-- period: 'weekly' | 'monthly' | 'yearly' | 'custom'
-- reset_day:
--   weekly  -> 1..7 (1=Mon, 7=Sun)
--   monthly -> 1..28, or 0 = last day of month
--   yearly  -> 1..12 (resets on day 1 of that month)
--   custom  -> unused
-- custom_days: cycle length in days when period='custom'
alter table public.budgets
  add column if not exists period text not null default 'monthly',
  add column if not exists reset_day int not null default 1,
  add column if not exists custom_days int;

alter table public.budgets
  drop constraint if exists budgets_period_check;
alter table public.budgets
  add constraint budgets_period_check
  check (period in ('weekly','monthly','yearly','custom'));

alter table public.budgets
  drop constraint if exists budgets_reset_day_check;
alter table public.budgets
  add constraint budgets_reset_day_check check (
    (period = 'weekly'  and reset_day between 1 and 7) or
    (period = 'monthly' and reset_day between 0 and 28) or
    (period = 'yearly'  and reset_day between 1 and 12) or
    (period = 'custom')
  );

alter table public.budgets
  drop constraint if exists budgets_custom_days_check;
alter table public.budgets
  add constraint budgets_custom_days_check check (
    (period <> 'custom') or (custom_days is not null and custom_days between 1 and 365)
  );
