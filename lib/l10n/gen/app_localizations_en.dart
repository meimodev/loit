// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get scanQuotaUnlimited => 'Unlimited';

  @override
  String get scanQuotaUnlimitedDescription =>
      'Scan as many receipts as you need';

  @override
  String get annualSavingsBadge => '4 months free';

  @override
  String get annualSavingsPercent => 'Save 33%';

  @override
  String get proMonthlyPrice => 'Rp99,000/mo';

  @override
  String get proAnnualPrice => 'Rp792,000/yr';

  @override
  String get teamMonthlyPrice => 'Rp199,000/mo';

  @override
  String get teamAnnualPrice => 'Rp1,592,000/yr';

  @override
  String get scanTopUpPrice => 'Rp19,000 for 10 scans';

  @override
  String get storageExtensionPrice => 'Rp19,000 for 6 months';

  @override
  String get paymentGooglePlayOnly =>
      'Payments processed securely via Google Play';

  @override
  String get restorePurchases => 'Restore purchases';

  @override
  String get iosComingSoon => 'iOS version coming soon';

  @override
  String get fxRateStale => 'Rates may be outdated';

  @override
  String fxConvertedFrom(String amount, String currency) {
    return '≈ $amount $currency';
  }
}
