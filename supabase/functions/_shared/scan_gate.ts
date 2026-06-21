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

// Single authority for gating + parsing a Scan (image OCR). Used by both the
// in-app `scan-receipt` Edge Function and the Telegram image handler so the
// quota model, retry behaviour, and reconciliation stay identical.
//
// Contract:
//   - Reserve one credit BEFORE the AI call (enforces the per-tier cap).
//   - Strict-retry once internally on malformed JSON — one logical capture is
//     billed once, no matter how many AI attempts it takes (last attempt's
//     output tokens drive the charge).
//   - After a usable parse, charge any credits beyond the reserved 1, by
//     output tokens (ADR-0017). This may overshoot the cap (soft cap).
//   - Refund the reserved credit when the AI returns no usable transaction
//     (`not_a_transaction` / `ai_failure` / thrown error). A usable result
//     (`ok` / `partial`) keeps the charge even if the caller later discards it.
//   - Save failures are the CALLER's concern; this helper does not refund them.
export type GatedScanResult =
  | { kind: "quota_reached" }
  | (ReceiptParseResult & {
    creditsCharged: number;
    creditsRemaining: number | null;
  });

export async function gatedScan(args: {
  userId: string;
  tier: string;
  imageBase64: string;
  categories?: Category[];
  accounts?: AccountRef[];
}): Promise<GatedScanResult> {
  const reserve = await consumeScanQuota(args.userId, args.tier);
  if (reserve === null) return { kind: "quota_reached" };

  let res: ReceiptParseResult;
  try {
    res = await parseReceiptImage({
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
  } catch (err) {
    await refundScanQuota(args.userId);
    throw err;
  }

  if (res.kind === "not_a_transaction" || res.kind === "ai_failure") {
    await refundScanQuota(args.userId);
    return { ...res, creditsCharged: 0, creditsRemaining: null };
  }

  // Usable parse — charge any credits beyond the 1 reserved at the gate.
  // ponytail: this reserve→charge→remaining block is hand-copied in the
  // telegram text + voice paths. Extract a shared `meterCapture` wrapper when a
  // 4th capture surface lands or the charge rule changes — not before (the
  // failure-messaging differs per surface, so only this 3-line tail is shared).
  const credits = creditsForTokens(res.completionTokens, 1);
  const usedAfter = await chargeExtraCredits(args.userId, credits - 1) ??
    reserve.used;
  const remaining = remainingFromUsed(usedAfter, reserve.cap);
  return { ...res, creditsCharged: credits, creditsRemaining: remaining };
}
