import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import Anthropic from "npm:@anthropic-ai/sdk@0.32.1";
import { createClient } from "npm:@supabase/supabase-js@2.46.1";

const anthropic = new Anthropic({ apiKey: Deno.env.get("ANTHROPIC_API_KEY")! });

const supabase = createClient(
  Deno.env.get("SUPABASE_URL")!,
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
);

const CORS_HEADERS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

type Category = { key: string; name: string; kind: string };
type AccountRef = { name: string };

const STATIC_PROMPT = `You are a financial document parser. Analyze the image and return ONLY valid JSON — no explanation, no markdown.

STEP 1 — Validity check.
Set "is_transaction" = true only if the image clearly shows ONE of:
- merchant receipt
- invoice / bill
- bank transfer-out confirmation (debit slip)
- payslip / salary slip
- bank transfer-in confirmation (credit slip)
- refund slip / credit memo
- deposit confirmation
- ATM withdrawal slip
- e-wallet / payment-app transaction confirmation
- any other document recording a single concrete monetary transaction with an amount

Set "is_transaction" = false for: random photos, screenshots of unrelated content, ID cards, menus without prices billed, marketing flyers, blank pages, blurred/illegible images, or documents that are NOT a transaction record (e.g. account statements summarising many transactions, price tags, business cards).

Also classify "transaction_kind" with one of:
"merchant_receipt" | "invoice" | "bank_transfer_out" | "bank_transfer_in" | "payslip" | "refund_slip" | "deposit_confirmation" | "atm_withdrawal" | "ewallet_transaction" | "other"
Use "other" when is_transaction is true but none of the named kinds fit. Use null when is_transaction is false.

If is_transaction is false, return ONLY:
{ "is_transaction": false, "transaction_kind": null, "reason": "short human-readable reason" }

STEP 2 — When is_transaction is true, classify type:
EXPENSE (merchant receipt, invoice, bank transfer-out, ATM withdrawal) or INCOME (payslip, bank transfer-in, refund slip, deposit confirmation).

STEP 3 — Select category and account.
You will be given two lists in the user message: available categories (with keys) and available accounts (with names).
- "category" MUST be an exact key from the categories list.
- "account" MUST be an exact name from the accounts list. Pick the account that most plausibly funded (expense) or received (income) the transaction. If the document names a specific bank, card, or wallet that matches an account name, prefer that. If no signal, pick the user's primary/default-looking account.

STEP 4 — Confidence.
Return a single "confidence" scalar between 0.0 and 1.0 reflecting overall certainty about the extraction (legibility, amount clarity, category fit, account fit). Use 0.90+ only when every field is clearly readable and unambiguous.

Return this exact shape (when is_transaction is true):
{
  "is_transaction": true,
  "transaction_kind": "merchant_receipt|invoice|bank_transfer_out|bank_transfer_in|payslip|refund_slip|deposit_confirmation|atm_withdrawal|ewallet_transaction|other",
  "type": "expense|income",
  "merchant": "string or null",
  "currency": "ISO 4217 code or null",
  "items": [{ "name": "string", "qty": 1, "unit_price": 0.00, "total_price": 0.00 }],
  "total": 0.00,
  "category": "exact key from categories list",
  "account": "exact name from accounts list",
  "confidence": 0.00
}

Rules:
- "total" must be a positive number; "type" conveys the sign.
- "category" must be exactly one key from the lists provided in the user message.
- "account" must be exactly one name from the accounts list in the user message.
- Calculate "total" from individual items "total_price" if the "total" is not present or clearly incorrect.
- Default "type" to "expense" when the document is ambiguous.
- Use null for any non-required field that cannot be read from the document.`;

// Fallback only used when client sends no categories payload (e.g. signed-out demo).
const DEFAULT_EXPENSE_CATS: Array<{ key: string; name: string }> = [
  { key: "dining", name: "Dining" },
  { key: "groceries", name: "Groceries" },
  { key: "transport", name: "Transport" },
  { key: "shopping", name: "Shopping" },
  { key: "entertainment", name: "Entertainment" },
  { key: "utilities", name: "Utilities" },
  { key: "health", name: "Health" },
  { key: "travel", name: "Travel" },
  { key: "other", name: "Other" },
];

const DEFAULT_INCOME_CATS: Array<{ key: string; name: string }> = [
  { key: "income_salary", name: "Salary" },
  { key: "income_bonus", name: "Bonus" },
  { key: "income_freelance", name: "Freelance" },
  { key: "income_investment", name: "Investment" },
  { key: "income_gift", name: "Gift" },
  { key: "income_refund", name: "Refund" },
  { key: "income_other", name: "Other Income" },
];

function buildDynamicContext(
  categories: Category[] | undefined,
  accounts: AccountRef[] | undefined,
): string {
  const expenseCats =
    categories
      ?.filter((c) => c.kind === "expense")
      .map((c) => ({ key: c.key, name: c.name })) ?? DEFAULT_EXPENSE_CATS;

  const incomeCats =
    categories
      ?.filter((c) => c.kind === "income")
      .map((c) => ({ key: c.key, name: c.name })) ?? DEFAULT_INCOME_CATS;

  const expenseList = expenseCats.map((c) => `${c.key} (${c.name})`).join(", ");
  const incomeList = incomeCats.map((c) => `${c.key} (${c.name})`).join(", ");
  const accountList =
    accounts && accounts.length > 0
      ? accounts.map((a) => a.name).join(", ")
      : "Cash";

  return `Available EXPENSE categories: ${expenseList}
Available INCOME categories: ${incomeList}
Available accounts: ${accountList}`;
}

