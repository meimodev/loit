/// The Church room's starting chart of accounts (ADR 0021).
///
/// A single, denomination-independent set of `room_categories` seeds — it only
/// *seeds* a new church room (penerimaan → income, pengeluaran → expense);
/// after creation the rows are authoritative and freely editable. The two
/// catch-all rows ("Lainnya" / "Penerimaan lain") are guaranteed by the DB
/// trigger (ADR 0009), so the chart deliberately omits a "Lain-lain" line.
///
/// Supersedes ADR-0019's per-denomination preset map: GMIM/GBI/Katolik no
/// longer carry distinct lists. The denomination picker survives as report /
/// profile metadata only — it no longer varies these categories.
///
/// `iconName` must be a valid [LoitCategories] icon name; `tint` a
/// `#RRGGBB` hex from the shared category palette.
class ChurchCategory {
  final String name;
  final String iconName;
  final String tint;
  const ChurchCategory(this.name, this.iconName, this.tint);
}

class ChurchCategories {
  final List<ChurchCategory> penerimaan;
  final List<ChurchCategory> pengeluaran;
  const ChurchCategories({required this.penerimaan, required this.pengeluaran});
}

/// Stable key for the free-text "other denomination" option (Screen 1).
const String kDenominationOther = 'Lainnya';

/// Order shown in the denomination picker (metadata only, ADR 0021).
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

/// The one chart of accounts every church room starts from (ADR 0021).
/// "Dana Transit / Titipan" is a real clearing/liability bucket, not a
/// catch-all. The expense catch-all is the trigger's "Lainnya" (ADR 0009).
const ChurchCategories churchChartOfAccounts = ChurchCategories(
  penerimaan: [
    ChurchCategory(
        'Persembahan & Persepuluhan', 'volunteer_activism_outlined', '#2F8F5E'),
    ChurchCategory('Usaha & Penggalangan Dana', 'trending_up', '#D49A2B'),
    ChurchCategory('Sumbangan & Bantuan', 'card_giftcard', '#4FA88B'),
    ChurchCategory('Dana Pembangunan', 'account_balance_outlined', '#3E7AC5'),
    ChurchCategory(
        'Dana Transit / Titipan', 'currency_exchange_outlined', '#5A6160'),
  ],
  pengeluaran: [
    ChurchCategory('Gaji & Tunjangan Pelayan', 'attach_money_outlined', '#C5443E'),
    ChurchCategory('Program & Pelayanan', 'local_activity_outlined', '#B15FC0'),
    ChurchCategory('Operasional & Kantor', 'receipt_long_outlined', '#F2A85C'),
    ChurchCategory('Pemeliharaan & Inventaris', 'handyman_outlined', '#6EAA92'),
    ChurchCategory('Diakonia & Sosial', 'favorite_border', '#E06B8A'),
    ChurchCategory('Pembangunan & Belanja Modal', 'home_outlined', '#3CA876'),
  ],
);

/// The church chart of accounts. Denomination-independent (ADR 0021) — the
/// argument is ignored, kept so existing callers need not change.
ChurchCategories presetFor(String denomination) => churchChartOfAccounts;
