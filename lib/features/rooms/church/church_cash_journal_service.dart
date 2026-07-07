import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../shared/providers/accounts_provider.dart';
import '../../../shared/providers/transactions_provider.dart';
import '../../reports/export_service.dart';

/// Buku Kas Umum (BKU — the general cash book), ADR 0027. A per-Room-account
/// chronological cash book: every movement in date order with a running saldo,
/// one section per account, each opening with Saldo Awal (carry-forward) and
/// closing with Saldo Akhir (= the account's real balance at range-end).
///
/// Unlike [ChurchReportService] (Laporan Keuangan) this **keeps transfers** — a
/// room-account transfer renders as two legs, an outgoing row in the source
/// account and an incoming row in the destination — and reads **pre-range**
/// rows to seed the opening saldo. Scoped to Room-account rows only, so an
/// Out-of-pocket room expense (personal-funded) never appears. Mechanical, no AI.
class ChurchCashJournalService {
  /// [allTxns] is the room's **full, date-unfiltered** transaction set (the
  /// service splits it into pre-range → opening and in-range → rows itself).
  /// [accounts] is the room's accounts including archived ones (history).
  /// [categoryNames] maps a txn's category key to a display name for the Uraian
  /// fallback. [baseCurrency] is the room currency (IDR for church rooms).
  Future<void> generateAndShare({
    required Map<String, dynamic> orgConfig,
    required String baseCurrency,
    required DateTime start,
    required DateTime end,
    required List<Account> accounts,
    required List<Txn> allTxns,
    required Map<String, String> categoryNames,
    bool asCsv = false,
  }) async {
    final rangeEnd = DateTime(end.year, end.month, end.day, 23, 59, 59);
    final sections = buildSections(
      accounts: accounts,
      allTxns: allTxns,
      start: start,
      rangeEnd: rangeEnd,
      baseCurrency: baseCurrency,
      categoryNames: categoryNames,
    );

    // Room-wide summary: real Penerimaan / Pengeluaran exclude transfer legs
    // (they net to zero across accounts); Saldo Akhir sums the sections'
    // closing balances (= total cash at range-end).
    var totalPen = 0.0;
    var totalPeng = 0.0;
    final roomIds = {for (final a in accounts) a.id};
    for (final t in allTxns) {
      if (t.createdAt.isBefore(start) || t.createdAt.isAfter(rangeEnd)) continue;
      if (t.isTransfer) continue;
      final from = t.accountId;
      if (from == null || !roomIds.contains(from)) continue;
      final amt = t.absAmountIn(baseCurrency);
      if (t.isIncome) {
        totalPen += amt;
      } else {
        totalPeng += amt;
      }
    }
    final totalClosing =
        sections.fold<double>(0, (s, sec) => s + sec.closing);

    if (asCsv) {
      await _shareCsv(orgConfig, start, end, sections);
      return;
    }

    final font = await PdfGoogleFonts.notoSansRegular();
    final bold = await PdfGoogleFonts.notoSansBold();
    final bytes = await buildJournalPdf(
      orgConfig: orgConfig,
      baseCurrency: baseCurrency,
      start: start,
      end: end,
      sections: sections,
      totalPen: totalPen,
      totalPeng: totalPeng,
      totalClosing: totalClosing,
      font: font,
      bold: bold,
    );
    final jemaat = (orgConfig['jemaat_name'] as String?)?.trim();
    final slug = (jemaat == null || jemaat.isEmpty ? 'gereja' : jemaat)
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    await Printing.sharePdf(bytes: bytes, filename: 'buku_kas_umum_$slug.pdf');
  }

