/// Central pricing constants for LOIT.
///
/// All billing happens through Google Play Billing in IDR. USD values are
/// display-only secondary text. Annual = 8 × monthly (4 months free).
class PricingConstants {
  const PricingConstants._();

  // Monthly prices (IDR) — Google Play price points
  static const int proMonthlyIdr = 99000;
  static const int teamMonthlyIdr = 199000;

  // Annual prices = 8 × monthly (4 months free)
  static const int proAnnualIdr = 792000; // 8 × 99,000
  static const int teamAnnualIdr = 1592000; // 8 × 199,000

  // One-time add-ons (Free tier only)
  static const int scanTopUpIdr = 19000; // 10 scans
  static const int storageExtensionIdr = 19000; // +6 months

  // USD equivalents (display only)
  static const double proMonthlyUsd = 5.99;
  static const double teamMonthlyUsd = 11.99;
  static const double proAnnualUsd = 47.99;
  static const double teamAnnualUsd = 95.99;

  // Google Play product IDs (must match Play Console SKUs exactly)
  // NOTE: `_1` suffix because the original IDs `loit_pro_monthly`,
  // `loit_pro_annual`, `loit_team_monthly`, `loit_team_annual` were
  // accidentally created under Play Console's One-time products page.
  // Play Console blocks reusing those IDs as subscriptions, so the
  // subscription SKUs use the `_1` variant.
  static const String skuProMonthly = 'loit_pro_monthly_1';
  static const String skuProAnnual = 'loit_pro_annual_1';
  static const String skuTeamMonthly = 'loit_team_monthly_1';
  static const String skuTeamAnnual = 'loit_team_annual_1';
  static const String skuScanTopUp = 'loit_scan_topup_10';
  static const String skuStorageExt = 'loit_storage_ext_6mo';

  static const Set<String> subscriptionSkus = {
    skuProMonthly,
    skuProAnnual,
    skuTeamMonthly,
    skuTeamAnnual,
  };

  static const Set<String> oneTimeSkus = {
    skuScanTopUp,
    skuStorageExt,
  };

  static const Set<String> allSkus = {
    ...subscriptionSkus,
    ...oneTimeSkus,
  };

  // iOS App Store product IDs (future — StoreKit not implemented yet)
  // static const String ioskuProMonthly  = 'com.loit.pro.monthly';
  // static const String ioskuProAnnual   = 'com.loit.pro.annual';
  // static const String ioskuTeamMonthly = 'com.loit.team.monthly';
  // static const String ioskuTeamAnnual  = 'com.loit.team.annual';
  //
  // iOS prices (future — ~15–20% premium over Android):
  //   Pro monthly iOS:  Rp115,000   Pro annual iOS:  Rp920,000
  //   Team monthly iOS: Rp229,000   Team annual iOS: Rp1,832,000
}
