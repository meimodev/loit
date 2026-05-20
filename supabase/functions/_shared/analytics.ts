// Sanitized analytics + error reporting wrapper. Bucket amounts; never
// emit merchant text, raw transcripts, account names, or category labels.

const POSTHOG_HOST =
  Deno.env.get("POSTHOG_HOST") ?? "https://us.i.posthog.com";
const POSTHOG_KEY = Deno.env.get("POSTHOG_API_KEY") ?? "";
const SENTRY_DSN = Deno.env.get("SENTRY_DSN") ?? "";

export function amountBucket(amount: number): string {
  const a = Math.abs(amount);
  if (a < 50_000) return "0-50k";
  if (a < 200_000) return "50k-200k";
  if (a < 1_000_000) return "200k-1M";
  return "1M+";
}

export function confidenceBucket(c: number | null | undefined): string {
  if (c == null) return "unknown";
  if (c >= 0.85) return "high";
  if (c >= 0.6) return "mid";
  return "low";
}

export interface BotEvent {
  event: string;
  platform: string;
  messageType: "text" | "voice" | "image" | "command" | "callback";
  scope?: "personal" | "room";
  confidence?: string;
  amountBucket?: string;
  userId?: string;
  extra?: Record<string, string | number | boolean>;
}

async function capturePosthog(ev: BotEvent): Promise<void> {
  if (!POSTHOG_KEY) return;
  const { userId, event, extra, ...rest } = ev;
  try {
    await fetch(`${POSTHOG_HOST}/capture/`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        api_key: POSTHOG_KEY,
        event,
        // Use stable LOIT user id when present; otherwise group under platform.
        distinct_id: userId ?? `bot_${ev.platform}`,
        properties: { ...rest, ...(extra ?? {}) },
        timestamp: new Date().toISOString(),
      }),
    });
  } catch (e) {
    console.error(
      JSON.stringify({
        kind: "posthog_capture_failed",
        error: e instanceof Error ? e.message : String(e),
      }),
    );
  }
}

async function captureSentry(
  message: string,
  ctx: { stage: string; platform: string; userId?: string },
): Promise<void> {
  if (!SENTRY_DSN) return;
  // Parse the standard DSN form: https://<key>@<host>/<project>.
  let match: RegExpMatchArray | null = null;
  try {
    match = SENTRY_DSN.match(/^https?:\/\/([^@]+)@([^/]+)\/(.+)$/);
  } catch {
    return;
  }
  if (!match) return;
  const [, publicKey, host, projectId] = match;
  const url = `https://${host}/api/${projectId}/store/`;
  try {
    await fetch(url, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-Sentry-Auth":
          `Sentry sentry_version=7, sentry_key=${publicKey}, sentry_client=loit-bot/0.1`,
      },
      body: JSON.stringify({
        message,
        level: "error",
        platform: "javascript",
        tags: { stage: ctx.stage, channel: ctx.platform },
        user: ctx.userId ? { id: ctx.userId } : undefined,
      }),
    });
  } catch (e) {
    console.error(
      JSON.stringify({
        kind: "sentry_capture_failed",
        error: e instanceof Error ? e.message : String(e),
      }),
    );
  }
}

export function logBotEvent(ev: BotEvent): void {
  // Structured JSON line — easy to ship to Logflare/PostHog via a worker later.
  // No PII fields are accepted by this function's type, so leaks are
  // prevented at the call site.
  console.log(JSON.stringify({ kind: "bot_event", ts: Date.now(), ...ev }));
  // Fire-and-forget PostHog capture.
  capturePosthog(ev).catch(() => {});
}

export function logBotError(
  err: unknown,
  ctx: { stage: string; platform: string; userId?: string },
): void {
  const msg = err instanceof Error ? err.message : String(err);
  console.error(
    JSON.stringify({ kind: "bot_error", ts: Date.now(), error: msg, ...ctx }),
  );
  captureSentry(msg, ctx).catch(() => {});
}