function extractPartialFields(rawText: string): Record<string, unknown> {
  const partial: Record<string, unknown> = {};
  const patterns: [string, RegExp][] = [
    ["type", /"type"\s*:\s*"(expense|income)"/],
    ["merchant", /"merchant"\s*:\s*"([^"]+)"/],
    ["date", /"date"\s*:\s*"(\d{4}-\d{2}-\d{2})"/],
    ["total", /"total"\s*:\s*([\d.]+)/],
    ["currency", /"currency"\s*:\s*"([A-Z]{3})"/],
    ["category", /"category"\s*:\s*"([^"]+)"/],
    ["account", /"account"\s*:\s*"([^"]+)"/],
    ["confidence", /"confidence"\s*:\s*([\d.]+)/],
  ];
  for (const [key, regex] of patterns) {
    const match = rawText.match(regex);
    if (match) partial[key] = match[1];
  }
  const itemsMatch = rawText.match(/"items"\s*:\s*(\[[\s\S]*?\])/);
  if (itemsMatch) {
    try {
      partial["items"] = JSON.parse(itemsMatch[1]);
    } catch { /* skip */ }
  }
  return partial;
}

async function authUser(req: Request): Promise<string | null> {
  const authHeader = req.headers.get("Authorization");
  if (!authHeader) return null;
  const token = authHeader.replace("Bearer ", "");
  const { data: { user }, error } = await supabase.auth.getUser(token);
  if (error || !user) return null;
  return user.id;
}

function jsonResponse(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json", ...CORS_HEADERS },
  });
}

serve(async (req) => {
  if (req.method === "OPTIONS")
    return new Response("ok", { headers: CORS_HEADERS });
  if (req.method !== "POST") {
    return new Response("Method Not Allowed", {
      status: 405,
      headers: CORS_HEADERS,
    });
  }

  const userId = await authUser(req);
  if (!userId) return jsonResponse({ error: "Unauthorized" }, 401);

  let body: {
    image?: string;
    categories?: Category[];
    accounts?: AccountRef[];
    strict_retry?: boolean;
  };
  try {
    body = await req.json();
  } catch {
    return jsonResponse({ error: "Invalid JSON body" }, 400);
  }

  const { image, categories, accounts, strict_retry } = body;
  if (!image) return jsonResponse({ error: "Missing image" }, 400);
  if (image.length > 8 * 1024 * 1024) {
    return jsonResponse({ error: "Image too large" }, 413);
  }

  const dynamicContext = buildDynamicContext(categories, accounts);
  const strictSuffix = strict_retry
    ? "\n\nReturn ONLY the JSON object. No prose, no markdown fences."
    : "";

  try {
    const result = await anthropic.messages.create({
      model: "claude-haiku-4-5-20251001",
      max_tokens: 1024,
      system: [
        {
          type: "text",
          text: STATIC_PROMPT,
          // deno-lint-ignore no-explicit-any
          cache_control: { type: "ephemeral" } as any,
        },
      ],
      messages: [
        {
          role: "user",
          content: [
            {
              type: "image",
              source: { type: "base64", media_type: "image/jpeg", data: image },
            },
            { type: "text", text: dynamicContext + strictSuffix },
          ],
        },
      ],
    });

    const text =
      result.content[0]?.type === "text" ? result.content[0].text : "";
    const stripped = text
      .trim()
      .replace(/^```(?:json)?\s*/i, "")
      .replace(/```\s*$/i, "")
      .trim();

    try {
      const parsed = JSON.parse(stripped);
      if (parsed && parsed.is_transaction === false) {
        return jsonResponse(
          {
            not_a_transaction: true,
            transaction_kind: parsed.transaction_kind ?? null,
            reason: typeof parsed.reason === "string" ? parsed.reason : null,
          },
          422,
        );
      }
      if (
        !(parsed.total > 0) &&
        Array.isArray(parsed.items) &&
        parsed.items.length > 0
      ) {
        parsed.total = parsed.items.reduce(
          (sum: number, item: Record<string, unknown>) => {
            const tp =
              typeof item.total_price === "number" ? item.total_price : 0;
            const qp =
              typeof item.qty === "number" &&
              typeof item.unit_price === "number"
                ? item.qty * item.unit_price
                : 0;
            return sum + (tp > 0 ? tp : qp);
          },
          0,
        );
      }
      // Clamp confidence into [0,1]; default to 0.5 if absent.
      if (typeof parsed.confidence !== "number") {
        parsed.confidence = 0.5;
      } else {
        parsed.confidence = Math.max(0, Math.min(1, parsed.confidence));
      }
      return jsonResponse(parsed, 200);
    } catch {
      const partialFields = extractPartialFields(stripped);
      const hasUsableTotal =
        typeof partialFields.total === "string" &&
        parseFloat(partialFields.total) > 0;
      const hasUsableItems =
        Array.isArray(partialFields.items) && partialFields.items.length > 0;
      if (hasUsableTotal || hasUsableItems) {
        const coerced: Record<string, unknown> = { ...partialFields };
        if (typeof coerced.total === "string") {
          coerced.total = parseFloat(coerced.total as string);
        }
        if (typeof coerced.confidence === "string") {
          const c = parseFloat(coerced.confidence as string);
          coerced.confidence = Number.isFinite(c)
            ? Math.max(0, Math.min(1, c))
            : 0.4;
        } else {
          coerced.confidence = 0.4;
        }
        return jsonResponse(coerced, 200);
      }
      return jsonResponse(
        { ai_failure: true, partial_fields: partialFields },
        422,
      );
    }
  } catch (err) {
    console.error("Claude API error:", err);
    return jsonResponse({ error: "Scan service unavailable" }, 500);
  }
});