  /// Splits [allTxns] per account into a carry-forward opening saldo (movements
  /// before [start]) and in-range journal rows, mirroring the canonical balance
  /// rule (`roomAccountBalancesProvider` / the `room_account_balance` SQL fn).
  /// A section is emitted only when it has in-range rows, a nonzero opening, or
  /// a nonzero closing (never-funded seeded accounts drop out).
  @visibleForTesting
  List<JournalSection> buildSections({
    required List<Account> accounts,
    required List<Txn> allTxns,
    required DateTime start,
    required DateTime rangeEnd,
    required String baseCurrency,
    required Map<String, String> categoryNames,
  }) {
    final byId = {for (final a in accounts) a.id: a};
    final sections = <JournalSection>[];

    for (final acc in accounts) {
      // Opening = initial_balance + every pre-range leg touching this account.
      var opening = acc.initialBalance;
      for (final t in allTxns) {
        if (!t.createdAt.isBefore(start)) continue;
        opening += _leg(t, acc.id, baseCurrency);
      }

      final inRange = allTxns
          .where((t) =>
              !t.createdAt.isBefore(start) &&
              !t.createdAt.isAfter(rangeEnd) &&
              (t.accountId == acc.id || t.toAccountId == acc.id))
          .toList()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

      final rows = <JournalRow>[];
      var running = opening;
      for (final t in inRange) {
        final amt = t.absAmountIn(baseCurrency);
        final incoming = t.toAccountId == acc.id; // incoming transfer leg
        double? pen;
        double? peng;
        String uraian;
        if (incoming) {
          pen = amt;
          final src = byId[t.accountId]?.name ?? 'akun lain';
          uraian = 'Transfer dari $src';
        } else if (t.isTransfer) {
          peng = amt;
          final dst = byId[t.toAccountId]?.name ?? 'akun lain';
          uraian = 'Transfer ke $dst';
        } else if (t.isIncome) {
          pen = amt;
          uraian = _uraian(t, categoryNames);
        } else {
          peng = amt;
          uraian = _uraian(t, categoryNames);
        }
        running += (pen ?? 0) - (peng ?? 0);
        rows.add(JournalRow(
          date: t.createdAt,
          uraian: uraian,
          penerimaan: pen,
          pengeluaran: peng,
          saldo: running,
        ));
      }

      final closing = running;
      if (rows.isEmpty && opening == 0 && closing == 0) continue;
      sections.add(JournalSection(
        accountName: acc.name,
        archived: acc.archivedAt != null,
        opening: opening,
        closing: closing,
        rows: rows,
      ));
    }
    return sections;
  }

  /// Signed contribution of transaction [t] to account [accId]'s balance, in
  /// [currency] — the canonical rule: income on this account adds, expense and
  /// the outgoing transfer leg subtract, the incoming transfer leg adds.
  double _leg(Txn t, String accId, String currency) {
    var delta = 0.0;
    if (t.accountId == accId) {
      final v = t.absAmountIn(currency);
      delta += t.isIncome ? v : -v;
    }
    if (t.toAccountId == accId) {
      delta += t.absAmountIn(currency); // transfer in
    }
    return delta;
  }

  String _uraian(Txn t, Map<String, String> categoryNames) {
    final title = t.displayTitle?.trim();
    if (title != null && title.isNotEmpty) return title;
    final cat = t.category;
    if (cat != null) {
      final name = categoryNames[cat];
      if (name != null && name.isNotEmpty) return name;
      if (cat.isNotEmpty) return cat;
    }
    return '—';
  }

  /// Renders the BKU PDF to bytes. [font]/[bold] optional (tests/preview fall
  /// back to built-in fonts).
  Future<Uint8List> buildJournalPdf({
    required Map<String, dynamic> orgConfig,
    required String baseCurrency,
    required DateTime start,
    required DateTime end,
    required List<JournalSection> sections,
    required double totalPen,
    required double totalPeng,
    required double totalClosing,
    pw.Font? font,
    pw.Font? bold,
  }) async {
    String money(num v) => formatMoney(v, baseCurrency);
    final periodLabel = _periodLabel(start, end);
    final jemaat = (orgConfig['jemaat_name'] as String?)?.trim();
    final jemaatName = jemaat == null || jemaat.isEmpty ? 'Gereja' : jemaat;

    final theme = font != null && bold != null
        ? pw.ThemeData.withFont(base: font, bold: bold)
        : null;
    final doc = pw.Document(theme: theme);
    doc.addPage(
      pw.MultiPage(
        theme: theme,
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(32, 36, 32, 36),
        header: (ctx) => pdfReportRunningHeader(ctx, jemaatName, periodLabel),
        footer: (ctx) => pdfReportPageFooter(ctx, label: 'Halaman'),
        build: (context) => [
          pdfReportCover(
            title: 'Buku Kas Umum',
            subtitle: jemaatName,
            fields: [('Periode', periodLabel)],
          ),
          pw.SizedBox(height: 18),
          pdfReportSectionTitle('Ringkasan'),
          pw.SizedBox(height: 6),
          pw.Row(children: [
            pw.Expanded(
                child: pdfReportSummaryCard(
                    'Penerimaan', money(totalPen), pdfReportSuccess)),
            pw.SizedBox(width: 8),
            pw.Expanded(
                child: pdfReportSummaryCard(
                    'Pengeluaran', money(totalPeng), pdfReportDanger)),
            pw.SizedBox(width: 8),
            pw.Expanded(
                child: pdfReportSummaryCard('Saldo Akhir', money(totalClosing),
                    totalClosing >= 0 ? pdfReportSuccess : pdfReportDanger)),
          ]),
          pw.SizedBox(height: 18),
          if (sections.isEmpty)
            pw.Text('Tidak ada mutasi kas pada periode ini.',
                style: const pw.TextStyle(fontSize: 10))
          else
            for (final sec in sections) ...[
              _sectionWidget(sec, money),
              pw.SizedBox(height: 16),
            ],
        ],
      ),
    );
    return doc.save();
  }

