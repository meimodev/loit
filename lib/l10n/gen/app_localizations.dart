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

  /// No description provided for @scanReceiptTitle.
  ///
  /// In en, this message translates to:
  /// **'Scan receipt'**
  String get scanReceiptTitle;

  /// No description provided for @scanReceipt.
  ///
  /// In en, this message translates to:
  /// **'RECEIPT'**
  String get scanReceipt;

  /// No description provided for @scanAlignHint.
  ///
  /// In en, this message translates to:
  /// **'Align receipt within frame'**
  String get scanAlignHint;

  /// No description provided for @scanReadingTitle.
  ///
  /// In en, this message translates to:
  /// **'Reading receipt'**
  String get scanReadingTitle;

  /// No description provided for @scanReadingBody.
  ///
  /// In en, this message translates to:
  /// **'Reading your receipt…'**
  String get scanReadingBody;

  /// No description provided for @scanReadingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Usually takes about 2 seconds. We\'re extracting merchant, total, and items.'**
  String get scanReadingSubtitle;

  /// No description provided for @scanPersonal.
  ///
  /// In en, this message translates to:
  /// **'Personal'**
  String get scanPersonal;

  /// No description provided for @scanRooms.
  ///
  /// In en, this message translates to:
  /// **'Rooms'**
  String get scanRooms;

  /// No description provided for @scanRoom.
  ///
  /// In en, this message translates to:
  /// **'Room'**
  String get scanRoom;

  /// No description provided for @scanSaved.
  ///
  /// In en, this message translates to:
  /// **'Receipt saved'**
  String get scanSaved;

  /// No description provided for @scanNoRooms.
  ///
  /// In en, this message translates to:
  /// **'No rooms yet — create one before scanning to a room.'**
  String get scanNoRooms;

  /// No description provided for @scanSendToRoom.
  ///
  /// In en, this message translates to:
  /// **'Send receipt to room'**
  String get scanSendToRoom;

  /// No description provided for @scanLimitReached.
  ///
  /// In en, this message translates to:
  /// **'Scan limit reached'**
  String get scanLimitReached;

  /// Quota exceeded message showing used scans
  ///
  /// In en, this message translates to:
  /// **'Used all {quota} scans on {tier} this month.'**
  String scanUsedAllScans(String quota, String tier);

  /// No description provided for @scanQuotaDefault.
  ///
  /// In en, this message translates to:
  /// **'You have used your monthly scan quota.'**
  String get scanQuotaDefault;

  /// No description provided for @scanTopUp.
  ///
  /// In en, this message translates to:
  /// **'Top up · 10 scans for Rp19,000'**
  String get scanTopUp;

  /// No description provided for @scanUpgrade.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to Pro — unlimited scans'**
  String get scanUpgrade;

  /// No description provided for @scanNotNow.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get scanNotNow;

  /// No description provided for @scanTakeAnother.
  ///
  /// In en, this message translates to:
  /// **'Take another photo'**
  String get scanTakeAnother;

  /// No description provided for @scanRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get scanRetry;

  /// No description provided for @scanCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get scanCancel;

  /// No description provided for @scanInviteInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invite is invalid or expired'**
  String get scanInviteInvalid;

  /// Error when joining room from QR scan
  ///
  /// In en, this message translates to:
  /// **'Could not join room: {error}'**
  String scanCouldNotJoinRoom(String error);

  /// No description provided for @scanJoinRoomTitle.
  ///
  /// In en, this message translates to:
  /// **'Join room?'**
  String get scanJoinRoomTitle;

  /// No description provided for @scanJoinRoomBody.
  ///
  /// In en, this message translates to:
  /// **'A LOIT room invite QR was detected. Join the room?'**
  String get scanJoinRoomBody;

  /// No description provided for @scanJoinRoom.
  ///
  /// In en, this message translates to:
  /// **'Join room'**
  String get scanJoinRoom;

  /// No description provided for @scanJoining.
  ///
  /// In en, this message translates to:
  /// **'Joining…'**
  String get scanJoining;

  /// No description provided for @scanNotTransaction.
  ///
  /// In en, this message translates to:
  /// **'That doesn\'t look like a transaction'**
  String get scanNotTransaction;

  /// No description provided for @scanNotTransactionBody.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t find a receipt, invoice, transfer slip, payslip, or similar transaction record in this image. Try a clearer photo of the document.'**
  String get scanNotTransactionBody;

  /// No description provided for @scanOfflineTitle.
  ///
  /// In en, this message translates to:
  /// **'You\'re offline'**
  String get scanOfflineTitle;

  /// No description provided for @scanOfflineBody.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t reach the scan service. Check connection and retry.'**
  String get scanOfflineBody;

  /// No description provided for @scanUnavailableTitle.
  ///
  /// In en, this message translates to:
  /// **'Scan service unavailable'**
  String get scanUnavailableTitle;

  /// No description provided for @scanUnavailableBody.
  ///
  /// In en, this message translates to:
  /// **'Scan service temporarily unavailable. Try again in a moment.'**
  String get scanUnavailableBody;

  /// No description provided for @receiptsTitle.
  ///
  /// In en, this message translates to:
  /// **'Receipts'**
  String get receiptsTitle;

  /// Error loading receipts
  ///
  /// In en, this message translates to:
  /// **'Failed to load: {error}'**
  String receiptsFailed(String error);

  /// Error downloading receipt file
  ///
  /// In en, this message translates to:
  /// **'Download failed: {error}'**
  String receiptsDownloadFailed(String error);

  /// Share sheet subject for receipt, e.g. 'Receipt Jan 15, 2026'
  ///
  /// In en, this message translates to:
  /// **'Receipt {date}'**
  String receiptsShareSubject(String date);

  /// No description provided for @receiptsFallback.
  ///
  /// In en, this message translates to:
  /// **'Receipt'**
  String get receiptsFallback;

  /// No description provided for @receiptsActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get receiptsActive;

  /// No description provided for @receiptsExpiring.
  ///
  /// In en, this message translates to:
  /// **'Expiring'**
  String get receiptsExpiring;

  /// No description provided for @receiptsExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get receiptsExpired;

  /// No description provided for @receiptsNoReceipts.
  ///
  /// In en, this message translates to:
  /// **'No receipts yet'**
  String get receiptsNoReceipts;

  /// No description provided for @receiptsEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Scanned receipts will appear here. Use the scanner to capture one.'**
  String get receiptsEmptyBody;

  /// No description provided for @reportsScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get reportsScreenTitle;

  /// No description provided for @reportsScreenIncome.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get reportsScreenIncome;

  /// No description provided for @reportsScreenExpenses.
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get reportsScreenExpenses;

  /// No description provided for @reportsScreenNet.
  ///
  /// In en, this message translates to:
  /// **'Net'**
  String get reportsScreenNet;

  /// No description provided for @reportsScreenNoData.
  ///
  /// In en, this message translates to:
  /// **'No data for this period'**
  String get reportsScreenNoData;

  /// No description provided for @reportsScreenCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get reportsScreenCategory;

  /// No description provided for @reportsScreenAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get reportsScreenAmount;

  /// No description provided for @reportsScreenPercent.
  ///
  /// In en, this message translates to:
  /// **'%'**
  String get reportsScreenPercent;

  /// No description provided for @reportsScreenEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Reports will appear when you have transactions.'**
  String get reportsScreenEmptyBody;

  /// No description provided for @exportScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Export data'**
  String get exportScreenTitle;

  /// No description provided for @exportScreenFormat.
  ///
  /// In en, this message translates to:
  /// **'Format'**
  String get exportScreenFormat;

  /// No description provided for @exportScreenDateRange.
  ///
  /// In en, this message translates to:
  /// **'Date range'**
  String get exportScreenDateRange;

  /// No description provided for @exportScreenLastMonth.
  ///
  /// In en, this message translates to:
  /// **'Last month'**
  String get exportScreenLastMonth;

  /// No description provided for @exportScreenLast3Months.
  ///
  /// In en, this message translates to:
  /// **'Last 3 months'**
  String get exportScreenLast3Months;

  /// No description provided for @exportScreenLast6Months.
  ///
  /// In en, this message translates to:
  /// **'Last 6 months'**
  String get exportScreenLast6Months;

  /// No description provided for @exportScreenLastYear.
  ///
  /// In en, this message translates to:
  /// **'Last year'**
  String get exportScreenLastYear;

  /// No description provided for @exportScreenAllTime.
  ///
  /// In en, this message translates to:
  /// **'All time'**
  String get exportScreenAllTime;

  /// No description provided for @exportScreenExport.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get exportScreenExport;

  /// No description provided for @exportScreenExporting.
  ///
  /// In en, this message translates to:
  /// **'Exporting…'**
  String get exportScreenExporting;

  /// No description provided for @exportScreenReady.
  ///
  /// In en, this message translates to:
  /// **'Your export is ready.'**
  String get exportScreenReady;

  /// Error when export fails
  ///
  /// In en, this message translates to:
  /// **'Export failed: {error}'**
  String exportScreenFailed(String error);

  /// No description provided for @exportScreenAccounts.
  ///
  /// In en, this message translates to:
  /// **'Accounts'**
  String get exportScreenAccounts;

  /// No description provided for @exportScreenTransactions.
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get exportScreenTransactions;

  /// No description provided for @exportScreenBudgets.
  ///
  /// In en, this message translates to:
  /// **'Budgets'**
  String get exportScreenBudgets;

  /// No description provided for @roomsScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Rooms'**
  String get roomsScreenTitle;

  /// No description provided for @roomsScreenNoRooms.
  ///
  /// In en, this message translates to:
  /// **'No rooms yet'**
  String get roomsScreenNoRooms;

  /// No description provided for @roomsScreenEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Create or join a room to track shared expenses.'**
  String get roomsScreenEmptyBody;

  /// No description provided for @roomsScreenCreateRoom.
  ///
  /// In en, this message translates to:
  /// **'Create room'**
  String get roomsScreenCreateRoom;

  /// No description provided for @roomsScreenJoinRoom.
  ///
  /// In en, this message translates to:
  /// **'Join room'**
  String get roomsScreenJoinRoom;

  /// Room member count, e.g. '3 members'
  ///
  /// In en, this message translates to:
  /// **'{n} members'**
  String roomsScreenMembers(int n);

  /// No description provided for @roomCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'Create room'**
  String get roomCreateTitle;

  /// No description provided for @roomCreateName.
  ///
  /// In en, this message translates to:
  /// **'Room name'**
  String get roomCreateName;

  /// No description provided for @roomCreateNamePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'e.g. Flatmates, Trip to Bali'**
  String get roomCreateNamePlaceholder;

  /// No description provided for @roomCreateDescription.
  ///
  /// In en, this message translates to:
  /// **'Description (optional)'**
  String get roomCreateDescription;

  /// No description provided for @roomCreateCreate.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get roomCreateCreate;

  /// No description provided for @roomCreateCreating.
  ///
  /// In en, this message translates to:
  /// **'Creating…'**
  String get roomCreateCreating;

  /// Error when room creation fails
  ///
  /// In en, this message translates to:
  /// **'Failed to create room: {error}'**
  String roomCreateFailed(String error);

  /// No description provided for @roomInviteTitle.
  ///
  /// In en, this message translates to:
  /// **'Invite members'**
  String get roomInviteTitle;

  /// No description provided for @roomInviteShare.
  ///
  /// In en, this message translates to:
  /// **'Share invite link'**
  String get roomInviteShare;

  /// No description provided for @roomInviteBody.
  ///
  /// In en, this message translates to:
  /// **'Anyone with this link can join the room.'**
  String get roomInviteBody;

  /// No description provided for @roomJoinTitle.
  ///
  /// In en, this message translates to:
  /// **'Join room'**
  String get roomJoinTitle;

  /// No description provided for @roomJoinJoining.
  ///
  /// In en, this message translates to:
  /// **'Joining…'**
  String get roomJoinJoining;

  /// No description provided for @roomJoinInvalid.
  ///
  /// In en, this message translates to:
  /// **'This invite is invalid or expired.'**
  String get roomJoinInvalid;

  /// Error when joining a room fails
  ///
  /// In en, this message translates to:
  /// **'Failed to join: {error}'**
  String roomJoinFailed(String error);

  /// No description provided for @roomDetailAddTransaction.
  ///
  /// In en, this message translates to:
  /// **'Add transaction'**
  String get roomDetailAddTransaction;

  /// No description provided for @roomDetailMembers.
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get roomDetailMembers;

  /// No description provided for @roomDetailBudgets.
  ///
  /// In en, this message translates to:
  /// **'Budgets'**
  String get roomDetailBudgets;

  /// No description provided for @roomDetailLeave.
  ///
  /// In en, this message translates to:
  /// **'Leave room'**
  String get roomDetailLeave;

  /// No description provided for @roomDetailLeaveTitle.
  ///
  /// In en, this message translates to:
  /// **'Leave room?'**
  String get roomDetailLeaveTitle;

  /// No description provided for @roomDetailLeaveBody.
  ///
  /// In en, this message translates to:
  /// **'Your transactions in this room will be kept.'**
  String get roomDetailLeaveBody;

  /// No description provided for @roomDetailLeaveConfirm.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get roomDetailLeaveConfirm;

  /// No description provided for @roomDetailDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete room?'**
  String get roomDetailDeleteTitle;

  /// No description provided for @roomDetailDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'All shared data in this room will be permanently deleted.'**
  String get roomDetailDeleteBody;

  /// No description provided for @roomDetailDeleteRoom.
  ///
  /// In en, this message translates to:
  /// **'Delete room'**
  String get roomDetailDeleteRoom;

  /// No description provided for @roomDetailBudgetTitle.
  ///
  /// In en, this message translates to:
  /// **'Room budget'**
  String get roomDetailBudgetTitle;

  /// No description provided for @roomDetailNotSynced.
  ///
  /// In en, this message translates to:
  /// **'Not synced'**
  String get roomDetailNotSynced;

  /// No description provided for @roomDetailNotSyncedBody.
  ///
  /// In en, this message translates to:
  /// **'This transaction hasn\'t synced yet. Edit to save it.'**
  String get roomDetailNotSyncedBody;

  /// No description provided for @paywallTitle.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to Pro'**
  String get paywallTitle;

  /// No description provided for @paywallSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Unlock unlimited scans, receipts, and budgets.'**
  String get paywallSubtitle;

  /// No description provided for @paywallContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get paywallContinue;

  /// No description provided for @paywallRestoring.
  ///
  /// In en, this message translates to:
  /// **'Restoring…'**
  String get paywallRestoring;

  /// No description provided for @paywallFree.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get paywallFree;

  /// No description provided for @paywallPro.
  ///
  /// In en, this message translates to:
  /// **'Pro'**
  String get paywallPro;

  /// No description provided for @paywallTeam.
  ///
  /// In en, this message translates to:
  /// **'Team'**
  String get paywallTeam;

  /// No description provided for @pwProSuccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Pro!'**
  String get pwProSuccessTitle;

  /// No description provided for @pwProSuccessBody.
  ///
  /// In en, this message translates to:
  /// **'You now have unlimited scans and premium features.'**
  String get pwProSuccessBody;

  /// No description provided for @pwProSuccessDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get pwProSuccessDone;

  /// No description provided for @billingManageTitle.
  ///
  /// In en, this message translates to:
  /// **'Manage subscription'**
  String get billingManageTitle;

  /// No description provided for @billingManageCurrentPlan.
  ///
  /// In en, this message translates to:
  /// **'Current plan'**
  String get billingManageCurrentPlan;

  /// No description provided for @billingManageCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel subscription'**
  String get billingManageCancel;

  /// No description provided for @billingManageCancelTitle.
  ///
  /// In en, this message translates to:
  /// **'Cancel subscription?'**
  String get billingManageCancelTitle;

  /// No description provided for @billingManageCancelBody.
  ///
  /// In en, this message translates to:
  /// **'You will lose Pro features at the end of your billing period.'**
  String get billingManageCancelBody;

  /// No description provided for @billingManageCancelConfirm.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get billingManageCancelConfirm;

  /// No description provided for @billingManageCancelFailed.
  ///
  /// In en, this message translates to:
  /// **'Cancel failed: {error}'**
  String billingManageCancelFailed(Object error);

  /// No description provided for @authWelcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to LOIT'**
  String get authWelcomeTitle;

  /// No description provided for @authWelcomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Personal & shared finance, calm by design.'**
  String get authWelcomeSubtitle;

  /// No description provided for @authWelcomeContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get authWelcomeContinue;

  /// No description provided for @authWelcomeEmail.
  ///
  /// In en, this message translates to:
  /// **'Sign in with email'**
  String get authWelcomeEmail;

  /// No description provided for @authWelcomeTerms.
  ///
  /// In en, this message translates to:
  /// **'By continuing you agree to our Terms of Service and Privacy Policy.'**
  String get authWelcomeTerms;

  /// No description provided for @authSignInTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get authSignInTitle;

  /// No description provided for @authSignInEmail.
  ///
  /// In en, this message translates to:
  /// **'Email address'**
  String get authSignInEmail;

  /// No description provided for @authSignInEmailPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'you@example.com'**
  String get authSignInEmailPlaceholder;

  /// No description provided for @authSignInContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get authSignInContinue;

  /// No description provided for @authSignInError.
  ///
  /// In en, this message translates to:
  /// **'Sign in failed: {error}'**
  String authSignInError(Object error);

  /// No description provided for @authOtpTitle.
  ///
  /// In en, this message translates to:
  /// **'Verify email'**
  String get authOtpTitle;

  /// No description provided for @authOtpBody.
  ///
  /// In en, this message translates to:
  /// **'Enter the code sent to {email}'**
  String authOtpBody(Object email);

  /// No description provided for @authOtpPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'123456'**
  String get authOtpPlaceholder;

  /// No description provided for @authOtpVerify.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get authOtpVerify;

  /// No description provided for @authOtpResend.
  ///
  /// In en, this message translates to:
  /// **'Resend code'**
  String get authOtpResend;

  /// No description provided for @authOtpResendSent.
  ///
  /// In en, this message translates to:
  /// **'Code resent'**
  String get authOtpResendSent;

  /// No description provided for @authOtpError.
  ///
  /// In en, this message translates to:
  /// **'Verification failed: {error}'**
  String authOtpError(Object error);

  /// No description provided for @authPermissionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Almost there'**
  String get authPermissionsTitle;

  /// No description provided for @authPermissionsBody.
  ///
  /// In en, this message translates to:
  /// **'LOIT needs a few permissions to work.'**
  String get authPermissionsBody;

  /// No description provided for @authPermissionsNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get authPermissionsNotifications;

  /// No description provided for @authPermissionsNotificationsDesc.
  ///
  /// In en, this message translates to:
  /// **'Get alerts for budgets, rooms, and receipts.'**
  String get authPermissionsNotificationsDesc;

  /// No description provided for @authPermissionsCamera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get authPermissionsCamera;

  /// No description provided for @authPermissionsCameraDesc.
  ///
  /// In en, this message translates to:
  /// **'Scan receipts and room invites.'**
  String get authPermissionsCameraDesc;

  /// No description provided for @authPermissionsContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get authPermissionsContinue;

  /// No description provided for @lockScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'LOIT'**
  String get lockScreenTitle;

  /// No description provided for @lockScreenUnlock.
  ///
  /// In en, this message translates to:
  /// **'Unlock'**
  String get lockScreenUnlock;

  /// No description provided for @lockScreenBiometricPrompt.
  ///
  /// In en, this message translates to:
  /// **'Authenticate to unlock LOIT'**
  String get lockScreenBiometricPrompt;

  /// No description provided for @lockScreenFailed.
  ///
  /// In en, this message translates to:
  /// **'Authentication failed'**
  String get lockScreenFailed;

  /// No description provided for @systemUpdateTitle.
  ///
  /// In en, this message translates to:
  /// **'Update required'**
  String get systemUpdateTitle;

  /// No description provided for @systemUpdateBody.
  ///
  /// In en, this message translates to:
  /// **'Please update LOIT to the latest version to continue.'**
  String get systemUpdateBody;

  /// No description provided for @systemUpdateAction.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get systemUpdateAction;

  /// No description provided for @roomArchiveTitle.
  ///
  /// In en, this message translates to:
  /// **'Archive room?'**
  String get roomArchiveTitle;

  /// No description provided for @roomArchiveConfirm.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get roomArchiveConfirm;

  /// No description provided for @roomArchiveRoom.
  ///
  /// In en, this message translates to:
  /// **'Archive room'**
  String get roomArchiveRoom;

  /// No description provided for @roomNewBudget.
  ///
  /// In en, this message translates to:
  /// **'New budget'**
  String get roomNewBudget;

  /// No description provided for @roomNewCategory.
  ///
  /// In en, this message translates to:
  /// **'New category'**
  String get roomNewCategory;

  /// Snackbar confirming category deletion
  ///
  /// In en, this message translates to:
  /// **'Deleted \"{name}\"'**
  String roomDeleteCategory(String name);

  /// Snackbar confirming label/txn deletion
  ///
  /// In en, this message translates to:
  /// **'Deleted \"{label}\"'**
  String roomDeletedLabel(String label);

  /// No description provided for @roomTxNotFound.
  ///
  /// In en, this message translates to:
  /// **'Transaction not in recent feed'**
  String get roomTxNotFound;

  /// Error when room operation fails
  ///
  /// In en, this message translates to:
  /// **'Update failed: {error}'**
  String roomUpdateFailed(String error);

  /// No description provided for @catScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get catScreenTitle;

  /// No description provided for @catScreenPersonalExpense.
  ///
  /// In en, this message translates to:
  /// **'Personal · Expense'**
  String get catScreenPersonalExpense;

  /// No description provided for @catScreenPersonalIncome.
  ///
  /// In en, this message translates to:
  /// **'Personal · Income'**
  String get catScreenPersonalIncome;

  /// No description provided for @catScreenRoom.
  ///
  /// In en, this message translates to:
  /// **'Room'**
  String get catScreenRoom;

  /// Room category group header
  ///
  /// In en, this message translates to:
  /// **'Room · {name}'**
  String catScreenRoomLabel(String name);

  /// No description provided for @catScreenInherited.
  ///
  /// In en, this message translates to:
  /// **'Inherited · read-only'**
  String get catScreenInherited;

  /// No description provided for @catScreenNoCategories.
  ///
  /// In en, this message translates to:
  /// **'No categories yet'**
  String get catScreenNoCategories;

  /// No description provided for @catScreenEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Tap \"Add category\" to create your first one.'**
  String get catScreenEmptyBody;

  /// Delete category confirmation title
  ///
  /// In en, this message translates to:
  /// **'Delete \"{name}\"?'**
  String catScreenDeleteTitle(String name);

  /// No description provided for @catScreenDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'Transactions or budgets with this category key will fall back to \"Other\".'**
  String get catScreenDeleteBody;

  /// No description provided for @catScreenDeleteBodyPermanent.
  ///
  /// In en, this message translates to:
  /// **'Transactions or budgets with this category key will fall back to \"Other\". This cannot be undone.'**
  String get catScreenDeleteBodyPermanent;

  /// No description provided for @catScreenCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get catScreenCancel;

  /// No description provided for @catScreenDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get catScreenDelete;

  /// No description provided for @catFormNewCategory.
  ///
  /// In en, this message translates to:
  /// **'New category'**
  String get catFormNewCategory;

  /// No description provided for @catFormEditCategory.
  ///
  /// In en, this message translates to:
  /// **'Edit category'**
  String get catFormEditCategory;

  /// No description provided for @catFormNewRoomCategory.
  ///
  /// In en, this message translates to:
  /// **'New room category'**
  String get catFormNewRoomCategory;

  /// No description provided for @catFormEditRoomCategory.
  ///
  /// In en, this message translates to:
  /// **'Edit room category'**
  String get catFormEditRoomCategory;

  /// No description provided for @catFormName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get catFormName;

  /// No description provided for @catFormNamePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'e.g. Coffee'**
  String get catFormNamePlaceholder;

  /// No description provided for @catFormType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get catFormType;

  /// No description provided for @catFormExpense.
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get catFormExpense;

  /// No description provided for @catFormIncome.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get catFormIncome;

  /// No description provided for @catFormColor.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get catFormColor;

  /// No description provided for @catFormIcon.
  ///
  /// In en, this message translates to:
  /// **'Icon'**
  String get catFormIcon;

  /// No description provided for @catFormSaveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get catFormSaveChanges;

  /// No description provided for @catFormCreateCategory.
  ///
  /// In en, this message translates to:
  /// **'Create category'**
  String get catFormCreateCategory;

  /// No description provided for @catFormNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Name required'**
  String get catFormNameRequired;

  /// Error when category save fails
  ///
  /// In en, this message translates to:
  /// **'Save failed: {error}'**
  String catFormSaveFailed(String error);

  /// No description provided for @catFormDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get catFormDelete;

  /// Error when category delete fails
  ///
  /// In en, this message translates to:
  /// **'Delete failed: {error}'**
  String catFormDeleteFailed(String error);

  /// No description provided for @notifFeedTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifFeedTitle;

  /// No description provided for @roomInviteLinkCopied.
  ///
  /// In en, this message translates to:
  /// **'Link copied'**
  String get roomInviteLinkCopied;

  /// No description provided for @roomInviteNoToken.
  ///
  /// In en, this message translates to:
  /// **'No invite token'**
  String get roomInviteNoToken;

  /// Error when regenerating invite link
  ///
  /// In en, this message translates to:
  /// **'Failed to regenerate: {error}'**
  String roomInviteRegenFailed(String error);

  /// No description provided for @roomUpgrade.
  ///
  /// In en, this message translates to:
  /// **'Upgrade'**
  String get roomUpgrade;

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
