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

  @override
  String get aboutTitle => 'About';

  @override
  String get aboutTagline => 'Personal & shared finance, calm by design.';

  @override
  String get aboutHelp => 'Help';

  @override
  String get aboutLegal => 'Legal';

  @override
  String get aboutBuild => 'Build';

  @override
  String get aboutHelpCenter => 'Help center';

  @override
  String get aboutContactSupport => 'Contact support';

  @override
  String get aboutSendFeedback => 'Send feedback';

  @override
  String get aboutTermsOfService => 'Terms of service';

  @override
  String get aboutPrivacyPolicy => 'Privacy policy';

  @override
  String get aboutOpenSourceLicenses => 'Open source licenses';

  @override
  String get notifTitle => 'Notifications';

  @override
  String get notifBudgets => 'Budgets';

  @override
  String get notifRooms => 'Rooms';

  @override
  String get notifReceipts => 'Receipts';

  @override
  String get notifDigestsNews => 'Digests & news';

  @override
  String get notifApproachingLimit => 'Approaching limit';

  @override
  String get notifApproachingLimitHelper => 'When you reach 80% of a budget.';

  @override
  String get notifWeeklyDigest => 'Weekly digest';

  @override
  String get notifWeeklyDigestHelper => 'Summary of last week budget progress.';

  @override
  String get notifNewTransactions => 'New transactions';

  @override
  String get notifMentionsInvites => 'Mentions & invites';

  @override
  String get notifExpiryReminders => 'Expiry reminders';

  @override
  String get notifExpiryRemindersHelper =>
      'Free tier · receipts auto-delete after 90 days.';

  @override
  String get notifMonthlySummary => 'Monthly summary';

  @override
  String get notifProductUpdates => 'Product updates';

  @override
  String get notifSystemFooter =>
      'System push permission is managed in your device settings.';

  @override
  String get prefsTitle => 'Preferences';

  @override
  String get prefsLanguage => 'Language';

  @override
  String get prefsAppLanguage => 'App language';

  @override
  String get prefsCurrency => 'Currency';

  @override
  String get prefsHomeCurrency => 'Home currency';

  @override
  String get prefsRegion => 'Region';

  @override
  String get prefsCountry => 'Country';

  @override
  String get prefsCategory => 'Categories';

  @override
  String get prefsManageCategories => 'Manage categories';

  @override
  String get prefsCustomize => 'Customize';

  @override
  String get prefsAppearance => 'Appearance';

  @override
  String get prefsTheme => 'Theme';

  @override
  String get prefsThemeSystem => 'System';

  @override
  String get prefsThemeLight => 'Light';

  @override
  String get prefsThemeDark => 'Dark';

  @override
  String get prefsSyncFooter =>
      'Theme + language preferences will sync across devices in a future release.';

  @override
  String get profileTitle => 'Profile';

  @override
  String get profileName => 'Name';

  @override
  String get profileEmail => 'Email';

  @override
  String get profilePhone => 'Phone';

  @override
  String get profileEmailHelper => 'Email is managed by your auth provider.';

  @override
  String get profileNotifications => 'NOTIFICATIONS';

  @override
  String get profileBudgetAlerts => 'Budget alerts';

  @override
  String get profileRoomActivity => 'Room activity';

  @override
  String get profileSaveChanges => 'Save changes';

  @override
  String get profileSaved => 'Profile saved';

  @override
  String profileSaveFailed(String error) {
    return 'Save failed: $error';
  }

  @override
  String get securityTitle => 'Security';

  @override
  String get securityLock => 'Lock';

  @override
  String get securityPrivacy => 'Privacy';

  @override
  String get securityBiometricUnlock => 'Biometric unlock';

  @override
  String get securityBiometricHelper =>
      'Lock LOIT with Face / fingerprint after 15s in background';

  @override
  String get securityBiometricNotAvailable => 'Not available on this device';

  @override
  String get securityHideAmounts => 'Hide amounts on lock screen';

  @override
  String get securityHideAmountsHelper =>
      'Replace amounts with •••• in notifications.';

  @override
  String securityBiometricSetupFailed(String error) {
    return 'Biometric setup failed: $error';
  }

  @override
  String get securitySessionFooter =>
      'Sessions are managed by your auth provider. Sign out from Settings to revoke access on this device.';

  @override
  String get securityBiometricReason => 'Enable biometric lock for LOIT';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsGeneral => 'General';

  @override
  String get settingsMoney => 'Money';

  @override
  String get settingsSubscription => 'Subscription';

  @override
  String get settingsPrivacyData => 'Privacy & data';

  @override
  String get settingsAbout => 'About';

  @override
  String get settingsDebug => 'Debug';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsCurrency => 'Currency';

  @override
  String get settingsTheme => 'Theme';

  @override
  String get settingsCategories => 'Categories';

  @override
  String get settingsCustomize => 'Customize';

  @override
  String get settingsAccounts => 'Accounts';

  @override
  String get settingsBudgets => 'Budgets';

  @override
  String settingsBudgetsActive(int count) {
    return '$count active';
  }

  @override
  String get settingsScansThisMonth => 'Scans this month';

  @override
  String get settingsUnlimited => 'Unlimited';

  @override
  String get settingsPlan => 'Plan';

  @override
  String get settingsReceipts => 'Receipts';

  @override
  String get settingsSecurity => 'Security';

  @override
  String get settingsNotifications => 'Notifications';

  @override
  String get settingsExportData => 'Export data';

  @override
  String get settingsCsvPdf => 'CSV / PDF';

  @override
  String get settingsDeleteAccount => 'Delete account';

  @override
  String get settingsHelpSupport => 'Help & support';

  @override
  String get settingsTermsPrivacy => 'Terms & privacy';

  @override
  String get settingsVersion => 'Version';

  @override
  String get settingsSignOut => 'Sign out';

  @override
  String get settingsHomeCurrency => 'Home currency';

  @override
  String get settingsDeleteAccountTitle => 'Delete account?';

  @override
  String get settingsDeleteAccountMessage =>
      'All your data will be permanently removed. This cannot be undone.';

  @override
  String get settingsCancel => 'Cancel';

  @override
  String get settingsDelete => 'Delete';

  @override
  String get settingsDeleteAccountSnackbar =>
      'Account deletion requires email to support.';

  @override
  String get debugSimulateOffline => 'Simulate offline';

  @override
  String get debugSimulateOfflineHelper =>
      'Show the offline banner for testing';

  @override
  String get tierActive => 'ACTIVE';
}
