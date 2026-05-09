-- Add language preference column to users table for server-side i18n.
-- Populated by the client's setLanguage write-through.
alter table public.users
  add column if not exists language text not null default 'en'
  check (language in ('en', 'id'));
