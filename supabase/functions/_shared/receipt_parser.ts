import { chatComplete, imageDataUrl } from "./openrouter.ts";

export type Category = { key: string; name: string; kind: string };
export type AccountRef = { name: string };

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

export function buildDynamicContext(
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
  // Never invent accounts: when the user has no active accounts, the parser
  // is told so explicitly and the server rejects the resulting save.
  const accountList =
    accounts && accounts.length > 0
      ? accounts.map((a) => a.name).join(", ")
      : "(none)";
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

// `completionTokens` rides on every result so the gate can meter AI Credits
// (ADR-0017). It is the output-token count of the AI call that produced this
// result (the last attempt when a strict retry ran).
export type ReceiptParseResult =
  | { kind: "ok"; parsed: Record<string, unknown>; completionTokens: number }
  | { kind: "not_a_transaction"; transactionKind: string | null; reason: string | null; completionTokens: number }
  | { kind: "partial"; partial: Record<string, unknown>; completionTokens: number }
  | { kind: "ai_failure"; partial: Record<string, unknown>; completionTokens: number };

export async function parseReceiptImage(args: {
  imageBase64: string;
  categories?: Category[];
  accounts?: AccountRef[];
  strictRetry?: boolean;
}): Promise<ReceiptParseResult> {
  const dynamicContext = buildDynamicContext(args.categories, args.accounts);
  const strictSuffix = args.strictRetry
    ? "\n\nReturn ONLY the JSON object. No prose, no markdown fences."
    : "";

  const { text, completionTokens } = await chatComplete({
    system: STATIC_PROMPT,
    userContent: [
      { type: "image_url", image_url: { url: imageDataUrl(args.imageBase64) } },
      { type: "text", text: dynamicContext + strictSuffix },
    ],
    // Long itemized receipts (70+ lines) overflow a small budget mid-`items`,
    // truncating the JSON before total/category/account and forcing a partial.
    // 8192 fits ~270 items; billing meters actual output, not this ceiling.
    maxTokens: 8192,
  });
  const stripped = text
    .trim()
    .replace(/^```(?:json)?\s*/i, "")
    .replace(/```\s*$/i, "")
    .trim();

  try {
    const parsed = JSON.parse(stripped);
    if (parsed && parsed.is_transaction === false) {
      return {
        kind: "not_a_transaction",
        transactionKind: parsed.transaction_kind ?? null,
        reason: typeof parsed.reason === "string" ? parsed.reason : null,
        completionTokens,
      };
    }
    // Arithmetic reconciliation — mirrors the in-app scanner's `_postProcess`
    // (tolerance 1.0 per line item) so both surfaces compute the same total
    // and raise the same mismatch flag.
    const items: Array<Record<string, unknown>> = Array.isArray(parsed.items)
      ? parsed.items
      : [];
    let itemSum = 0;
    for (const item of items) {
      const tp = typeof item.total_price === "number" ? item.total_price : 0;
      const qp =
        typeof item.qty === "number" && typeof item.unit_price === "number"
          ? item.qty * item.unit_price
          : 0;
      itemSum += tp > 0 ? tp : qp;
    }
    const returnedTotal = typeof parsed.total === "number" ? parsed.total : 0;
    parsed.total_computed = false;
    parsed.reconcile_warning = false;
    if (!(returnedTotal > 0) && itemSum > 0) {
      parsed.total = itemSum;
      parsed.total_computed = true;
    } else if (returnedTotal > 0 && itemSum > 0) {
      const tol = 1.0 * items.length;
      if (Math.abs(returnedTotal - itemSum) > tol) parsed.reconcile_warning = true;
    }
    if (typeof parsed.confidence !== "number") {
      parsed.confidence = 0.5;
    } else {
      parsed.confidence = Math.max(0, Math.min(1, parsed.confidence));
    }
    return { kind: "ok", parsed, completionTokens };
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
      return { kind: "partial", partial: coerced, completionTokens };
    }
    return { kind: "ai_failure", partial: partialFields, completionTokens };
  }
}
