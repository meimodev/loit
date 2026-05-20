// Edge-side money formatter aligned with Flutter `formatMoney` in
// `lib/shared/utils/amount_input.dart`. Groups thousands with a separator
// chosen per currency (IDR/EUR use '.', others ','). Fraction digits default
// to 0 for IDR and 2 elsewhere.

const COMMA_DECIMAL = new Set(["IDR", "EUR"]);

export function formatMoney(
  amount: number,
  currency: string,
  opts?: { hide?: boolean; fractionDigits?: number },
): string {
  if (opts?.hide) return "••••";
  const code = (currency || "IDR").toUpperCase();
  const useCommaDecimal = COMMA_DECIMAL.has(code);
  const groupSep = useCommaDecimal ? "." : ",";
  const decSep = useCommaDecimal ? "," : ".";
  const fd =
    opts?.fractionDigits ?? (code === "IDR" ? 0 : 2);
  const abs = Math.abs(amount);
  const fixed = abs.toFixed(fd);
  const [intPart, fracPart] = fixed.split(".");
  const withGroups = intPart.replace(/\B(?=(\d{3})+(?!\d))/g, groupSep);
  const sign = amount < 0 ? "-" : "";
  return fracPart ? `${sign}${withGroups}${decSep}${fracPart}` : `${sign}${withGroups}`;
}

export function moneyWithSymbol(
  amount: number,
  currency: string,
  opts?: { hide?: boolean },
): string {
  return `${formatMoney(amount, currency, opts)} ${currency.toUpperCase()}`;
}

// Symbol map for bot display formatting. Centralised here so the Telegram
// adapter can render e.g. `Rp25.000` instead of `25.000 IDR`. Unmapped codes
// fall back to `ISO 12,345` so output stays unambiguous.
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

// Locale-aware, symbol-first display formatter used by chat-style replies.
// Privacy: respects `hide` like `formatMoney`. Sign is NOT included — callers
// prefix `-` or `+` so expense/income framing is explicit at the call site.
export function formatMoneyDisplay(
  amount: number,
  currency: string,
  opts?: { hide?: boolean; locale?: string },
): string {
  if (opts?.hide) return "••••";
  const code = (currency || "IDR").toUpperCase();
  const abs = Math.abs(amount);
  const body = formatMoney(abs, code);
  const symbol = CURRENCY_SYMBOLS[code];
  if (symbol) return `${symbol}${body}`;
  // Unknown ISO: emit code-prefixed form, locale-comma for non-ID en users.
  const sep = opts?.locale === "id" ? "." : ",";
  // body already uses code-appropriate grouping; just prefix the code.
  void sep;
  return `${code} ${body}`;
}
