-- Per-user in-app notifications feed.
-- Edge Functions insert with service-role; users read/update only their own rows.

create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  kind text not null,
  title text not null,
  body text,
  deep_link text,
  metadata jsonb not null default '{}'::jsonb,
  read_at timestamptz,
  created_at timestamptz not null default now()
);

create index if not exists notifications_user_created_idx
  on public.notifications (user_id, created_at desc);

create index if not exists notifications_user_unread_idx
  on public.notifications (user_id) where read_at is null;

alter table public.notifications enable row level security;

drop policy if exists "user reads own notifications" on public.notifications;
create policy "user reads own notifications"
  on public.notifications for select
  using (auth.uid() = user_id);

drop policy if exists "user updates own notifications" on public.notifications;
create policy "user updates own notifications"
  on public.notifications for update
  using (auth.uid() = user_id);

drop policy if exists "user deletes own notifications" on public.notifications;
create policy "user deletes own notifications"
  on public.notifications for delete
  using (auth.uid() = user_id);

-- Realtime publication so client can subscribe to inserts/updates.
do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'notifications'
  ) then
    execute 'alter publication supabase_realtime add table public.notifications';
  end if;
end $$;
