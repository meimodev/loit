# 16. All server-side AI consolidated on OpenRouter

Date: 2026-06-21

## Status

Accepted

Supersedes [0001](0001-telegram-bot-gemini.md) and the provider/transport
decisions in [0002](0002-telegram-bot-back-to-claude.md). The *behavioural*
intent of 0002 (bot + in-app scanner share one Claude receipt parser; Claude
Haiku does text and image; a separate model handles voice transcription) is
preserved — only the transport and the voice transcriber change.

## Context

All server-side AI lives in three shared Edge Function modules:

- `_shared/text_parser.ts` — text → transaction JSON, Claude Haiku via the
  native `@anthropic-ai/sdk`.
- `_shared/receipt_parser.ts` — image → transaction JSON in **one** Claude
  Haiku vision call (OCR + parse together). Shared by the Telegram bot and the
  in-app scanner (`scan-receipt`).
- `_shared/gemini.ts` — Telegram voice note → transcript, Google
  `gemini-3.5-flash`, then handed to `text_parser.ts`.

Two providers, two SDKs, two API keys (`ANTHROPIC_API_KEY`, `GEMINI_API_KEY`),
two billing relationships. We want a single account for billing and keys, the
freedom to fail over between upstreams without code changes, and access to
OpenAI models (Whisper) without a third vendor relationship.

## Decision

Route **all** server-side AI through OpenRouter. Remove `@anthropic-ai/sdk` and
`@google/genai`; talk to OpenRouter directly over `fetch` (no provider SDK).

Pipelines (unchanged in shape except voice):

- **Text** → `anthropic/claude-haiku-4.5` via OpenRouter chat/completions.
- **Image / in-app scan** → `anthropic/claude-haiku-4.5` **vision**, one
  call, OCR + parse together. No separate OCR model. (An earlier proposal to
  pre-extract with GPT-5.x-mini was rejected: it doubles calls, latency and
  cost and re-forks the unified image path for no quality evidence.)
- **Voice** → `openai/whisper-large-v3-turbo` via OpenRouter's
  `/api/v1/audio/transcriptions` endpoint (base64-JSON contract, **not**
  multipart, **not** chat/completions), then the transcript flows into the
  existing text path. Replaces Gemini.

Resilience: **same-model provider failover only.** OpenRouter `provider`
routing lets `claude-haiku` be served by Anthropic / Bedrock / Vertex
interchangeably, and Whisper by OpenAI / Groq / Google. Model and prompt never
change, so the JSON contract is never at risk. No cross-model fallback.

Prompt caching: the large `STATIC_PROMPT` blocks are sent as **content-array
text blocks with per-block `cache_control: {type:"ephemeral"}`**. Per-block
breakpoints (unlike a top-level `cache_control`, which would pin routing to
Anthropic-only) are honoured across all three Claude upstreams, so caching and
failover coexist. OpenRouter sticky routing keeps the cache warm. Caching is
therefore best-effort: a Bedrock/Vertex failover may not engage it.

Config: new `OPENROUTER_API_KEY` secret. Model ids stay as named constants
(per 0002's "wrong id = runtime 404" lesson) and slugs are verified at
`openrouter.ai/<slug>/providers` before deploy.

Cutover: incremental — text, then image, then voice, each verified in prod
before the next. `ANTHROPIC_API_KEY` and `GEMINI_API_KEY` stay set until all
three are verified, then are removed. Rollback is redeploying the prior
function; no runtime provider toggle (rejected — it keeps both code paths and
both SDKs alive for marginal benefit).

## Consequences

- **New single point of failure.** Today Anthropic and Gemini fail
  independently; after this, an OpenRouter outage takes down text, image and
  voice at once. Same-model provider failover mitigates upstream (Anthropic)
  outages but not an OpenRouter-level one.
- One key, one bill, one SDK-less transport; `gemini.ts` and the two provider
  SDK deps are deleted.
- Voice no longer depends on a Gemini model id; it depends on the Whisper slug
  and OpenRouter's STT endpoint instead (a different 404 surface, same class of
  risk).
- Caching is best-effort rather than guaranteed; cost may rise modestly on the
  failover path.
- **BYOK is an intentional interim, not the steady state.** We start in BYOK
  mode (`is_byok:true`) to drain prepaid Anthropic credits bought outside
  OpenRouter. While BYOK is active a 2026-06-21 dry-run showed: still billed via
  Anthropic (no consolidated bill), no Bedrock/Vertex failover, and zero
  prompt-cache activity — caching and cross-provider failover only switch on
  once routing moves to OpenRouter credits. The transition is automatic: leave
  "Always use for this provider" OFF (default) so an exhausted BYOK key falls
  back to OpenRouter credits mid-stream rather than hard-failing. (Turning it ON
  makes exhaustion a hard error.) Note a 5% BYOK platform fee is drawn from
  OpenRouter credits beyond the first 1M req/mo even while on BYOK. Verify the
  handoff later via OpenRouter's Activity page and `cache_write_tokens > 0` in
  `scripts/or_dryrun.ts`.
- DB/analytics state, scan quota gating (`scan_gate.ts`) and the receipt JSON
  contract are unchanged — this is transport + voice-transcriber only.
