// Single transport for ALL server-side AI: OpenRouter. Replaces the
// @anthropic-ai/sdk and @google/genai SDKs. See
// docs/adr/0016-all-ai-through-openrouter.md.
//
// Two OpenRouter APIs are used:
//   - chat/completions  → text + image (Claude Haiku, vision included)
//   - audio/transcriptions → voice (Whisper)
//
// Model ids are pinned constants (per ADR-0002's "wrong id = runtime 404"
// lesson); verify each slug at openrouter.ai/<slug>/providers before deploy.
// OpenRouter's default routing already fails over between a model's upstream
// providers (Claude: Anthropic/Bedrock/Vertex; Whisper: OpenAI/Groq/Google),
// so no explicit `provider` block is needed for same-model failover.

const OPENROUTER_BASE = "https://openrouter.ai/api/v1";
const API_KEY = Deno.env.get("OPENROUTER_API_KEY")!;

export const OPENROUTER_CHAT_MODEL = "anthropic/claude-haiku-4.5";
export const OPENROUTER_STT_MODEL = "openai/whisper-large-v3-turbo";

// OpenAI-format content part. `cache_control` rides on a part for Anthropic
// prompt caching; per-block breakpoints are honoured across all three Claude
// upstreams, so caching and failover coexist (top-level cache_control would
// pin routing to Anthropic only).
export type ContentPart =
  | { type: "text"; text: string; cache_control?: { type: "ephemeral" } }
  | { type: "image_url"; image_url: { url: string } };

export interface ChatResult {
  text: string;
  // Completion (output) tokens — drives AI Credit metering (ADR-0017).
  completionTokens: number;
}

// Send one chat/completions request and return the assistant's text plus the
// completion-token count. `system` is sent as a cached text block.
// `userContent` is either a plain string or an OpenAI-format content array
// (text + image_url parts). Throws on transport / non-2xx so callers route to
// their own failure path, exactly as the Anthropic SDK did.
export async function chatComplete(args: {
  system: string;
  userContent: string | ContentPart[];
  maxTokens: number;
  model?: string;
}): Promise<ChatResult> {
  const userContent: ContentPart[] =
    typeof args.userContent === "string"
      ? [{ type: "text", text: args.userContent }]
      : args.userContent;

  const res = await fetch(`${OPENROUTER_BASE}/chat/completions`, {
    method: "POST",
    headers: {
      "Authorization": `Bearer ${API_KEY}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      model: args.model ?? OPENROUTER_CHAT_MODEL,
      max_tokens: args.maxTokens,
      messages: [
        {
          role: "system",
          content: [
            {
              type: "text",
              text: args.system,
              cache_control: { type: "ephemeral" },
            },
          ],
        },
        { role: "user", content: userContent },
      ],
    }),
  });

  if (!res.ok) {
    throw new Error(`OpenRouter chat ${res.status}: ${await res.text()}`);
  }
  const data = await res.json();
  return {
    text: data?.choices?.[0]?.message?.content ?? "",
    completionTokens: data?.usage?.completion_tokens ?? 0,
  };
}

// Build a base64 data URL for an image part (JPEG from the preprocessor).
export function imageDataUrl(base64: string, mime = "image/jpeg"): string {
  return `data:${mime};base64,${base64}`;
}

// Map a MIME type to the `format` extension OpenRouter's STT endpoint wants.
// Telegram voice notes arrive as audio/ogg (opus), which Whisper accepts.
function mimeToFormat(mime: string): string {
  const sub = mime.split("/")[1]?.split(";")[0]?.trim().toLowerCase() ?? "ogg";
  const map: Record<string, string> = {
    mpeg: "mp3",
    "x-wav": "wav",
    "x-m4a": "m4a",
  };
  return map[sub] ?? sub;
}

// Transcribe a base64 voice note via OpenRouter's audio/transcriptions
// endpoint (base64-JSON contract — NOT multipart). Returns the trimmed
// transcript. Throws on transport / non-2xx.
export async function transcribeAudio(
  audioBase64: string,
  mimeType: string,
): Promise<string> {
  const res = await fetch(`${OPENROUTER_BASE}/audio/transcriptions`, {
    method: "POST",
    headers: {
      "Authorization": `Bearer ${API_KEY}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      model: OPENROUTER_STT_MODEL,
      input_audio: { data: audioBase64, format: mimeToFormat(mimeType) },
    }),
  });

  if (!res.ok) {
    throw new Error(`OpenRouter STT ${res.status}: ${await res.text()}`);
  }
  const data = await res.json();
  return (data?.text ?? "").trim();
}
