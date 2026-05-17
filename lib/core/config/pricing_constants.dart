/// Central pricing constants for LOIT.
///
/// All billing happens through Google Play Billing in IDR. USD values are
/// display-only secondary text. Annual = 8 × monthly (4 months free).
///
/// v2 scanner pipeline tier scheme: Free 5 / Lite 30 / Pro 150 scans/month.
/// Team tier dropped — legacy `team` rows migrated to `pro` server-side.
class PricingConstants {
  const PricingConstants._();

  // Monthly prices (IDR) — Google Play price points
  static const int liteMonthlyIdr = 49000;
  static const int proMonthlyIdr = 99000;

  // Annual prices = 8 × monthly (4 months free)
  static const int liteAnnualIdr = 392000; // 8 × 49,000
  static const int proAnnualIdr = 792000; // 8 × 99,000

  // One-time add-ons (Free tier only)
  static const int scanTopUpIdr = 9000; // 15 scans (v2 SKU)
  static const int storageExtensionIdr = 19000; // +6 months

  // USD equivalents (display only)
  static const double liteMonthlyUsd = 2.99;
  static const double proMonthlyUsd = 5.99;
  static const double liteAnnualUsd = 23.99;
  static const double proAnnualUsd = 47.99;

  // Google Play product IDs (must match Play Console SKUs exactly).
  // `_1` suffix is a historical artifact for the Pro tier.
  static const String skuLiteMonthly = 'loit_lite_monthly';
  static const String skuLiteAnnual = 'loit_lite_annual';
  static const String skuProMonthly = 'loit_pro_monthly_1';
  static const String skuProAnnual = 'loit_pro_annual_1';

  /// v2 top-up: Rp 9,000 for 15 scans. Replaces deprecated `loit_scan_topup_10`.
  static const String skuScanTopUp = 'loit_scan_topup_15';

  /// Deprecated — kept only so historical receipts can still be reconciled by
  /// the webhook. Do not surface in new paywall flows.
  static const String skuScanTopUpLegacy = 'loit_scan_topup_10';

  static const String skuStorageExt = 'loit_storage_ext_6mo';

  static const Set<String> subscriptionSkus = {
    skuLiteMonthly,
    skuLiteAnnual,
    skuProMonthly,
    skuProAnnual,
  };

  static const Set<String> oneTimeSkus = {
    skuScanTopUp,
    skuStorageExt,
  };

  static const Set<String> allSkus = {
    ...subscriptionSkus,
    ...oneTimeSkus,
  };
}
