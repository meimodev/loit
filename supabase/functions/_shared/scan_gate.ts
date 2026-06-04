import { consumeScanQuota, refundScanQuota } from "./quota.ts";
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
//   - Reserve one Scan BEFORE the AI call (enforces the per-tier cap).
//   - Strict-retry once internally on malformed JSON — one logical scan is at
//     most one charge, no matter how many AI attempts it takes.
//   - Refund ONLY when the AI returns no usable transaction
//     (`not_a_transaction` / `ai_failure` / thrown error). A usable result
//     (`ok` / `partial`) keeps the charge even if the caller later discards it.
//   - Save failures are the CALLER's concern; this helper does not refund them.
export type GatedScanResult =
  | { kind: "quota_reached" }
  | ReceiptParseResult;

export async function gatedScan(args: {
  userId: string;
  tier: string;
  imageBase64: string;
  categories?: Category[];
  accounts?: AccountRef[];
}): Promise<GatedScanResult> {
  const used = await consumeScanQuota(args.userId, args.tier);
  if (used === null) return { kind: "quota_reached" };

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
  }
  return res;
}
