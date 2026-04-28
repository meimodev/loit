# LOIT — Claude Code Implementation Prompt
## Pricing, Payment & Scan Quota Changes

> Pass this entire file to Claude Code as the task prompt.
> All changes are scoped to the Flutter project described in `LOIT_Product_Blueprint.md`.
> Do not modify anything outside the scope listed below.

---

## Context

This prompt implements three connected decisions made after the initial blueprint:

1. **Payment system replaced** — Midtrans is removed entirely. Google Play Billing is the sole payment mechanism at launch (Android only). A payment abstraction layer must be built so iOS/StoreKit 2 can be added later without touching business logic.
2. **Scan quotas changed** — Pro tier moves from 50 scans/month to unlimited. Team was already unlimited and stays that way. The scan top-up pack is removed from Pro. Free tier is unchanged (8 scans/month, top-up available).
3. **Annual pricing changed** — Annual billing is now priced as 8 months (4 months free), replacing the previous 2-months-free model. Monthly prices are also adjusted to clean Google Play Billing price points.

---

## 1. Pricing Constants

Create or update a central pricing constants file at:
```
lib/core/config/pricing_constants.dart
```

Define the following. All values in IDR (integer, no decimals):

```dart
class PricingConstants {
  // Monthly prices (IDR) — Google Play price points
  static const int proMonthlyIdr   = 99000;
  static const int teamMonthlyIdr  = 199000;

  // Annual prices = 8 × monthly (4 months free)
  static const int proAnnualIdr    = 792000;   // 8 × 99,000
  static const int teamAnnualIdr   = 1592000;  // 8 × 199,000

  // One-time add-ons (Free tier only)
  static const int scanTopUpIdr         = 19000;  // 10 scans
  static const int storageExtensionIdr  = 19000;  // +6 months

  // USD equivalents (for display only — billing is always in IDR via Google Play)
  static const double proMonthlyUsd   = 5.99;
  static const double teamMonthlyUsd  = 11.99;
  static const double proAnnualUsd    = 47.99;
  static const double teamAnnualUsd   = 95.99;

  // Google Play product IDs (must match Play Console SKUs exactly)
  static const String skuProMonthly   = 'loit_pro_monthly_1';
  static const String skuProAnnual    = 'loit_pro_annual_1';
  static const String skuTeamMonthly  = 'loit_team_monthly_1';
  static const String skuTeamAnnual   = 'loit_team_annual_1';
  static const String skuScanTopUp    = 'loit_scan_topup_10';
  static const String skuStorageExt   = 'loit_storage_ext_6mo';

  // iOS App Store product IDs (future — do not implement StoreKit yet, IDs for reference only)
  // static const String ioskuProMonthly  = 'com.loit.pro.monthly';
  // static const String ioskuProAnnual   = 'com.loit.pro.annual';
  // static const String ioskuTeamMonthly = 'com.loit.team.monthly';
  // static const String ioskuTeamAnnual  = 'com.loit.team.annual';

  // iOS prices (future — ~15–20% premium over Android)
  // Pro monthly iOS:  Rp115,000
  // Team monthly iOS: Rp229,000
  // Pro annual iOS:   Rp920,000
  // Team annual iOS:  Rp1,832,000
}
```

---

## 2. Scan Quota — Feature Gate Update

Update `lib/shared/providers/feature_gate.dart` (or wherever tier scan limits are defined).

Change the Pro scan quota from `50` to `null` (null = unlimited), consistent with how Team is already handled.

```dart
int? monthlyScanQuota(UserTier tier) {
  switch (tier) {
    case UserTier.free: return 8;
    case UserTier.pro:  return null;  // changed from 50 → unlimited
    case UserTier.team: return null;  // unchanged
  }
}
```

Wherever the scan counter UI is rendered for Pro or Team users, replace the quota display with an "Unlimited" label. The `ScannerService` must not deduct from or enforce a quota for Pro and Team users.

---

## 3. Scan Top-Up — Remove from Pro and Team

The scan top-up IAP (`loit_scan_topup_10`) is **only available to Free tier users**.

Apply the following changes:

### 3a. PaymentService / purchase eligibility
Add a guard before initiating a top-up purchase:
```dart
bool canPurchaseScanTopUp(UserTier tier) => tier == UserTier.free;
```
If a Pro or Team user somehow reaches the top-up flow, throw an assertion error in debug and silently no-op in release.

### 3b. UI — Scanner screen
- For Free users: keep the existing "Top up scans" CTA when quota is low.
- For Pro and Team users: remove all top-up CTAs and quota progress indicators. Replace with a static "Unlimited scans" label.

