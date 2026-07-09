import {
  parseReceiptImage,
  type AccountRef,
  type Category,
  type ReceiptParseResult,
} from "./receipt_parser.ts";
import { gatedCapture, type GatedCaptureResult } from "./gated_capture.ts";

// The generic metering tail lives in gated_capture.ts (kept dependency-light so
// non-receipt functions like classify-taxonomy can reuse it without pulling in
// receipt parsing). Re-exported here for back-compat with callers that import
// it from scan_gate (e.g. parse-voice).
export { gatedCapture } from "./gated_capture.ts";
export type { GatedCaptureResult, Metered } from "./gated_capture.ts";

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
