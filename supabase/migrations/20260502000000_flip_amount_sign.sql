-- Flip stored amount sign convention.
-- Before: income < 0, expense > 0.
-- After:  income > 0, expense < 0. Transfers unchanged (positive magnitude;
--         direction encoded by from/to account ids).

update public.transactions
set amount = -amount,
    amount_home_currency = case
      when amount_home_currency is null then null
      else -amount_home_currency
    end
where type in ('income', 'expense');
