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

  @override
  String get fxRateStale => 'Kurs mungkin sudah tidak terbaru';

  @override
  String fxConvertedFrom(String amount, String currency) {
    return '≈ $amount $currency';
  }

  @override
  String get aboutTitle => 'Tentang';

  @override
  String get aboutTagline =>
      'Keuangan pribadi & bersama, tenang secara desain.';

  @override
  String get aboutHelp => 'Bantuan';

  @override
  String get aboutLegal => 'Hukum';

  @override
  String get aboutBuild => 'Versi';

  @override
  String get aboutHelpCenter => 'Pusat bantuan';

  @override
  String get aboutContactSupport => 'Hubungi dukungan';

  @override
  String get aboutSendFeedback => 'Kirim masukan';

  @override
  String get aboutTermsOfService => 'Ketentuan layanan';

  @override
  String get aboutPrivacyPolicy => 'Kebijakan privasi';

  @override
  String get aboutOpenSourceLicenses => 'Lisensi sumber terbuka';

  @override
  String get notifTitle => 'Notifikasi';

  @override
  String get notifBudgets => 'Anggaran';

  @override
  String get notifRooms => 'Ruangan';

  @override
  String get notifReceipts => 'Struk';

  @override
  String get notifDigestsNews => 'Ringkasan & berita';

  @override
  String get notifApproachingLimit => 'Mendekati batas';

  @override
  String get notifApproachingLimitHelper =>
      'Saat Anda mencapai 80% dari anggaran.';

  @override
  String get notifWeeklyDigest => 'Ringkasan mingguan';

  @override
  String get notifWeeklyDigestHelper =>
      'Ringkasan progres anggaran minggu lalu.';

  @override
  String get notifNewTransactions => 'Transaksi baru';

  @override
  String get notifMentionsInvites => 'Sebutan & undangan';

  @override
  String get notifExpiryReminders => 'Pengingat kedaluwarsa';

  @override
  String get notifExpiryRemindersHelper =>
      'Tingkat gratis · struk otomatis terhapus setelah 90 hari.';

  @override
  String get notifMonthlySummary => 'Ringkasan bulanan';

  @override
  String get notifProductUpdates => 'Pembaruan produk';

  @override
  String get notifSystemFooter =>
      'Izin push sistem dikelola di pengaturan perangkat Anda.';

  @override
  String get prefsTitle => 'Preferensi';

  @override
  String get prefsLanguage => 'Bahasa';

  @override
  String get prefsAppLanguage => 'Bahasa aplikasi';

  @override
  String get prefsCurrency => 'Mata uang';

  @override
  String get prefsHomeCurrency => 'Mata uang utama';

  @override
  String get prefsRegion => 'Wilayah';

  @override
  String get prefsCountry => 'Negara';

  @override
  String get prefsCategory => 'Kategori';

  @override
  String get prefsManageCategories => 'Kelola kategori';

  @override
  String get prefsCustomize => 'Sesuaikan';

  @override
  String get prefsAppearance => 'Tampilan';

  @override
  String get prefsTheme => 'Tema';

  @override
  String get prefsThemeSystem => 'Sistem';

  @override
  String get prefsThemeLight => 'Terang';

  @override
  String get prefsThemeDark => 'Gelap';

  @override
  String get prefsSyncFooter =>
      'Preferensi tema + bahasa akan disinkronkan antar perangkat di rilis mendatang.';

  @override
  String get profileTitle => 'Profil';

  @override
  String get profileName => 'Nama';

  @override
  String get profileEmail => 'Email';

  @override
  String get profilePhone => 'Telepon';

  @override
  String get profileEmailHelper =>
      'Email dikelola oleh penyedia autentikasi Anda.';

  @override
  String get profileNotifications => 'NOTIFIKASI';

  @override
  String get profileBudgetAlerts => 'Peringatan anggaran';

  @override
  String get profileRoomActivity => 'Aktivitas ruangan';

  @override
  String get profileSaveChanges => 'Simpan perubahan';

  @override
  String get profileSaved => 'Profil disimpan';

  @override
  String profileSaveFailed(String error) {
    return 'Gagal menyimpan: $error';
  }

  @override
  String get securityTitle => 'Keamanan';

  @override
  String get securityLock => 'Kunci';

  @override
  String get securityPrivacy => 'Privasi';

  @override
  String get securityBiometricUnlock => 'Buka kunci biometrik';

  @override
  String get securityBiometricHelper =>
      'Kunci LOIT dengan Wajah / sidik jari setelah 15 detik di latar';

  @override
  String get securityBiometricNotAvailable => 'Tidak tersedia di perangkat ini';

  @override
  String get securityHideAmounts => 'Sembunyikan jumlah di layar kunci';

  @override
  String get securityHideAmountsHelper =>
      'Ganti jumlah dengan •••• di notifikasi.';

  @override
  String securityBiometricSetupFailed(String error) {
    return 'Penyiapan biometrik gagal: $error';
  }

  @override
  String get securitySessionFooter =>
      'Sesi dikelola oleh penyedia autentikasi Anda. Keluar dari Pengaturan untuk mencabut akses di perangkat ini.';

  @override
  String get securityBiometricReason => 'Aktifkan kunci biometrik untuk LOIT';

  @override
  String get settingsTitle => 'Pengaturan';

  @override
  String get settingsGeneral => 'Umum';

  @override
  String get settingsMoney => 'Keuangan';

  @override
  String get settingsSubscription => 'Langganan';

  @override
  String get settingsPrivacyData => 'Privasi & data';

  @override
  String get settingsAbout => 'Tentang';

  @override
  String get settingsDebug => 'Debug';

  @override
  String get settingsLanguage => 'Bahasa';

  @override
  String get settingsCurrency => 'Mata uang';

  @override
  String get settingsTheme => 'Tema';

  @override
  String get settingsCategories => 'Kategori';

  @override
  String get settingsCustomize => 'Sesuaikan';

  @override
  String get settingsAccounts => 'Akun';

  @override
  String get settingsBudgets => 'Anggaran';

  @override
  String settingsBudgetsActive(int count) {
    return '$count aktif';
  }

  @override
  String get settingsScansThisMonth => 'Pemindaian bulan ini';

  @override
  String get settingsUnlimited => 'Tanpa batas';

  @override
  String get settingsPlan => 'Paket';

  @override
  String get settingsReceipts => 'Struk';

  @override
  String get settingsSecurity => 'Keamanan';

  @override
  String get settingsNotifications => 'Notifikasi';

  @override
  String get settingsExportData => 'Ekspor data';

  @override
  String get settingsCsvPdf => 'CSV / PDF';

  @override
  String get settingsDeleteAccount => 'Hapus akun';

  @override
  String get settingsHelpSupport => 'Bantuan & dukungan';

  @override
  String get settingsTermsPrivacy => 'Ketentuan & privasi';

  @override
  String get settingsVersion => 'Versi';

  @override
  String get settingsSignOut => 'Keluar';

  @override
  String get settingsHomeCurrency => 'Mata uang utama';

  @override
  String get settingsDeleteAccountTitle => 'Hapus akun?';

  @override
  String get settingsDeleteAccountMessage =>
      'Semua data Anda akan dihapus secara permanen. Ini tidak dapat dibatalkan.';

  @override
  String get settingsCancel => 'Batal';

  @override
  String get settingsDelete => 'Hapus';

  @override
  String get settingsDeleteAccountSnackbar =>
      'Penghapusan akun memerlukan email ke dukungan.';

  @override
  String get debugSimulateOffline => 'Simulasikan offline';

  @override
  String get debugSimulateOfflineHelper =>
      'Tampilkan spanduk offline untuk pengujian';

  @override
  String get dashboardInsights => 'WAWASAN';

  @override
  String get dashboardSeeReport => 'Lihat laporan →';

  @override
  String get dashboardSpendingThisMonth => 'Pengeluaran bulan ini';

  @override
  String get dashboardAvgPerDay => 'RATA/HARI';

  @override
  String get dashboardMtd => 'MTD';

  @override
  String get dashboardSeePastReports => 'Lihat laporan sebelumnya';

  @override
  String get dashboardIncome => 'Pemasukan';

  @override
  String get dashboardExpense => 'Pengeluaran';

  @override
  String get dashboardSeeAllCategories => 'Lihat semua kategori';

  @override
  String get dashboardAddBudget => 'Tambah anggaran';

  @override
  String dashboardBudgetsOver(int count, int day, int total) {
    return '$count anggaran melebihi. Hari ke-$day dari $total.';
  }

  @override
  String get dashboardAssets => 'Aset';

  @override
  String get dashboardLiabilities => 'Liabilitas';

  @override
  String get dashboardNetWorth => 'Kekayaan bersih';

  @override
  String get dashboardAccounts => 'Akun';

  @override
  String get dashboardBudgets => 'Anggaran';

  @override
  String get dashboardCategories => 'Kategori';

  @override
  String get dashboardQuickStats => 'Statistik cepat';

  @override
  String dashboardOnTrack(int onTrack, int total) {
    return '$onTrack dari $total sesuai jalur';
  }

  @override
  String get dashboardOverBudget => 'Melebihi anggaran';

  @override
  String get dashboardSpentMtd => 'Dibelanjakan MTD';

  @override
  String get dashboardTransactions => 'Transaksi';

  @override
  String get dashboardAddFirstAccount =>
      'Tambahkan akun pertama Anda untuk mulai melacak saldo.';

  @override
  String get dashboardAddAccount => 'Tambah akun';

  @override
  String dashboardOfPattern(String spent, String limit) {
    return '$spent dari $limit';
  }

  @override
  String get category_dining => 'Makanan';

  @override
  String get category_groceries => 'Belanja';

  @override
  String get category_transport => 'Transportasi';

  @override
  String get category_shopping => 'Belanja';

  @override
  String get category_entertainment => 'Hiburan';

  @override
  String get category_utilities => 'Utilitas';

  @override
  String get category_health => 'Kesehatan';

  @override
  String get category_travel => 'Perjalanan';

  @override
  String get category_other => 'Lainnya';

  @override
  String get category_income_salary => 'Gaji';

  @override
  String get category_income_bonus => 'Bonus';

  @override
  String get category_income_freelance => 'Freelance';

  @override
  String get category_income_investment => 'Investasi';

  @override
  String get category_income_gift => 'Hadiah';

  @override
  String get category_income_refund => 'Pengembalian';

  @override
  String get category_income_other => 'Pemasukan lain';

  @override
  String get txFormNewTransaction => 'Transaksi baru';

  @override
  String get txFormEditTransaction => 'Edit transaksi';

  @override
  String get txFormManualEntry => 'Entri manual';

  @override
  String get txFormConfirm => 'Konfirmasi';

  @override
  String get txFormCouldntRead => 'Tidak dapat membaca struk ini';

  @override
  String get txFormPreFilled =>
      'Kolom di bawah telah diisi dengan data yang dapat dipulihkan.';

  @override
  String get txFormAiParsed => 'AI membaca struk ini';

  @override
  String get txFormPleaseReview => 'Silakan periksa sebelum menyimpan.';

  @override
  String get txFormItemBreakdown => 'Tampaknya rincian item';

  @override
  String get txFormSwitchToItemsMsg =>
      'Beralih ke mode Item untuk daftar terstruktur.';

  @override
  String get txFormAmount => 'Jumlah';

  @override
  String get txFormCurrency => 'Mata uang';

  @override
  String get txFormFromAccount => 'Dari akun';

  @override
  String get txFormAccount => 'Akun';

  @override
  String get txFormToAccount => 'Ke akun';

  @override
  String get txFormIncomeCategory => 'Kategori pemasukan';

  @override
  String get txFormExpenseCategory => 'Kategori pengeluaran';

  @override
  String get txFormDate => 'Tanggal';

  @override
  String get txFormTime => 'Waktu';

  @override
  String get txFormNotes => 'Catatan';

  @override
  String get txFormMerchant => 'Toko';

  @override
  String get txFormOptional => 'Opsional';

  @override
  String get txFormStoreOrPayer => 'Toko atau pembayar';

  @override
  String get txFormItemName => 'Nama item';

  @override
  String get txFormQty => 'Jml';

  @override
  String get txFormUnitPrice => 'Harga satuan';

  @override
  String get txFormTotal => 'Total';

  @override
  String get txFormSelectAccount => 'Pilih akun';

  @override
  String get txFormSelectDestination => 'Pilih tujuan';

  @override
  String get txFormTabText => 'Teks';

  @override
  String get txFormTabItems => 'Item';

  @override
  String get txFormAddItem => 'Tambah item';

  @override
  String get txFormSwitchToItemsBtn => 'Beralih ke Item';

  @override
  String get txFormDismiss => 'Tutup';

  @override
  String get txFormSave => 'Simpan';

  @override
  String get txFormExpense => 'Pengeluaran';

  @override
  String get txFormIncome => 'Pemasukan';

  @override
  String get txFormTransfer => 'Transfer';

  @override
  String get txFormRemove => 'Hapus';

  @override
  String get txFormValidAmount => 'Masukkan jumlah yang valid';

  @override
  String get txFormSelectAnAccount => 'Pilih akun';

  @override
  String get txFormSelectDestAccount => 'Pilih akun tujuan';

  @override
  String txFormSaveFailed(String error) {
    return 'Gagal menyimpan: $error';
  }

  @override
  String get txFormExistingNotes =>
      'Catatan yang ada tidak dikenali — mulai rincian baru.';

  @override
  String get txFormAddAccountFirst =>
      'Tambahkan akun terlebih dahulu sebelum menyimpan transaksi.';

  @override
  String txFormOneFxApprox(String currency, String amount, String home) {
    return '1 $currency ≈ $amount $home';
  }

  @override
  String get txDetailTitle => 'Transaksi';

  @override
  String get txDetailEdit => 'Edit';

  @override
  String get txDetailNotSynced => 'Belum disinkronkan';

  @override
  String get txDetailNotSyncedBody =>
      'Transaksi ini belum disinkronkan. Edit untuk menyimpan.';

  @override
  String get txDetailDetails => 'Detail';

  @override
  String get txDetailNotes => 'Catatan';

  @override
  String get txDetailReceipt => 'Struk';

  @override
  String get txDetailDate => 'Tanggal';

  @override
  String get txDetailType => 'Tipe';

  @override
  String get txDetailAccount => 'Akun';

  @override
  String get txDetailToAccount => 'Ke akun';

  @override
  String get txDetailCategory => 'Kategori';

  @override
  String get txDetailCurrency => 'Mata uang';

  @override
  String get txDetailFxRate => 'Kurs FX';

  @override
  String get txDetailHomeAmount => 'Jumlah utama';

  @override
  String get txDetailSource => 'Sumber';

  @override
  String get txDetailAiScanned => 'Dipindai AI';

  @override
  String get txDetailManualFallback => 'Manual';

  @override
  String get txDetailTotal => 'Total';

  @override
  String get txDetailFallbackTransfer => 'Transfer';

  @override
  String get txDetailDeleteTransaction => 'Hapus transaksi';

  @override
  String get txDetailDeleteTitle => 'Hapus transaksi?';

  @override
  String get txDetailDeleteBody => 'Ini tidak dapat dibatalkan.';

  @override
  String get txDetailCancel => 'Batal';

  @override
  String get txDetailDelete => 'Hapus';

  @override
  String get txDetailNotFound => 'Tidak ditemukan';

  @override
  String get txListSearch => 'Cari';

  @override
  String get txListNewTransaction => 'Transaksi baru';

  @override
  String get txListFilterSource => 'Filter sumber';

  @override
  String get txListNotSynced => 'Belum disinkronkan';

  @override
  String get txListIncome => 'Pemasukan';

  @override
  String get txListExpenses => 'Pengeluaran';

  @override
  String get txListTotal => 'Total';

  @override
  String get txListNoMatches =>
      'Tidak ada transaksi yang cocok dengan filter ini';

  @override
  String get txListNoTransactions => 'Belum ada transaksi';

  @override
  String get txListEmptySwitchAll =>
      'Coba alihkan ke Semua untuk melihat semua transaksi bulan ini.';

  @override
  String get txListEmptyAddTransaction =>
      'Tambahkan transaksi atau pindai struk untuk memulai.';

  @override
  String get txListEmptyScanReceipt => 'Pindai struk';

  @override
  String get txListShowAll => 'Tampilkan semua';

  @override
  String txListCategoriesTrending(int count) {
    return '$count kategori meningkat';
  }

  @override
  String get txListTapBudget => 'Ketuk anggaran untuk melihat detail.';

  @override
  String get txListViewBudgets => 'Lihat anggaran';

  @override
  String get txListToday => 'Hari ini';

  @override
  String get txListYesterday => 'Kemarin';

  @override
  String txListRoomDeleteSnackbar(String roomName) {
    return 'Transaksi ini milik \"$roomName\". Hapus dari ruangan.';
  }

  @override
  String get txListOpenRoom => 'Buka ruangan';

  @override
  String get txListDeleted => 'Transaksi dihapus';

  @override
  String get txListUndo => 'Batalkan';

  @override
  String txListDeleteFailed(String error) {
    return 'Gagal menghapus: $error';
  }

  @override
  String txListUndoFailed(String error) {
    return 'Gagal membatalkan: $error';
  }

  @override
  String get txListDelete => 'Hapus';

  @override
  String get txListFilterTransactions => 'Filter transaksi';

  @override
  String get txListAll => 'Semua';

  @override
  String get txListPersonal => 'Pribadi';

  @override
  String get txListRooms => 'Ruangan';

  @override
  String txListFooter(int filtered, int total) {
    return '$filtered dari $total total';
  }

  @override
  String get txListRoom => 'Ruangan';

  @override
  String get txSearchPlaceholder => 'Cari catatan, kategori…';

  @override
  String get txSearchType => 'Tipe';

  @override
  String get txSearchDate => 'Tanggal';

  @override
  String get txSearchSource => 'Sumber';

  @override
  String get txSearchIncome => 'Pemasukan';

  @override
  String get txSearchExpense => 'Pengeluaran';

  @override
  String get txSearchThisWeek => 'Minggu ini';

  @override
  String get txSearchThisMonth => 'Bulan ini';

  @override
  String get txSearchThisYear => 'Tahun ini';

  @override
  String get txSearchCustom => 'Kustom';

  @override
  String get txSearchPersonal => 'Pribadi';

  @override
  String get txSearchRooms => 'Ruangan';

  @override
  String get txSearchNoMatches => 'Tidak cocok';

  @override
  String get txSearchNoMatchesBody =>
      'Tidak ada transaksi yang cocok dengan filter.';

  @override
  String txSearchNoMatchesQuery(String query) {
    return 'Tidak ada yang cocok dengan \"$query\".';
  }

  @override
  String get txSearchEmptyTitle => 'Cari transaksi Anda';

  @override
  String get txSearchEmptyBody =>
      'Ketik kategori, catatan, atau pilih filter di atas.';

  @override
  String get txSearchRecent => 'Terbaru';

  @override
  String get txSearchRoom => 'Ruangan';

  @override
  String get quickAddTitle => 'Tambah pengeluaran';

  @override
  String get quickAddAmount => 'JUMLAH';

  @override
  String get quickAddContinue => 'Lanjutkan';

  @override
  String quickAddRegionSuffix(Object currency) {
    return '$currency · ID';
  }

  @override
  String get budgetFormNewBudget => 'Anggaran baru';

  @override
  String get budgetFormEditBudget => 'Edit anggaran';

  @override
  String get budgetFormLimit => 'BATAS';

  @override
  String get budgetFormSetup => 'PENGATURAN';

  @override
  String get budgetFormCategory => 'Kategori';

  @override
  String get budgetFormPeriod => 'Periode';

  @override
  String get budgetFormResetsOn => 'Diatur ulang pada';

  @override
  String get budgetFormAlerts => 'PERINGATAN';

  @override
  String get budgetFormAt70 => 'Pada 70%';

  @override
  String get budgetFormAt100 => 'Pada 100%';

  @override
  String get budgetFormDailyOverBudget => 'Harian melebihi';

  @override
  String get budgetFormPersonalOnlyInfo =>
      'Ini hanya terlihat di Pribadi. Anggaran ruangan diatur di masing-masing ruangan.';

  @override
  String get budgetFormCreateBudget => 'Buat anggaran';

  @override
  String get budgetFormSaveChanges => 'Simpan perubahan';

  @override
  String get budgetFormInvalidAmount => 'Masukkan jumlah lebih dari 0';

  @override
  String get budgetFormMonday => 'Senin';

  @override
  String get budgetFormTuesday => 'Selasa';

  @override
  String get budgetFormWednesday => 'Rabu';

  @override
  String get budgetFormThursday => 'Kamis';

  @override
  String get budgetFormFriday => 'Jumat';

  @override
  String get budgetFormSaturday => 'Sabtu';

  @override
  String get budgetFormSunday => 'Minggu';

  @override
  String get budgetFormJanuary => 'Januari';

  @override
  String get budgetFormFebruary => 'Februari';

  @override
  String get budgetFormMarch => 'Maret';

  @override
  String get budgetFormApril => 'April';

  @override
  String get budgetFormMay => 'Mei';

  @override
  String get budgetFormJune => 'Juni';

  @override
  String get budgetFormJuly => 'Juli';

  @override
  String get budgetFormAugust => 'Agustus';

  @override
  String get budgetFormSeptember => 'September';

  @override
  String get budgetFormOctober => 'Oktober';

  @override
  String get budgetFormNovember => 'November';

  @override
  String get budgetFormDecember => 'Desember';

  @override
  String get budgetFormLastDay => 'Hari terakhir';

  @override
  String budgetFormDay(int d) {
    return 'Hari ke-$d';
  }

  @override
  String budgetForm1Month(String month) {
    return '1 $month';
  }

  @override
  String get budgetFormEvery => 'Setiap';

  @override
  String budgetFormEveryNDays(int n) {
    return 'Setiap $n hari';
  }

  @override
  String get budgetDetailNotFound => 'Anggaran tidak ditemukan';

  @override
  String budgetDetailDayInCycle(int day, int total) {
    return 'Hari ke-$day / $total';
  }

  @override
  String budgetDetailOverBudget(int pct, String overAmt) {
    return '$pct% — $overAmt melebihi';
  }

  @override
  String budgetDetailUsed(int pct) {
    return '$pct% digunakan';
  }

  @override
  String budgetDetailRolloverScheduled(String overAmt, String date) {
    return 'Rollover dijadwalkan — $overAmt akan mengurangi batas pada $date.';
  }

  @override
  String get budgetDetailContributingTop5 => 'KONTRIBUSI · 5 TERATAS';

  @override
  String get budgetDetailDeleteBudget => 'Hapus anggaran';

  @override
  String get budgetDetailDeleteTitle => 'Hapus anggaran?';

  @override
  String budgetDetailDeleteBody(String category) {
    return 'Ini menghapus permanen anggaran $category. Transaksi tetap ada. Ini tidak dapat dibatalkan.';
  }

  @override
  String get budgetDetailCancel => 'Batal';

  @override
  String get budgetDetailDelete => 'Hapus';

  @override
  String budgetDetailDeleteFailed(String error) {
    return 'Gagal menghapus: $error';
  }

  @override
  String get budgetDetailEditLimit => 'Edit batas';

  @override
  String get budgetDetailRollOver => 'Roll over';

  @override
  String budgetDetailRollOverSuccess(String overAmt) {
    return '$overAmt dibawa ke siklus berikutnya';
  }

  @override
  String budgetDetailRollOverFailed(String error) {
    return 'Gagal roll over: $error';
  }

  @override
  String get budgetsScreenNewBudget => 'Anggaran baru';

  @override
  String get budgetsScreenFilter => 'Filter';

  @override
  String get budgetsScreenLimit => 'Batas';

  @override
  String get budgetsScreenSpent => 'Dibelanjakan';

  @override
  String get budgetsScreenLeft => 'Tersisa';

  @override
  String get budgetsScreenNoBudgets => 'Belum ada anggaran';

  @override
  String get budgetsScreenEmptyBody =>
      'Tetapkan batas bulanan per kategori untuk melacak pengeluaran sekilas.';

  @override
  String get budgetsScreenCategories => 'Kategori';

  @override
  String get budgetsScreenNoLimits => 'Belum ada batas';

  @override
  String budgetsScreenDayOver(int day, int days, int overCount) {
    return 'Hari ke-$day · $days — $overCount melebihi';
  }

  @override
  String budgetsScreenOnPace(int day, int days) {
    return 'Hari ke-$day · $days — sesuai';
  }

  @override
  String budgetsScreenOverPace(int day, int days) {
    return 'Hari ke-$day · $days — melebihi laju';
  }

  @override
  String get budgetsScreenMonthly => 'Bulanan';

  @override
  String get budgetsScreenWeekly => 'Mingguan';

  @override
  String get budgetsScreenCustom => 'Kustom';

  @override
  String get accountsScreenTitle => 'Akun';

  @override
  String get accountsScreenAssets => 'Aset';

  @override
  String get accountsScreenLiabilities => 'Liabilitas';

  @override
  String get accountsScreenAddAccount => 'Tambah akun';

  @override
  String get accountsScreenNoAccounts => 'Belum ada akun';

  @override
  String get accountsScreenEmptyBody =>
      'Tambahkan uang tunai, rekening bank, dan kartu untuk melacak saldo.';

  @override
  String accountsScreenAssetType(String currency) {
    return 'Aset · $currency';
  }

  @override
  String accountsScreenLiabilityType(String currency) {
    return 'Liabilitas · $currency';
  }

  @override
  String get accountFormNewAccount => 'Akun baru';

  @override
  String get accountFormEditAccount => 'Edit akun';

  @override
  String get accountFormName => 'Nama';

  @override
  String get accountFormNamePlaceholder => 'mis. BCA Tabungan';

  @override
  String get accountFormType => 'Tipe';

  @override
  String get accountFormAsset => 'Aset';

  @override
  String get accountFormLiability => 'Liabilitas';

  @override
  String get accountFormCurrency => 'Mata uang';

  @override
  String get accountFormCurrentBalance => 'Saldo saat ini';

  @override
  String get accountFormOpeningBalance => 'Saldo awal';

  @override
  String get accountFormSaveChanges => 'Simpan perubahan';

  @override
  String get accountFormCreateAccount => 'Buat akun';

  @override
  String get accountFormNameRequired => 'Nama diperlukan';

  @override
  String get accountFormNameAlreadyUsed => 'Nama sudah digunakan';

  @override
  String accountFormSaveFailed(String error) {
    return 'Gagal menyimpan: $error';
  }

  @override
  String get accountFormBalanceAdjustment => 'Penyesuaian saldo';

  @override
  String get accountFormAddAdjustmentTitle => 'Tambah transaksi penyesuaian?';

  @override
  String accountFormAddAdjustmentBody(
    String current,
    String target,
    String txLabel,
    String delta,
  ) {
    return 'Saldo akan berubah dari $current menjadi $target.\n\nTransaksi $txLabel sebesar $delta (kategori \"Penyesuaian\") akan ditambahkan untuk mencatat perubahan.';
  }

  @override
  String get accountFormAddAdjustment => 'Tambah penyesuaian';

  @override
  String get accountFormCancel => 'Batal';

  @override
  String get accountFormArchive => 'Arsipkan';

  @override
  String get accountFormDelete => 'Hapus';

  @override
  String get accountFormArchiveTitle => 'Arsipkan akun?';

  @override
  String get accountFormArchiveBody =>
      'Akun akan disembunyikan tetapi data tetap disimpan.';

  @override
  String get accountFormDeleteTitle => 'Hapus akun?';

  @override
  String accountFormDeleteBody(String name) {
    return 'Ini menghapus permanen \"$name\". Ini tidak dapat dibatalkan.';
  }

  @override
  String accountFormDeleteBodyWithTxns(
    String name,
    int affected,
    String plural,
  ) {
    return 'Ini menghapus permanen \"$name\" dan $affected transaksi yang merujuknya. Ini tidak dapat dibatalkan.';
  }

  @override
  String accountFormDeleteFailed(String error) {
    return 'Gagal menghapus: $error';
  }

  @override
  String get accountFormLiabilityInfo =>
      'Untuk pinjaman, buat Transfer dari akun liabilitas ini ke akun aset.';

  @override
  String get accountFormRecentTransactions => 'Transaksi terbaru';

  @override
  String get scanReceiptTitle => 'Pindai struk';

  @override
  String get scanReceipt => 'STRUK';

  @override
  String get scanAlignHint => 'Sejajarkan struk dalam bingkai';

  @override
  String get scanReadingTitle => 'Membaca struk';

  @override
  String get scanReadingBody => 'Membaca struk Anda…';

  @override
  String get scanReadingSubtitle =>
      'Biasanya sekitar 2 detik. Kami mengekstrak toko, total, dan item.';

  @override
  String get scanPersonal => 'Pribadi';

  @override
  String get scanRooms => 'Ruangan';

  @override
  String get scanRoom => 'Ruangan';

  @override
  String get scanSaved => 'Struk disimpan';

  @override
  String get scanNoRooms =>
      'Belum ada ruangan — buat ruangan sebelum memindai ke ruangan.';

  @override
  String get scanSendToRoom => 'Kirim struk ke ruangan';

  @override
  String get scanLimitReached => 'Batas pemindaian tercapai';

  @override
  String scanUsedAllScans(String quota, String tier) {
    return 'Menggunakan semua $quota pemindaian di $tier bulan ini.';
  }

  @override
  String get scanQuotaDefault =>
      'Anda telah menggunakan kuota pemindaian bulanan Anda.';

  @override
  String get scanTopUp => 'Isi ulang · 10 pemindaian seharga Rp19.000';

  @override
  String get scanUpgrade => 'Upgrade ke Pro — pemindaian tanpa batas';

  @override
  String get scanNotNow => 'Nanti saja';

  @override
  String get scanTakeAnother => 'Ambil foto lain';

  @override
  String get scanRetry => 'Coba lagi';

  @override
  String get scanCancel => 'Batal';

  @override
  String get scanInviteInvalid => 'Undangan tidak valid atau kedaluwarsa';

  @override
  String scanCouldNotJoinRoom(String error) {
    return 'Tidak dapat bergabung ke ruangan: $error';
  }

  @override
  String get scanJoinRoomTitle => 'Gabung ruangan?';

  @override
  String get scanJoinRoomBody =>
      'QR undangan ruangan LOIT terdeteksi. Gabung ruangan?';

  @override
  String get scanJoinRoom => 'Gabung ruangan';

  @override
  String get scanJoining => 'Bergabung…';

  @override
  String get scanNotTransaction => 'Itu tidak terlihat seperti transaksi';

  @override
  String get scanNotTransactionBody =>
      'Kami tidak menemukan struk, faktur, slip transfer, slip gaji, atau catatan transaksi serupa di gambar ini. Coba foto yang lebih jelas dari dokumen.';

  @override
  String get scanOfflineTitle => 'Anda sedang offline';

  @override
  String get scanOfflineBody =>
      'Kami tidak dapat menjangkau layanan pemindaian. Periksa koneksi dan coba lagi.';

  @override
  String get scanUnavailableTitle => 'Layanan pemindaian tidak tersedia';

  @override
  String get scanUnavailableBody =>
      'Layanan pemindaian sementara tidak tersedia. Coba lagi sebentar lagi.';

  @override
  String get receiptsTitle => 'Struk';

  @override
  String receiptsFailed(String error) {
    return 'Gagal memuat: $error';
  }

  @override
  String receiptsDownloadFailed(String error) {
    return 'Gagal mengunduh: $error';
  }

  @override
  String receiptsShareSubject(String date) {
    return 'Struk $date';
  }

  @override
  String get receiptsFallback => 'Struk';

  @override
  String get receiptsActive => 'Aktif';

  @override
  String get receiptsExpiring => 'Segera kedaluwarsa';

  @override
  String get receiptsExpired => 'Kedaluwarsa';

  @override
  String get receiptsNoReceipts => 'Belum ada struk';

  @override
  String get receiptsEmptyBody =>
      'Struk yang dipindai akan muncul di sini. Gunakan pemindai untuk menangkap satu.';

  @override
  String get reportsScreenTitle => 'Laporan';

  @override
  String get reportsScreenIncome => 'Pemasukan';

  @override
  String get reportsScreenExpenses => 'Pengeluaran';

  @override
  String get reportsScreenNet => 'Bersih';

  @override
  String get reportsScreenNoData => 'Tidak ada data untuk periode ini';

  @override
  String get reportsScreenCategory => 'Kategori';

  @override
  String get reportsScreenAmount => 'Jumlah';

  @override
  String get reportsScreenPercent => '%';

  @override
  String get reportsScreenEmptyBody =>
      'Laporan akan muncul saat Anda memiliki transaksi.';

  @override
  String get exportScreenTitle => 'Ekspor data';

  @override
  String get exportScreenFormat => 'Format';

  @override
  String get exportScreenDateRange => 'Rentang tanggal';

  @override
  String get exportScreenLastMonth => 'Bulan lalu';

  @override
  String get exportScreenLast3Months => '3 bulan terakhir';

  @override
  String get exportScreenLast6Months => '6 bulan terakhir';

  @override
  String get exportScreenLastYear => 'Tahun lalu';

  @override
  String get exportScreenAllTime => 'Sepanjang waktu';

  @override
  String get exportScreenExport => 'Ekspor';

  @override
  String get exportScreenExporting => 'Mengekspor…';

  @override
  String get exportScreenReady => 'Ekspor Anda siap.';

  @override
  String exportScreenFailed(String error) {
    return 'Ekspor gagal: $error';
  }

  @override
  String get exportScreenAccounts => 'Akun';

  @override
  String get exportScreenTransactions => 'Transaksi';

  @override
  String get exportScreenBudgets => 'Anggaran';

  @override
  String get roomsScreenTitle => 'Ruangan';

  @override
  String get roomsScreenNoRooms => 'Belum ada ruangan';

  @override
  String get roomsScreenEmptyBody =>
      'Buat atau gabung ruangan untuk melacak pengeluaran bersama.';

  @override
  String get roomsScreenCreateRoom => 'Buat ruangan';

  @override
  String get roomsScreenJoinRoom => 'Gabung ruangan';

  @override
  String roomsScreenMembers(int n) {
    return '$n anggota';
  }

  @override
  String get roomCreateTitle => 'Buat ruangan';

  @override
  String get roomCreateName => 'Nama ruangan';

  @override
  String get roomCreateNamePlaceholder => 'mis. Teman Serumah, Liburan ke Bali';

  @override
  String get roomCreateDescription => 'Deskripsi (opsional)';

  @override
  String get roomCreateCreate => 'Buat';

  @override
  String get roomCreateCreating => 'Membuat…';

  @override
  String roomCreateFailed(String error) {
    return 'Gagal membuat ruangan: $error';
  }

  @override
  String get roomInviteTitle => 'Undang anggota';

  @override
  String get roomInviteShare => 'Bagikan tautan undangan';

  @override
  String get roomInviteBody =>
      'Siapa pun dengan tautan ini dapat bergabung ke ruangan.';

  @override
  String get roomJoinTitle => 'Gabung ruangan';

  @override
  String get roomJoinJoining => 'Bergabung…';

  @override
  String get roomJoinInvalid => 'Undangan ini tidak valid atau kedaluwarsa.';

  @override
  String roomJoinFailed(String error) {
    return 'Gagal bergabung: $error';
  }

  @override
  String get roomDetailAddTransaction => 'Tambah transaksi';

  @override
  String get roomDetailMembers => 'Anggota';

  @override
  String get roomDetailBudgets => 'Anggaran';

  @override
  String get roomDetailLeave => 'Tinggalkan ruangan';

  @override
  String get roomDetailLeaveTitle => 'Tinggalkan ruangan?';

  @override
  String get roomDetailLeaveBody =>
      'Transaksi Anda di ruangan ini akan tetap disimpan.';

  @override
  String get roomDetailLeaveConfirm => 'Tinggalkan';

  @override
  String get roomDetailDeleteTitle => 'Hapus ruangan?';

  @override
  String get roomDetailDeleteBody =>
      'Semua data bersama di ruangan ini akan dihapus permanen.';

  @override
  String get roomDetailDeleteRoom => 'Hapus ruangan';

  @override
  String get roomDetailBudgetTitle => 'Anggaran ruangan';

  @override
  String get roomDetailNotSynced => 'Belum disinkronkan';

  @override
  String get roomDetailNotSyncedBody =>
      'Transaksi ini belum disinkronkan. Edit untuk menyimpan.';

  @override
  String get paywallTitle => 'Upgrade ke Pro';

  @override
  String get paywallSubtitle =>
      'Buka pemindaian, struk, dan anggaran tanpa batas.';

  @override
  String get paywallContinue => 'Lanjutkan';

  @override
  String get paywallRestoring => 'Memulihkan…';

  @override
  String get paywallFree => 'Gratis';

  @override
  String get paywallPro => 'Pro';

  @override
  String get paywallTeam => 'Tim';

  @override
  String get pwProSuccessTitle => 'Selamat datang di Pro!';

  @override
  String get pwProSuccessBody =>
      'Anda sekarang memiliki pemindaian tanpa batas dan fitur premium.';

  @override
  String get pwProSuccessDone => 'Selesai';

  @override
  String get billingManageTitle => 'Kelola langganan';

  @override
  String get billingManageCurrentPlan => 'Paket saat ini';

  @override
  String get billingManageCancel => 'Batalkan langganan';

  @override
  String get billingManageCancelTitle => 'Batalkan langganan?';

  @override
  String get billingManageCancelBody =>
      'Anda akan kehilangan fitur Pro di akhir periode penagihan.';

  @override
  String get billingManageCancelConfirm => 'Batalkan';

  @override
  String billingManageCancelFailed(Object error) {
    return 'Gagal membatalkan: $error';
  }

  @override
  String get authWelcomeTitle => 'Selamat datang di LOIT';

  @override
  String get authWelcomeSubtitle =>
      'Keuangan pribadi & bersama, tenang secara desain.';

  @override
  String get authWelcomeContinue => 'Lanjutkan dengan Google';

  @override
  String get authWelcomeEmail => 'Masuk dengan email';

  @override
  String get authWelcomeTerms =>
      'Dengan melanjutkan Anda menyetujui Ketentuan Layanan dan Kebijakan Privasi kami.';

  @override
  String get authSignInTitle => 'Masuk';

  @override
  String get authSignInEmail => 'Alamat email';

  @override
  String get authSignInEmailPlaceholder => 'anda@contoh.com';

  @override
  String get authSignInContinue => 'Lanjutkan';

  @override
  String authSignInError(Object error) {
    return 'Gagal masuk: $error';
  }

  @override
  String get authOtpTitle => 'Verifikasi email';

  @override
  String authOtpBody(Object email) {
    return 'Masukkan kode yang dikirim ke $email';
  }

  @override
  String get authOtpPlaceholder => '123456';

  @override
  String get authOtpVerify => 'Verifikasi';

  @override
  String get authOtpResend => 'Kirim ulang kode';

  @override
  String get authOtpResendSent => 'Kode dikirim ulang';

  @override
  String authOtpError(Object error) {
    return 'Verifikasi gagal: $error';
  }

  @override
  String get authPermissionsTitle => 'Hampir selesai';

  @override
  String get authPermissionsBody =>
      'LOIT membutuhkan beberapa izin untuk bekerja.';

  @override
  String get authPermissionsNotifications => 'Notifikasi';

  @override
  String get authPermissionsNotificationsDesc =>
      'Dapatkan peringatan untuk anggaran, ruangan, dan struk.';

  @override
  String get authPermissionsCamera => 'Kamera';

  @override
  String get authPermissionsCameraDesc => 'Pindai struk dan undangan ruangan.';

  @override
  String get authPermissionsContinue => 'Lanjutkan';

  @override
  String get lockScreenTitle => 'LOIT';

  @override
  String get lockScreenUnlock => 'Buka kunci';

  @override
  String get lockScreenBiometricPrompt => 'Autentikasi untuk membuka LOIT';

  @override
  String get lockScreenFailed => 'Autentikasi gagal';

  @override
  String get systemUpdateTitle => 'Pembaruan diperlukan';

  @override
  String get systemUpdateBody =>
      'Silakan perbarui LOIT ke versi terbaru untuk melanjutkan.';

  @override
  String get systemUpdateAction => 'Perbarui';

  @override
  String get roomArchiveTitle => 'Arsipkan ruangan?';

  @override
  String get roomArchiveConfirm => 'Arsipkan';

  @override
  String get roomArchiveRoom => 'Arsipkan ruangan';

  @override
  String get roomNewBudget => 'Anggaran baru';

  @override
  String get roomNewCategory => 'Kategori baru';

  @override
  String roomDeleteCategory(String name) {
    return 'Dihapus \"$name\"';
  }

  @override
  String roomDeletedLabel(String label) {
    return 'Dihapus \"$label\"';
  }

  @override
  String get roomTxNotFound => 'Transaksi tidak ada di umpan terbaru';

  @override
  String roomUpdateFailed(String error) {
    return 'Gagal memperbarui: $error';
  }

  @override
  String get catScreenTitle => 'Kategori';

  @override
  String get catScreenPersonalExpense => 'Pribadi · Pengeluaran';

  @override
  String get catScreenPersonalIncome => 'Pribadi · Pemasukan';

  @override
  String get catScreenRoom => 'Ruangan';

  @override
  String catScreenRoomLabel(String name) {
    return 'Ruangan · $name';
  }

  @override
  String get catScreenInherited => 'Diwariskan · hanya baca';

  @override
  String get catScreenNoCategories => 'Belum ada kategori';

  @override
  String get catScreenEmptyBody =>
      'Ketuk \"Tambah kategori\" untuk membuat yang pertama.';

  @override
  String catScreenDeleteTitle(String name) {
    return 'Hapus \"$name\"?';
  }

  @override
  String get catScreenDeleteBody =>
      'Transaksi atau anggaran dengan kunci kategori ini akan jatuh ke \"Lainnya\".';

  @override
  String get catScreenDeleteBodyPermanent =>
      'Transaksi atau anggaran dengan kunci kategori ini akan jatuh ke \"Lainnya\". Ini tidak dapat dibatalkan.';

  @override
  String get catScreenCancel => 'Batal';

  @override
  String get catScreenDelete => 'Hapus';

  @override
  String get catFormNewCategory => 'Kategori baru';

  @override
  String get catFormEditCategory => 'Edit kategori';

  @override
  String get catFormNewRoomCategory => 'Kategori ruangan baru';

  @override
  String get catFormEditRoomCategory => 'Edit kategori ruangan';

  @override
  String get catFormName => 'Nama';

  @override
  String get catFormNamePlaceholder => 'mis. Kopi';

  @override
  String get catFormType => 'Tipe';

  @override
  String get catFormExpense => 'Pengeluaran';

  @override
  String get catFormIncome => 'Pemasukan';

  @override
  String get catFormColor => 'Warna';

  @override
  String get catFormIcon => 'Ikon';

  @override
  String get catFormSaveChanges => 'Simpan perubahan';

  @override
  String get catFormCreateCategory => 'Buat kategori';

  @override
  String get catFormNameRequired => 'Nama diperlukan';

  @override
  String catFormSaveFailed(String error) {
    return 'Gagal menyimpan: $error';
  }

  @override
  String get catFormDelete => 'Hapus';

  @override
  String catFormDeleteFailed(String error) {
    return 'Gagal menghapus: $error';
  }

  @override
  String get notifFeedTitle => 'Notifikasi';

  @override
  String get roomInviteLinkCopied => 'Tautan disalin';

  @override
  String get roomInviteNoToken => 'Tidak ada token undangan';

  @override
  String roomInviteRegenFailed(String error) {
    return 'Gagal membuat ulang: $error';
  }

  @override
  String get roomUpgrade => 'Upgrade';

  @override
  String get tierActive => 'AKTIF';
}
