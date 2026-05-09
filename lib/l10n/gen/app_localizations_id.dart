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
  String get tierActive => 'AKTIF';
}
