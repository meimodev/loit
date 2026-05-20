import Anthropic from "npm:@anthropic-ai/sdk@0.32.1";
import type { UserContext } from "./user_context.ts";

const anthropic = new Anthropic({ apiKey: Deno.env.get("ANTHROPIC_API_KEY")! });

const TEXT_STATIC_PROMPT = `You are LOIT's transaction parser for chat messages. Read the user's message and return ONLY valid JSON — no prose, no markdown fences.

Decide first: is this message describing exactly one concrete monetary transaction the user wants logged? If not (greeting, question, ambiguous, balance check, transfer history etc.), return:
{ "is_transaction": false, "reason": "short reason" }

When it IS a transaction, classify "type" = "expense" or "income". Spending words = expense; receiving money, salary, refund, deposit, transfer-in = income.

Use the lists in the user message:
- "destination_room" — if the user clearly names one of the rooms in the list, return its exact name; otherwise null.
- If "destination_room" is null, "category" MUST be an exact key from the PERSONAL categories list.
- If "destination_room" is set, "category" MUST be an exact key from THAT ROOM's categories list — never use personal keys for room transactions, and never use one room's keys for a different room.
- "account" MUST be an exact name from the accounts list. Do not invent accounts. If the accounts list is empty, set "account" to "" — the server will reject the transaction.

Currency defaults to the user's home currency unless the message names a different ISO code or symbol.

"confidence" is a single 0.0-1.0 scalar reflecting how sure you are about every field.

"date" is the date the transaction occurred (YYYY-MM-DD). Resolve relative wording such as "yesterday", "kemarin", "last Friday", or "May 1" against "Today" provided in the user message. If the message does not name or imply a date, default to "Today".

Return when is_transaction is true:
{
  "is_transaction": true,
  "type": "expense|income",
  "merchant": "string or null",
  "currency": "ISO 4217 code",
  "total": 0.00,
  "category": "exact key",
  "account": "exact name",
  "destination_room": "exact room name or null",
  "notes": "short, original phrasing if useful, else null",
  "date": "YYYY-MM-DD",
  "confidence": 0.00
}

Rules:
- "total" must be positive; sign is conveyed by "type".
- Always pick a category — never invent keys.
- Pick the most plausible account if unspecified.
- "date" must be in YYYY-MM-DD format. Default to today when not stated.`;

export interface TextParseSuccess {
  is_transaction: true;
  type: "expense" | "income";
  merchant: string | null;
  currency: string;
  total: number;
  category: string;
  account: string;
  destination_room: string | null;
  notes: string | null;
  date: string | null;
  confidence: number;
}

export interface TextParseRejected {
  is_transaction: false;
  reason: string | null;
}

export type TextParseResult =
  | { kind: "ok"; parsed: TextParseSuccess }
  | { kind: "rejected"; reason: string | null }
  | { kind: "ai_failure" };

function buildContextBlock(ctx: UserContext): string {
  const personalExpense = ctx.categories
    .filter((c) => c.scope === "user" && c.kind === "expense")
    .map((c) => `${c.key} (${c.name})`)
    .join(", ");
  const personalIncome = ctx.categories
    .filter((c) => c.scope === "user" && c.kind === "income")
    .map((c) => `${c.key} (${c.name})`)
    .join(", ");
  const accs = ctx.accounts.map((a) => a.name).join(", ");
  const roomBlocks: string[] = [];
  for (const room of ctx.rooms) {
    const exp = ctx.categories
      .filter(
        (c) => c.scope === "room" && c.roomId === room.id && c.kind === "expense",
      )
      .map((c) => `${c.key} (${c.name})`)
      .join(", ");
    const inc = ctx.categories
      .filter(
        (c) => c.scope === "room" && c.roomId === room.id && c.kind === "income",
      )
      .map((c) => `${c.key} (${c.name})`)
      .join(", ");
    roomBlocks.push(
      `  - Room "${room.name}":\n      expense=[${exp || "(none)"}]\n      income=[${inc || "(none)"}]`,
    );
  }
  return `User language: ${ctx.language}
Home currency: ${ctx.homeCurrency}
PERSONAL expense categories: ${personalExpense || "(none)"}
PERSONAL income categories: ${personalIncome || "(none)"}
Available accounts: ${accs || "(none)"}
Available rooms:
${roomBlocks.length > 0 ? roomBlocks.join("\n") : "  (none)"}`;
}

