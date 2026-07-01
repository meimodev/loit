-- ADR-0022: in-app voice Capture. Add 'voice' as a first-class transaction
-- source so voice-parsed transactions are distinguishable from image scans
-- ('scanned') and Telegram captures ('bot_chat' / 'bot_image') in analytics.

alter table transactions
  drop constraint if exists transactions_source_check;

alter table transactions
  add constraint transactions_source_check
  check (source in ('manual', 'scanned', 'bot_image', 'bot_chat', 'voice'));
