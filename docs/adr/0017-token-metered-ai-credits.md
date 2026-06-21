# 17. Token-metered AI Credits replace flat scan quota

Date: 2026-06-21

## Status

Accepted

Builds on [0016](0016-all-ai-through-openrouter.md) (all AI on OpenRouter,
which exposes per-call `usage.completion_tokens`).

## Context

Server-side AI gating used a flat **scan quota**: one image scan = one charge,
voice = one charge, text = free/unlimited. Caps: free 5, lite 30, pro 150 per
month (+ top-up bonus); unknown tier = unlimited.

Two problems surfaced:

1. **Truncation.** Receipt parsing capped output at `max_tokens: 1024`. A long
   receipt (70+ items) overflows that mid-`items`, so the JSON is cut off
   before `total`/`category`/`account` and the parse degrades to a partial. The
   output shape lists `items` *before* those fields, so truncation loses the
   ones that matter.
2. **Naming/fairness.** "Scan" already billed voice and could bill text, yet a
   2-item and a 70-item receipt cost the same one unit. The owner wants heavy
   captures to cost more, every AI path to count, and the user-facing term to
   stop implying "a photo."

## Decision

Replace the flat scan quota with **token-metered AI Credits.**

- **Unit:** `credits = max(1, ceil(completion_tokens / 1024))` per capture.
  Output (completion) tokens only — they scale with item/content count. The
  fixed image+prompt input (~1.6k tokens) is the cost floor and is covered by
  the base 1 credit; counting it would make every image cost ≥2.
- **All paths metered, floor 1:** text, voice, and image each cost ≥1 credit.
  Text is no longer unlimited. Voice is metered on its **Haiku parse step's**
  completion tokens (Whisper STT bills per second, has no token count; its cost
  is absorbed into the floor).
- **Soft cap, charge-after.** Units are only known after the model responds, but
  the cap is enforced before. So: gate the capture if ≥1 credit remains, run it,
  then charge the actual credits. The final capture may push the user *over* the
  cap — those tokens are already spent and cannot be un-billed. The next capture
  is then blocked. Overshoot is bounded to one capture.
- **Refund** the reserved credit on `not_a_transaction` / `ai_failure` / thrown
  error; a usable parse keeps the full charge. Failed captures never bill.
- **Caps unchanged** (free 5 / lite 30 / pro 150 + bonus; unknown = unlimited).
  Deliberately kept tight now that text counts: this is an aggressive upsell —
  a daily-logging free user reaches the cap within a week. Retention risk
  accepted in exchange for monetization pressure.
- **`max_tokens` raised 1024 → 8192** to end truncation (~270 items). Billing
  uses actual completion tokens, not this ceiling, so the raise does not inflate
  normal charges; a pathological receipt costs at most 8 credits in one capture.
- **User-facing name: "AI Credits" / "Kredit AI."** "Credits" naturally come in
  variable amounts, so "one receipt = 3 credits" reads as normal rather than a
  bug. The bot shows remaining credits on every capture, the per-capture cost
  when >1, and a block/reset message at the cap; the app shows a credits meter.

`CLAUDE.md`'s stale "free 8 / pro·team unlimited" is corrected to the code's
free 5 / pro 150 as part of this work.

## Consequences

- **The cap is soft, not hard.** A single large capture can exceed the monthly
  cap; the system eats that token cost. Acceptable because the overshoot is
  bounded to one capture and absolute cost is tiny (~1.5¢ for a 70-item receipt
  on Haiku at $1/M in, $5/M out).
- **Cost is unpredictable to users**, mitigated only by the per-capture credit
  feedback. Without that feedback this model is a support liability.
- **Text logging is no longer free** — friction on the highest-volume, cheapest
  path; the chief retention risk of the tight-cap choice.
- **Plumbing widens:** `chatComplete` must return `usage`; parsers bubble it to
  the gate; a new SQL RPC charges N credits allowing overshoot; the bot and
  `scan-receipt` return remaining credits; Flutter renames scan→credits across
  `FeatureFlags`, l10n (en/id), paywall, top-up and settings copy.
- **Top-ups and tiers still work** — bonus credits add to the cap; metering is
  skipped only for unlimited (unknown-tier) accounts.
- DB column names (`scans_used_this_month`, `scan_topup_bonus_this_month`) and
  RPCs keep their `scan` names internally to avoid a destructive migration; only
  the user-facing language becomes "credits". A future rename is cosmetic.
