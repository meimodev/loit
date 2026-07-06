import {
  chargeExtraCredits,
  consumeScanQuota,
  creditsForTokens,
  refundScanQuota,
  remainingFromUsed,
} from "./quota.ts";

// Generic gating tail shared by every AI Capture surface (image OCR, voice/text
// parse, taxonomy classification). Each surface owns its own result vocabulary,
// so the caller supplies `parse` and a `classify` that maps the result to
// {usable, completionTokens}. Kept dependency-light (quota only) so any function
// can reuse it without dragging in receipt-parsing code.
//
// Contract:
//   - Reserve one credit BEFORE the AI call (enforces the per-tier cap).
//   - Run `parse` (which may retry internally — one logical capture is billed
//     once regardless of attempts; the result's completion tokens drive charge).
//   - After a usable parse, charge any credits beyond the reserved 1, by output
//     tokens (ADR-0017). This may overshoot the cap (soft cap).
//   - Refund the reserved credit when `classify` reports not-usable, or `parse`
//     throws. A usable result keeps the charge even if the caller later discards
//     it. Save failures are the CALLER's concern.
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
