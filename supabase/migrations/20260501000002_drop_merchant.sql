-- Drop merchant column from transactions. Title for tx cards is derived from
-- notes. Scanner output maps merchant string into the notes field client-side.

alter table public.transactions drop column if exists merchant;
