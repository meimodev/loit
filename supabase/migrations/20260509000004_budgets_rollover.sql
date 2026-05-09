-- One-shot rollover: when a budget is over its limit, the user can
-- carry the overspend amount as a penalty into the next cycle. The
-- penalty is consumed exactly once and reduces the effective limit
-- only while the next-cycle window is active.
alter table public.budgets
  add column if not exists rollover_amount numeric not null default 0,
  add column if not exists rollover_cycle_start timestamptz;

comment on column public.budgets.rollover_amount is
  'Penalty amount in budget currency to deduct from limit during rollover_cycle_start window.';
comment on column public.budgets.rollover_cycle_start is
  'Cycle window start the rollover applies to. Cleared once consumed.';
