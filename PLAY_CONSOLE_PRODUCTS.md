# Google Play Console — Product Configuration (LOIT)

App package: `id.activid.loit`
Currency: IDR primary. USD display-only.
Annual = 8× monthly (4 months free).

---

## Prerequisites

1. Play Console account (Activid org).
2. App created with package `id.activid.loit`.
3. Merchant account linked (Setup → Monetization setup).
4. AAB uploaded to Internal testing track at least once (required to unlock IAP UI).
5. App signing: Play App Signing enabled. Upload key = `android/app/upload-keystore.jks` (alias `upload`).

---

## A. Subscriptions (4 SKUs)

Path: **Monetize → Products → Subscriptions → Create subscription**

For each subscription:

| Field | Pro Monthly | Pro Annual | Team Monthly | Team Annual |
|---|---|---|---|---|
| Product ID | `loit_pro_monthly_1` | `loit_pro_annual_1` | `loit_team_monthly_1` | `loit_team_annual_1` |
| Name | LOIT Pro Monthly | LOIT Pro Annual | LOIT Team Monthly | LOIT Team Annual |
| Description | Pro features, monthly | Pro features, yearly (4 mo free) | Team features, monthly | Team features, yearly (4 mo free) |
| Benefit (1) | Unlimited receipt scan | Unlimited receipt scan | Multi-user rooms | Multi-user rooms |
| Benefit (2) | Recurring bills | Recurring bills | All Pro benefits | All Pro benefits |
| Benefit (3) | Export PDF/CSV | Export PDF/CSV | Priority support | Priority support |
| Tax category | Digital goods (PPN handled by Google) | same | same | same |

### Base plan (one per subscription)

- Plan ID: `monthly` (for monthly SKUs) / `annual` (for annual SKUs)
- Billing period: P1M (monthly) / P1Y (annual)
- Renewal type: Auto-renewing
- Grace period: 3 days
- Account hold: 30 days
- Resubscribe: enabled
- Pause: disabled
- Prorate mode (upgrade): IMMEDIATE_WITH_TIME_PRORATION

### Regional pricing (IDR primary)

Set price in **Indonesia (ID)** first, then auto-convert other regions.

| SKU | Price IDR | Price USD (display) |
|---|---|---|
| `loit_pro_monthly_1` | 99,000 | 5.99 |
| `loit_pro_annual_1` | 792,000 | 47.99 |
| `loit_team_monthly_1` | 199,000 | 11.99 |
| `loit_team_annual_1` | 1,592,000 | 95.99 |

After ID set: **Set prices in other countries** → Auto-convert. Review US/SG/MY/AU then **Apply**.

### Offers (optional — free trial)

Per base plan → **Add offer**:
- Offer ID: `intro-7d-free`
- Eligibility: New customer acquisition
- Phase 1: Free trial, P7D
- Phase 2: anchor base plan

---

## B. In-app products (2 SKUs, consumable)

Path: **Monetize → Products → In-app products → Create product**

| Field | Scan Top-up | Storage Extension |
|---|---|---|
| Product ID | `loit_scan_topup_10` | `loit_storage_ext_6mo` |
| Name | 10 Receipt Scans | Storage +6 Months |
| Description | Adds 10 receipt scans to Free tier | Extends receipt storage by 6 months |
| Type | Consumable (managed) | Consumable (managed) |
| Price IDR | 19,000 | 19,000 |
| Price USD | 1.19 | 1.19 |
| Status | Active | Active |

Consumable = client must `consumePurchase()` after grant. RevenueCat handles via `purchase()` flow.

---

## C. Testing setup

1. **License testers**: Setup → License testing → add tester emails (Google accounts).
2. **Internal testing track**: Release → Testing → Internal testing → upload AAB → add testers email list.
3. Tester opt-in URL → install via Play Store on real device.
4. Test card: License testers see "TEST card" in purchase sheet. No real charge.

---

## D. RevenueCat wiring

1. RevenueCat dashboard → Project → **Apps → + New** → Android.
2. Package: `id.activid.loit`.
3. Upload **Service account JSON**: Play Console → Setup → API access → Create service account in Google Cloud → grant Play Console permission "Finance" + "View financial data" + "Manage orders and subscriptions" → download JSON → upload to RevenueCat.
4. RevenueCat → **Products** → import from Play (or add manually). Product IDs must match exactly:
   - `loit_pro_monthly_1`, `loit_pro_annual_1`, `loit_team_monthly_1`, `loit_team_annual_1`
   - `loit_scan_topup_10`, `loit_storage_ext_6mo`
5. **Entitlements**:
   - `pro` → attached: `loit_pro_monthly_1`, `loit_pro_annual_1`
   - `team` → attached: `loit_team_monthly_1`, `loit_team_annual_1` (and `pro` via override if Team includes Pro)
   - Top-ups not entitlements — granted server-side via webhook.
6. **Offerings**:
   - `default` → packages: monthly (pro_monthly), annual (pro_annual), monthly_team (team_monthly), annual_team (team_annual)
7. **Webhook**: RevenueCat → Project Settings → Integrations → Webhooks → URL = `https://<supabase-ref>.functions.supabase.co/revenuecat-webhook`. Auth header secret matches edge fn env `REVENUECAT_WEBHOOK_SECRET`.

---

## E. Pre-launch checklist

- [ ] AAB uploaded to Internal testing
- [ ] All 6 SKUs created + Active
- [ ] Subscription base plans active
- [ ] Prices set in ID + auto-converted globally
- [ ] License testers added
- [ ] RevenueCat service account JSON uploaded
- [ ] Entitlements `pro` + `team` mapped
- [ ] Offering `default` published
- [ ] Webhook URL set + secret matches
- [ ] Test purchase from real device (license tester) → entitlement appears in RevenueCat customer view → Supabase `users.tier` updates

---

## F. Common errors

| Error | Cause | Fix |
|---|---|---|
| `BillingResponseCode.ITEM_UNAVAILABLE` | SKU not Active or not on track containing tester | Activate SKU, ensure tester on Internal track |
| `DEVELOPER_ERROR` | App package signed with wrong key | Re-upload AAB signed by upload keystore |
| RevenueCat shows products as missing | Service account lacks Play permission | Re-grant Finance + Orders permissions, wait 24h |
| `BillingResponseCode.USER_CANCELED` on test | Tester not on license tester list | Add Google account to License testing |
