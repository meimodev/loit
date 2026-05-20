-- ============================================================
-- Messaging pipeline foundation (Telegram first, platform-neutral)
-- ============================================================
-- Adds tables for external chat linking, link codes, pending parsed
-- transactions, undo tokens, rate limiting, and edit sessions. Adds
-- transactions to the supabase_realtime publication so the personal
-- feed picks up bot-originated writes. Adds a true scan quota refund
-- RPC, plus a security-definer disconnect RPC the app calls.
-- ============================================================

BEGIN;

-- ---------------------------------------------------------------
-- 1. user_messaging_links — maps LOIT user to many external chats
-- ---------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.user_messaging_links (
  id                       uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id                  uuid        NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  platform                 text        NOT NULL CHECK (platform IN ('telegram', 'whatsapp')),
  external_chat_id         text        NOT NULL,
  metadata                 jsonb       NOT NULL DEFAULT '{}'::jsonb,
  linked_at                timestamptz NOT NULL DEFAULT now(),
  last_used_at             timestamptz,
  disclosure_accepted_at   timestamptz NOT NULL DEFAULT now()
);

CREATE UNIQUE INDEX IF NOT EXISTS user_messaging_links_platform_chat_idx
  ON public.user_messaging_links (platform, external_chat_id);

CREATE INDEX IF NOT EXISTS user_messaging_links_user_idx
  ON public.user_messaging_links (user_id, platform);

ALTER TABLE public.user_messaging_links ENABLE ROW LEVEL SECURITY;

CREATE POLICY user_messaging_links_select_own ON public.user_messaging_links
  FOR SELECT USING (auth.uid() = user_id);

-- Writes go through security-definer RPCs / Edge Functions; no client
-- INSERT/UPDATE/DELETE policies on purpose.

-- ---------------------------------------------------------------
-- 2. messaging_link_codes — short-lived hashed link codes
-- ---------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.messaging_link_codes (
  id            uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id       uuid        NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  platform      text        NOT NULL CHECK (platform IN ('telegram', 'whatsapp')),
  code_hash     text        NOT NULL,
  expires_at    timestamptz NOT NULL,
  consumed_at   timestamptz,
  created_at    timestamptz NOT NULL DEFAULT now()
);

CREATE UNIQUE INDEX IF NOT EXISTS messaging_link_codes_hash_idx
  ON public.messaging_link_codes (platform, code_hash);

CREATE INDEX IF NOT EXISTS messaging_link_codes_user_idx
  ON public.messaging_link_codes (user_id, platform, expires_at);

ALTER TABLE public.messaging_link_codes ENABLE ROW LEVEL SECURITY;

CREATE POLICY messaging_link_codes_select_own ON public.messaging_link_codes
  FOR SELECT USING (auth.uid() = user_id);

