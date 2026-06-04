# 2. Telegram bot AI returns to Claude; Gemini kept only for voice transcription

Date: 2026-06-03

## Status

Accepted (supersedes [0001](0001-telegram-bot-gemini.md))

## Context

[ADR 0001](0001-telegram-bot-gemini.md) moved the Telegram bot's AI
interactions (text → transaction JSON, image-caption metadata, voice, receipt
OCR) from Claude Haiku to Google Gemini (`gemini-3.5-flash`), forking receipt
parsing so the in-app scanner stayed on Claude. We are reversing that decision
for the bot's text, caption, and receipt paths.

The one wrinkle: voice. Claude has **no audio input** — the Anthropic API
accepts text and images only. So the bot cannot be "all Claude": something
still has to turn a voice note into text before Haiku can parse it. ADR 0001's
predecessor used OpenAI Whisper (primary) + a Claude `input_audio` fallback;
0001 collapsed voice into a single Gemini multimodal call (audio → JSON, no
intermediate transcript).

## Decision

- **Bot AI returns to Claude Haiku (`claude-haiku-4-5-20251001`)** for text,
  image-caption metadata, and receipt OCR. The bot re-imports
  `_shared/receipt_parser.ts` (Claude) and the Gemini fork
  `_shared/receipt_parser_gemini.ts` is **deleted** — bot and in-app scanner
  share one receipt parser again, ending the mixed-provider fork from 0001.
- **Voice becomes two-step: transcribe → parse.** A single Gemini call
  (`gemini-3.5-flash`, plain-text output) transcribes the voice note; the
  transcript is then fed into the existing Claude text parser
  (`parseTransactionText`). Voice and text share one parser after
  transcription, so voice **regains** the deterministic rescues
  (`tryItemizedFallback`, `tryRoomTargetedRescue`) that 0001's one-shot path
  lost.
- **Gemini is retained for exactly one job: voice transcription.** `gemini.ts`
  is trimmed to a single `geminiTranscribe` helper; the JSON-mode `geminiJson`
  is removed (no remaining callers).
- **No transcription fallback.** A failed Gemini transcribe refunds the scan
  quota and replies "couldn't understand" — matching the no-fallback posture
  0001 already accepted. Whisper and the Claude `input_audio` fallback stay
  removed; `OPENAI_API_KEY` stays gone.
- Secrets: `ANTHROPIC_API_KEY` and `GEMINI_API_KEY` both live.

## Consequences

- **Still mixed-provider, but inverted and minimised.** 0001 was Gemini-bot +
  Claude-scanner. Now it is Claude everywhere except Gemini for the single
  thing Claude cannot do (hear audio). A future reader should not "unify" by
  dropping Gemini without a replacement transcriber.
- **One receipt parser again.** Deleting the fork removes the drift risk 0001
  introduced; bot and scanner OCR can no longer diverge.
- **Voice fallback still absent.** A failed Gemini transcribe has no second
  transcriber. Acceptable for bot volume; revisit if voice failure rates rise.
- **Model-ID dependency persists.** `gemini-3.5-flash` must remain a valid
  Google AI Studio model id; a wrong/retired id fails voice at runtime (404).
- Prompt caching for the Claude paths returns to Anthropic explicit
  `cache_control: { type: "ephemeral" }` wrappers (as before 0001).
