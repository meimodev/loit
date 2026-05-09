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
  String get scanReceiptTitle => 'Scan receipt';

  @override
  String get scanReceipt => 'RECEIPT';

  @override
  String get scanAlignHint => 'Align receipt within frame';

  @override
  String get scanReadingTitle => 'Reading receipt';

  @override
  String get scanReadingBody => 'Reading your receipt…';

  @override
  String get scanReadingSubtitle =>
      'Usually takes about 2 seconds. We\'re extracting merchant, total, and items.';

  @override
  String get scanPersonal => 'Personal';

  @override
  String get scanRooms => 'Rooms';

  @override
  String get scanRoom => 'Room';

  @override
  String get scanSaved => 'Receipt saved';

  @override
  String get scanNoRooms =>
      'No rooms yet — create one before scanning to a room.';

  @override
  String get scanSendToRoom => 'Send receipt to room';

  @override
  String get scanLimitReached => 'Scan limit reached';

  @override
  String scanUsedAllScans(String quota, String tier) {
    return 'Used all $quota scans on $tier this month.';
  }

  @override
  String get scanQuotaDefault => 'You have used your monthly scan quota.';

  @override
  String get scanTopUp => 'Top up · 10 scans for Rp19,000';

  @override
  String get scanUpgrade => 'Upgrade to Pro — unlimited scans';

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
  String get tierActive => 'ACTIVE';
}