-- ---------------------------------------------------------------
-- 3. bot_pending_transactions — low-confidence parse holding pen
-- ---------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.bot_pending_transactions (
  id                 uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id            uuid        NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  platform           text        NOT NULL,
  external_chat_id   text        NOT NULL,
  bot_message_id     text,
  payload            jsonb       NOT NULL,
  confidence         numeric,
  state              text        NOT NULL DEFAULT 'awaiting_user',
  expires_at         timestamptz NOT NULL DEFAULT (now() + interval '24 hours'),
  created_at         timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS bot_pending_transactions_chat_idx
  ON public.bot_pending_transactions (platform, external_chat_id, created_at DESC);
CREATE INDEX IF NOT EXISTS bot_pending_transactions_expires_idx
  ON public.bot_pending_transactions (expires_at);

ALTER TABLE public.bot_pending_transactions ENABLE ROW LEVEL SECURITY;
CREATE POLICY bot_pending_select_own ON public.bot_pending_transactions
  FOR SELECT USING (auth.uid() = user_id);

-- ---------------------------------------------------------------
-- 4. bot_transaction_undo_tokens — short-lived undo handles
-- ---------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.bot_transaction_undo_tokens (
  id                  uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id             uuid        NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  transaction_id      uuid        NOT NULL REFERENCES public.transactions(id) ON DELETE CASCADE,
  platform            text        NOT NULL,
  external_chat_id    text        NOT NULL,
  bot_message_id      text,
  scope               text        NOT NULL CHECK (scope IN ('personal', 'room')),
  room_id             uuid        REFERENCES public.rooms(id) ON DELETE CASCADE,
  expires_at          timestamptz NOT NULL,
  created_at          timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS bot_undo_tokens_chat_idx
  ON public.bot_transaction_undo_tokens (platform, external_chat_id, created_at DESC);
CREATE INDEX IF NOT EXISTS bot_undo_tokens_expires_idx
  ON public.bot_transaction_undo_tokens (expires_at);
CREATE INDEX IF NOT EXISTS bot_undo_tokens_txn_idx
  ON public.bot_transaction_undo_tokens (transaction_id);

ALTER TABLE public.bot_transaction_undo_tokens ENABLE ROW LEVEL SECURITY;
CREATE POLICY bot_undo_select_own ON public.bot_transaction_undo_tokens
  FOR SELECT USING (auth.uid() = user_id);

-- ---------------------------------------------------------------
-- 5. bot_rate_limit_events — rolling-window source
-- ---------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.bot_rate_limit_events (
  id                bigserial    PRIMARY KEY,
  platform          text         NOT NULL,
  external_chat_id  text         NOT NULL,
  user_id           uuid         REFERENCES public.users(id) ON DELETE SET NULL,
  event_at          timestamptz  NOT NULL DEFAULT now(),
  warned            boolean      NOT NULL DEFAULT false
);

CREATE INDEX IF NOT EXISTS bot_rate_limit_events_chat_time_idx
  ON public.bot_rate_limit_events (platform, external_chat_id, event_at DESC);
CREATE INDEX IF NOT EXISTS bot_rate_limit_events_event_at_idx
  ON public.bot_rate_limit_events (event_at);

ALTER TABLE public.bot_rate_limit_events ENABLE ROW LEVEL SECURITY;
-- Server-only. No client policies.

-- ---------------------------------------------------------------
-- 6. bot_edit_sessions — multi-turn edit state
-- ---------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.bot_edit_sessions (
  id                 uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id            uuid        NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  platform           text        NOT NULL,
  external_chat_id   text        NOT NULL,
  transaction_id     uuid        REFERENCES public.transactions(id) ON DELETE CASCADE,
  awaiting_field     text        NOT NULL,
  context            jsonb       NOT NULL DEFAULT '{}'::jsonb,
  bot_message_id     text,
  expires_at         timestamptz NOT NULL DEFAULT (now() + interval '15 minutes'),
  created_at         timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS bot_edit_sessions_chat_idx
  ON public.bot_edit_sessions (platform, external_chat_id, created_at DESC);
CREATE INDEX IF NOT EXISTS bot_edit_sessions_expires_idx
  ON public.bot_edit_sessions (expires_at);

ALTER TABLE public.bot_edit_sessions ENABLE ROW LEVEL SECURITY;
CREATE POLICY bot_edit_sessions_select_own ON public.bot_edit_sessions
  FOR SELECT USING (auth.uid() = user_id);

-- ---------------------------------------------------------------
-- 7. Realtime publication for personal transactions feed
-- ---------------------------------------------------------------
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime'
      AND schemaname = 'public'
      AND tablename = 'transactions'
  ) THEN
    EXECUTE 'ALTER PUBLICATION supabase_realtime ADD TABLE public.transactions';
  END IF;
END $$;

-- ---------------------------------------------------------------
-- 8. refund_scan_quota — true decrement, floored at zero
-- ---------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.refund_scan_quota(p_user_id uuid)
RETURNS int LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  new_count int;
BEGIN
  UPDATE public.users
  SET scans_used_this_month = GREATEST(scans_used_this_month - 1, 0)
  WHERE id = p_user_id
  RETURNING scans_used_this_month INTO new_count;

  RETURN new_count;
END;
$$;

-- ---------------------------------------------------------------
-- 9. generate_telegram_link_code — issues a one-time code
--    Returns the raw code; only hashed form is stored.
-- ---------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.generate_telegram_link_code()
RETURNS text LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_user_id   uuid := auth.uid();
  v_raw_code  text;
  v_hash      text;
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'not authenticated';
  END IF;

  -- 64-bit random, base32-ish — short, URL-safe.
  v_raw_code := lower(encode(gen_random_bytes(12), 'hex'));
  v_hash     := encode(digest(v_raw_code, 'sha256'), 'hex');

  -- Invalidate any older outstanding telegram codes for this user.
  UPDATE public.messaging_link_codes
  SET consumed_at = now()
  WHERE user_id = v_user_id
    AND platform = 'telegram'
    AND consumed_at IS NULL
    AND expires_at > now();

  INSERT INTO public.messaging_link_codes (user_id, platform, code_hash, expires_at)
  VALUES (v_user_id, 'telegram', v_hash, now() + interval '15 minutes');

  RETURN v_raw_code;
END;
$$;

-- pgcrypto provides gen_random_bytes / digest; ensure it's enabled.
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- ---------------------------------------------------------------
-- 10. check_messaging_link_status — app polls this after issuing code
-- ---------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.check_messaging_link_status(p_platform text)
RETURNS TABLE (
  linked            boolean,
  external_chat_id  text,
  linked_at         timestamptz
) LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_user_id uuid := auth.uid();
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'not authenticated';
  END IF;

  RETURN QUERY
  SELECT TRUE, l.external_chat_id, l.linked_at
  FROM public.user_messaging_links l
  WHERE l.user_id = v_user_id AND l.platform = p_platform
  ORDER BY l.linked_at DESC
  LIMIT 1;

  IF NOT FOUND THEN
    RETURN QUERY SELECT FALSE, NULL::text, NULL::timestamptz;
  END IF;
END;
$$;

-- ---------------------------------------------------------------
-- 11. disconnect_messaging_link — app calls to remove a link
-- ---------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.disconnect_messaging_link(p_platform text)
RETURNS int LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_user_id uuid := auth.uid();
  v_removed int;
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'not authenticated';
  END IF;

  WITH del AS (
    DELETE FROM public.user_messaging_links
    WHERE user_id = v_user_id AND platform = p_platform
    RETURNING 1
  )
  SELECT count(*) INTO v_removed FROM del;

  RETURN v_removed;
END;
$$;

GRANT EXECUTE ON FUNCTION public.generate_telegram_link_code() TO authenticated;
GRANT EXECUTE ON FUNCTION public.check_messaging_link_status(text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.disconnect_messaging_link(text) TO authenticated;
-- refund_scan_quota called by Edge Functions (service role); no anon grant.

-- ---------------------------------------------------------------
-- 12. Cleanup function — hourly via pg_cron in a follow-up wiring step.
-- ---------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.cleanup_messaging_state()
RETURNS void LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  DELETE FROM public.bot_pending_transactions   WHERE expires_at < now();
  DELETE FROM public.bot_transaction_undo_tokens WHERE expires_at < now();
  DELETE FROM public.messaging_link_codes
    WHERE (expires_at < now()) OR (consumed_at IS NOT NULL AND consumed_at < now() - interval '7 days');
  DELETE FROM public.bot_edit_sessions          WHERE expires_at < now();
  DELETE FROM public.bot_rate_limit_events      WHERE event_at < now() - interval '24 hours';
END;
$$;

COMMIT;
