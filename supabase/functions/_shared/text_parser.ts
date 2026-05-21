import Anthropic from "npm:@anthropic-ai/sdk@0.32.1";
import type { UserContext } from "./user_context.ts";
import { formatBreakdownNotes } from "./notes_breakdown.ts";

const anthropic = new Anthropic({ apiKey: Deno.env.get("ANTHROPIC_API_KEY")! });

const TEXT_STATIC_PROMPT = `You are LOIT's transaction parser for chat messages. Read the user's message and return ONLY valid JSON — no prose, no markdown fences.

Decide first: is this message describing exactly one concrete monetary transaction the user wants logged? A single purchase may contain MULTIPLE line items (e.g. "beras 10kg 250000 ayam 12kg 15000" — one shopping trip with two items). Itemised text still counts as one transaction; sum the line totals. Reject only when the message is a greeting, question, balance check, transfer history, or otherwise not a concrete purchase/income event:
{ "is_transaction": false, "reason": "short reason" }

If the message clearly describes a purchase or income event, set is_transaction=true EVEN WHEN wording is sloppy, contains typos ("dagin" → daging), mixes Indonesian/English, or trails with a destination marker. Do not reject just because the message ends with a room name. Words like "untuk", "buat", "ke", "for", "to", "in" followed by a name from the rooms list mark the destination room — they NEVER make the message non-transactional.

When it IS a transaction, classify "type" = "expense" or "income". Spending words = expense; receiving money, salary, refund, deposit, transfer-in = income.

Use the lists in the user message:
- "destination_room" — if the user clearly names one of the rooms in the list (often after "untuk"/"buat"/"ke"/"for"/"to"/"in"), return its exact name; otherwise null.
- If "destination_room" is null, "category" MUST be an exact key from the PERSONAL categories list.
- If "destination_room" is set, "category" MUST be an exact key from THAT ROOM's categories list — never use personal keys for room transactions, and never use one room's keys for a different room.
- "account" MUST be an exact name from the accounts list. Do not invent accounts. If the accounts list is empty, set "account" to "" — the server will reject the transaction.

Worked example — message "beli daging babi 2kg 237k dari pasar untuk rumah" with rooms list containing "rumah":
{ "is_transaction": true, "type": "expense", "merchant": "pasar", "total": 237000, "destination_room": "rumah", "category": <expense key from rumah's list>, ... }

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
  "items": [ { "name": "string", "qty": 0, "unit_price": 0, "total_price": 0 } ],
  "date": "YYYY-MM-DD",
  "confidence": 0.00
}

"items" is optional. Include it whenever the message lists distinct line items with their own amounts (a grocery list, a multi-product receipt). Each item should carry whichever of qty/unit_price/total_price the message actually states. If only one product is mentioned, omit "items".

Rules:
- "total" must be positive; sign is conveyed by "type".
- Always pick a category — never invent keys.
- Pick the most plausible account if unspecified.
- "date" must be in YYYY-MM-DD format. Default to today when not stated.`;

export interface TextParseItem {
  name: string;
  qty?: number | null;
  unit_price?: number | null;
  total_price?: number | null;
}

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
  items: TextParseItem[] | null;
  date: string | null;
  confidence: number;
  // True when this result came from a deterministic rescue path
  // (room-targeted fallback) rather than the AI parser. Used for telemetry
  // and to opt into the low-confidence confirm flow even if confidence is
  // otherwise high.
  rescued?: boolean;
}

export interface TextParseRejected {
  is_transaction: false;
  reason: string | null;
}

export type TextParseResult =
  | { kind: "ok"; parsed: TextParseSuccess }
  | { kind: "rejected"; reason: string | null }
  | { kind: "ai_failure" };

