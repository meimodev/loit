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

  /// No description provided for @dashboardInsights.
  ///
  /// In en, this message translates to:
  /// **'INSIGHTS'**
  String get dashboardInsights;

  /// No description provided for @dashboardSeeReport.
  ///
  /// In en, this message translates to:
  /// **'See report →'**
  String get dashboardSeeReport;

  /// No description provided for @dashboardSpendingThisMonth.
  ///
  /// In en, this message translates to:
  /// **'Spending this month'**
  String get dashboardSpendingThisMonth;

  /// No description provided for @dashboardAvgPerDay.
  ///
  /// In en, this message translates to:
  /// **'AVG/DAY'**
  String get dashboardAvgPerDay;

  /// No description provided for @dashboardMtd.
  ///
  /// In en, this message translates to:
  /// **'MTD'**
  String get dashboardMtd;

  /// No description provided for @dashboardSeePastReports.
  ///
  /// In en, this message translates to:
  /// **'See past reports'**
  String get dashboardSeePastReports;

  /// No description provided for @dashboardIncome.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get dashboardIncome;

  /// No description provided for @dashboardExpense.
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get dashboardExpense;

  /// No description provided for @dashboardSeeAllCategories.
  ///
  /// In en, this message translates to:
  /// **'See all categories'**
  String get dashboardSeeAllCategories;

  /// No description provided for @dashboardAddBudget.
  ///
  /// In en, this message translates to:
  /// **'Add budget'**
  String get dashboardAddBudget;

  /// Dense alert showing over-budget count and current day of month
  ///
  /// In en, this message translates to:
  /// **'{count} budgets over. Day {day} of {total}.'**
  String dashboardBudgetsOver(int count, int day, int total);

  /// No description provided for @dashboardAssets.
  ///
  /// In en, this message translates to:
  /// **'Assets'**
  String get dashboardAssets;

  /// No description provided for @dashboardLiabilities.
  ///
  /// In en, this message translates to:
  /// **'Liabilities'**
  String get dashboardLiabilities;

  /// No description provided for @dashboardNetWorth.
  ///
  /// In en, this message translates to:
  /// **'Net worth'**
  String get dashboardNetWorth;

  /// No description provided for @dashboardAccounts.
  ///
  /// In en, this message translates to:
  /// **'Accounts'**
  String get dashboardAccounts;

  /// No description provided for @dashboardBudgets.
  ///
  /// In en, this message translates to:
  /// **'Budgets'**
  String get dashboardBudgets;

  /// No description provided for @dashboardCategories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get dashboardCategories;

  /// No description provided for @dashboardQuickStats.
  ///
  /// In en, this message translates to:
  /// **'Quick stats'**
  String get dashboardQuickStats;

  /// Number of budgets on track, e.g. '3 of 5 on track'
  ///
  /// In en, this message translates to:
  /// **'{onTrack} of {total} on track'**
  String dashboardOnTrack(int onTrack, int total);

  /// No description provided for @dashboardOverBudget.
  ///
  /// In en, this message translates to:
  /// **'Over budget'**
  String get dashboardOverBudget;

  /// No description provided for @dashboardSpentMtd.
  ///
  /// In en, this message translates to:
  /// **'Spent MTD'**
  String get dashboardSpentMtd;

  /// No description provided for @dashboardTransactions.
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get dashboardTransactions;

  /// No description provided for @dashboardAddFirstAccount.
  ///
  /// In en, this message translates to:
  /// **'Add your first account to start tracking balances.'**
  String get dashboardAddFirstAccount;

  /// No description provided for @dashboardAddAccount.
  ///
  /// In en, this message translates to:
  /// **'Add account'**
  String get dashboardAddAccount;

  /// Budget spending summary, e.g. 'Rp500,000 of Rp1,000,000'
  ///
  /// In en, this message translates to:
  /// **'{spent} of {limit}'**
  String dashboardOfPattern(String spent, String limit);

  /// No description provided for @category_dining.
  ///
  /// In en, this message translates to:
  /// **'Dining'**
  String get category_dining;

  /// No description provided for @category_groceries.
  ///
  /// In en, this message translates to:
  /// **'Groceries'**
  String get category_groceries;

  /// No description provided for @category_transport.
  ///
  /// In en, this message translates to:
  /// **'Transport'**
  String get category_transport;

  /// No description provided for @category_shopping.
  ///
  /// In en, this message translates to:
  /// **'Shopping'**
  String get category_shopping;

  /// No description provided for @category_entertainment.
  ///
  /// In en, this message translates to:
  /// **'Entertainment'**
  String get category_entertainment;

  /// No description provided for @category_utilities.
  ///
  /// In en, this message translates to:
  /// **'Utilities'**
  String get category_utilities;

  /// No description provided for @category_health.
  ///
  /// In en, this message translates to:
  /// **'Health'**
  String get category_health;

  /// No description provided for @category_travel.
  ///
  /// In en, this message translates to:
  /// **'Travel'**
  String get category_travel;

  /// No description provided for @category_other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get category_other;

  /// No description provided for @category_income_salary.
  ///
  /// In en, this message translates to:
  /// **'Salary'**
  String get category_income_salary;

  /// No description provided for @category_income_bonus.
  ///
  /// In en, this message translates to:
  /// **'Bonus'**
  String get category_income_bonus;

  /// No description provided for @category_income_freelance.
  ///
  /// In en, this message translates to:
  /// **'Freelance'**
  String get category_income_freelance;

  /// No description provided for @category_income_investment.
  ///
  /// In en, this message translates to:
  /// **'Investment'**
  String get category_income_investment;

  /// No description provided for @category_income_gift.
  ///
  /// In en, this message translates to:
  /// **'Gift'**
  String get category_income_gift;

  /// No description provided for @category_income_refund.
  ///
  /// In en, this message translates to:
  /// **'Refund'**
  String get category_income_refund;

  /// No description provided for @category_income_other.
  ///
  /// In en, this message translates to:
  /// **'Other income'**
  String get category_income_other;

  /// No description provided for @txFormNewTransaction.
  ///
  /// In en, this message translates to:
  /// **'New transaction'**
  String get txFormNewTransaction;

  /// No description provided for @txFormEditTransaction.
  ///
  /// In en, this message translates to:
  /// **'Edit transaction'**
  String get txFormEditTransaction;

  /// No description provided for @txFormManualEntry.
  ///
  /// In en, this message translates to:
  /// **'Manual entry'**
  String get txFormManualEntry;

  /// No description provided for @txFormConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get txFormConfirm;

  /// No description provided for @txFormCouldntRead.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t read this receipt'**
  String get txFormCouldntRead;

  /// No description provided for @txFormPreFilled.
  ///
  /// In en, this message translates to:
  /// **'Fields below were pre-filled with what we recovered.'**
  String get txFormPreFilled;

  /// No description provided for @txFormAiParsed.
  ///
  /// In en, this message translates to:
  /// **'AI parsed this receipt'**
  String get txFormAiParsed;

  /// No description provided for @txFormPleaseReview.
  ///
  /// In en, this message translates to:
  /// **'Please review before saving.'**
  String get txFormPleaseReview;

  /// No description provided for @txFormItemBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Looks like an item breakdown'**
  String get txFormItemBreakdown;

  /// No description provided for @txFormSwitchToItemsMsg.
  ///
  /// In en, this message translates to:
  /// **'Switch to Items mode for a structured list.'**
  String get txFormSwitchToItemsMsg;

  /// No description provided for @txFormAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get txFormAmount;

  /// No description provided for @txFormCurrency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get txFormCurrency;

  /// No description provided for @txFormFromAccount.
  ///
  /// In en, this message translates to:
  /// **'From account'**
  String get txFormFromAccount;

  /// No description provided for @txFormAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get txFormAccount;

  /// No description provided for @txFormToAccount.
  ///
  /// In en, this message translates to:
  /// **'To account'**
  String get txFormToAccount;

  /// No description provided for @txFormIncomeCategory.
  ///
  /// In en, this message translates to:
  /// **'Income category'**
  String get txFormIncomeCategory;

  /// No description provided for @txFormExpenseCategory.
  ///
  /// In en, this message translates to:
  /// **'Expense category'**
  String get txFormExpenseCategory;

  /// No description provided for @txFormDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get txFormDate;

  /// No description provided for @txFormTime.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get txFormTime;

  /// No description provided for @txFormNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get txFormNotes;

  /// No description provided for @txFormMerchant.
  ///
  /// In en, this message translates to:
  /// **'Merchant'**
  String get txFormMerchant;

  /// No description provided for @txFormOptional.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get txFormOptional;

  /// No description provided for @txFormStoreOrPayer.
  ///
  /// In en, this message translates to:
  /// **'Store or payer'**
  String get txFormStoreOrPayer;

  /// No description provided for @txFormItemName.
  ///
  /// In en, this message translates to:
  /// **'Item name'**
  String get txFormItemName;

  /// No description provided for @txFormQty.
  ///
  /// In en, this message translates to:
  /// **'Qty'**
  String get txFormQty;

  /// No description provided for @txFormUnitPrice.
  ///
  /// In en, this message translates to:
  /// **'Unit price'**
  String get txFormUnitPrice;

  /// No description provided for @txFormTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get txFormTotal;

  /// No description provided for @txFormSelectAccount.
  ///
  /// In en, this message translates to:
  /// **'Select account'**
  String get txFormSelectAccount;

  /// No description provided for @txFormSelectDestination.
  ///
  /// In en, this message translates to:
  /// **'Select destination'**
  String get txFormSelectDestination;

  /// No description provided for @txFormTabText.
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get txFormTabText;

  /// No description provided for @txFormTabItems.
  ///
  /// In en, this message translates to:
  /// **'Items'**
  String get txFormTabItems;

  /// No description provided for @txFormAddItem.
  ///
  /// In en, this message translates to:
  /// **'Add item'**
  String get txFormAddItem;

  /// No description provided for @txFormSwitchToItemsBtn.
  ///
  /// In en, this message translates to:
  /// **'Switch to Items'**
  String get txFormSwitchToItemsBtn;

  /// No description provided for @txFormDismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get txFormDismiss;

  /// No description provided for @txFormSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get txFormSave;

  /// No description provided for @txFormExpense.
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get txFormExpense;

  /// No description provided for @txFormIncome.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get txFormIncome;

  /// No description provided for @txFormTransfer.
  ///
  /// In en, this message translates to:
  /// **'Transfer'**
  String get txFormTransfer;

  /// No description provided for @txFormRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get txFormRemove;

  /// No description provided for @txFormValidAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid amount'**
  String get txFormValidAmount;

  /// No description provided for @txFormSelectAnAccount.
  ///
  /// In en, this message translates to:
  /// **'Select an account'**
  String get txFormSelectAnAccount;

  /// No description provided for @txFormSelectDestAccount.
  ///
  /// In en, this message translates to:
  /// **'Select a destination account'**
  String get txFormSelectDestAccount;

  /// Error when transaction save fails
  ///
  /// In en, this message translates to:
  /// **'Save failed: {error}'**
  String txFormSaveFailed(String error);

  /// No description provided for @txFormExistingNotes.
  ///
  /// In en, this message translates to:
  /// **'Existing notes not recognized — start a fresh breakdown.'**
  String get txFormExistingNotes;

  /// No description provided for @txFormAddAccountFirst.
  ///
  /// In en, this message translates to:
  /// **'Add an account first before saving a transaction.'**
  String get txFormAddAccountFirst;

  /// FX rate display, e.g. '1 IDR ≈ 0.000067 USD'
  ///
  /// In en, this message translates to:
  /// **'1 {currency} ≈ {amount} {home}'**
  String txFormOneFxApprox(String currency, String amount, String home);

  /// No description provided for @txDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Transaction'**
  String get txDetailTitle;

  /// No description provided for @txDetailEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get txDetailEdit;

  /// No description provided for @txDetailNotSynced.
  ///
  /// In en, this message translates to:
  /// **'Not synced'**
  String get txDetailNotSynced;

  /// No description provided for @txDetailNotSyncedBody.
  ///
  /// In en, this message translates to:
  /// **'This transaction hasn\'t synced yet. Edit to save it.'**
  String get txDetailNotSyncedBody;

  /// No description provided for @txDetailDetails.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get txDetailDetails;

  /// No description provided for @txDetailNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get txDetailNotes;

  /// No description provided for @txDetailReceipt.
  ///
  /// In en, this message translates to:
  /// **'Receipt'**
  String get txDetailReceipt;

  /// No description provided for @txDetailDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get txDetailDate;

  /// No description provided for @txDetailType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get txDetailType;

  /// No description provided for @txDetailAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get txDetailAccount;

  /// No description provided for @txDetailToAccount.
  ///
  /// In en, this message translates to:
  /// **'To account'**
  String get txDetailToAccount;

  /// No description provided for @txDetailCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get txDetailCategory;

  /// No description provided for @txDetailCurrency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get txDetailCurrency;

  /// No description provided for @txDetailFxRate.
  ///
  /// In en, this message translates to:
  /// **'FX rate'**
  String get txDetailFxRate;

  /// No description provided for @txDetailHomeAmount.
  ///
  /// In en, this message translates to:
  /// **'Home amount'**
  String get txDetailHomeAmount;

  /// No description provided for @txDetailSource.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get txDetailSource;

  /// No description provided for @txDetailAiScanned.
  ///
  /// In en, this message translates to:
  /// **'AI scanned'**
  String get txDetailAiScanned;

  /// No description provided for @txDetailManualFallback.
  ///
  /// In en, this message translates to:
  /// **'Manual fallback'**
  String get txDetailManualFallback;

  /// No description provided for @txDetailTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get txDetailTotal;

  /// No description provided for @txDetailFallbackTransfer.
  ///
  /// In en, this message translates to:
  /// **'Transfer'**
  String get txDetailFallbackTransfer;

  /// No description provided for @txDetailDeleteTransaction.
  ///
  /// In en, this message translates to:
  /// **'Delete transaction'**
  String get txDetailDeleteTransaction;

  /// No description provided for @txDetailDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete transaction?'**
  String get txDetailDeleteTitle;

  /// No description provided for @txDetailDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'This cannot be undone.'**
  String get txDetailDeleteBody;

  /// No description provided for @txDetailCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get txDetailCancel;

  /// No description provided for @txDetailDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get txDetailDelete;

  /// No description provided for @txDetailNotFound.
  ///
  /// In en, this message translates to:
  /// **'Not found'**
  String get txDetailNotFound;

  /// No description provided for @txListSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get txListSearch;

  /// No description provided for @txListNewTransaction.
  ///
  /// In en, this message translates to:
  /// **'New transaction'**
  String get txListNewTransaction;

  /// No description provided for @txListFilterSource.
  ///
  /// In en, this message translates to:
  /// **'Filter source'**
  String get txListFilterSource;

  /// No description provided for @txListNotSynced.
  ///
  /// In en, this message translates to:
  /// **'Not synced'**
  String get txListNotSynced;

  /// No description provided for @txListIncome.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get txListIncome;

  /// No description provided for @txListExpenses.
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get txListExpenses;

  /// No description provided for @txListTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get txListTotal;

  /// No description provided for @txListNoMatches.
  ///
  /// In en, this message translates to:
  /// **'No transactions match this filter'**
  String get txListNoMatches;

  /// No description provided for @txListNoTransactions.
  ///
  /// In en, this message translates to:
  /// **'No transactions yet'**
  String get txListNoTransactions;

  /// No description provided for @txListEmptySwitchAll.
  ///
  /// In en, this message translates to:
  /// **'Try switching to All to see every transaction this month.'**
  String get txListEmptySwitchAll;

  /// No description provided for @txListEmptyAddTransaction.
  ///
  /// In en, this message translates to:
  /// **'Add a transaction or scan a receipt to get started.'**
  String get txListEmptyAddTransaction;

  /// No description provided for @txListEmptyScanReceipt.
  ///
  /// In en, this message translates to:
  /// **'Scan receipt'**
  String get txListEmptyScanReceipt;

  /// No description provided for @txListShowAll.
  ///
  /// In en, this message translates to:
  /// **'Show all'**
  String get txListShowAll;

  /// Budget alert banner, e.g. '3 categories trending high'
  ///
  /// In en, this message translates to:
  /// **'{count} categories trending high'**
  String txListCategoriesTrending(int count);

  /// No description provided for @txListTapBudget.
  ///
  /// In en, this message translates to:
  /// **'Tap a budget to drill down.'**
  String get txListTapBudget;

  /// No description provided for @txListViewBudgets.
  ///
  /// In en, this message translates to:
  /// **'View budgets'**
  String get txListViewBudgets;

  /// No description provided for @txListToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get txListToday;

  /// No description provided for @txListYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get txListYesterday;

  /// Warning when trying to delete a room transaction outside the room
  ///
  /// In en, this message translates to:
  /// **'This transaction belongs to \"{roomName}\". Delete it from the room.'**
  String txListRoomDeleteSnackbar(String roomName);

  /// No description provided for @txListOpenRoom.
  ///
  /// In en, this message translates to:
  /// **'Open room'**
  String get txListOpenRoom;

  /// No description provided for @txListDeleted.
  ///
  /// In en, this message translates to:
  /// **'Transaction deleted'**
  String get txListDeleted;

  /// No description provided for @txListUndo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get txListUndo;

  /// Error when transaction delete fails
  ///
  /// In en, this message translates to:
  /// **'Delete failed: {error}'**
  String txListDeleteFailed(String error);

  /// Error when transaction undo fails
  ///
  /// In en, this message translates to:
  /// **'Undo failed: {error}'**
  String txListUndoFailed(String error);

  /// No description provided for @txListDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get txListDelete;

  /// No description provided for @txListFilterTransactions.
  ///
  /// In en, this message translates to:
  /// **'Filter transactions'**
  String get txListFilterTransactions;

  /// No description provided for @txListAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get txListAll;

  /// No description provided for @txListPersonal.
  ///
  /// In en, this message translates to:
  /// **'Personal'**
  String get txListPersonal;

  /// No description provided for @txListRooms.
  ///
  /// In en, this message translates to:
  /// **'Rooms'**
  String get txListRooms;

  /// Footer showing filtered vs total count
  ///
  /// In en, this message translates to:
  /// **'{filtered} of {total} total'**
  String txListFooter(int filtered, int total);

  /// No description provided for @txListRoom.
  ///
  /// In en, this message translates to:
  /// **'Room'**
  String get txListRoom;

  /// No description provided for @txSearchPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Search notes, category…'**
  String get txSearchPlaceholder;

  /// No description provided for @txSearchType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get txSearchType;

  /// No description provided for @txSearchDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get txSearchDate;

  /// No description provided for @txSearchSource.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get txSearchSource;

  /// No description provided for @txSearchIncome.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get txSearchIncome;

  /// No description provided for @txSearchExpense.
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get txSearchExpense;

  /// No description provided for @txSearchThisWeek.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get txSearchThisWeek;

  /// No description provided for @txSearchThisMonth.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get txSearchThisMonth;

  /// No description provided for @txSearchThisYear.
  ///
  /// In en, this message translates to:
  /// **'This year'**
  String get txSearchThisYear;

  /// No description provided for @txSearchCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get txSearchCustom;

  /// No description provided for @txSearchPersonal.
  ///
  /// In en, this message translates to:
  /// **'Personal'**
  String get txSearchPersonal;

  /// No description provided for @txSearchRooms.
  ///
  /// In en, this message translates to:
  /// **'Rooms'**
  String get txSearchRooms;

  /// No description provided for @txSearchNoMatches.
  ///
  /// In en, this message translates to:
  /// **'No matches'**
  String get txSearchNoMatches;

  /// No description provided for @txSearchNoMatchesBody.
  ///
  /// In en, this message translates to:
  /// **'No transactions match the filters.'**
  String get txSearchNoMatchesBody;

  /// Empty search result with query term
  ///
  /// In en, this message translates to:
  /// **'Nothing matched \"{query}\".'**
  String txSearchNoMatchesQuery(String query);

  /// No description provided for @txSearchEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Search your transactions'**
  String get txSearchEmptyTitle;

  /// No description provided for @txSearchEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Type a category, note, or pick a filter above.'**
  String get txSearchEmptyBody;

  /// No description provided for @txSearchRecent.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get txSearchRecent;

  /// No description provided for @txSearchRoom.
  ///
  /// In en, this message translates to:
  /// **'Room'**
  String get txSearchRoom;

  /// No description provided for @quickAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Add expense'**
  String get quickAddTitle;

  /// No description provided for @quickAddAmount.
  ///
  /// In en, this message translates to:
  /// **'AMOUNT'**
  String get quickAddAmount;

  /// No description provided for @quickAddContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get quickAddContinue;

  /// No description provided for @quickAddRegionSuffix.
  ///
  /// In en, this message translates to:
  /// **'{currency} · ID'**
  String quickAddRegionSuffix(Object currency);

  /// No description provided for @budgetFormNewBudget.
  ///
  /// In en, this message translates to:
  /// **'New budget'**
  String get budgetFormNewBudget;

  /// No description provided for @budgetFormEditBudget.
  ///
  /// In en, this message translates to:
  /// **'Edit budget'**
  String get budgetFormEditBudget;

  /// No description provided for @budgetFormLimit.
  ///
  /// In en, this message translates to:
  /// **'LIMIT'**
  String get budgetFormLimit;

  /// No description provided for @budgetFormSetup.
  ///
  /// In en, this message translates to:
  /// **'SETUP'**
  String get budgetFormSetup;

  /// No description provided for @budgetFormCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get budgetFormCategory;

  /// No description provided for @budgetFormPeriod.
  ///
  /// In en, this message translates to:
  /// **'Period'**
  String get budgetFormPeriod;

  /// No description provided for @budgetFormResetsOn.
  ///
  /// In en, this message translates to:
  /// **'Resets on'**
  String get budgetFormResetsOn;

  /// No description provided for @budgetFormAlerts.
  ///
  /// In en, this message translates to:
  /// **'ALERTS'**
  String get budgetFormAlerts;

  /// No description provided for @budgetFormAt70.
  ///
  /// In en, this message translates to:
  /// **'At 70%'**
  String get budgetFormAt70;

  /// No description provided for @budgetFormAt100.
  ///
  /// In en, this message translates to:
  /// **'At 100%'**
  String get budgetFormAt100;

  /// No description provided for @budgetFormDailyOverBudget.
  ///
  /// In en, this message translates to:
  /// **'Daily over budget'**
  String get budgetFormDailyOverBudget;

  /// No description provided for @budgetFormPersonalOnlyInfo.
  ///
  /// In en, this message translates to:
  /// **'You\'ll see this in Personal only. Room budgets are set in each room.'**
  String get budgetFormPersonalOnlyInfo;

  /// No description provided for @budgetFormCreateBudget.
  ///
  /// In en, this message translates to:
  /// **'Create budget'**
  String get budgetFormCreateBudget;

  /// No description provided for @budgetFormSaveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get budgetFormSaveChanges;

  /// No description provided for @budgetFormInvalidAmount.
  ///
  /// In en, this message translates to:
  /// **'Please enter an amount greater than 0'**
  String get budgetFormInvalidAmount;

  /// No description provided for @budgetFormMonday.
  ///
  /// In en, this message translates to:
  /// **'Monday'**
  String get budgetFormMonday;

  /// No description provided for @budgetFormTuesday.
  ///
  /// In en, this message translates to:
  /// **'Tuesday'**
  String get budgetFormTuesday;

  /// No description provided for @budgetFormWednesday.
  ///
  /// In en, this message translates to:
  /// **'Wednesday'**
  String get budgetFormWednesday;

  /// No description provided for @budgetFormThursday.
  ///
  /// In en, this message translates to:
  /// **'Thursday'**
  String get budgetFormThursday;

  /// No description provided for @budgetFormFriday.
  ///
  /// In en, this message translates to:
  /// **'Friday'**
  String get budgetFormFriday;

  /// No description provided for @budgetFormSaturday.
  ///
  /// In en, this message translates to:
  /// **'Saturday'**
  String get budgetFormSaturday;

  /// No description provided for @budgetFormSunday.
  ///
  /// In en, this message translates to:
  /// **'Sunday'**
  String get budgetFormSunday;

  /// No description provided for @budgetFormJanuary.
  ///
  /// In en, this message translates to:
  /// **'January'**
  String get budgetFormJanuary;

  /// No description provided for @budgetFormFebruary.
  ///
  /// In en, this message translates to:
  /// **'February'**
  String get budgetFormFebruary;

  /// No description provided for @budgetFormMarch.
  ///
  /// In en, this message translates to:
  /// **'March'**
  String get budgetFormMarch;

  /// No description provided for @budgetFormApril.
  ///
  /// In en, this message translates to:
  /// **'April'**
  String get budgetFormApril;

  /// No description provided for @budgetFormMay.
  ///
  /// In en, this message translates to:
  /// **'May'**
  String get budgetFormMay;

  /// No description provided for @budgetFormJune.
  ///
  /// In en, this message translates to:
  /// **'June'**
  String get budgetFormJune;

  /// No description provided for @budgetFormJuly.
  ///
  /// In en, this message translates to:
  /// **'July'**
  String get budgetFormJuly;

  /// No description provided for @budgetFormAugust.
  ///
  /// In en, this message translates to:
  /// **'August'**
  String get budgetFormAugust;

  /// No description provided for @budgetFormSeptember.
  ///
  /// In en, this message translates to:
  /// **'September'**
  String get budgetFormSeptember;

  /// No description provided for @budgetFormOctober.
  ///
  /// In en, this message translates to:
  /// **'October'**
  String get budgetFormOctober;

  /// No description provided for @budgetFormNovember.
  ///
  /// In en, this message translates to:
  /// **'November'**
  String get budgetFormNovember;

  /// No description provided for @budgetFormDecember.
  ///
  /// In en, this message translates to:
  /// **'December'**
  String get budgetFormDecember;

  /// No description provided for @budgetFormLastDay.
  ///
  /// In en, this message translates to:
  /// **'Last day'**
  String get budgetFormLastDay;

  /// Day of month label, e.g. 'Day 15'
  ///
  /// In en, this message translates to:
  /// **'Day {d}'**
  String budgetFormDay(int d);

  /// Yearly reset label, e.g. '1 January'
  ///
  /// In en, this message translates to:
  /// **'1 {month}'**
  String budgetForm1Month(String month);

  /// No description provided for @budgetFormEvery.
  ///
  /// In en, this message translates to:
  /// **'Every'**
  String get budgetFormEvery;

  /// Custom reset interval, e.g. 'Every 7 days'
  ///
  /// In en, this message translates to:
  /// **'Every {n} days'**
  String budgetFormEveryNDays(int n);

  /// No description provided for @budgetDetailNotFound.
  ///
  /// In en, this message translates to:
  /// **'Budget not found'**
  String get budgetDetailNotFound;

  /// Day-in-cycle progress, e.g. 'Day 5 / 30'
  ///
  /// In en, this message translates to:
  /// **'Day {day} / {total}'**
  String budgetDetailDayInCycle(int day, int total);

  /// Over-budget status, e.g. '120% — Rp50,000 over'
  ///
  /// In en, this message translates to:
  /// **'{pct}% — {overAmt} over'**
  String budgetDetailOverBudget(int pct, String overAmt);

  /// On-budget status, e.g. '65% used'
  ///
  /// In en, this message translates to:
  /// **'{pct}% used'**
  String budgetDetailUsed(int pct);

  /// Rollover info banner, e.g. 'Rollover scheduled — Rp50,000 will reduce the limit on May 1, 2026.'
  ///
  /// In en, this message translates to:
  /// **'Rollover scheduled — {overAmt} will reduce the limit on {date}.'**
  String budgetDetailRolloverScheduled(String overAmt, String date);

  /// No description provided for @budgetDetailContributingTop5.
  ///
  /// In en, this message translates to:
  /// **'CONTRIBUTING · TOP 5'**
  String get budgetDetailContributingTop5;

  /// No description provided for @budgetDetailDeleteBudget.
  ///
  /// In en, this message translates to:
  /// **'Delete budget'**
  String get budgetDetailDeleteBudget;

  /// No description provided for @budgetDetailDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete budget?'**
  String get budgetDetailDeleteTitle;

  /// Delete budget confirmation dialog body
  ///
  /// In en, this message translates to:
  /// **'This permanently deletes the {category} budget. Transactions are kept. This cannot be undone.'**
  String budgetDetailDeleteBody(String category);

  /// No description provided for @budgetDetailCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get budgetDetailCancel;

  /// No description provided for @budgetDetailDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get budgetDetailDelete;

  /// Error when budget delete fails
  ///
  /// In en, this message translates to:
  /// **'Delete failed: {error}'**
  String budgetDetailDeleteFailed(String error);

  /// No description provided for @budgetDetailEditLimit.
  ///
  /// In en, this message translates to:
  /// **'Edit limit'**
  String get budgetDetailEditLimit;

  /// No description provided for @budgetDetailRollOver.
  ///
  /// In en, this message translates to:
  /// **'Roll over'**
  String get budgetDetailRollOver;

  /// Success message after rolling over excess
  ///
  /// In en, this message translates to:
  /// **'{overAmt} carried into next cycle'**
  String budgetDetailRollOverSuccess(String overAmt);

  /// Error when budget rollover fails
  ///
  /// In en, this message translates to:
  /// **'Roll over failed: {error}'**
  String budgetDetailRollOverFailed(String error);

  /// No description provided for @budgetsScreenNewBudget.
  ///
  /// In en, this message translates to:
  /// **'New budget'**
  String get budgetsScreenNewBudget;

  /// No description provided for @budgetsScreenFilter.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get budgetsScreenFilter;

  /// No description provided for @budgetsScreenLimit.
  ///
  /// In en, this message translates to:
  /// **'Limit'**
  String get budgetsScreenLimit;

  /// No description provided for @budgetsScreenSpent.
  ///
  /// In en, this message translates to:
  /// **'Spent'**
  String get budgetsScreenSpent;

  /// No description provided for @budgetsScreenLeft.
  ///
  /// In en, this message translates to:
  /// **'Left'**
  String get budgetsScreenLeft;

  /// No description provided for @budgetsScreenNoBudgets.
  ///
  /// In en, this message translates to:
  /// **'No budgets yet'**
  String get budgetsScreenNoBudgets;

  /// No description provided for @budgetsScreenEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Set a monthly limit per category to track spend at a glance.'**
  String get budgetsScreenEmptyBody;

  /// No description provided for @budgetsScreenCategories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get budgetsScreenCategories;

  /// No description provided for @budgetsScreenNoLimits.
  ///
  /// In en, this message translates to:
  /// **'No limits set'**
  String get budgetsScreenNoLimits;

  /// Pace label showing over-budget count
  ///
  /// In en, this message translates to:
  /// **'Day {day} · {days} — {overCount} over'**
  String budgetsScreenDayOver(int day, int days, int overCount);

  /// Pace label when on track
  ///
  /// In en, this message translates to:
  /// **'Day {day} · {days} — on pace'**
  String budgetsScreenOnPace(int day, int days);

  /// Pace label when spending too fast
  ///
  /// In en, this message translates to:
  /// **'Day {day} · {days} — over pace'**
  String budgetsScreenOverPace(int day, int days);

  /// No description provided for @budgetsScreenMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get budgetsScreenMonthly;

  /// No description provided for @budgetsScreenWeekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get budgetsScreenWeekly;

  /// No description provided for @budgetsScreenCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get budgetsScreenCustom;

  /// No description provided for @accountsScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Accounts'**
  String get accountsScreenTitle;

  /// No description provided for @accountsScreenAssets.
  ///
  /// In en, this message translates to:
  /// **'Assets'**
  String get accountsScreenAssets;

  /// No description provided for @accountsScreenLiabilities.
  ///
  /// In en, this message translates to:
  /// **'Liabilities'**
  String get accountsScreenLiabilities;

  /// No description provided for @accountsScreenAddAccount.
  ///
  /// In en, this message translates to:
  /// **'Add account'**
  String get accountsScreenAddAccount;

  /// No description provided for @accountsScreenNoAccounts.
  ///
  /// In en, this message translates to:
  /// **'No accounts yet'**
  String get accountsScreenNoAccounts;

  /// No description provided for @accountsScreenEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Add your cash, bank accounts, and cards to track balances.'**
  String get accountsScreenEmptyBody;

  /// Account row subtitle, e.g. 'Asset · IDR'
  ///
  /// In en, this message translates to:
  /// **'Asset · {currency}'**
  String accountsScreenAssetType(String currency);

  /// Account row subtitle, e.g. 'Liability · IDR'
  ///
  /// In en, this message translates to:
  /// **'Liability · {currency}'**
  String accountsScreenLiabilityType(String currency);

  /// No description provided for @accountFormNewAccount.
  ///
  /// In en, this message translates to:
  /// **'New account'**
  String get accountFormNewAccount;

  /// No description provided for @accountFormEditAccount.
  ///
  /// In en, this message translates to:
  /// **'Edit account'**
  String get accountFormEditAccount;

  /// No description provided for @accountFormName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get accountFormName;

  /// No description provided for @accountFormNamePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'e.g. BCA Savings'**
  String get accountFormNamePlaceholder;

  /// No description provided for @accountFormType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get accountFormType;

  /// No description provided for @accountFormAsset.
  ///
  /// In en, this message translates to:
  /// **'Asset'**
  String get accountFormAsset;

  /// No description provided for @accountFormLiability.
  ///
  /// In en, this message translates to:
  /// **'Liability'**
  String get accountFormLiability;

  /// No description provided for @accountFormCurrency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get accountFormCurrency;

  /// No description provided for @accountFormCurrentBalance.
  ///
  /// In en, this message translates to:
  /// **'Current balance'**
  String get accountFormCurrentBalance;

  /// No description provided for @accountFormOpeningBalance.
  ///
  /// In en, this message translates to:
  /// **'Opening balance'**
  String get accountFormOpeningBalance;

  /// No description provided for @accountFormSaveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get accountFormSaveChanges;

  /// No description provided for @accountFormCreateAccount.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get accountFormCreateAccount;

  /// No description provided for @accountFormNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Name required'**
  String get accountFormNameRequired;

  /// No description provided for @accountFormNameAlreadyUsed.
  ///
  /// In en, this message translates to:
  /// **'Name already used'**
  String get accountFormNameAlreadyUsed;

  /// Error when account save fails
  ///
  /// In en, this message translates to:
  /// **'Save failed: {error}'**
  String accountFormSaveFailed(String error);

  /// No description provided for @accountFormBalanceAdjustment.
  ///
  /// In en, this message translates to:
  /// **'Balance adjustment'**
  String get accountFormBalanceAdjustment;

  /// No description provided for @accountFormAddAdjustmentTitle.
  ///
  /// In en, this message translates to:
  /// **'Add adjustment transaction?'**
  String get accountFormAddAdjustmentTitle;

  /// Adjustment confirmation dialog body
  ///
  /// In en, this message translates to:
  /// **'Balance will change from {current} to {target}.\n\nA {txLabel} transaction of {delta} (category \"Adjustment\") will be added to record the change.'**
  String accountFormAddAdjustmentBody(
    String current,
    String target,
    String txLabel,
    String delta,
  );

  /// No description provided for @accountFormAddAdjustment.
  ///
  /// In en, this message translates to:
  /// **'Add adjustment'**
  String get accountFormAddAdjustment;

  /// No description provided for @accountFormCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get accountFormCancel;

  /// No description provided for @accountFormArchive.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get accountFormArchive;

  /// No description provided for @accountFormDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get accountFormDelete;

  /// No description provided for @accountFormArchiveTitle.
  ///
  /// In en, this message translates to:
  /// **'Archive account?'**
  String get accountFormArchiveTitle;

  /// No description provided for @accountFormArchiveBody.
  ///
  /// In en, this message translates to:
  /// **'The account will be hidden but data is kept.'**
  String get accountFormArchiveBody;

  /// No description provided for @accountFormDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete account?'**
  String get accountFormDeleteTitle;

  /// Delete account confirmation (0 transactions)
  ///
  /// In en, this message translates to:
  /// **'This permanently deletes \"{name}\". This cannot be undone.'**
  String accountFormDeleteBody(String name);

  /// Delete account confirmation (with transactions affected)
  ///
  /// In en, this message translates to:
  /// **'This permanently deletes \"{name}\" and {affected} transaction{plural} that reference it. This cannot be undone.'**
  String accountFormDeleteBodyWithTxns(
    String name,
    int affected,
    String plural,
  );

  /// Error when account delete fails
  ///
  /// In en, this message translates to:
  /// **'Delete failed: {error}'**
  String accountFormDeleteFailed(String error);

  /// No description provided for @accountFormLiabilityInfo.
  ///
  /// In en, this message translates to:
  /// **'For loans, create a Transfer from this liability account to an asset account.'**
  String get accountFormLiabilityInfo;

  /// No description provided for @accountFormRecentTransactions.
  ///
  /// In en, this message translates to:
  /// **'Recent transactions'**
  String get accountFormRecentTransactions;

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
