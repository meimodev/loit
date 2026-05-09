import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_id.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('id'),
  ];

  /// No description provided for @scanQuotaUnlimited.
  ///
  /// In en, this message translates to:
  /// **'Unlimited'**
  String get scanQuotaUnlimited;

  /// No description provided for @scanQuotaUnlimitedDescription.
  ///
  /// In en, this message translates to:
  /// **'Scan as many receipts as you need'**
  String get scanQuotaUnlimitedDescription;

  /// No description provided for @annualSavingsBadge.
  ///
  /// In en, this message translates to:
  /// **'4 months free'**
  String get annualSavingsBadge;

  /// No description provided for @annualSavingsPercent.
  ///
  /// In en, this message translates to:
  /// **'Save 33%'**
  String get annualSavingsPercent;

  /// No description provided for @proMonthlyPrice.
  ///
  /// In en, this message translates to:
  /// **'Rp99,000/mo'**
  String get proMonthlyPrice;

  /// No description provided for @proAnnualPrice.
  ///
  /// In en, this message translates to:
  /// **'Rp792,000/yr'**
  String get proAnnualPrice;

  /// No description provided for @teamMonthlyPrice.
  ///
  /// In en, this message translates to:
  /// **'Rp199,000/mo'**
  String get teamMonthlyPrice;

  /// No description provided for @teamAnnualPrice.
  ///
  /// In en, this message translates to:
  /// **'Rp1,592,000/yr'**
  String get teamAnnualPrice;

  /// No description provided for @scanTopUpPrice.
  ///
  /// In en, this message translates to:
  /// **'Rp19,000 for 10 scans'**
  String get scanTopUpPrice;

  /// No description provided for @storageExtensionPrice.
  ///
  /// In en, this message translates to:
  /// **'Rp19,000 for 6 months'**
  String get storageExtensionPrice;

  /// No description provided for @paymentGooglePlayOnly.
  ///
  /// In en, this message translates to:
  /// **'Payments processed securely via Google Play'**
  String get paymentGooglePlayOnly;

  /// No description provided for @restorePurchases.
  ///
  /// In en, this message translates to:
  /// **'Restore purchases'**
  String get restorePurchases;

  /// No description provided for @iosComingSoon.
  ///
  /// In en, this message translates to:
  /// **'iOS version coming soon'**
  String get iosComingSoon;

  /// No description provided for @fxRateStale.
  ///
  /// In en, this message translates to:
  /// **'Rates may be outdated'**
  String get fxRateStale;

  /// Converted amount display, e.g. '≈ 150,000 IDR'
  ///
  /// In en, this message translates to:
  /// **'≈ {amount} {currency}'**
  String fxConvertedFrom(String amount, String currency);

  /// No description provided for @aboutTitle.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get aboutTitle;

  /// No description provided for @aboutTagline.
  ///
  /// In en, this message translates to:
  /// **'Personal & shared finance, calm by design.'**
  String get aboutTagline;

  /// No description provided for @aboutHelp.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get aboutHelp;

  /// No description provided for @aboutLegal.
  ///
  /// In en, this message translates to:
  /// **'Legal'**
  String get aboutLegal;

  /// No description provided for @aboutBuild.
  ///
  /// In en, this message translates to:
  /// **'Build'**
  String get aboutBuild;

  /// No description provided for @aboutHelpCenter.
  ///
  /// In en, this message translates to:
  /// **'Help center'**
  String get aboutHelpCenter;

  /// No description provided for @aboutContactSupport.
  ///
  /// In en, this message translates to:
  /// **'Contact support'**
  String get aboutContactSupport;

  /// No description provided for @aboutSendFeedback.
  ///
  /// In en, this message translates to:
  /// **'Send feedback'**
  String get aboutSendFeedback;

  /// No description provided for @aboutTermsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of service'**
  String get aboutTermsOfService;

  /// No description provided for @aboutPrivacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy'**
  String get aboutPrivacyPolicy;

  /// No description provided for @aboutOpenSourceLicenses.
  ///
  /// In en, this message translates to:
  /// **'Open source licenses'**
  String get aboutOpenSourceLicenses;

  /// No description provided for @notifTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifTitle;

  /// No description provided for @notifBudgets.
  ///
  /// In en, this message translates to:
  /// **'Budgets'**
  String get notifBudgets;

  /// No description provided for @notifRooms.
  ///
  /// In en, this message translates to:
  /// **'Rooms'**
  String get notifRooms;

  /// No description provided for @notifReceipts.
  ///
  /// In en, this message translates to:
  /// **'Receipts'**
  String get notifReceipts;

  /// No description provided for @notifDigestsNews.
  ///
  /// In en, this message translates to:
  /// **'Digests & news'**
  String get notifDigestsNews;

  /// No description provided for @notifApproachingLimit.
  ///
  /// In en, this message translates to:
  /// **'Approaching limit'**
  String get notifApproachingLimit;

  /// No description provided for @notifApproachingLimitHelper.
  ///
  /// In en, this message translates to:
  /// **'When you reach 80% of a budget.'**
  String get notifApproachingLimitHelper;

  /// No description provided for @notifWeeklyDigest.
  ///
  /// In en, this message translates to:
  /// **'Weekly digest'**
  String get notifWeeklyDigest;

  /// No description provided for @notifWeeklyDigestHelper.
  ///
  /// In en, this message translates to:
  /// **'Summary of last week budget progress.'**
  String get notifWeeklyDigestHelper;

  /// No description provided for @notifNewTransactions.
  ///
  /// In en, this message translates to:
  /// **'New transactions'**
  String get notifNewTransactions;

  /// No description provided for @notifMentionsInvites.
  ///
  /// In en, this message translates to:
  /// **'Mentions & invites'**
  String get notifMentionsInvites;

  /// No description provided for @notifExpiryReminders.
  ///
  /// In en, this message translates to:
  /// **'Expiry reminders'**
  String get notifExpiryReminders;

  /// No description provided for @notifExpiryRemindersHelper.
  ///
  /// In en, this message translates to:
  /// **'Free tier · receipts auto-delete after 90 days.'**
  String get notifExpiryRemindersHelper;

  /// No description provided for @notifMonthlySummary.
  ///
  /// In en, this message translates to:
  /// **'Monthly summary'**
  String get notifMonthlySummary;

  /// No description provided for @notifProductUpdates.
  ///
  /// In en, this message translates to:
  /// **'Product updates'**
  String get notifProductUpdates;

  /// No description provided for @notifSystemFooter.
  ///
  /// In en, this message translates to:
  /// **'System push permission is managed in your device settings.'**
  String get notifSystemFooter;

  /// No description provided for @prefsTitle.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get prefsTitle;

  /// No description provided for @prefsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get prefsLanguage;

  /// No description provided for @prefsAppLanguage.
  ///
  /// In en, this message translates to:
  /// **'App language'**
  String get prefsAppLanguage;

  /// No description provided for @prefsCurrency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get prefsCurrency;

  /// No description provided for @prefsHomeCurrency.
  ///
  /// In en, this message translates to:
  /// **'Home currency'**
  String get prefsHomeCurrency;

  /// No description provided for @prefsRegion.
  ///
  /// In en, this message translates to:
  /// **'Region'**
  String get prefsRegion;

  /// No description provided for @prefsCountry.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get prefsCountry;

  /// No description provided for @prefsCategory.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get prefsCategory;

  /// No description provided for @prefsManageCategories.
  ///
  /// In en, this message translates to:
  /// **'Manage categories'**
  String get prefsManageCategories;

  /// No description provided for @prefsCustomize.
  ///
  /// In en, this message translates to:
  /// **'Customize'**
  String get prefsCustomize;

  /// No description provided for @prefsAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get prefsAppearance;

  /// No description provided for @prefsTheme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get prefsTheme;

  /// No description provided for @prefsThemeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get prefsThemeSystem;

  /// No description provided for @prefsThemeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get prefsThemeLight;

  /// No description provided for @prefsThemeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get prefsThemeDark;

  /// No description provided for @prefsSyncFooter.
  ///
  /// In en, this message translates to:
  /// **'Theme + language preferences will sync across devices in a future release.'**
  String get prefsSyncFooter;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTitle;

  /// No description provided for @profileName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get profileName;

  /// No description provided for @profileEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get profileEmail;

  /// No description provided for @profilePhone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get profilePhone;

  /// No description provided for @profileEmailHelper.
  ///
  /// In en, this message translates to:
  /// **'Email is managed by your auth provider.'**
  String get profileEmailHelper;

  /// No description provided for @profileNotifications.
  ///
  /// In en, this message translates to:
  /// **'NOTIFICATIONS'**
  String get profileNotifications;

  /// No description provided for @profileBudgetAlerts.
  ///
  /// In en, this message translates to:
  /// **'Budget alerts'**
  String get profileBudgetAlerts;

  /// No description provided for @profileRoomActivity.
  ///
  /// In en, this message translates to:
  /// **'Room activity'**
  String get profileRoomActivity;

  /// No description provided for @profileSaveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get profileSaveChanges;

  /// No description provided for @profileSaved.
  ///
  /// In en, this message translates to:
  /// **'Profile saved'**
  String get profileSaved;

  /// Error message when profile save fails
  ///
  /// In en, this message translates to:
  /// **'Save failed: {error}'**
  String profileSaveFailed(String error);

  /// No description provided for @securityTitle.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get securityTitle;

  /// No description provided for @securityLock.
  ///
  /// In en, this message translates to:
  /// **'Lock'**
  String get securityLock;

  /// No description provided for @securityPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get securityPrivacy;

  /// No description provided for @securityBiometricUnlock.
  ///
  /// In en, this message translates to:
  /// **'Biometric unlock'**
  String get securityBiometricUnlock;

  /// No description provided for @securityBiometricHelper.
  ///
  /// In en, this message translates to:
  /// **'Lock LOIT with Face / fingerprint after 15s in background'**
  String get securityBiometricHelper;

  /// No description provided for @securityBiometricNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Not available on this device'**
  String get securityBiometricNotAvailable;

  /// No description provided for @securityHideAmounts.
  ///
  /// In en, this message translates to:
  /// **'Hide amounts on lock screen'**
  String get securityHideAmounts;

  /// No description provided for @securityHideAmountsHelper.
  ///
  /// In en, this message translates to:
  /// **'Replace amounts with •••• in notifications.'**
  String get securityHideAmountsHelper;

  /// Error when biometric auth setup fails
  ///
  /// In en, this message translates to:
  /// **'Biometric setup failed: {error}'**
  String securityBiometricSetupFailed(String error);

  /// No description provided for @securitySessionFooter.
  ///
  /// In en, this message translates to:
  /// **'Sessions are managed by your auth provider. Sign out from Settings to revoke access on this device.'**
  String get securitySessionFooter;

  /// No description provided for @securityBiometricReason.
  ///
  /// In en, this message translates to:
  /// **'Enable biometric lock for LOIT'**
  String get securityBiometricReason;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsGeneral.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get settingsGeneral;

  /// No description provided for @settingsMoney.
  ///
  /// In en, this message translates to:
  /// **'Money'**
  String get settingsMoney;

  /// No description provided for @settingsSubscription.
  ///
  /// In en, this message translates to:
  /// **'Subscription'**
  String get settingsSubscription;

  /// No description provided for @settingsPrivacyData.
  ///
  /// In en, this message translates to:
  /// **'Privacy & data'**
  String get settingsPrivacyData;

  /// No description provided for @settingsAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsAbout;

  /// No description provided for @settingsDebug.
  ///
  /// In en, this message translates to:
  /// **'Debug'**
  String get settingsDebug;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsCurrency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get settingsCurrency;

  /// No description provided for @settingsTheme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingsTheme;

  /// No description provided for @settingsCategories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get settingsCategories;

  /// No description provided for @settingsCustomize.
  ///
  /// In en, this message translates to:
  /// **'Customize'**
  String get settingsCustomize;

  /// No description provided for @settingsAccounts.
  ///
  /// In en, this message translates to:
  /// **'Accounts'**
  String get settingsAccounts;

  /// No description provided for @settingsBudgets.
  ///
  /// In en, this message translates to:
  /// **'Budgets'**
  String get settingsBudgets;

  /// Number of active budgets, e.g. '3 active'
  ///
  /// In en, this message translates to:
  /// **'{count} active'**
  String settingsBudgetsActive(int count);

  /// No description provided for @settingsScansThisMonth.
  ///
  /// In en, this message translates to:
  /// **'Scans this month'**
  String get settingsScansThisMonth;

  /// No description provided for @settingsUnlimited.
  ///
  /// In en, this message translates to:
  /// **'Unlimited'**
  String get settingsUnlimited;

  /// No description provided for @settingsPlan.
  ///
  /// In en, this message translates to:
  /// **'Plan'**
  String get settingsPlan;

  /// No description provided for @settingsReceipts.
  ///
  /// In en, this message translates to:
  /// **'Receipts'**
  String get settingsReceipts;

  /// No description provided for @settingsSecurity.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get settingsSecurity;

  /// No description provided for @settingsNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get settingsNotifications;

  /// No description provided for @settingsExportData.
  ///
  /// In en, this message translates to:
  /// **'Export data'**
  String get settingsExportData;

  /// No description provided for @settingsCsvPdf.
  ///
  /// In en, this message translates to:
  /// **'CSV / PDF'**
  String get settingsCsvPdf;

  /// No description provided for @settingsDeleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get settingsDeleteAccount;

  /// No description provided for @settingsHelpSupport.
  ///
  /// In en, this message translates to:
  /// **'Help & support'**
  String get settingsHelpSupport;

  /// No description provided for @settingsTermsPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Terms & privacy'**
  String get settingsTermsPrivacy;

  /// No description provided for @settingsVersion.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get settingsVersion;

  /// No description provided for @settingsSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get settingsSignOut;

  /// No description provided for @settingsHomeCurrency.
  ///
  /// In en, this message translates to:
  /// **'Home currency'**
  String get settingsHomeCurrency;

  /// No description provided for @settingsDeleteAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete account?'**
  String get settingsDeleteAccountTitle;

  /// No description provided for @settingsDeleteAccountMessage.
  ///
  /// In en, this message translates to:
  /// **'All your data will be permanently removed. This cannot be undone.'**
  String get settingsDeleteAccountMessage;

  /// No description provided for @settingsCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get settingsCancel;

  /// No description provided for @settingsDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get settingsDelete;

  /// No description provided for @settingsDeleteAccountSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Account deletion requires email to support.'**
  String get settingsDeleteAccountSnackbar;

  /// No description provided for @debugSimulateOffline.
  ///
  /// In en, this message translates to:
  /// **'Simulate offline'**
  String get debugSimulateOffline;

  /// No description provided for @debugSimulateOfflineHelper.
  ///
  /// In en, this message translates to:
  /// **'Show the offline banner for testing'**
  String get debugSimulateOfflineHelper;

  /// No description provided for @tierActive.
  ///
  /// In en, this message translates to:
  /// **'ACTIVE'**
  String get tierActive;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'id'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'id':
      return AppLocalizationsId();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
