import {
  chargeExtraCredits,
  consumeScanQuota,
  creditsForTokens,
  refundScanQuota,
  remainingFromUsed,
} from "./quota.ts";
import {
  parseReceiptImage,
  type AccountRef,
  type Category,
  type ReceiptParseResult,
} from "./receipt_parser.ts";

// Generic gating tail shared by every AI Capture surface (image OCR via
// `gatedScan`, voice/text parse via the parse-voice Edge Function). Each
// surface owns its own result vocabulary, so the caller supplies `parse` and a
// `classify` that maps the result to {usable, completionTokens}.
//
// Contract:
//   - Reserve one credit BEFORE the AI call (enforces the per-tier cap).
//   - Run `parse` (which may itself retry internally — one logical capture is
//     billed once regardless of attempts; the result's completion tokens drive
//     the charge).
//   - After a usable parse, charge any credits beyond the reserved 1, by output
//     tokens (ADR-0017). This may overshoot the cap (soft cap).
//   - Refund the reserved credit when `classify` reports not-usable, or `parse`
//     throws. A usable result keeps the charge even if the caller later
//     discards it. Save failures are the CALLER's concern.
export type Metered<T> = T & {
  creditsCharged: number;
  creditsRemaining: number | null;
};
export type GatedCaptureResult<T> = { kind: "quota_reached" } | Metered<T>;

export async function gatedCapture<T extends object>(args: {
  userId: string;
  tier: string;
  parse: () => Promise<T>;
  classify: (res: T) => { usable: boolean; completionTokens: number };
}): Promise<GatedCaptureResult<T>> {
  const reserve = await consumeScanQuota(args.userId, args.tier);
  if (reserve === null) return { kind: "quota_reached" };

  let res: T;
  try {
    res = await args.parse();
  } catch (err) {
    await refundScanQuota(args.userId);
    throw err;
  }

  const { usable, completionTokens } = args.classify(res);
  if (!usable) {
    await refundScanQuota(args.userId);
    return { ...res, creditsCharged: 0, creditsRemaining: null };
  }

  const credits = creditsForTokens(completionTokens, 1);
  const usedAfter = await chargeExtraCredits(args.userId, credits - 1) ??
    reserve.used;
  const remaining = remainingFromUsed(usedAfter, reserve.cap);
  return { ...res, creditsCharged: credits, creditsRemaining: remaining };
}

// Single authority for gating + parsing a Scan (image OCR). Used by both the
// in-app `scan-receipt` Edge Function and the Telegram image handler so the
// quota model, retry behaviour, and reconciliation stay identical. Thin wrapper
// over `gatedCapture` — owns only the image-specific parse + strict retry.
export type GatedScanResult = GatedCaptureResult<ReceiptParseResult>;

export function gatedScan(args: {
  userId: string;
  tier: string;
  imageBase64: string;
  categories?: Category[];
  accounts?: AccountRef[];
}): Promise<GatedScanResult> {
  return gatedCapture<ReceiptParseResult>({
    userId: args.userId,
    tier: args.tier,
    parse: async () => {
      let res = await parseReceiptImage({
        imageBase64: args.imageBase64,
        categories: args.categories,
        accounts: args.accounts,
        strictRetry: false,
      });
      if (res.kind === "ai_failure") {
        // One stricter retry — the expensive vision tokens already burned, so
        // squeeze a usable parse out before giving up. Still one charge.
        res = await parseReceiptImage({
          imageBase64: args.imageBase64,
          categories: args.categories,
          accounts: args.accounts,
          strictRetry: true,
        });
      }
      return res;
    },
    classify: (res) => ({
      usable: res.kind !== "not_a_transaction" && res.kind !== "ai_failure",
      completionTokens:
        res.kind === "ok" || res.kind === "partial" ? res.completionTokens : 0,
    }),
  });
}
