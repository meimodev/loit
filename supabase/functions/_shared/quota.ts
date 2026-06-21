import { serviceClient } from "./supabase.ts";

// Per-tier monthly base caps. Keep in sync with
// `lib/core/config/pricing_constants.dart` (scanCapFree/Lite/Pro) — the Dart
// client is the source of truth; this is the hand-copied server mirror.
const TIER_CAP: Record<string, number | null> = {
  free: 5,
  lite: 30,
  pro: 150,
};

// Outcome of reserving one credit at the gate. `cap` is the effective cap
// (base + top-up bonus), null = unlimited; threaded out so callers can compute
// remaining credits after the charge without a second DB read.
export interface ReserveResult {
  used: number; // running monthly count AFTER this reservation
  cap: number | null; // null = unlimited
}

// Atomically reserve one scan. Returns { used, cap }, or null when the cap was
// already reached. Unlimited tiers always succeed (cap null).
export async function consumeScanQuota(
  userId: string,
  tier: string,
): Promise<ReserveResult | null> {
  const sb = serviceClient();
  await sb.rpc("reset_scan_quota_if_new_month", { p_user_id: userId });
  const base = TIER_CAP[tier] ?? null;
  if (base === null) {
    // No cap — count consumption for analytics but never block.
    const { data } = await sb.rpc("increment_scan_quota", {
      p_user_id: userId,
      p_limit: Number.MAX_SAFE_INTEGER,
    });
    const used = data as number | null;
    return used === null ? null : { used, cap: null };
  }
  const { data: bonusRow } = await sb
    .from("users")
    .select("scan_topup_bonus_this_month")
    .eq("id", userId)
    .maybeSingle();
  const bonus = bonusRow?.scan_topup_bonus_this_month ?? 0;
  const effective = base + bonus;
  const { data } = await sb.rpc("increment_scan_quota", {
    p_user_id: userId,
    p_limit: effective,
  });
  const used = data as number | null;
  return used === null ? null : { used, cap: effective };
}

export async function refundScanQuota(userId: string): Promise<void> {
  const sb = serviceClient();
  await sb.rpc("refund_scan_quota", { p_user_id: userId });
}

// --- AI Credits (ADR-0017) ------------------------------------------------
// One capture costs max(floor, ceil(completion_tokens / 1024)) credits.
// Output tokens only — they scale with content; the fixed image/prompt input
// is the floor and is covered by the 1 credit reserved at the gate.
const TOKENS_PER_CREDIT = 1024;

export function creditsForTokens(completionTokens: number, floor = 1): number {
  return Math.max(floor, Math.ceil(completionTokens / TOKENS_PER_CREDIT));
}

// Charge `extra` credits beyond the 1 already reserved at the gate. Allows the
// monthly count to overshoot the cap (soft cap) — the true cost is only known
// after the AI responds. Returns the new running count, or null when nothing
// was charged (extra <= 0) so the caller falls back to the reserved count.
export async function chargeExtraCredits(
  userId: string,
  extra: number,
): Promise<number | null> {
  if (extra <= 0) return null;
  const sb = serviceClient();
  const { data } = await sb.rpc("add_scan_quota", {
    p_user_id: userId,
    p_amount: extra,
  });
  return data as number | null;
}

// Credits left this month, for user feedback only (not the gate authority).
// Computed from the post-charge `used` + the `cap` carried out of the reserve —
// no DB read. null = unlimited. Clamped at 0 so an overshoot reads as "0 left".
export function remainingFromUsed(
  used: number,
  cap: number | null,
): number | null {
  return cap === null ? null : Math.max(0, cap - used);
}
