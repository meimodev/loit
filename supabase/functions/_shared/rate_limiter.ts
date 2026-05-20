import { serviceClient } from "./supabase.ts";
import type { Platform } from "./messaging_identity.ts";

const WINDOW_MS = 60 * 60 * 1000; // 1 hour
const MAX_EVENTS = 50;

export interface RateDecision {
  allowed: boolean;
  // True the first time the limit is exceeded — warn once, then go silent.
  shouldWarn: boolean;
  remaining: number;
}

export async function checkRateLimit(
  platform: Platform,
  externalChatId: string,
  userId: string | null,
): Promise<RateDecision> {
  const sb = serviceClient();
  const windowStart = new Date(Date.now() - WINDOW_MS).toISOString();

  const { data: recent } = await sb
    .from("bot_rate_limit_events")
    .select("id, warned, event_at")
    .eq("platform", platform)
    .eq("external_chat_id", externalChatId)
    .gte("event_at", windowStart)
    .order("event_at", { ascending: false });

  const count = recent?.length ?? 0;
  if (count >= MAX_EVENTS) {
    const alreadyWarned = recent?.some((r) => r.warned) ?? false;
    if (alreadyWarned) {
      return { allowed: false, shouldWarn: false, remaining: 0 };
    }
    // Mark a warn event so we only warn once per window.
    await sb.from("bot_rate_limit_events").insert({
      platform,
      external_chat_id: externalChatId,
      user_id: userId,
      warned: true,
    });
    return { allowed: false, shouldWarn: true, remaining: 0 };
  }

  await sb.from("bot_rate_limit_events").insert({
    platform,
    external_chat_id: externalChatId,
    user_id: userId,
    warned: false,
  });
  return { allowed: true, shouldWarn: false, remaining: MAX_EVENTS - count - 1 };
}
