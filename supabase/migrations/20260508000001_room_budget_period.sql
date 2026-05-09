-- Mirror of personal budgets period support, applied to room_budgets.
alter table public.room_budgets
  add column if not exists period text not null default 'monthly',
  add column if not exists reset_day int not null default 1,
  add column if not exists custom_days int;

alter table public.room_budgets
  drop constraint if exists room_budgets_period_check;
alter table public.room_budgets
  add constraint room_budgets_period_check
  check (period in ('weekly','monthly','yearly','custom'));

alter table public.room_budgets
  drop constraint if exists room_budgets_reset_day_check;
alter table public.room_budgets
  add constraint room_budgets_reset_day_check check (
    (period = 'weekly'  and reset_day between 1 and 7) or
    (period = 'monthly' and reset_day between 0 and 28) or
    (period = 'yearly'  and reset_day between 1 and 12) or
    (period = 'custom')
  );

alter table public.room_budgets
  drop constraint if exists room_budgets_custom_days_check;
alter table public.room_budgets
  add constraint room_budgets_custom_days_check check (
    (period <> 'custom') or (custom_days is not null and custom_days between 1 and 365)
  );
