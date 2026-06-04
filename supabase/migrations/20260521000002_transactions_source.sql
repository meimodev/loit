-- Canonical transaction origin column. Replaces the inferred
-- ai_parsed/is_manual_fallback duo at the display layer; those columns stay
-- for backward compatibility with existing flows.

alter table public.transactions
  add column if not exists source text;

alter table public.transactions
  drop constraint if exists transactions_source_check;
alter table public.transactions
  add constraint transactions_source_check
  check (source in ('manual', 'scanned', 'bot_image', 'bot_chat'));

-- Backfill from existing booleans:
--   ai_parsed = true  -> scanned
--   otherwise         -> manual
update public.transactions
   set source = case when ai_parsed = true then 'scanned' else 'manual' end
 where source is null;

alter table public.transactions
  alter column source set default 'manual';
alter table public.transactions
  alter column source set not null;