  static pw.Widget _sectionWidget(
    JournalSection sec,
    String Function(num) money,
  ) {
    final title = sec.archived ? '${sec.accountName} (arsip)' : sec.accountName;
    final fmt = DateFormat('dd/MM/yyyy', 'id');
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pdfReportSectionTitle(title),
        pw.SizedBox(height: 6),
        pw.TableHelper.fromTextArray(
          cellAlignments: {
            0: pw.Alignment.centerLeft,
            1: pw.Alignment.centerLeft,
            2: pw.Alignment.centerRight,
            3: pw.Alignment.centerRight,
            4: pw.Alignment.centerRight,
          },
          headerStyle: pw.TextStyle(
              color: pdfReportMuted, fontSize: 9, fontWeight: pw.FontWeight.bold),
          headerDecoration: const pw.BoxDecoration(color: pdfReportSurface),
          cellStyle: pw.TextStyle(color: pdfReportInk, fontSize: 9),
          cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
          border: pw.TableBorder(
            horizontalInside: pw.BorderSide(color: pdfReportSubtle, width: 0.5),
            top: pw.BorderSide(color: pdfReportSubtle, width: 0.5),
            bottom: pw.BorderSide(color: pdfReportSubtle, width: 0.5),
          ),
          columnWidths: {
            0: const pw.FlexColumnWidth(1.3),
            1: const pw.FlexColumnWidth(3),
            2: const pw.FlexColumnWidth(1.5),
            3: const pw.FlexColumnWidth(1.5),
            4: const pw.FlexColumnWidth(1.6),
          },
          headers: const [
            'Tanggal',
            'Uraian',
            'Penerimaan',
            'Pengeluaran',
            'Saldo'
          ],
          data: [
            ['', 'Saldo Awal', '', '', money(sec.opening)],
            for (final r in sec.rows)
              [
                fmt.format(r.date),
                r.uraian,
                r.penerimaan == null ? '' : money(r.penerimaan!),
                r.pengeluaran == null ? '' : money(r.pengeluaran!),
                money(r.saldo),
              ],
            ['', 'Saldo Akhir', '', '', money(sec.closing)],
          ],
        ),
      ],
    );
  }

  /// Listing-style CSV: the actual journal rows under an `Akun` grouping column
  /// with Saldo Awal / Saldo Akhir marker rows — not summary subtotals. Raw
  /// integer rupiah, Indonesian headers, jemaat + period metadata block.
  Future<void> _shareCsv(
    Map<String, dynamic> orgConfig,
    DateTime start,
    DateTime end,
    List<JournalSection> sections,
  ) async {
    final jemaat = (orgConfig['jemaat_name'] as String?)?.trim();
    final name = jemaat == null || jemaat.isEmpty ? 'Gereja' : jemaat;
    final fmt = DateFormat('dd/MM/yyyy', 'id');

    final rows = <List<dynamic>>[
      ['Buku Kas Umum', name],
      ['Periode', _periodLabel(start, end)],
      [],
      ['Akun', 'Tanggal', 'Uraian', 'Penerimaan', 'Pengeluaran', 'Saldo'],
      for (final sec in sections) ...[
        [sec.accountName, '', 'Saldo Awal', '', '', sec.opening.round()],
        for (final r in sec.rows)
          [
            sec.accountName,
            fmt.format(r.date),
            r.uraian,
            r.penerimaan == null ? '' : r.penerimaan!.round(),
            r.pengeluaran == null ? '' : r.pengeluaran!.round(),
            r.saldo.round(),
          ],
        [sec.accountName, '', 'Saldo Akhir', '', '', sec.closing.round()],
      ],
    ];

    final slug = name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    await shareCsvRows(rows, 'buku_kas_umum_$slug');
  }

  static String _periodLabel(DateTime start, DateTime end) {
    final fmt = DateFormat('d MMM yyyy', 'id');
    return '${fmt.format(start)} – ${fmt.format(end)}';
  }
}

class JournalSection {
  JournalSection({
    required this.accountName,
    required this.archived,
    required this.opening,
    required this.closing,
    required this.rows,
  });
  final String accountName;
  final bool archived;
  final double opening;
  final double closing;
  final List<JournalRow> rows;
}

class JournalRow {
  JournalRow({
    required this.date,
    required this.uraian,
    required this.penerimaan,
    required this.pengeluaran,
    required this.saldo,
  });
  final DateTime date;
  final String uraian;
  final double? penerimaan;
  final double? pengeluaran;
  final double saldo;
}
