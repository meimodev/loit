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
  String get tierActive => 'AKTIF';
}
