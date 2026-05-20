import { serviceClient } from "./supabase.ts";

// Per-tier monthly base caps; mirror Flutter `FeatureFlags.scanLimitPerMonth`.
const TIER_CAP: Record<string, number | null> = {
  free: 5,
  lite: 30,
  pro: 150,
};

export interface QuotaState {
  used: number;
  bonus: number;
  cap: number | null; // null = unlimited
  reached: boolean;
}

export async function readQuotaState(
  userId: string,
  tier: string,
): Promise<QuotaState> {
  const sb = serviceClient();
  await sb.rpc("reset_scan_quota_if_new_month", { p_user_id: userId });
  const { data } = await sb
    .from("users")
    .select("scans_used_this_month, scan_topup_bonus_this_month")
    .eq("id", userId)
    .maybeSingle();
  const used = data?.scans_used_this_month ?? 0;
  const bonus = data?.scan_topup_bonus_this_month ?? 0;
  const base = TIER_CAP[tier] ?? null;
  const cap = base === null ? null : base + bonus;
  const reached = cap !== null && used >= cap;
  return { used, bonus, cap, reached };
}

// Atomically reserve one scan. Returns the new used count, or null when
// the cap was already reached. Unlimited tiers always succeed.
export async function consumeScanQuota(
  userId: string,
  tier: string,
): Promise<number | null> {
  const sb = serviceClient();
  await sb.rpc("reset_scan_quota_if_new_month", { p_user_id: userId });
  const base = TIER_CAP[tier] ?? null;
  if (base === null) {
    // No cap — count consumption for analytics but never block.
    const { data } = await sb.rpc("increment_scan_quota", {
      p_user_id: userId,
      p_limit: Number.MAX_SAFE_INTEGER,
    });
    return data as number | null;
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
  return data as number | null;
}

export async function refundScanQuota(userId: string): Promise<void> {
  const sb = serviceClient();
  await sb.rpc("refund_scan_quota", { p_user_id: userId });
}