// Normalize a room-name string for tolerant matching: lowercase, strip
// surrounding/edge punctuation + quotes, collapse internal whitespace.
function normalizeRoomName(raw: string): string {
  return raw
    .toLowerCase()
    .replace(/^[\s"'`“”‘’.,;:!?()\[\]{}<>]+|[\s"'`“”‘’.,;:!?()\[\]{}<>]+$/g, "")
    .replace(/\s+/g, " ")
    .trim();
}

export function findRoomByName(
  ctx: UserContext,
  raw: string | null | undefined,
): { id: string; name: string } | null {
  if (!raw) return null;
  const needle = normalizeRoomName(raw);
  if (!needle) return null;
  for (const r of ctx.rooms) {
    if (normalizeRoomName(r.name) === needle) {
      return { id: r.id, name: r.name };
    }
  }
  return null;
}

// Indonesian/English destination markers — followed by a room name. Used by
// the deterministic rescue path when Claude rejects a clearly-roomed message.
const ROOM_MARKERS = ["untuk", "buat", "ke", "for", "to", "in"];

// Extract the trailing fragment after a destination marker. Returns the raw
// text (lowercased, normalized) the user appears to have addressed as a room,
// regardless of whether it matches any actual room in the user's context.
// Useful to surface "room X not found" replies when the marker is present
// but ctx.rooms is empty / has no match.
export function extractIntendedRoomName(message: string): string | null {
  const lower = ` ${message.toLowerCase().replace(/\s+/g, " ")} `;
  for (const marker of ROOM_MARKERS) {
    const needle = ` ${marker} `;
    const idx = lower.lastIndexOf(needle);
    if (idx < 0) continue;
    const tail = lower.slice(idx + needle.length).trim();
    if (!tail) continue;
    // Cap to ~4 trailing words so we don't grab full sentences.
    const words = tail.split(/\s+/).slice(0, 4).join(" ");
    const cleaned = normalizeRoomName(words);
    if (cleaned) return cleaned;
  }
  return null;
}

function detectRoomInMessage(
  message: string,
  ctx: UserContext,
): { id: string; name: string } | null {
  if (ctx.rooms.length === 0) return null;
  const lower = ` ${message.toLowerCase()} `;
  // Try marker-anchored match first ("untuk <room>"), then any-position
  // substring match. Both go through normalizeRoomName to tolerate casing
  // and trailing punctuation.
  for (const room of ctx.rooms) {
    const target = normalizeRoomName(room.name);
    if (!target) continue;
    for (const marker of ROOM_MARKERS) {
      const idx = lower.indexOf(` ${marker} ${target}`);
      if (idx >= 0) return { id: room.id, name: room.name };
    }
  }
  for (const room of ctx.rooms) {
    const target = normalizeRoomName(room.name);
    if (!target) continue;
    if (lower.includes(` ${target} `) || lower.endsWith(` ${target} `)) {
      return { id: room.id, name: room.name };
    }
  }
  return null;
}

// Scan for the most plausible single amount in free text. Picks the
// LARGEST positive number after k/rb/ribu/jt/juta/m multiplier expansion —
// usually the total when both qty and price appear (e.g. "2kg 237k" → 237000
// wins over 2). Returns null when no amount-shaped token is found.
function extractSingleAmount(message: string): number | null {
  const re = /(\d[\d.,]*)\s*(rb|ribu|k|jt|juta|m)?\b/giu;
  let best: number | null = null;
  for (const m of message.matchAll(re)) {
    const base = parseAmountToken(m[1] ?? "");
    if (base == null || base <= 0) continue;
    const mult = (m[2] ?? "").toLowerCase();
    const value = base * (UNIT_MULTIPLIERS[mult] ?? 1);
    if (value <= 0) continue;
    if (best == null || value > best) best = value;
  }
  return best;
}

function pickFallbackCategoryForRoom(
  ctx: UserContext,
  roomId: string,
  kind: "expense" | "income",
): string | null {
  const roomCats = ctx.categories.filter(
    (c) => c.scope === "room" && c.roomId === roomId && c.kind === kind,
  );
  if (roomCats.length === 0) return null;
  if (kind === "expense") {
    const foodHints = [
      "groceries",
      "grocery",
      "food",
      "makanan",
      "belanja",
      "dapur",
    ];
    for (const hint of foodHints) {
      const m = roomCats.find(
        (c) =>
          c.key.toLowerCase().includes(hint) ||
          c.name.toLowerCase().includes(hint),
      );
      if (m) return m.key;
    }
  }
  const other =
    roomCats.find((c) => c.key === (kind === "income" ? "income_other" : "other")) ??
    roomCats.find((c) => c.key.toLowerCase().includes("other")) ??
    roomCats[0];
  return other?.key ?? null;
}

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
      // SDK 0.32 doesn't type prompt-caching control yet; runtime accepts it.
      // deno-lint-ignore no-explicit-any
      ({
        type: "text",
        text: TEXT_STATIC_PROMPT,
        cache_control: { type: "ephemeral" },
      } as any),
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
      // Deterministic itemised fallback covers multi-item shopping lists the
      // AI sometimes misclassifies as non-transactions.
      const fb = tryItemizedFallback(message, ctx);
      if (fb) return { kind: "ok", parsed: fb };
      // Single-item rescue: Haiku occasionally rejects room-targeted
      // messages like "beli daging 237k untuk rumah". When an amount and a
      // known room are both present, route through the confirm flow.
      const roomRescue = tryRoomTargetedRescue(message, ctx);
      if (roomRescue) return { kind: "ok", parsed: roomRescue };
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
      const itemsRaw = Array.isArray(parsed.items) ? parsed.items : null;
      const items: TextParseItem[] | null = itemsRaw
        ? itemsRaw
            .map((it: any) => ({
              name: typeof it?.name === "string" ? it.name.trim() : "",
              qty: toFiniteOrNull(it?.qty),
              unit_price: toFiniteOrNull(it?.unit_price),
              total_price: toFiniteOrNull(it?.total_price),
            }))
            .filter(
              (it: TextParseItem) =>
                it.name.length > 0 ||
                it.total_price != null ||
                it.unit_price != null,
            )
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
          items: items && items.length > 0 ? items : null,
          date,
          confidence,
        },
      };
    }
    // AI couldn't classify or rejected — try a deterministic itemised
    // fallback before giving up.
    const fb = tryItemizedFallback(message, ctx);
    if (fb) return { kind: "ok", parsed: fb };
    const roomRescue = tryRoomTargetedRescue(message, ctx);
    if (roomRescue) return { kind: "ok", parsed: roomRescue };
    return { kind: "ai_failure" };
  } catch {
    const fb = tryItemizedFallback(message, ctx);
    if (fb) return { kind: "ok", parsed: fb };
    const roomRescue = tryRoomTargetedRescue(message, ctx);
    if (roomRescue) return { kind: "ok", parsed: roomRescue };
    return { kind: "ai_failure" };
  }
}

