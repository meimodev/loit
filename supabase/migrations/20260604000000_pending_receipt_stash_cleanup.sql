-- ============================================================
-- Stash-aware messaging cleanup.
-- ============================================================
-- Low-confidence Telegram receipt images park the photo in the private
-- `receipts` bucket and record its path on the pending row
-- (`payload->>'receiptStash'`). pg_cron / plpgsql cannot delete storage
-- objects, so this hourly SQL sweep must NOT delete stash-bearing pending
-- rows — otherwise the blob is orphaned. The daily `receipt-expiry-cron`
-- Edge Function owns the full lifecycle for those rows (delete blob + row).
-- Everything else is pruned exactly as before.
-- ============================================================

BEGIN;

CREATE OR REPLACE FUNCTION public.cleanup_messaging_state()
RETURNS void LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  DELETE FROM public.bot_pending_transactions
    WHERE expires_at < now()
      AND (payload->>'receiptStash') IS NULL;
  DELETE FROM public.bot_transaction_undo_tokens WHERE expires_at < now();
  DELETE FROM public.messaging_link_codes
    WHERE (expires_at < now()) OR (consumed_at IS NOT NULL AND consumed_at < now() - interval '7 days');
  DELETE FROM public.bot_edit_sessions          WHERE expires_at < now();
  DELETE FROM public.bot_rate_limit_events      WHERE event_at < now() - interval '24 hours';
END;
$$;

COMMIT;
