-- ============================================================
-- Align app-side disconnect with Telegram-side /end
-- ============================================================
-- Replace `disconnect_messaging_link` so it clears the same bot
-- state the Telegram `/end` command clears. Without this, app
-- disconnect leaves pending parses, edit sessions, and undo
-- tokens around that could later mutate the user's data when
-- the chat was re-linked or when an old inline button is tapped.
-- ============================================================

BEGIN;

CREATE OR REPLACE FUNCTION public.disconnect_messaging_link(p_platform text)
RETURNS int LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_user_id uuid := auth.uid();
  v_removed int;
  v_chat_ids text[];
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'not authenticated';
  END IF;

  SELECT array_agg(external_chat_id)
    INTO v_chat_ids
  FROM public.user_messaging_links
  WHERE user_id = v_user_id AND platform = p_platform;

  IF v_chat_ids IS NOT NULL AND array_length(v_chat_ids, 1) > 0 THEN
    DELETE FROM public.bot_pending_transactions
    WHERE user_id = v_user_id
      AND platform = p_platform
      AND external_chat_id = ANY(v_chat_ids);

    DELETE FROM public.bot_edit_sessions
    WHERE user_id = v_user_id
      AND platform = p_platform
      AND external_chat_id = ANY(v_chat_ids);

    DELETE FROM public.bot_transaction_undo_tokens
    WHERE user_id = v_user_id
      AND platform = p_platform
      AND external_chat_id = ANY(v_chat_ids);
  END IF;

  UPDATE public.messaging_link_codes
  SET consumed_at = now()
  WHERE user_id = v_user_id
    AND platform = p_platform
    AND consumed_at IS NULL;

  WITH del AS (
    DELETE FROM public.user_messaging_links
    WHERE user_id = v_user_id AND platform = p_platform
    RETURNING 1
  )
  SELECT count(*) INTO v_removed FROM del;

  RETURN v_removed;
END;
$$;

GRANT EXECUTE ON FUNCTION public.disconnect_messaging_link(text) TO authenticated;

COMMIT;