function toFiniteOrNull(x: unknown): number | null {
  if (typeof x === "number" && Number.isFinite(x)) return x;
  if (typeof x === "string") {
    const n = Number(x.replace(/[^\d.\-]/g, ""));
    if (Number.isFinite(n)) return n;
  }
  return null;
}

// Lightweight number parser that understands Indonesian thousand separators
// ("250.000", "1.250") AND Western decimals ("12.50"). When the trailing
// segment is exactly 1-2 digits and the others are 3-digit groups we treat
// the last separator as decimal; otherwise all separators are thousands.
function parseAmountToken(raw: string): number | null {
  const t = raw.trim();
  if (!t) return null;
  const cleaned = t.replace(/[^\d.,]/g, "");
  if (!cleaned) return null;
  if (!/[.,]/.test(cleaned)) {
    const n = Number(cleaned);
    return Number.isFinite(n) ? n : null;
  }
  const lastSep = Math.max(cleaned.lastIndexOf("."), cleaned.lastIndexOf(","));
  const tail = cleaned.slice(lastSep + 1);
  if (tail.length === 1 || tail.length === 2) {
    const head = cleaned.slice(0, lastSep).replace(/[.,]/g, "");
    const n = Number(`${head || "0"}.${tail}`);
    return Number.isFinite(n) ? n : null;
  }
  const n = Number(cleaned.replace(/[.,]/g, ""));
  return Number.isFinite(n) ? n : null;
}

