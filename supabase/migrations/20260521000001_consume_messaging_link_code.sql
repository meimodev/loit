-- ============================================================
-- Atomic link-code consumption + chat-owner replacement
-- ============================================================
-- Previously the Edge Function ran code validation, previous-user
-- cleanup, link upsert, and code consumption as four separate
-- Supabase calls. A failure after the previous user's link was
-- deleted but before the new link upsert committed could leave
-- the chat orphaned. This RPC executes the whole sequence in a
-- single transaction so the prior link is only torn down when the
-- new link row and code consumption commit together.
-- ============================================================

BEGIN;

CREATE OR REPLACE FUNCTION public.consume_messaging_link_code(
  p_platform          text,
  p_raw_code          text,
  p_external_chat_id  text,
  p_metadata          jsonb
)
RETURNS uuid LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_hash              text;
  v_now               timestamptz := now();
  v_code_id           uuid;
  v_code_user_id      uuid;
  v_expires_at        timestamptz;
  v_consumed_at       timestamptz;
  v_existing_user_id  uuid;
BEGIN
  IF p_platform IS NULL OR p_raw_code IS NULL OR p_external_chat_id IS NULL THEN
    RETURN NULL;
  END IF;

  v_hash := encode(digest(p_raw_code, 'sha256'), 'hex');

  -- Lock the code row so concurrent consumers can't double-spend.
  SELECT id, user_id, expires_at, consumed_at
    INTO v_code_id, v_code_user_id, v_expires_at, v_consumed_at
  FROM public.messaging_link_codes
  WHERE platform = p_platform AND code_hash = v_hash
  FOR UPDATE;

  IF v_code_id IS NULL THEN
    RETURN NULL;
  END IF;
  IF v_consumed_at IS NOT NULL THEN
    RETURN NULL;
  END IF;
  IF v_expires_at < v_now THEN
    RETURN NULL;
  END IF;

  -- If the chat is already linked to a different user, tear down that
  -- previous owner's bot-scoped state inside the same transaction.
  SELECT user_id
    INTO v_existing_user_id
  FROM public.user_messaging_links
  WHERE platform = p_platform AND external_chat_id = p_external_chat_id
  FOR UPDATE;

  IF v_existing_user_id IS NOT NULL AND v_existing_user_id <> v_code_user_id THEN
    DELETE FROM public.bot_pending_transactions
    WHERE platform = p_platform
      AND external_chat_id = p_external_chat_id
      AND user_id = v_existing_user_id;

    DELETE FROM public.bot_edit_sessions
    WHERE platform = p_platform
      AND external_chat_id = p_external_chat_id
      AND user_id = v_existing_user_id;

    DELETE FROM public.bot_transaction_undo_tokens
    WHERE platform = p_platform
      AND external_chat_id = p_external_chat_id
      AND user_id = v_existing_user_id;

    UPDATE public.messaging_link_codes
    SET consumed_at = v_now
    WHERE platform = p_platform
      AND user_id = v_existing_user_id
      AND consumed_at IS NULL
      AND id <> v_code_id;

    DELETE FROM public.user_messaging_links
    WHERE platform = p_platform
      AND external_chat_id = p_external_chat_id;
  END IF;

  INSERT INTO public.user_messaging_links (
    user_id, platform, external_chat_id, metadata,
    linked_at, last_used_at, disclosure_accepted_at
  ) VALUES (
    v_code_user_id, p_platform, p_external_chat_id, COALESCE(p_metadata, '{}'::jsonb),
    v_now, v_now, v_now
  )
  ON CONFLICT (platform, external_chat_id) DO UPDATE SET
    user_id                = EXCLUDED.user_id,
    metadata               = EXCLUDED.metadata,
    linked_at              = EXCLUDED.linked_at,
    last_used_at           = EXCLUDED.last_used_at,
    disclosure_accepted_at = EXCLUDED.disclosure_accepted_at;

  UPDATE public.messaging_link_codes
  SET consumed_at = v_now
  WHERE id = v_code_id;

  RETURN v_code_user_id;
END;
$$;

-- Edge Functions call this with the service role.
GRANT EXECUTE ON FUNCTION public.consume_messaging_link_code(text, text, text, jsonb) TO service_role;

COMMIT;
