# LOIT

Indonesian personal-finance app. This glossary fixes the language around AI
usage metering and gating — the terms below are easy to conflate and the
distinctions are load-bearing for billing and abuse control.

## Language

### AI usage & gating

**Scan**:
A single metered AI extraction of one transaction from an **image** or **voice
note**. The billable unit. A Scan is consumed at AI-call time and refunded only
when the AI returns no usable transaction.
_Avoid_: credit, OCR call, scan credit.

**Scan quota**:
The per-tier monthly cap on **Scans** (free 5, lite 30, pro 150; `null` =
unlimited). Enforced server-side; the client cap check is a UX pre-check only,
never the authority.
_Avoid_: scan credit, scan limit (when referring to the running balance).

**Text parse**:
AI interpretation of a **typed** chat message into a transaction. Gated by the
**Rate limit** only; never drawn from the **Scan quota**.
_Avoid_: text scan.

**Rate limit**:
A per-chat throttle on bot messages (50 / hour). Gates **Text parse** and
flooding. Independent of **Scan quota** — a different concept with a different
window and a different purpose (abuse control, not billing).
_Avoid_: quota, throttle quota.

**Receipt image**:
The stored photo of a scanned document, kept in the private `receipts` bucket
for non-free tiers and auto-expiring. Distinct from the **Scan** that produced
it — a Scan can occur without a Receipt image being kept (free tier, or
unstored paths).
_Avoid_: receipt, attachment.

**Pending transaction**:
A low-confidence parse held for explicit user confirmation before it becomes a
**Transaction**. The **Scan** that produced it is already spent; confirming or
discarding it does not change the **Scan quota**.
_Avoid_: draft, unconfirmed scan.

## Example dialogue

> **Dev:** A free user sends three text messages and one photo to the bot. What
> gets charged?
> **Domain:** The photo is one **Scan** against their **Scan quota** (free cap
> 5). The three texts are **Text parses** — they cost no Scans; they only count
> toward the **Rate limit**.
> **Dev:** The photo came back low-confidence, so it's a **Pending
> transaction**. If they ignore it, do they get the Scan back?
> **Domain:** No. The Scan was spent the moment the image hit the AI. A refund
> only happens when the AI returns nothing usable — not when the user declines a
> usable result.