function pickFallbackCategory(
  ctx: UserContext,
  kind: "expense" | "income",
): string | null {
  const personal = ctx.categories.filter(
    (c) => c.scope === "user" && c.kind === kind,
  );
  if (personal.length === 0) return null;
  if (kind === "expense") {
    const foodHints = [
      "groceries",
      "grocery",
      "food",
      "makanan",
      "belanja",
      "dapur",
    ];
    for (const hint of foodHints) {
      const m = personal.find(
        (c) =>
          c.key.toLowerCase().includes(hint) ||
          c.name.toLowerCase().includes(hint),
      );
      if (m) return m.key;
    }
  }
  const other =
    personal.find((c) => c.key === (kind === "income" ? "income_other" : "other")) ??
    personal.find((c) => c.key.toLowerCase().includes("other")) ??
    personal[0];
  return other?.key ?? null;
}

function pickFallbackAccount(ctx: UserContext): string | null {
  if (ctx.accounts.length === 0) return null;
  const cash = ctx.accounts.find((a) => a.name.toLowerCase() === "cash");
  return (cash ?? ctx.accounts[0]).name;
}

// Match repeated `name [qty unit] amount` blocks. Examples that should
// trigger this: "beras 10kg 250000 ayam 12kg 15000", "kopi 25rb teh 18rb".
const ITEMIZED_BLOCK = new RegExp(
  String.raw`([A-Za-z][A-Za-z\s]*?)\s+(?:(\d+(?:[.,]\d+)?)\s*(kg|g|gr|gram|l|ml|pcs|pc|x|×)?\s+)?(\d[\d.,]*)(?:\s*(rb|ribu|k|jt|juta|m))?`,
  "giu",
);

const UNIT_MULTIPLIERS: Record<string, number> = {
  rb: 1_000,
  ribu: 1_000,
  k: 1_000,
  jt: 1_000_000,
  juta: 1_000_000,
  m: 1_000_000,
};

export function tryItemizedFallback(
  message: string,
  ctx: UserContext,
): TextParseSuccess | null {
  const cleaned = message.replace(/\s+/g, " ").trim();
  if (cleaned.length < 4) return null;
  // Need at least two item-like chunks to bother — single-product messages
  // are better handled by the AI path on its own.
  const matches = [...cleaned.matchAll(ITEMIZED_BLOCK)];
  if (matches.length < 2) return null;

  const items: TextParseItem[] = [];
  let runningTotal = 0;
  for (const m of matches) {
    const name = (m[1] ?? "").trim();
    const qtyRaw = m[2] ?? "";
    const amountRaw = m[4] ?? "";
    const mult = (m[5] ?? "").toLowerCase();
    if (!name || !amountRaw) continue;
    const amountBase = parseAmountToken(amountRaw);
    if (amountBase == null || amountBase <= 0) continue;
    const totalPrice = amountBase * (UNIT_MULTIPLIERS[mult] ?? 1);
    const qty = qtyRaw ? parseAmountToken(qtyRaw) : null;
    items.push({
      name,
      qty: qty ?? null,
      unit_price: null,
      total_price: totalPrice,
    });
    runningTotal += totalPrice;
  }
  if (items.length < 2 || runningTotal <= 0) return null;

  const category = pickFallbackCategory(ctx, "expense");
  const account = pickFallbackAccount(ctx);
  if (!category || !account) return null;

  const notes = formatBreakdownNotes({
    merchant: null,
    items: items.map((it) => ({
      name: it.name,
      qty: it.qty,
      unit_price: it.unit_price,
      total_price: it.total_price,
    })),
    total: runningTotal,
    currency: ctx.homeCurrency,
  });

  return {
    is_transaction: true,
    type: "expense",
    merchant: null,
    currency: ctx.homeCurrency,
    total: runningTotal,
    category,
    account,
    destination_room: null,
    notes,
    items,
    date: null,
    // Low confidence so caller routes through pending-confirm flow.
    confidence: 0.5,
  };
}

