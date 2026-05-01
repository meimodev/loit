-- Drop the recurring_bills feature entirely. Replaced by manual transaction
-- entry (income + expense). Cron runner `recurring-bills-cron` is also being
-- removed; deploy will fail to find the table after this migration is applied,
-- so unschedule the cron and remove the function before deploying.

drop table if exists public.recurring_bills cascade;
