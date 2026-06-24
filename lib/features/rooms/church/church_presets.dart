/// Denomination → starting financial categories for a Church room (ADR 0019).
///
/// App-side constant: it only *seeds* a new church room's `room_categories`
/// (penerimaan → income, pengeluaran → expense). After creation the rows are
/// authoritative and freely editable. The two catch-all rows ("Lainnya" /
/// "Pemasukan lain") are guaranteed by the DB trigger, so the presets here
/// deliberately omit a "Lain-lain" line.
///
/// Visible denominations: GMIM, GBI, Katolik, Gereja Baptis, GKI, GPdI, GPIB,
/// HKBP, Lainnya. Only GMIM/GBI/Katolik carry dedicated presets; every other
/// entry (and free text under "Lainnya") falls back to the generic preset.
class ChurchCategories {
  final List<String> penerimaan;
  final List<String> pengeluaran;
  const ChurchCategories({required this.penerimaan, required this.pengeluaran});
}

/// Stable key for the free-text "other denomination" option (Screen 1).
const String kDenominationOther = 'Lainnya';

/// Order shown in the denomination picker.
const List<String> denominationOrder = [
  'GMIM',
  'GBI',
  'Katolik',
  'Gereja Baptis',
  'GKI',
  'GPdI',
  'GPIB',
  'HKBP',
  'Lainnya',
];

const Map<String, ChurchCategories> denominationPresets = {
  'GMIM': ChurchCategories(
    penerimaan: [
      'Persepuluhan',
      'Kolekte Minggu',
      'Kolekte Kebaktian Khusus',
      'Kolekte Pembangunan',
      'Kolekte Diakonia',
      'Donasi Khusus',
    ],
    pengeluaran: [
      'Honor Pelayan',
      'Operasional Gereja',
      'Pemeliharaan Gedung',
      'Kegiatan Ibadah',
      'Dana Sosial / Diakonia',
    ],
  ),
  'GBI': ChurchCategories(
    penerimaan: [
      'Persepuluhan',
      'Persembahan Ibadah Raya',
      'Persembahan Ibadah Sel',
      'Persembahan Pembangunan',
      'Persembahan Misi',
      'Donasi',
    ],
    pengeluaran: [
      'Honor Gembala / Pelayan',
      'Operasional Gereja',
      'Pemeliharaan Gedung',
      'Kegiatan Sel & KTB',
      'Program Misi',
      'Dana Sosial',
    ],
  ),
  'Katolik': ChurchCategories(
    penerimaan: [
      'Kolekte Misa Minggu',
      'Kolekte Misa Harian',
      'Kolekte Khusus (APP, dll)',
      'Persembahan Natal / Paskah',
      'Sumbangan Umat',
    ],
    pengeluaran: [
      'Honorarium Pastor',
      'Operasional Paroki',
      'Pemeliharaan Gedung Gereja',
      'Kegiatan Pastoral',
      'Karitatif / Sosial',
    ],
  ),
  'Lainnya': ChurchCategories(
    penerimaan: [
      'Persembahan / Kolekte',
      'Persepuluhan',
      'Donasi',
    ],
    pengeluaran: [
      'Honor Pelayan',
      'Operasional',
      'Pemeliharaan',
      'Kegiatan Gereja',
    ],
  ),
};

/// Preset for [denomination], falling back to the generic "Lainnya" preset for
/// any denomination without a dedicated list (GPdI/GPIB/HKBP free-text, etc.).
ChurchCategories presetFor(String denomination) =>
    denominationPresets[denomination] ?? denominationPresets[kDenominationOther]!;
