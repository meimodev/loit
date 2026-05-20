-- ============================================================
-- Schedule cleanup_messaging_state() hourly via pg_cron.
-- ============================================================
-- Companion to 20260520000000_messaging_pipeline.sql. The function
-- prunes expired bot pending transactions, undo tokens, edit
-- sessions, link codes, and old rate-limit events.
-- ============================================================

BEGIN;

CREATE EXTENSION IF NOT EXISTS pg_cron;

DO $$
BEGIN
  -- Drop any previously-scheduled copy so re-running this migration is
  -- idempotent on environments where the job already exists.
  IF EXISTS (
    SELECT 1 FROM cron.job WHERE jobname = 'messaging_state_cleanup'
  ) THEN
    PERFORM cron.unschedule('messaging_state_cleanup');
  END IF;

  PERFORM cron.schedule(
    'messaging_state_cleanup',
    '0 * * * *',
    $cron$SELECT public.cleanup_messaging_state();$cron$
  );
END $$;

COMMIT;