### 3c. Paywall screens
Remove the scan top-up option from any paywall or settings screen shown to Pro or Team users.

### 3d. Supabase Edge Function — scan quota enforcement
In the `scan-receipt` Edge Function, update the quota check:
- If `user.tier == 'free'`: enforce the 8-scan monthly cap as before.
- If `user.tier == 'pro'` or `user.tier == 'team'`: skip quota check entirely. Do not decrement any counter. Proceed directly to the Claude API call.

---

## 4. Payment System — Replace Midtrans with Google Play Billing

### 4a. Remove Midtrans

- Remove the `midtrans_service.dart` file from `lib/core/services/`.
- Remove all Midtrans-related imports, references, and initialisation in `main.dart`.
- Remove Midtrans from `pubspec.yaml` dependencies.
- Delete any Midtrans-related Supabase Edge Functions (the Midtrans webhook handler).
- Remove Midtrans environment variables from `.env` / `--dart-define-from-file` config.

### 4b. Create a Payment Abstraction Layer

Create `lib/core/services/payment_service.dart` as a platform-agnostic interface. This is the ONLY payment interface the rest of the app should ever touch.

```dart
abstract class PaymentService {
  Future<PurchaseResult> purchaseSubscription(String productId);
  Future<PurchaseResult> purchaseOneTime(String productId);
  Future<void> restorePurchases();
  Stream<PurchaseUpdate> get purchaseUpdates;
}
```

Create `lib/core/services/google_play_payment_service.dart` implementing `PaymentService` using the `in_app_purchase` Flutter package. This is the only concrete implementation needed at launch.

Wire it via Riverpod:
```dart
// In providers
final paymentServiceProvider = Provider<PaymentService>((ref) {
  // Platform detection kept here — only place in codebase
  if (Platform.isAndroid) return GooglePlayPaymentService();
  // iOS: throw UnimplementedError at runtime for now
  // Future: if (Platform.isIOS) return AppStorePaymentService();
  throw UnimplementedError('Payment not supported on this platform yet.');
});
```

### 4c. Add `in_app_purchase` dependency

Add to `pubspec.yaml`:
```yaml
dependencies:
  in_app_purchase: ^3.2.0
```

### 4d. Google Play Billing implementation

`GooglePlayPaymentService` must handle:
- Product details fetch on init for all SKUs in `PricingConstants`
- `BillingClient` connection and reconnection on disconnect
- Purchase verification: after a successful purchase, call a new Supabase Edge Function `verify-purchase` (see §4e) with the purchase token before granting entitlement
- Subscription status restoration via `restorePurchases()`
- Pending purchases (e.g. carrier billing) — listen and handle when they complete
- Proper acknowledgement of purchases after verification

### 4e. Supabase Edge Function — `verify-purchase`

Create a new Edge Function `verify-purchase` that:
1. Receives `{ purchaseToken, productId, userId }` from the Flutter client
2. Calls the **Google Play Developer API** (`purchases.subscriptions.get` for subscriptions, `purchases.products.get` for one-time) using a service account stored as an Edge Function secret
3. If valid: updates `users.tier` (for subscriptions) or `users.scan_credits` / `users.storage_extended_until` (for one-time) in Supabase
4. Returns `{ success: true, tier: 'pro' | 'team' | 'free' }` or an error
5. Is idempotent — re-verifying the same token must not double-grant credits

Secrets required in Supabase dashboard (do not commit to repo):
- `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON` — the full service account JSON
- `GOOGLE_PLAY_PACKAGE_NAME` — `com.loit.app` (confirm exact package name)

### 4f. Remove the old Midtrans webhook Edge Function

Delete the Edge Function that previously handled Midtrans `notification` webhooks and updated user tiers. Its role is now fully replaced by `verify-purchase`.

---

## 5. Annual Billing — Update Pricing and UI

### 5a. Annual discount label
Update all UI copy that references annual savings. The new saving is **4 months free** (previously 2 months free).

Find and replace across all `.dart` and `.arb` localisation files:
- `"2 months free"` → `"4 months free"`
- `"Save 17%"` or similar → `"Save 33%"`
- Any hardcoded annual price strings → pull from `PricingConstants`

### 5b. Paywall screen — annual toggle
In the paywall/pricing screen, when the user toggles to "Annual":
- Display the annual price from `PricingConstants` (e.g. `Rp792,000/year`)
- Show the per-month equivalent: `Rp792,000 ÷ 12 = Rp66,000/mo` (just for display)
- Show the savings badge: **"4 months free"** or **"Save 33%"**