// Rescue path: Claude rejected the message OR returned malformed JSON, but
// the user clearly named a room and stated an amount. Build a low-confidence
// TextParseSuccess so the caller routes through the confirm flow with a
// category picker, rather than replying "I couldn't understand that".
export function tryRoomTargetedRescue(
  message: string,
  ctx: UserContext,
): TextParseSuccess | null {
  const room = detectRoomInMessage(message, ctx);
  if (!room) return null;
  const amount = extractSingleAmount(message);
  if (amount == null || amount <= 0) return null;
  const category = pickFallbackCategoryForRoom(ctx, room.id, "expense");
  const account = pickFallbackAccount(ctx);
  if (!category || !account) return null;
  return {
    is_transaction: true,
    type: "expense",
    merchant: null,
    currency: ctx.homeCurrency,
    total: amount,
    category,
    account,
    destination_room: room.name,
    notes: message.trim() || null,
    items: null,
    date: null,
    confidence: 0.4,
    rescued: true,
  };
}

// Caption-metadata parser for image submissions. Only extracts date hints and
// destination room — never amount/category/account. Returns null fields when
// the caption does not explicitly state or imply them. Captions are typically
// short ("for May 1", "kemarin", "rumah trip") and may not describe a money
// transaction at all, so this skips the is_transaction gate that
// parseTransactionText enforces.
export interface CaptionMetadata {
  date: string | null;
  destination_room: string | null;
}

const CAPTION_META_PROMPT = `You are LOIT's image-caption metadata parser. The caption accompanies a receipt photo. Extract ONLY two fields and return strict JSON — no prose, no markdown.

Fields:
- "date": YYYY-MM-DD. Resolve relative wording ("yesterday", "kemarin", "last Friday", "May 1") against the "Today" value in the user message. If the caption does not mention or imply a date, return null. Do NOT guess.
- "destination_room": exact room name from the rooms list when the caption clearly names one of them. Otherwise null. Do NOT invent room names.

Return:
{ "date": "YYYY-MM-DD" | null, "destination_room": "exact room name" | null }`;

export async function parseCaptionMetadata(
  caption: string,
  ctx: UserContext,
): Promise<CaptionMetadata> {
  const today = new Date().toISOString().slice(0, 10);
  const roomNames = ctx.rooms.map((r) => `"${r.name}"`).join(", ");
  const userBlock = `Today: ${today}
Rooms: ${roomNames || "(none)"}

Caption: ${caption}`;

  try {
    const result = await anthropic.messages.create({
      model: "claude-haiku-4-5-20251001",
      max_tokens: 128,
      system: [
        // SDK 0.32 doesn't type prompt-caching control yet; runtime accepts it.
        // deno-lint-ignore no-explicit-any
        ({
          type: "text",
          text: CAPTION_META_PROMPT,
          cache_control: { type: "ephemeral" },
        } as any),
      ],
      messages: [{ role: "user", content: [{ type: "text", text: userBlock }] }],
    });
    const raw = result.content[0]?.type === "text" ? result.content[0].text : "";
    const stripped = raw
      .trim()
      .replace(/^```(?:json)?\s*/i, "")
      .replace(/```\s*$/i, "")
      .trim();
    const parsed = JSON.parse(stripped);
    const date = (() => {
      if (typeof parsed?.date !== "string") return null;
      if (!/^\d{4}-\d{2}-\d{2}$/.test(parsed.date)) return null;
      const d = new Date(`${parsed.date}T00:00:00Z`);
      // Reject overflowed dates like "2026-02-31" — round-trip through
      // toISOString to ensure the input names a real calendar day.
      if (isNaN(d.getTime()) || d.toISOString().slice(0, 10) !== parsed.date) {
        return null;
      }
      return parsed.date;
    })();
    const roomRaw =
      typeof parsed?.destination_room === "string" ? parsed.destination_room : null;
    const destination_room = findRoomByName(ctx, roomRaw)?.name ?? null;
    return { date, destination_room };
  } catch {
    return { date: null, destination_room: null };
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
  // Cast: stricter lib.dom types reject Uint8Array<ArrayBufferLike> as BlobPart
  // even though Deno's Blob accepts it. Safe — Uint8Array is a valid BlobPart
  // at runtime.
  form.append("file", new Blob([audio as BlobPart]), filename);
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
