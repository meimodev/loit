# 4. Gate AI scans server-side; charge per AI call, not per save

Date: 2026-06-04

## Status

Accepted

## Context

AI extraction ("**Scan**" — image OCR or voice transcription into a transaction;
see CONTEXT.md) is the app's most expensive per-request operation and the unit
the **Scan quota** meters. Two surfaces invoke it: the in-app scanner and the
Telegram bot. They had drifted into two different, partly-broken gating models:

- **In-app scanner**: the `scan-receipt` Edge Function enforced *nothing*. The
  quota check lived entirely in the Flutter client (`scanner_screen` cap check),
  and the client recorded usage *after a successful save* via
  `increment_scan_quota` with a no-enforce limit (`1<<30`). Any valid JWT could
  POST `scan-receipt` directly, unbounded, on the free tier, and never record a
  use — uncapped Claude spend.
- **Telegram bot**: image and voice were gated server-side (`consumeScanQuota`
  before the AI call, refund on failure), but **text** parsing drew no quota at
  all, and image used a *separate* code path from the in-app scanner
  (duplicated parse + preprocess, no strict-retry, no receipt-image storage,
  no arithmetic reconciliation).

We also had to settle *when* a Scan is spent: in-app charged on save (scan +
discard was free); Telegram charged at AI-call time.

## Decision

- **Enforcement is server-side and authoritative.** A shared
  `_shared/scan_gate.ts` (`gatedScan`) is the single gate: reserve quota →
  call the AI (with internal strict-retry) → refund only when the AI returns no
  usable transaction. Both `scan-receipt` and the Telegram image handler call
  it. The Flutter cap check is demoted to a UX pre-check, not the authority;
  `scan-receipt` returns **402** when the cap is reached.
- **Charge at AI-call time; refund only on AI failure.** A Scan is spent the
  moment the image/voice reaches the AI. Refund happens only on
  `not_a_transaction` / `ai_failure` / thrown error — i.e. no usable result. A
  user who *discards* a usable low-confidence result still pays, because the
  expensive call already happened. The client stops calling
  `increment_scan_quota`; the realtime `users`-row subscription refreshes the
  used count.
- **Text on Telegram is gated by the Rate limit only**, never the Scan quota.
  The free Scan cap is 5/month; charging text against it would make the bot
  unusable. The 50/hour-per-chat rate limit is text's gate.
- **Telegram images reuse the in-app pipeline**: shared gated helper,
  strict-retry, arithmetic reconciliation, and Receipt-image storage for
  non-free tiers. For low-confidence images (which become a Pending
  transaction), the photo is stashed to a temp storage path at scan time and
  promoted to `receipts/{userId}/{txnId}.jpg` on confirm; orphaned stashes are
  swept by the receipt-expiry cron.

## Consequences

- **In-app scan + discard now costs a Scan.** Previously free. A reader looking
  at old client code (increment-on-save) will find this surprising — it is
  deliberate: the gate moved off the client and onto the AI call, which is
  where the money is spent.
- **A successful AI extraction that then fails to save still costs a Scan**
  (the AI call succeeded). Save failures are not refunded; only AI no-result is.
- **One retry = one charge.** Strict-retry moved *inside* the helper, so a
  single client request can never double-charge. The client's network-error
  retry is kept (it never reached the server, so it never charged).
- **`PendingScanCounts` offline queue is now dead.** In-app scanning requires
  network (the AI call), so the offline-increment fallback can never fire; its
  write/drain code is removed. The Drift table is left in place to avoid a
  schema migration.
- Reversible in principle, but the client/server billing contract and the
  user-visible "discard costs" semantics make a reversal user-facing, not
  purely internal.