Do not show the USD equivalent as the primary price. IDR is always primary. USD may be shown in small muted text as secondary if screen space allows.

### 5c. Settings / subscription management screen
Update the displayed renewal amount and billing period wherever the current subscription details are shown to the user.

---

## 6. Localisation Strings

Update `lib/l10n/app_en.arb` and `lib/l10n/app_id.arb` with new or changed strings.

Required new/changed keys:

```json
{
  "scanQuotaUnlimited": "Unlimited",
  "scanQuotaUnlimitedDescription": "Scan as many receipts as you need",
  "annualSavingsBadge": "4 months free",
  "annualSavingsPercent": "Save 33%",
  "proMonthlyPrice": "Rp99,000/mo",
  "proAnnualPrice": "Rp792,000/yr",
  "teamMonthlyPrice": "Rp199,000/mo",
  "teamAnnualPrice": "Rp1,592,000/yr",
  "scanTopUpPrice": "Rp19,000 for 10 scans",
  "storageExtensionPrice": "Rp19,000 for 6 months",
  "paymentGooglePlayOnly": "Payments processed securely via Google Play",
  "restorePurchases": "Restore purchases",
  "iosComingSoon": "iOS version coming soon"
}
```

Add Indonesian (`id`) equivalents for each key.

---

## 7. Update the Tier Comparison Table (Paywall UI)

Reflect the following final feature matrix in the paywall screen:

| Feature | Free | Pro | Team |
|---|---|---|---|
| Bill scans | 8/month | Unlimited | Unlimited |
| Scan top-up | ✅ Rp19,000/10 | ❌ Not needed | ❌ Not needed |
| Receipt storage | ❌ | ✅ 1 year | ✅ 1 year |
| Storage extension | ❌ | ✅ Rp19,000/6mo | ✅ Rp19,000/6mo |
| Currencies | 10 | 180+ | 180+ |
| Budget categories | 3 | Unlimited | Unlimited |
| Rooms created | 3 | 10 | 25 |
| Members per room | 3 | 7 | 15 |
| CSV / PDF export | ❌ | ✅ | ✅ |
| Recurring bills | ❌ | ✅ | ✅ |
| Room admin controls | ❌ | ❌ | ✅ |
| Priority support | ❌ | ❌ | ✅ |
| Monthly price | Free | Rp99,000 | Rp199,000 |
| Annual price | — | Rp792,000 | Rp1,592,000 |

---

## 8. Update Phase 3 Scope Reference

The original `Phase 3 — Pro Layer` referenced Midtrans Snap checkout. Update all inline comments and TODO items in Phase 3 files to reference Google Play Billing instead. No functional change — just ensures future developers aren't confused by stale references.

---

## 9. QA Checklist for These Changes

After implementation, the following must all pass before considering this complete:

- [ ] Free user hits 8-scan quota → top-up CTA appears → purchase completes via Google Play → 10 scans credited
- [ ] Pro user has no scan counter → no top-up CTA visible anywhere
- [ ] Team user has no scan counter → no top-up CTA visible anywhere
- [ ] Annual Pro purchase via Google Play → `verify-purchase` Edge Function grants `tier = pro` → user sees Pro features immediately
- [ ] Annual Team purchase → same flow for Team
- [ ] Monthly subscription purchase → same verify flow
- [ ] Restore purchases → previous entitlement correctly re-applied
- [ ] Annual paywall toggle shows "4 months free" and correct price
- [ ] No reference to Midtrans remains in client code (`grep -r "midtrans" lib/` returns zero results)
- [ ] `PaymentService` interface used everywhere — no direct Google Play API calls outside `GooglePlayPaymentService`
- [ ] `verify-purchase` is idempotent — calling twice with same token does not double-credit
- [ ] Storage extension purchase (Pro/Team) works end to end via Google Play
- [ ] All new localisation strings render correctly in EN and ID

---

## 10. Do Not Change

The following are explicitly out of scope for this prompt:

- Auth system (Supabase Auth, Google SSO, Apple SSO)
- Room feature logic
- AI scanning logic and Claude Sonnet 4.6 prompt
- Offline sync behaviour
- FCM push notifications
- Any database schema beyond `users.tier`, `users.scan_credits`, `users.storage_extended_until`
- Free tier scan quota (stays at 8/month)
- Receipt expiry policy and flow
- Currency or FX rate logic

---

*LOIT — Split bills, not friendships.*