export async function parseTransactionText(
  message: string,
  ctx: UserContext,
): Promise<TextParseResult> {
  const today = new Date().toISOString().slice(0, 10);
  const userBlock = `${buildContextBlock(ctx)}
Today: ${today}

User message: ${message}`;

  const result = await anthropic.messages.create({
    model: "claude-haiku-4-5-20251001",
    max_tokens: 512,
    system: [
      {
        type: "text",
        text: TEXT_STATIC_PROMPT,
        // deno-lint-ignore no-explicit-any
        cache_control: { type: "ephemeral" } as any,
      },
    ],
    messages: [{ role: "user", content: [{ type: "text", text: userBlock }] }],
  });

  const raw = result.content[0]?.type === "text" ? result.content[0].text : "";
  const stripped = raw
    .trim()
    .replace(/^```(?:json)?\s*/i, "")
    .replace(/```\s*$/i, "")
    .trim();
  try {
    const parsed = JSON.parse(stripped);
    if (parsed?.is_transaction === false) {
      return { kind: "rejected", reason: parsed.reason ?? null };
    }
    if (
      parsed?.is_transaction === true &&
      typeof parsed.total === "number" &&
      parsed.total > 0 &&
      typeof parsed.category === "string" &&
      typeof parsed.account === "string"
    ) {
      const confidence =
        typeof parsed.confidence === "number"
          ? Math.max(0, Math.min(1, parsed.confidence))
          : 0.5;
      const date =
        typeof parsed.date === "string" && /^\d{4}-\d{2}-\d{2}$/.test(parsed.date)
          ? parsed.date
          : null;
      return {
        kind: "ok",
        parsed: {
          is_transaction: true,
          type: parsed.type === "income" ? "income" : "expense",
          merchant: parsed.merchant ?? null,
          currency:
            typeof parsed.currency === "string" && parsed.currency.length === 3
              ? parsed.currency.toUpperCase()
              : ctx.homeCurrency,
          total: parsed.total,
          category: parsed.category,
          account: parsed.account,
          destination_room: parsed.destination_room ?? null,
          notes: parsed.notes ?? null,
          date,
          confidence,
        },
      };
    }
    return { kind: "ai_failure" };
  } catch {
    return { kind: "ai_failure" };
  }
}

// Whisper transcription. Returns null when transcription is empty/garbage.
export async function transcribeVoice(
  audio: Uint8Array,
  filename: string,
  language: string,
): Promise<string | null> {
  const apiKey = Deno.env.get("OPENAI_API_KEY");
  if (!apiKey) throw new Error("OPENAI_API_KEY not set");
  const form = new FormData();
  form.append("file", new Blob([audio]), filename);
  form.append("model", "whisper-1");
  // Bias toward Indonesian when user language is id, but keep mixed allowed.
  if (language === "id") form.append("language", "id");
  form.append("response_format", "text");

  const res = await fetch("https://api.openai.com/v1/audio/transcriptions", {
    method: "POST",
    headers: { Authorization: `Bearer ${apiKey}` },
    body: form,
  });
  if (!res.ok) throw new Error(`Whisper failed: ${res.status}`);
  const text = (await res.text()).trim();
  if (text.length < 2) return null;
  return text;
}

// Claude direct-audio fallback. Receives base64-encoded audio and returns a
// transcript-shaped string, or null on failure.
export async function transcribeWithClaudeFallback(
  audioBase64: string,
  mimeType: string,
): Promise<string | null> {
  try {
    const result = await anthropic.messages.create({
      model: "claude-haiku-4-5-20251001",
      max_tokens: 400,
      messages: [
        {
          role: "user",
          content: [
            // Claude SDK accepts a generic "input_audio" content part for
            // multimodal audio in recent versions. Cast to any to keep this
            // file compiling against older SDK typings.
            // deno-lint-ignore no-explicit-any
            { type: "input_audio", source: { type: "base64", media_type: mimeType, data: audioBase64 } } as any,
            {
              type: "text",
              text: "Transcribe verbatim. Return only the transcript text, no commentary.",
            },
          ],
        },
      ],
    });
    const text = result.content[0]?.type === "text" ? result.content[0].text : "";
    const trimmed = text.trim();
    return trimmed.length >= 2 ? trimmed : null;
  } catch {
    return null;
  }
}
