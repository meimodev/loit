// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Indonesian (`id`).
class AppLocalizationsId extends AppLocalizations {
  AppLocalizationsId([String locale = 'id']) : super(locale);

  @override
  String get scanQuotaUnlimited => 'Tanpa batas';

  @override
  String get scanQuotaUnlimitedDescription =>
      'Pindai struk sebanyak yang Anda butuhkan';

  @override
  String get annualSavingsBadge => 'Gratis 4 bulan';

  @override
  String get annualSavingsPercent => 'Hemat 33%';

  @override
  String get proMonthlyPrice => 'Rp99.000/bln';

  @override
  String get proAnnualPrice => 'Rp792.000/thn';

  @override
  String get teamMonthlyPrice => 'Rp199.000/bln';

  @override
  String get teamAnnualPrice => 'Rp1.592.000/thn';

  @override
  String get scanTopUpPrice => 'Rp19.000 untuk 10 pemindaian';

  @override
  String get storageExtensionPrice => 'Rp19.000 untuk 6 bulan';

  @override
  String get paymentGooglePlayOnly =>
      'Pembayaran diproses dengan aman melalui Google Play';

  @override
  String get restorePurchases => 'Pulihkan pembelian';

  @override
  String get iosComingSoon => 'Versi iOS segera hadir';
}
