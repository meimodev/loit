// Edge-side mirror of `formatBreakdown` in
// `lib/features/transactions/notes_breakdown.dart`. Produces the same canonical
// `notes` text the Flutter app's `parseBreakdown` recognises so Telegram-saved
// receipt transactions render with the in-app item-breakdown UI.

const CURRENCY_SYMBOLS: Record<string, string> = {
  IDR: "Rp",
  USD: "$",
  EUR: "€",
  GBP: "£",
  SGD: "S$",
  MYR: "RM",
  THB: "฿",
  PHP: "₱",
  VND: "₫",
  JPY: "¥",
  CNY: "¥",
  AUD: "A$",
  NZD: "NZ$",
  CAD: "C$",
  HKD: "HK$",
  KRW: "₩",
  INR: "₹",
};

function currencySymbol(currency: string): string {
  const code = (currency || "").toUpperCase();
  return CURRENCY_SYMBOLS[code] ?? code;
}

// Mirrors Flutter `NumberFormat('#,##0.##', 'id_ID')`:
// - thousands grouped with '.'
// - decimals separated by ',', up to 2 digits, trailing zeros stripped
function fmtNum(v: number): string {
  if (!Number.isFinite(v)) return "";
  const sign = v < 0 ? "-" : "";
  const abs = Math.abs(v);
  const rounded = Math.round(abs * 100) / 100;
  const fixed = rounded.toFixed(2);
  const [intRaw, fracRaw] = fixed.split(".");
  const intGrouped = intRaw.replace(/\B(?=(\d{3})+(?!\d))/g, ".");
  const frac = (fracRaw || "").replace(/0+$/, "");
  return frac ? `${sign}${intGrouped},${frac}` : `${sign}${intGrouped}`;
}

function fmtMoney(v: number, currency: string | null | undefined): string {
  const n = fmtNum(v);
  if (!currency) return n;
  return `${currencySymbol(currency)} ${n}`;
}

export interface BreakdownItemInput {
  name?: unknown;
  qty?: unknown;
  unit_price?: unknown;
  total_price?: unknown;
}

export interface BreakdownInput {
  merchant?: string | null;
  items?: BreakdownItemInput[] | null;
  total?: number | null;
  currency?: string | null;
}

function toFiniteNumber(x: unknown): number | null {
  if (typeof x === "number" && Number.isFinite(x)) return x;
  if (typeof x === "string" && x.trim()) {
    const n = Number(x);
    if (Number.isFinite(n)) return n;
  }
  return null;
}

// Normalises a parsed receipt to the canonical notes-breakdown text. Returns
// null when there's nothing structured to render (no merchant + no items).
export function formatBreakdownNotes(input: BreakdownInput): string | null {
  const merchant = (input.merchant ?? "").toString().trim();
  const rawItems = Array.isArray(input.items) ? input.items : [];
  const currency = input.currency ?? null;

  const lines: string[] = [];
  const headerLine = merchant.length > 0 ? merchant : null;

  type Norm = {
    name: string;
    qty: number | null;
    unit: number | null;
    total: number | null;
  };
  const items: Norm[] = [];
  for (const raw of rawItems) {
    const name = ((raw?.name ?? "") as string).toString().trim();
    const qty = toFiniteNumber(raw?.qty);
    const unit = toFiniteNumber(raw?.unit_price);
    const total = toFiniteNumber(raw?.total_price);
    if (!name && qty == null && unit == null && total == null) continue;
    items.push({ name, qty, unit, total });
  }

  if (!headerLine && items.length === 0) return null;

  // `parseBreakdown` requires a non-empty, non-bullet first line. When we have
  // items but no merchant, fall back to a placeholder so the structure stays
  // recognisable.
  lines.push(headerLine ?? (items.length > 0 ? "Receipt" : ""));

  for (const it of items) {
    const parts = ["- ", it.name];
    const right: string[] = [];
    const hasQty = it.qty != null && it.qty > 0;
    const hasUnit = it.unit != null && it.unit > 0;
    const hasTotal = it.total != null && it.total > 0;
    if (hasQty && hasUnit) {
      right.push(`${fmtNum(it.qty!)} × ${fmtMoney(it.unit!, currency)}`);
    } else if (hasQty) {
      right.push(`${fmtNum(it.qty!)} ×`);
    } else if (hasUnit) {
      right.push(`× ${fmtMoney(it.unit!, currency)}`);
    }
    if (hasTotal) {
      right.push(`= ${fmtMoney(it.total!, currency)}`);
    }
    if (right.length > 0) {
      parts.push(it.name ? " : " : "");
      parts.push(right.join(" "));
    }
    lines.push(parts.join(""));
  }

  const total = toFiniteNumber(input.total);
  if (total != null && total > 0) {
    lines.push(`Total: ${fmtMoney(total, currency)}`);
  }

  return lines.join("\n");
}

// Loose detector: does this text look like the canonical breakdown shape?
// Used by `saveTransaction` to avoid prepending merchant again when the
// caller already produced canonical notes.
export function looksLikeCanonicalBreakdown(text: string): boolean {
  if (!text) return false;
  const lines = text.split("\n");
  if (lines.length < 2) return false;
  const bullet = /^\s*[-•*]\s+/;
  const totalLine = /^\s*Total\s*:/i;
  for (let i = 1; i < lines.length; i++) {
    const ln = lines[i];
    if (!ln.trim()) continue;
    if (bullet.test(ln) || totalLine.test(ln)) return true;
  }
  return false;
}
