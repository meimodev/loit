-- ADR-0029: Telegram voice becomes a first-class transaction source. The bot
-- already knew `sourceType === "voice"` and collapsed it into 'bot_chat',
-- making Telegram voice indistinguishable from Telegram text.
--
-- No backfill: historical Telegram voice rows are stored as 'bot_chat' and
-- nothing recovers which they were (`ai_parsed` is true for both). They stay
-- labelled "Telegram Text".

alter table transactions
  drop constraint if exists transactions_source_check;

alter table transactions
  add constraint transactions_source_check
  check (source in ('manual', 'scanned', 'bot_image', 'bot_chat', 'voice', 'bot_voice'));
