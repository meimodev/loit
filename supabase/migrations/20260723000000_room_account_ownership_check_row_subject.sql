-- ADR-0032: enforce_transaction_account_ownership() must validate the ROW's
-- subject (NEW.user_id), not the session actor (auth.uid()).
--
-- Bug: room transactions submitted through any SERVICE-ROLE writer — the
-- Telegram bot (telegram_text/voice/image), parse-voice, scan-receipt — were
-- rejected by this BEFORE INSERT trigger. The room-account branch called
-- is_room_member(v_room_id), which resolves membership against auth.uid().
-- Under service role auth.uid() is NULL, so the check returned false and the
-- insert raised 'account_id is a room account the user cannot access'. The
-- Telegram pipeline surfaced this as "transaksi tidak ditemukan".
--
-- Fix: check that NEW.user_id (the transaction's owner) is a member of the room
-- that owns the account, via an inline EXISTS. This is the correct invariant —
-- ownership is a property of the row, not of whoever executes the insert. No
-- client regression: RLS already forces NEW.user_id = auth.uid() on client
-- writes, so the two checks are equivalent there. is_room_member() is left
-- unchanged; it is still correct for RLS policies, which run as the end user.

create or replace function public.enforce_transaction_account_ownership()
returns trigger
language plpgsql
security definer
set search_path to 'public', 'pg_temp'
as $function$
declare
  v_user_id uuid;
  v_room_id uuid;
begin
  -- account_id leg (always present)
  select user_id, room_id into v_user_id, v_room_id
    from accounts where id = new.account_id;
  if not found then
    raise exception 'account_id does not exist';
  end if;
  if v_room_id is not null then
    if not exists (
      select 1 from room_members
      where room_id = v_room_id and user_id = new.user_id
    ) then
      raise exception 'account_id is a room account the user cannot access';
    end if;
    if new.room_id is distinct from v_room_id then
      raise exception 'transaction room_id must match the room account';
    end if;
  elsif v_user_id <> new.user_id then
    raise exception 'account_id does not belong to user';
  end if;

  -- to_account_id leg (transfers only)
  if new.to_account_id is not null then
    select user_id, room_id into v_user_id, v_room_id
      from accounts where id = new.to_account_id;
    if not found then
      raise exception 'to_account_id does not exist';
    end if;
    if v_room_id is not null then
      if not exists (
        select 1 from room_members
        where room_id = v_room_id and user_id = new.user_id
      ) then
        raise exception 'to_account_id is a room account the user cannot access';
      end if;
      if new.room_id is distinct from v_room_id then
        raise exception 'transaction room_id must match the room account';
      end if;
    elsif v_user_id <> new.user_id then
      raise exception 'to_account_id does not belong to user';
    end if;
  end if;

  return new;
end;
$function$;
