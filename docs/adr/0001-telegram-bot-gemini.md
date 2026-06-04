# 1. Telegram bot AI runs on Gemini; in-app scanner stays on Claude

Date: 2026-06-03

## Status

Superseded by [0002](0002-telegram-bot-back-to-claude.md)

## Context

The Telegram bot's AI interactions (text → transaction JSON, image-caption
metadata, voice transcription, receipt OCR) were served by Claude Haiku
(`claude-haiku-4-5-20251001`) via `@anthropic-ai/sdk`, with OpenAI Whisper as
the primary voice transcriber and Claude as the voice fallback. We want the
bot's interactions on Google Gemini (`gemini-3.5-flash` via `@google/genai`).

Two facts complicate a naive swap:

1. `parseReceiptImage` in `_shared/receipt_parser.ts` is **shared** — it serves
   both the bot and the in-app `scan-receipt` Edge Function (the Phase 3
   quota'd scanner). Swapping it in place would silently move the in-app
   scanner to Gemini too, which is outside the scope of "change the bot."
2. The voice path had two-tier redundancy (Whisper primary, Claude fallback).

## Decision

- **The Telegram bot uses Gemini; the in-app scanner stays on Claude.** We fork
  receipt parsing: the bot gets a Gemini receipt parser; `receipt_parser.ts`
  is left untouched so `scan-receipt` keeps using Claude. This is a deliberate
  mixed-provider state.
- **Voice goes single-vendor, one-shot.** Whisper and the Claude audio fallback
  are removed. A single Gemini multimodal call takes the voice note directly to
  transaction JSON (no intermediate transcript). The transcript had no other
  consumer (it was never displayed or logged), so nothing user-visible is lost.
- Gemini calls use `responseMimeType: "application/json"` (no fence-stripping)
  but **not** a strict `responseSchema` — the parser returns a union
  (`is_transaction` true/false, optional `items[]`) that a rigid schema fights.
  Existing JS-side validation and deterministic fallbacks are retained.
- Prompt caching relies on Gemini **implicit** caching; the Anthropic
  `cache_control` wrappers are dropped (no explicit `CachedContent` lifecycle).
- Gemini Developer API + a new `GEMINI_API_KEY` secret. `OPENAI_API_KEY` is
  removed; `ANTHROPIC_API_KEY` is retained for the in-app scanner.

## Consequences

- **Mixed providers by design.** Bot = Gemini, app scanner = Claude. Two
  receipt-parsing implementations and two LLM SDKs/keys coexist. A future
  reader should not "fix" this by unifying without revisiting this ADR.
- **Voice loses its fallback.** A failed Gemini audio call has no second
  transcriber. Acceptable for the bot's volume; revisit if voice failure rates
  rise.
- **Voice loses deterministic text rescues.** `tryItemizedFallback` and
  `tryRoomTargetedRescue` run on message text. One-shot audio has no text, so a
  failed voice parse falls through to "couldn't understand" — text messages
  keep both rescues.
- **Model ID risk.** `gemini-3.5-flash` must be confirmed against the live
  Google AI Studio model list before deploy; a wrong ID fails at runtime.
- Implicit caching is less guaranteed than Anthropic's explicit cache; a small
  cost increase on cache misses is accepted for ops simplicity.
