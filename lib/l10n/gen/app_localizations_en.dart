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
  String get aboutAppName => 'LOIT';

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
  String get dashboardInsights => 'INSIGHTS';

  @override
  String get dashboardSeeReport => 'See report →';

  @override
  String get dashboardSpendingThisMonth => 'Spending this month';

  @override
  String get dashboardAvgPerDay => 'AVG/DAY';

  @override
  String get dashboardMtd => 'MTD';

  @override
  String get dashboardSeePastReports => 'See past reports';

  @override
  String get dashboardIncome => 'Income';

  @override
  String get dashboardExpense => 'Expense';

  @override
  String get dashboardSeeAllCategories => 'See all categories';

  @override
  String get dashboardAddBudget => 'Add budget';

  @override
  String dashboardBudgetsOver(int count, int day, int total) {
    return '$count budgets over. Day $day of $total.';
  }

  @override
  String get dashboardAssets => 'Assets';

  @override
  String get dashboardLiabilities => 'Liabilities';

  @override
  String get dashboardNetWorth => 'Net worth';

  @override
  String get dashboardAccounts => 'Accounts';

  @override
  String get dashboardBudgets => 'Budgets';

  @override
  String get dashboardCategories => 'Categories';

  @override
  String get dashboardQuickStats => 'Quick stats';

  @override
  String dashboardOnTrack(int onTrack, int total) {
    return '$onTrack of $total on track';
  }

  @override
  String get dashboardOverBudget => 'Over budget';

  @override
  String get dashboardSpentMtd => 'Spent MTD';

  @override
  String get dashboardTransactions => 'Transactions';

  @override
  String get dashboardAddFirstAccount =>
      'Add your first account to start tracking balances.';

  @override
  String get dashboardAddAccount => 'Add account';

  @override
  String dashboardOfPattern(String spent, String limit) {
    return '$spent of $limit';
  }

  @override
  String get category_dining => 'Dining';

  @override
  String get category_groceries => 'Groceries';

  @override
  String get category_transport => 'Transport';

  @override
  String get category_shopping => 'Shopping';

  @override
  String get category_entertainment => 'Entertainment';

  @override
  String get category_utilities => 'Utilities';

  @override
  String get category_health => 'Health';

  @override
  String get category_travel => 'Travel';

  @override
  String get category_other => 'Other';

  @override
  String get category_income_salary => 'Salary';

  @override
  String get category_income_bonus => 'Bonus';

  @override
  String get category_income_freelance => 'Freelance';

  @override
  String get category_income_investment => 'Investment';

  @override
  String get category_income_gift => 'Gift';

  @override
  String get category_income_refund => 'Refund';

  @override
  String get category_income_other => 'Other income';

  @override
  String get txFormNewTransaction => 'New transaction';

  @override
  String get txFormEditTransaction => 'Edit transaction';

  @override
  String get txFormManualEntry => 'Manual entry';

  @override
  String get txFormConfirm => 'Confirm';

  @override
  String get txFormCouldntRead => 'Couldn\'t read this receipt';

  @override
  String get txFormPreFilled =>
      'Fields below were pre-filled with what we recovered.';

  @override
  String get txFormAiParsed => 'AI parsed this receipt';

  @override
  String get txFormPleaseReview => 'Please review before saving.';

  @override
  String get txFormItemBreakdown => 'Looks like an item breakdown';

  @override
  String get txFormSwitchToItemsMsg =>
      'Switch to Items mode for a structured list.';

  @override
  String get txFormAmount => 'Amount';

  @override
  String get txFormCurrency => 'Currency';

  @override
  String get txFormFromAccount => 'From account';

  @override
  String get txFormAccount => 'Account';

  @override
  String get txFormToAccount => 'To account';

  @override
  String get txFormIncomeCategory => 'Income category';

  @override
  String get txFormExpenseCategory => 'Expense category';

  @override
  String get txFormDate => 'Date';

  @override
  String get txFormTime => 'Time';

  @override
  String get txFormNotes => 'Notes';

  @override
  String get txFormMerchant => 'Merchant';

  @override
  String get txFormOptional => 'Optional';

  @override
  String get txFormStoreOrPayer => 'Store or payer';

  @override
  String get txFormItemName => 'Item name';

  @override
  String get txFormQty => 'Qty';

  @override
  String get txFormUnitPrice => 'Unit price';

  @override
  String get txFormTotal => 'Total';

  @override
  String get txFormSelectAccount => 'Select account';

  @override
  String get txFormSelectDestination => 'Select destination';

  @override
  String get txFormTabText => 'Text';

  @override
  String get txFormTabItems => 'Items';

  @override
  String get txFormAddItem => 'Add item';

  @override
  String get txFormSwitchToItemsBtn => 'Switch to Items';

  @override
  String get txFormDismiss => 'Dismiss';

  @override
  String get txFormSave => 'Save';

  @override
  String get txFormExpense => 'Expense';

  @override
  String get txFormIncome => 'Income';

  @override
  String get txFormTransfer => 'Transfer';

  @override
  String get txFormRemove => 'Remove';

  @override
  String get txFormValidAmount => 'Enter a valid amount';

  @override
  String get txFormSelectAnAccount => 'Select an account';

  @override
  String get txFormSelectDestAccount => 'Select a destination account';

  @override
  String txFormSaveFailed(String error) {
    return 'Save failed: $error';
  }

  @override
  String get txFormExistingNotes =>
      'Existing notes not recognized — start a fresh breakdown.';

  @override
  String get txFormAddAccountFirst =>
      'Add an account first before saving a transaction.';

  @override
  String txFormOneFxApprox(String currency, String amount, String home) {
    return '1 $currency ≈ $amount $home';
  }

  @override
  String get txDetailTitle => 'Transaction';

  @override
  String get txDetailEdit => 'Edit';

  @override
  String get txDetailNotSynced => 'Not synced';

  @override
  String get txDetailNotSyncedBody =>
      'This transaction hasn\'t synced yet. Edit to save it.';

  @override
  String get txDetailDetails => 'Details';

  @override
  String get txDetailNotes => 'Notes';

  @override
  String get txDetailReceipt => 'Receipt';

  @override
  String get txDetailDate => 'Date';

  @override
  String get txDetailType => 'Type';

  @override
  String get txDetailAccount => 'Account';

  @override
  String get txDetailToAccount => 'To account';

  @override
  String get txDetailCategory => 'Category';

  @override
  String get txDetailCurrency => 'Currency';

  @override
  String get txDetailFxRate => 'FX rate';

  @override
  String get txDetailHomeAmount => 'Home amount';

  @override
  String get txDetailSource => 'Source';

  @override
  String get txDetailAiScanned => 'AI scanned';

  @override
  String get txDetailManualFallback => 'Manual fallback';

  @override
  String get txDetailSourceManual => 'Manual';

  @override
  String get txDetailSourceScanned => 'Scanned';

  @override
  String get txDetailSourceBotImage => 'Bot image';

  @override
  String get txDetailSourceBotChat => 'Bot chat';

  @override
  String get txDetailTotal => 'Total';

  @override
  String get txDetailFallbackTransfer => 'Transfer';

  @override
  String get txDetailDeleteTransaction => 'Delete transaction';

  @override
  String get txDetailDeleteTitle => 'Delete transaction?';

  @override
  String get txDetailDeleteBody => 'This cannot be undone.';

  @override
  String get txDetailCancel => 'Cancel';

  @override
  String get txDetailDelete => 'Delete';

  @override
  String get txDetailNotFound => 'Not found';

  @override
  String get txListSearch => 'Search';

  @override
  String get txListNewTransaction => 'New transaction';

  @override
  String get txListFilterSource => 'Filter source';

  @override
  String get txListNotSynced => 'Not synced';

  @override
  String get txListIncome => 'Income';

  @override
  String get txListExpenses => 'Expenses';

  @override
  String get txListTotal => 'Total';

  @override
  String get txListNoMatches => 'No transactions match this filter';

  @override
  String get txListNoTransactions => 'No transactions yet';

  @override
  String get txListEmptySwitchAll =>
      'Try switching to All to see every transaction this month.';

  @override
  String get txListEmptyAddTransaction =>
      'Add a transaction or scan a receipt to get started.';

  @override
  String get txListEmptyScanReceipt => 'Scan receipt';

  @override
  String get txListShowAll => 'Show all';

  @override
  String txListCategoriesTrending(int count) {
    return '$count categories trending high';
  }

  @override
  String get txListTapBudget => 'Tap a budget to drill down.';

  @override
  String get txListViewBudgets => 'View budgets';

  @override
  String get txListToday => 'Today';

  @override
  String get txListYesterday => 'Yesterday';

  @override
  String txListRoomDeleteSnackbar(String roomName) {
    return 'This transaction belongs to \"$roomName\". Delete it from the room.';
  }

  @override
  String get txListOpenRoom => 'Open room';

  @override
  String get txListDeleted => 'Transaction deleted';

  @override
  String get txListUndo => 'Undo';

  @override
  String txListDeleteFailed(String error) {
    return 'Delete failed: $error';
  }

  @override
  String txListUndoFailed(String error) {
    return 'Undo failed: $error';
  }

  @override
  String get txListDelete => 'Delete';

  @override
  String get txListFilterTransactions => 'Filter transactions';

  @override
  String get txListAll => 'All';

  @override
  String get txListPersonal => 'Personal';

  @override
  String get txListRooms => 'Rooms';

  @override
  String txListFooter(int filtered, int total) {
    return '$filtered of $total total';
  }

  @override
  String get txListRoom => 'Room';

  @override
  String get txSearchPlaceholder => 'Search notes, category…';

  @override
  String get txSearchType => 'Type';

  @override
  String get txSearchDate => 'Date';

  @override
  String get txSearchSource => 'Source';

  @override
  String get txSearchIncome => 'Income';

  @override
  String get txSearchExpense => 'Expense';

  @override
  String get txSearchThisWeek => 'This week';

  @override
  String get txSearchThisMonth => 'This month';

  @override
  String get txSearchThisYear => 'This year';

  @override
  String get txSearchCustom => 'Custom';

  @override
  String get txSearchPersonal => 'Personal';

  @override
  String get txSearchRooms => 'Rooms';

  @override
  String get txSearchNoMatches => 'No matches';

  @override
  String get txSearchNoMatchesBody => 'No transactions match the filters.';

  @override
  String txSearchNoMatchesQuery(String query) {
    return 'Nothing matched \"$query\".';
  }

  @override
  String get txSearchEmptyTitle => 'Search your transactions';

  @override
  String get txSearchEmptyBody =>
      'Type a category, note, or pick a filter above.';

  @override
  String get txSearchRecent => 'Recent';

  @override
  String get txSearchRoom => 'Room';

  @override
  String get quickAddTitle => 'Add expense';

  @override
  String get quickAddAmount => 'AMOUNT';

  @override
  String get quickAddContinue => 'Continue';

  @override
  String quickAddRegionSuffix(Object currency) {
    return '$currency · ID';
  }

  @override
  String get budgetFormNewBudget => 'New budget';

  @override
  String get budgetFormEditBudget => 'Edit budget';

  @override
  String get budgetFormLimit => 'LIMIT';

  @override
  String get budgetFormSetup => 'SETUP';

  @override
  String get budgetFormCategory => 'Category';

  @override
  String get budgetFormPeriod => 'Period';

  @override
  String get budgetFormResetsOn => 'Resets on';

  @override
  String get budgetFormAlerts => 'ALERTS';

  @override
  String get budgetFormAt70 => 'At 70%';

  @override
  String get budgetFormAt100 => 'At 100%';

  @override
  String get budgetFormDailyOverBudget => 'Daily over budget';

  @override
  String get budgetFormPersonalOnlyInfo =>
      'You\'ll see this in Personal only. Room budgets are set in each room.';

  @override
  String get budgetFormCreateBudget => 'Create budget';

  @override
  String get budgetFormSaveChanges => 'Save changes';

  @override
  String get budgetFormInvalidAmount => 'Please enter an amount greater than 0';

  @override
  String get budgetFormMonday => 'Monday';

  @override
  String get budgetFormTuesday => 'Tuesday';

  @override
  String get budgetFormWednesday => 'Wednesday';

  @override
  String get budgetFormThursday => 'Thursday';

  @override
  String get budgetFormFriday => 'Friday';

  @override
  String get budgetFormSaturday => 'Saturday';

  @override
  String get budgetFormSunday => 'Sunday';

  @override
  String get budgetFormJanuary => 'January';

  @override
  String get budgetFormFebruary => 'February';

  @override
  String get budgetFormMarch => 'March';

  @override
  String get budgetFormApril => 'April';

  @override
  String get budgetFormMay => 'May';

  @override
  String get budgetFormJune => 'June';

  @override
  String get budgetFormJuly => 'July';

  @override
  String get budgetFormAugust => 'August';

  @override
  String get budgetFormSeptember => 'September';

  @override
  String get budgetFormOctober => 'October';

  @override
  String get budgetFormNovember => 'November';

  @override
  String get budgetFormDecember => 'December';

  @override
  String get budgetFormLastDay => 'Last day';

  @override
  String budgetFormDay(int d) {
    return 'Day $d';
  }

  @override
  String budgetForm1Month(String month) {
    return '1 $month';
  }

  @override
  String get budgetFormEvery => 'Every';

  @override
  String budgetFormEveryNDays(int n) {
    return 'Every $n days';
  }

  @override
  String get budgetDetailNotFound => 'Budget not found';

  @override
  String budgetDetailDayInCycle(int day, int total) {
    return 'Day $day / $total';
  }

  @override
  String budgetDetailOverBudget(int pct, String overAmt) {
    return '$pct% — $overAmt over';
  }

  @override
  String budgetDetailUsed(int pct) {
    return '$pct% used';
  }

  @override
  String budgetDetailRolloverScheduled(String overAmt, String date) {
    return 'Rollover scheduled — $overAmt will reduce the limit on $date.';
  }

  @override
  String get budgetDetailContributingTop5 => 'CONTRIBUTING · TOP 5';

  @override
  String get budgetDetailDeleteBudget => 'Delete budget';

  @override
  String get budgetDetailDeleteTitle => 'Delete budget?';

  @override
  String budgetDetailDeleteBody(String category) {
    return 'This permanently deletes the $category budget. Transactions are kept. This cannot be undone.';
  }

  @override
  String get budgetDetailCancel => 'Cancel';

  @override
  String get budgetDetailDelete => 'Delete';

  @override
  String budgetDetailDeleteFailed(String error) {
    return 'Delete failed: $error';
  }

  @override
  String get budgetDetailEditLimit => 'Edit limit';

  @override
  String get budgetDetailRollOver => 'Roll over';

  @override
  String budgetDetailRollOverSuccess(String overAmt) {
    return '$overAmt carried into next cycle';
  }

  @override
  String budgetDetailRollOverFailed(String error) {
    return 'Roll over failed: $error';
  }

  @override
  String get budgetsScreenNewBudget => 'New budget';

  @override
  String get budgetsScreenFilter => 'Filter';

  @override
  String get budgetsScreenLimit => 'Limit';

  @override
  String get budgetsScreenSpent => 'Spent';

  @override
  String get budgetsScreenLeft => 'Left';

  @override
  String get budgetsScreenNoBudgets => 'No budgets yet';

  @override
  String get budgetsScreenEmptyBody =>
      'Set a monthly limit per category to track spend at a glance.';

  @override
  String get budgetsScreenCategories => 'Categories';

  @override
  String get budgetsScreenNoLimits => 'No limits set';

  @override
  String budgetsScreenDayOver(int day, int days, int overCount) {
    return 'Day $day · $days — $overCount over';
  }

  @override
  String budgetsScreenOnPace(int day, int days) {
    return 'Day $day · $days — on pace';
  }

  @override
  String budgetsScreenOverPace(int day, int days) {
    return 'Day $day · $days — over pace';
  }

  @override
  String get budgetsScreenMonthly => 'Monthly';

  @override
  String get budgetsScreenWeekly => 'Weekly';

  @override
  String get budgetsScreenCustom => 'Custom';

  @override
  String get accountsScreenTitle => 'Accounts';

  @override
  String get accountsScreenAssets => 'Assets';

  @override
  String get accountsScreenLiabilities => 'Liabilities';

  @override
  String get accountsScreenAddAccount => 'Add account';

  @override
  String get accountsScreenNoAccounts => 'No accounts yet';

  @override
  String get accountsScreenEmptyBody =>
      'Add your cash, bank accounts, and cards to track balances.';

  @override
  String accountsScreenAssetType(String currency) {
    return 'Asset · $currency';
  }

  @override
  String accountsScreenLiabilityType(String currency) {
    return 'Liability · $currency';
  }

  @override
  String get accountFormNewAccount => 'New account';

  @override
  String get accountFormEditAccount => 'Edit account';

  @override
  String get accountFormName => 'Name';

  @override
  String get accountFormNamePlaceholder => 'e.g. BCA Savings';

  @override
  String get accountFormType => 'Type';

  @override
  String get accountFormAsset => 'Asset';

  @override
  String get accountFormLiability => 'Liability';

  @override
  String get accountFormCurrency => 'Currency';

  @override
  String get accountFormCurrentBalance => 'Current balance';

  @override
  String get accountFormOpeningBalance => 'Opening balance';

  @override
  String get accountFormSaveChanges => 'Save changes';

  @override
  String get accountFormCreateAccount => 'Create account';

  @override
  String get accountFormNameRequired => 'Name required';

  @override
  String get accountFormNameAlreadyUsed => 'Name already used';

  @override
  String accountFormSaveFailed(String error) {
    return 'Save failed: $error';
  }

  @override
  String get accountFormBalanceAdjustment => 'Balance adjustment';

  @override
  String get accountFormAddAdjustmentTitle => 'Add adjustment transaction?';

  @override
  String accountFormAddAdjustmentBody(
    String current,
    String target,
    String txLabel,
    String delta,
  ) {
    return 'Balance will change from $current to $target.\n\nA $txLabel transaction of $delta (category \"Adjustment\") will be added to record the change.';
  }

  @override
  String get accountFormAddAdjustment => 'Add adjustment';

  @override
  String get accountFormCancel => 'Cancel';

  @override
  String get accountFormArchive => 'Archive';

  @override
  String get accountFormDelete => 'Delete';

  @override
  String get accountFormArchiveTitle => 'Archive account?';

  @override
  String get accountFormArchiveBody =>
      'The account will be hidden but data is kept.';

  @override
  String get accountFormDeleteTitle => 'Delete account?';

  @override
  String accountFormDeleteBody(String name) {
    return 'This permanently deletes \"$name\". This cannot be undone.';
  }

  @override
  String accountFormDeleteBodyWithTxns(
    String name,
    int affected,
    String plural,
  ) {
    return 'This permanently deletes \"$name\" and $affected transaction$plural that reference it. This cannot be undone.';
  }

  @override
  String accountFormDeleteFailed(String error) {
    return 'Delete failed: $error';
  }

  @override
  String get accountFormLiabilityInfo =>
      'For loans, create a Transfer from this liability account to an asset account.';

  @override
  String get accountFormRecentTransactions => 'Recent transactions';

  @override
  String get scanReceiptTitle => 'Scan document';

  @override
  String get scanReceipt => 'DOCUMENT';

  @override
  String get scanAlignHint => 'Position document within frame';

  @override
  String get scanReadingTitle => 'Reading document';

  @override
  String get scanReadingBody => 'Reading your document…';

  @override
  String get scanReadingSubtitle =>
      'Usually takes about 2 seconds. Extracting merchant, total, account, and items.';

  @override
  String get scanPersonal => 'Personal';

  @override
  String get scanRooms => 'Rooms';

  @override
  String get scanRoom => 'Room';

  @override
  String get scanSaved => 'Saved';

  @override
  String get scanNoRooms =>
      'No rooms yet — create one before scanning to a room.';

  @override
  String get scanSendToRoom => 'Send to room';

  @override
  String get scanLimitReached => 'Scan limit reached';

  @override
  String get scanReviewTitle => 'Review scan';

  @override
  String get scanConfidenceHigh => 'Looks good';

  @override
  String get scanConfidenceLow => 'Some details may need correction';

  @override
  String get scanReconcileMismatch =>
      'Line items don\'t add up to the printed total — using the printed total.';

  @override
  String get scanTotalComputed => 'Total computed from line items.';

  @override
  String get scanFieldAccount => 'Account';

  @override
  String get scanFieldCategory => 'Category';

  @override
  String scanItemsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
    );
    return '$_temp0';
  }

  @override
  String get scanSaveNow => 'Save';

  @override
  String scanAutoConfirmIn(int seconds) {
    return 'Saving in ${seconds}s — tap to save now';
  }

  @override
  String get scanCancelAutoSave => 'Cancel auto-save';

  @override
  String get scanEditDetails => 'Edit details';

  @override
  String get scanSaveFailed => 'Couldn\'t save — try again.';

  @override
  String get scanUnknownMerchant => 'Unknown merchant';

  @override
  String get scanNoAccount => 'No account selected — opening edit form.';

  @override
  String get scanQualityBlurry => 'Looks blurry — hold the camera steady.';

  @override
  String get scanQualityTooDark => 'Too dark — find better light.';

  @override
  String get scanQualityBadAspect =>
      'Crop looks off — recapture the full document.';

  @override
  String get scanRateLimited =>
      'Too many scans in a short time. Try again in a minute.';

  @override
  String get scanProCapReached => 'You\'ve hit your monthly Pro scan limit.';

  @override
  String get scanLiteCapReached => 'You\'ve hit your monthly Lite scan limit.';

  @override
  String get scanSettingsAutoConfirm =>
      'Auto-save high-confidence scans after 3 seconds';

  @override
  String get scanSettingsSection => 'Scanning';

  @override
  String get scanInfoPlanSection => 'Your plan';

  @override
  String get scanInfoUsageSection => 'This month';

  @override
  String get scanInfoTopUpSection => 'Need more?';

  @override
  String get scanInfoPrefsSection => 'Preferences';

  @override
  String scanInfoUsage(int used, int total) {
    return '$used / $total scans used';
  }

  @override
  String get scanInfoUsageUnlimited => 'Unlimited scanning';

  @override
  String scanInfoResetsOn(String date) {
    return 'Resets on $date';
  }

  @override
  String scanInfoTierBenefit(int scans) {
    return '$scans scans per month';
  }

  @override
  String get scanInfoRecentLink => 'Recent scans';

  @override
  String scanInfoTopUpCta(String price) {
    return 'Top up 15 scans · $price';
  }

  @override
  String scanInfoBonusBreakdown(int bonus) {
    return 'Includes +$bonus top-up scans';
  }

  @override
  String get scanInfoTopUpHelper => 'Adds 15 scans to this month\'s allowance';

  @override
  String get scanInfoTopUpSuccess => '15 scans added to this month';

  @override
  String get scanInfoUpgradeCta => 'Change plan';

  @override
  String scanUsedAllScans(String quota, String tier) {
    return 'Used all $quota scans on $tier this month.';
  }

  @override
  String get scanQuotaDefault => 'You have used your monthly scan quota.';

  @override
  String get scanTopUp => 'Top up · 15 scans for Rp9,000';

  @override
  String get scanUpgrade => 'Upgrade to Pro — 150 scans/month';

  @override
  String get scanNotNow => 'Not now';

  @override
  String get scanTakeAnother => 'Take another photo';

  @override
  String get scanRetry => 'Retry';

  @override
  String get scanCancel => 'Cancel';

  @override
  String get scanInviteInvalid => 'Invite is invalid or expired';

  @override
  String scanCouldNotJoinRoom(String error) {
    return 'Could not join room: $error';
  }

  @override
  String get scanJoinRoomTitle => 'Join room?';

  @override
  String get scanJoinRoomBody =>
      'A LOIT room invite QR was detected. Join the room?';

  @override
  String get scanJoinRoom => 'Join room';

  @override
  String get scanJoining => 'Joining…';

  @override
  String get scanNotTransaction => 'That doesn\'t look like a transaction';

  @override
  String get scanNotTransactionBody =>
      'We couldn\'t find a receipt, invoice, transfer slip, payslip, or similar transaction record in this image. Try a clearer photo of the document.';

  @override
  String get scanOfflineTitle => 'You\'re offline';

  @override
  String get scanOfflineBody =>
      'We couldn\'t reach the scan service. Check connection and retry.';

  @override
  String get scanUnavailableTitle => 'Scan service unavailable';

  @override
  String get scanUnavailableBody =>
      'Scan service temporarily unavailable. Try again in a moment.';

  @override
  String get receiptsTitle => 'Receipts';

  @override
  String receiptsFailed(String error) {
    return 'Failed to load: $error';
  }

  @override
  String receiptsDownloadFailed(String error) {
    return 'Download failed: $error';
  }

  @override
  String receiptsShareSubject(String date) {
    return 'Receipt $date';
  }

  @override
  String get receiptsFallback => 'Receipt';

  @override
  String get receiptsActive => 'Active';

  @override
  String get receiptsExpiring => 'Expiring';

  @override
  String get receiptsExpired => 'Expired';

  @override
  String get receiptsNoReceipts => 'No receipts yet';

  @override
  String get receiptsEmptyBody =>
      'Scanned receipts will appear here. Use the scanner to capture one.';

  @override
  String get reportsScreenTitle => 'Reports';

  @override
  String get reportsScreenIncome => 'Income';

  @override
  String get reportsScreenExpenses => 'Expenses';

  @override
  String get reportsScreenNet => 'Net';

  @override
  String get reportsScreenNoData => 'No data for this period';

  @override
  String get reportsScreenCategory => 'Category';

  @override
  String get reportsScreenAmount => 'Amount';

  @override
  String get reportsScreenPercent => '%';

  @override
  String get reportsScreenEmptyBody =>
      'Reports will appear when you have transactions.';

  @override
  String get exportScreenTitle => 'Export data';

  @override
  String get exportScreenFormat => 'Format';

  @override
  String get exportScreenDateRange => 'Date range';

  @override
  String get exportScreenLastMonth => 'Last month';

  @override
  String get exportScreenLast3Months => 'Last 3 months';

  @override
  String get exportScreenLast6Months => 'Last 6 months';

  @override
  String get exportScreenLastYear => 'Last year';

  @override
  String get exportScreenAllTime => 'All time';

  @override
  String get exportScreenExport => 'Export';

  @override
  String get exportScreenExporting => 'Exporting…';

  @override
  String get exportScreenReady => 'Your export is ready.';

  @override
  String exportScreenFailed(String error) {
    return 'Export failed: $error';
  }

  @override
  String get exportScreenAccounts => 'Accounts';

  @override
  String get exportScreenTransactions => 'Transactions';

  @override
  String get exportScreenBudgets => 'Budgets';

  @override
  String get roomsScreenTitle => 'Rooms';

  @override
  String get roomsScreenNoRooms => 'No rooms yet';

  @override
  String get roomsScreenEmptyBody =>
      'Create or join a room to track shared expenses.';

  @override
  String get roomsScreenCreateRoom => 'Create room';

  @override
  String get roomsScreenJoinRoom => 'Join room';

  @override
  String roomsScreenMembers(int n) {
    return '$n members';
  }

  @override
  String get roomCreateTitle => 'Create room';

  @override
  String get roomCreateName => 'Room name';

  @override
  String get roomCreateNamePlaceholder => 'e.g. Flatmates, Trip to Bali';

  @override
  String get roomCreateDescription => 'Description (optional)';

  @override
  String get roomCreateCreate => 'Create';

  @override
  String get roomCreateCreating => 'Creating…';

  @override
  String roomCreateFailed(String error) {
    return 'Failed to create room: $error';
  }

  @override
  String get roomInviteTitle => 'Invite members';

  @override
  String get roomInviteShare => 'Share invite link';

  @override
  String get roomInviteBody => 'Anyone with this link can join the room.';

  @override
  String get roomJoinTitle => 'Join room';

  @override
  String get roomJoinJoining => 'Joining…';

  @override
  String get roomJoinInvalid => 'This invite is invalid or expired.';

  @override
  String roomJoinFailed(String error) {
    return 'Failed to join: $error';
  }

  @override
  String get roomDetailAddTransaction => 'Add transaction';

  @override
  String get roomDetailMembers => 'Members';

  @override
  String get roomDetailBudgets => 'Budgets';

  @override
  String get roomDetailLeave => 'Leave room';

  @override
  String get roomDetailLeaveTitle => 'Leave room?';

  @override
  String get roomDetailLeaveBody =>
      'Your transactions in this room will be kept.';

  @override
  String get roomDetailLeaveConfirm => 'Leave';

  @override
  String get roomDetailDeleteTitle => 'Delete room?';

  @override
  String get roomDetailDeleteBody =>
      'All shared data in this room will be permanently deleted.';

  @override
  String get roomDetailDeleteRoom => 'Delete room';

  @override
  String get roomDetailBudgetTitle => 'Room budget';

  @override
  String get roomDetailNotSynced => 'Not synced';

  @override
  String get roomDetailNotSyncedBody =>
      'This transaction hasn\'t synced yet. Edit to save it.';

  @override
  String get paywallTitle => 'Upgrade to Pro';

  @override
  String get paywallSubtitle =>
      'Unlock unlimited scans, receipts, and budgets.';

  @override
  String get paywallContinue => 'Continue';

  @override
  String get paywallRestoring => 'Restoring…';

  @override
  String get paywallFree => 'Free';

  @override
  String get paywallPro => 'Pro';

  @override
  String get paywallTeam => 'Team';

  @override
  String get pwProSuccessTitle => 'Welcome to Pro!';

  @override
  String get pwProSuccessBody =>
      'You now have unlimited scans and premium features.';

  @override
  String get pwProSuccessDone => 'Done';

  @override
  String get billingManageTitle => 'Manage subscription';

  @override
  String get billingManageCurrentPlan => 'Current plan';

  @override
  String get billingManageCancel => 'Cancel subscription';

  @override
  String get billingManageCancelTitle => 'Cancel subscription?';

  @override
  String get billingManageCancelBody =>
      'You will lose Pro features at the end of your billing period.';

  @override
  String get billingManageCancelConfirm => 'Cancel';

  @override
  String billingManageCancelFailed(Object error) {
    return 'Cancel failed: $error';
  }

  @override
  String get authWelcomeTitle => 'Welcome to LOIT';

  @override
  String get authWelcomeSubtitle =>
      'Personal & shared finance, calm by design.';

  @override
  String get authWelcomeContinue => 'Continue with Google';

  @override
  String get authWelcomeEmail => 'Sign in with email';

  @override
  String get authWelcomeTerms =>
      'By continuing you agree to our Terms of Service and Privacy Policy.';

  @override
  String get authSignInTitle => 'Sign in';

  @override
  String get authSignInEmail => 'Email address';

  @override
  String get authSignInEmailPlaceholder => 'you@example.com';

  @override
  String get authSignInContinue => 'Continue';

  @override
  String authSignInError(Object error) {
    return 'Sign in failed: $error';
  }

  @override
  String get authOtpTitle => 'Verify email';

  @override
  String authOtpBody(Object email) {
    return 'Enter the code sent to $email';
  }

  @override
  String get authOtpPlaceholder => '123456';

  @override
  String get authOtpVerify => 'Verify';

  @override
  String get authOtpResend => 'Resend code';

  @override
  String get authOtpResendSent => 'Code resent';

  @override
  String authOtpError(Object error) {
    return 'Verification failed: $error';
  }

  @override
  String get authPermissionsTitle => 'Almost there';

  @override
  String get authPermissionsBody => 'LOIT needs a few permissions to work.';

  @override
  String get authPermissionsNotifications => 'Notifications';

  @override
  String get authPermissionsNotificationsDesc =>
      'Get alerts for budgets, rooms, and receipts.';

  @override
  String get authPermissionsCamera => 'Camera';

  @override
  String get authPermissionsCameraDesc => 'Scan receipts and room invites.';

  @override
  String get authPermissionsContinue => 'Continue';

  @override
  String get lockScreenTitle => 'LOIT';

  @override
  String get lockScreenUnlock => 'Unlock';

  @override
  String get lockScreenBiometricPrompt => 'Authenticate to unlock LOIT';

  @override
  String get lockScreenFailed => 'Authentication failed';

  @override
  String get systemUpdateTitle => 'Update required';

  @override
  String get systemUpdateBody =>
      'Please update LOIT to the latest version to continue.';

  @override
  String get systemUpdateAction => 'Update';

  @override
  String get roomArchiveTitle => 'Archive room?';

  @override
  String get roomArchiveConfirm => 'Archive';

  @override
  String get roomArchiveRoom => 'Archive room';

  @override
  String get roomNewBudget => 'New budget';

  @override
  String get roomNewCategory => 'New category';

  @override
  String roomDeleteCategory(String name) {
    return 'Deleted \"$name\"';
  }

  @override
  String roomDeletedLabel(String label) {
    return 'Deleted \"$label\"';
  }

  @override
  String get roomTxNotFound => 'Transaction not in recent feed';

  @override
  String roomUpdateFailed(String error) {
    return 'Update failed: $error';
  }

  @override
  String get catScreenTitle => 'Categories';

  @override
  String get catScreenPersonalExpense => 'Personal · Expense';

  @override
  String get catScreenPersonalIncome => 'Personal · Income';

  @override
  String get catScreenRoom => 'Room';

  @override
  String catScreenRoomLabel(String name) {
    return 'Room · $name';
  }

  @override
  String get catScreenInherited => 'Inherited · read-only';

  @override
  String get catScreenNoCategories => 'No categories yet';

  @override
  String get catScreenEmptyBody =>
      'Tap \"Add category\" to create your first one.';

  @override
  String catScreenDeleteTitle(String name) {
    return 'Delete \"$name\"?';
  }

  @override
  String get catScreenDeleteBody =>
      'Transactions or budgets with this category key will fall back to \"Other\".';

  @override
  String get catScreenDeleteBodyPermanent =>
      'Transactions or budgets with this category key will fall back to \"Other\". This cannot be undone.';

  @override
  String get catScreenCancel => 'Cancel';

  @override
  String get catScreenDelete => 'Delete';

  @override
  String get catFormNewCategory => 'New category';

  @override
  String get catFormEditCategory => 'Edit category';

  @override
  String get catFormNewRoomCategory => 'New room category';

  @override
  String get catFormEditRoomCategory => 'Edit room category';

  @override
  String get catFormName => 'Name';

  @override
  String get catFormNamePlaceholder => 'e.g. Coffee';

  @override
  String get catFormType => 'Type';

  @override
  String get catFormExpense => 'Expense';

  @override
  String get catFormIncome => 'Income';

  @override
  String get catFormColor => 'Color';

  @override
  String get catFormIcon => 'Icon';

  @override
  String get catFormSaveChanges => 'Save changes';

  @override
  String get catFormCreateCategory => 'Create category';

  @override
  String get catFormNameRequired => 'Name required';

  @override
  String catFormSaveFailed(String error) {
    return 'Save failed: $error';
  }

  @override
  String get catFormDelete => 'Delete';

  @override
  String catFormDeleteFailed(String error) {
    return 'Delete failed: $error';
  }

  @override
  String get notifFeedTitle => 'Notifications';

  @override
  String get roomInviteLinkCopied => 'Link copied';

  @override
  String get roomInviteNoToken => 'No invite token';

  @override
  String roomInviteRegenFailed(String error) {
    return 'Failed to regenerate: $error';
  }

  @override
  String get roomUpgrade => 'Upgrade';

  @override
  String get roomCopy => 'COPY';

  @override
  String get roomTileUntitled => 'Untitled';

  @override
  String get roomTileArchivedLabel => 'Archived';

  @override
  String get roomTileNoDescription => 'No description set — tap to add one.';

  @override
  String get roomTileYouOwn => 'You own this';

  @override
  String roomTileYourRole(String role) {
    return 'You · $role';
  }

  @override
  String roomTileCreated(String date) {
    return 'Created $date';
  }

  @override
  String get roomOnlineOnlyYou => 'Only you online';

  @override
  String get roomOnlineStatus => 'Online';

  @override
  String roomOnlineYouPlus(int count) {
    return 'You + $count online';
  }

  @override
  String roomOnlineOthers(int count) {
    return '$count online';
  }

  @override
  String get roomMembershipTitle => 'Membership';

  @override
  String roomMembershipUsageUnlimited(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count rooms / ∞',
      one: '1 room / ∞',
    );
    return '$_temp0';
  }

  @override
  String roomMembershipUsageLimited(int count, int limit) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count rooms / $limit',
      one: '1 room / $limit',
    );
    return '$_temp0';
  }

  @override
  String roomMembershipAtLimit(String tier) {
    return 'You\'ve reached the room limit on $tier.';
  }

  @override
  String roomInvitesPending(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pending invites',
      one: '1 pending invite',
    );
    return '$_temp0';
  }

  @override
  String get roomUnknownRoom => 'Unknown room';

  @override
  String get roomDetailRoomFallback => 'Room';

  @override
  String get roomArchiveBody =>
      'Members will retain read-only access. This cannot be undone.';

  @override
  String get roomMemberUnknown => 'Unknown';

  @override
  String get roomMemberRoleFallback => 'member';

  @override
  String get roomReportsTooltip => 'Reports';

  @override
  String get roomInviteTooltip => 'Invite';

  @override
  String get roomDetailFeedTab => 'Feed';

  @override
  String get roomDetailCategoriesTab => 'Categories';

  @override
  String get roomFeedNoActivity => 'No activity';

  @override
  String get roomFeedNoActivityMonth => 'No activity this month';

  @override
  String get roomFeedArchivedEmpty => 'This room is archived';

  @override
  String get roomFeedEmptyBody => 'Try a different month or log a new expense.';

  @override
  String get roomFeedEarlier => 'Earlier';

  @override
  String get roomSummaryExpenses => 'EXPENSES';

  @override
  String get roomSummaryIncome => 'INCOME';

  @override
  String get roomBudgetsNoSet => 'No budgets set';

  @override
  String get roomBudgetsNoSetBody =>
      'Set category caps so the room knows when to slow down.';

  @override
  String get roomBudgetResetsToday => 'resets today';

  @override
  String get roomBudgetResetsTomorrow => 'resets tomorrow';

  @override
  String roomBudgetResetsInDays(int days) {
    return 'resets in ${days}d';
  }

  @override
  String roomBudgetSpent(String amount) {
    return '$amount spent';
  }

  @override
  String get roomCatsEmptyBody =>
      'Add room-specific categories so members tag transactions consistently.';

  @override
  String get roomCatsArchivedNote =>
      'Room is archived. Categories are read-only.';

  @override
  String get roomCatsCreatorOnlyNote =>
      'Only the room creator can add or edit categories.';

  @override
  String get roomSectionExpenseLabel => 'EXPENSE';

  @override
  String get roomSectionIncomeLabel => 'INCOME';

  @override
  String get splashTagline => 'Split bills, not friendships.';

  @override
  String get welcomeSlide1Title => 'Track spending in seconds.';

  @override
  String get welcomeSlide1Body =>
      'Snap a receipt or tap in an amount. We do the math.';

  @override
  String get welcomeSlide2Title => 'Share with friends, privately.';

  @override
  String get welcomeSlide2Body =>
      'Create a room for trips or the apartment. No one sees the rest.';

  @override
  String get welcomeSlide3Title => 'Budgets that make sense.';

  @override
  String get welcomeSlide3Body =>
      'Category limits, gentle alerts, real insight.';

  @override
  String get welcomeNext => 'Next';

  @override
  String get welcomeGetStarted => 'Get started';

  @override
  String get receiptExpiringToday => 'Receipt photos are being deleted today.';

  @override
  String receiptExpiringDays(int days) {
    return 'Receipt photos expire in $days days.';
  }

  @override
  String budgetOverAlert(String category, String pct) {
    return '$category is over budget ($pct%)';
  }

  @override
  String budgetNearAlert(String category, String pct) {
    return '$category is at $pct% of budget';
  }

  @override
  String get permissionsStep => 'Step 2 of 2';

  @override
  String get roomArchived => 'ARCHIVED';

  @override
  String get roomColorIdentity => 'COLOR IDENTITY';

  @override
  String get roomBaseCurrency => 'BASE CURRENCY';

  @override
  String get roomScanToJoin => 'Scan to join';

  @override
  String get roomPasteInvite => 'Paste an invite link or token';

  @override
  String get reportsThisMonth => 'THIS MONTH';

  @override
  String get reportsBeta => 'BETA';

  @override
  String get shellPressBack => 'Press back again to exit';

  @override
  String exportFailed(String error) {
    return 'Export failed: $error';
  }

  @override
  String get tierActive => 'ACTIVE';

  @override
  String get roomsIntroTitle => 'Welcome to Rooms';

  @override
  String get roomsIntroSubtitle =>
      'Track shared spending together. A few ways people use Rooms:';

  @override
  String get roomsIntroUseCase1 =>
      'Shared business budget — track team expenses with co-founders or staff.';

  @override
  String get roomsIntroUseCase2 =>
      'Trip expenses with friends — split a holiday and settle up later.';

  @override
  String get roomsIntroUseCase3 =>
      'Family monthly expense tracking — keep household spending in one place.';

  @override
  String get roomsIntroCta => 'Got it';

  @override
  String get paywallHeroPro => 'You\'re on Pro.\nEverything\nunlocked.';

  @override
  String get paywallHero => 'Smarter scans.\nFairer caps.\nGo Pro.';

  @override
  String get paywallLite => 'Lite';

  @override
  String get paywallPlanYearly => 'Yearly';

  @override
  String get paywallPlanMonthly => 'Monthly';

  @override
  String get paywallFreeFeatures => '5 scans/mo · 3 budgets · 3 months reports';

  @override
  String get paywallLiteAnnualFeatures =>
      'Save 4 months · 30 scans/mo · Unlimited budgets';

  @override
  String get paywallLiteMonthlyFeatures =>
      '30 scans/mo · Unlimited budgets · Cancel anytime';

  @override
  String get paywallProAnnualFeatures =>
      'Save 4 months · 150 scans/mo · Unlimited budgets · Export';

  @override
  String get paywallProMonthlyFeatures =>
      '150 scans/mo · Unlimited budgets · Cancel anytime';

  @override
  String get paywallBestValue => 'BEST VALUE';

  @override
  String get paywallCtaFree => 'Continue on Free';

  @override
  String paywallCtaLiteAnnual(String price) {
    return 'Start Lite · $price/yr';
  }

  @override
  String paywallCtaLiteMonthly(String price) {
    return 'Start Lite · $price/mo';
  }

  @override
  String paywallCtaProAnnual(String price) {
    return 'Start Pro · $price/yr';
  }

  @override
  String paywallCtaProMonthly(String price) {
    return 'Start Pro · $price/mo';
  }

  @override
  String get paywallCtaAllSet => 'You\'re all set';

  @override
  String paywallTierActive(String tier) {
    return 'Your $tier subscription is active.';
  }

  @override
  String get paywallPurchaseCancelled => 'Purchase cancelled.';

  @override
  String get paywallPurchaseFailed => 'Purchase failed.';

  @override
  String paywallPurchaseStartError(String error) {
    return 'Could not start purchase: $error';
  }

  @override
  String get paywallPurchaseComplete => 'Purchase complete. Unlocking…';

  @override
  String get paywallPurchaseRestored => 'Purchase restored.';

  @override
  String get paywallPurchasePending =>
      'Purchase pending. Waiting for confirmation…';

  @override
  String get billingPaidBody => 'All Pro features unlocked.';

  @override
  String get billingFreeBody => 'Limited features. Upgrade for more.';

  @override
  String get billingLiteBody => 'Lite plan active.';

  @override
  String billingNextRenewal(String date) {
    return 'Next renewal · $date';
  }

  @override
  String billingPlanEndsOn(String date) {
    return 'Plan ends on $date';
  }

  @override
  String get billingUpgradeCta => 'Upgrade';

  @override
  String get billingPlanBenefits => 'What you get';

  @override
  String get billingFreeBenefit1 => '5 document scans / month';

  @override
  String get billingFreeBenefit2 => '3 budget categories';

  @override
  String get billingFreeBenefit3 => '1 shared room';

  @override
  String get billingLiteBenefit1 => '30 document scans / month';

  @override
  String get billingLiteBenefit2 => 'Unlimited budgets + custom categories';

  @override
  String get billingLiteBenefit3 => '3 shared rooms';

  @override
  String get billingProBenefit1 => '150 document scans / month';

  @override
  String get billingProBenefit2 =>
      'Unlimited budgets, exports, receipt storage';

  @override
  String get billingProBenefit3 => 'Unlimited rooms + full history';

  @override
  String get billingGroupBilling => 'Billing';

  @override
  String get billingGroupManagePlay => 'Manage in Google Play';

  @override
  String get billingChangePlan => 'Change plan';

  @override
  String get billingPlayFootnote =>
      'Cancellations and plan changes are handled by Google Play. Your current period stays active until renewal.';

  @override
  String get quickActionsGroup => 'Quick actions';

  @override
  String get quickActionsSettingsLabel => 'Show quick actions notification';

  @override
  String get quickActionsSettingsDescription =>
      'Keeps today\'s spending and four shortcuts (Scan, Add, Transactions, Rooms) in your notification tray. Some devices may hide ongoing notifications due to battery optimization.';

  @override
  String get quickActionsChannelName => 'Quick actions';

  @override
  String get quickActionsChannelDescription =>
      'Ongoing quick-actions notification with today\'s spending.';

  @override
  String get quickActionsNotificationTitle => 'LOIT';

  @override
  String quickActionsBodyTodayExpense(String amount) {
    return 'Today: $amount';
  }

  @override
  String get quickActionsBodyLauncher => 'Tap to access shortcuts';

  @override
  String get quickActionsBodyHidden => 'Today: ••••';

  @override
  String get quickActionsScan => 'Scan';

  @override
  String get quickActionsAdd => 'Add';

  @override
  String get quickActionsViewTransactions => 'Transactions';

  @override
  String get quickActionsViewRooms => 'Rooms';

  @override
  String get quickActionsPermissionPromptTitle => 'Enable notifications';

  @override
  String get quickActionsPermissionPromptBody =>
      'Turn on notifications to get the quick-actions tray and room alerts.';

  @override
  String get quickActionsOpenSettings => 'Open settings';

  @override
  String get cancel => 'Cancel';

  @override
  String get settingsConnections => 'Connections';

  @override
  String get settingsTelegram => 'Telegram';

  @override
  String get settingsTelegramConnected => 'Connected';

  @override
  String get settingsTelegramNotConnected => 'Not connected';

  @override
  String get telegramTitle => 'Telegram';

  @override
  String get telegramIntro =>
      'Connect Telegram to log transactions by sending text, voice notes, or receipt photos to LoitAppBot.';

  @override
  String get telegramConnect => 'Connect Telegram';

  @override
  String get telegramConnecting => 'Connecting…';

  @override
  String get telegramDisconnect => 'Disconnect Telegram';

  @override
  String get telegramDisclosureLabel => 'Privacy notice';

  @override
  String get telegramDisclosureBody =>
      'Before you connect, please read:\n\n• Messages you send to LoitAppBot are stored by Telegram on their servers under Telegram\'s terms — LOIT cannot control or delete that chat history.\n• Message contents (text, photos, voice notes) are processed by Anthropic Claude (and OpenAI Whisper for voice) to create transactions on your behalf.\n• Your Telegram chat ID is stored by LOIT so we can identify you when you message the bot. You can disconnect at any time from Settings.\n• Please do not send account numbers, passwords, ID/KTP numbers, card details, or other sensitive personal data through Telegram.\n• Hide Amounts hides values inside the LOIT app only — it does NOT redact amounts in your Telegram chat history with the bot.\n\nBy connecting, you accept these conditions in line with Indonesia\'s Personal Data Protection Law (UU PDP).';

  @override
  String get telegramDisclosureAccept => 'I understand and want to connect.';

  @override
  String get telegramConnectedSectionLabel => 'Connected account';

  @override
  String get telegramConnectedChat => 'Chat ID';

  @override
  String get telegramDisconnectTitle => 'Disconnect Telegram?';

  @override
  String get telegramDisconnectBody =>
      'Your Telegram chat will no longer log transactions. Past transactions stay.';

  @override
  String get telegramDisconnectConfirm => 'Disconnect';

  @override
  String get telegramOpenFailed => 'Couldn\'t open Telegram.';

  @override
  String get telegramGenerateFailed =>
      'Couldn\'t generate link code. Try again.';
}
