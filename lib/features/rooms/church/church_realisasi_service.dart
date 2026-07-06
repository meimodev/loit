import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/env.dart';
import '../../../shared/providers/transactions_provider.dart';
import '../../reports/export_service.dart' show formatMoney, shareCsvRows;
import 'mata_anggaran.dart';

const String kUnclassified = 'UNCLASSIFIED';

/// Outline rollup for a Mata Anggaran tree: each node's total is its own direct
/// amount plus every deeper node in the contiguous block beneath it (children,
/// grandchildren) until a row of equal-or-shallower [MataAnggaran.depth]. Pure
/// and testable — the money path of the Realisasi report.
List<double> subtreeTotals(
    List<MataAnggaran> tree, Map<String, double> direct) {
  final out = List<double>.filled(tree.length, 0);
  for (var i = 0; i < tree.length; i++) {
    var sum = direct[tree[i].kode] ?? 0;
    for (var j = i + 1; j < tree.length && tree[j].depth > tree[i].depth; j++) {
      sum += direct[tree[j].kode] ?? 0;
    }
    out[i] = sum;
  }
  return out;
}

/// Raised when the treasurer has no AI Credits left to generate the report
/// (server soft cap, ADR-0017). Surfaced as a top-up prompt, not an error.
class RealisasiQuotaException implements Exception {}

class RealisasiResult {
  const RealisasiResult({
    required this.mapping,
    required this.creditsCharged,
    required this.creditsRemaining,
  });

  /// txn id → Mata Anggaran kode, or [kUnclassified].
  final Map<String, String> mapping;
  final int creditsCharged;
  final int? creditsRemaining; // null = unlimited tier
}

/// Laporan Realisasi Mata Anggaran (ADR-0026): AI-classifies a period's room
/// transactions onto GMIM's fixed chart, then builds a category-grouped PDF.
/// Stateless — every generation re-classifies and re-charges credits; a wrong
/// code is corrected by improving the source transaction's note and regenerating.
class ChurchRealisasiService {
  /// Sends the scoped, non-transfer transactions to the generic classifier Edge
  /// Function and returns the id→kode mapping plus credits charged. Throws
  /// [RealisasiQuotaException] on 402, or a generic [Exception] otherwise.
  Future<RealisasiResult> classify(List<Txn> txns) async {
    final items = [
      for (final t in txns)
        if (!t.isTransfer && t.id != null)
          {
            'id': t.id,
            'kind': t.isIncome ? 'income' : 'expense',
            'text': _itemText(t),
          },
    ];
    if (items.isEmpty) {
      return const RealisasiResult(
          mapping: {}, creditsCharged: 0, creditsRemaining: null);
    }

    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) throw Exception('Not signed in');

    final res = await http.post(
      Uri.parse('${Env.supabaseUrl}/functions/v1/classify-taxonomy'),
      headers: {
        'Authorization': 'Bearer ${session.accessToken}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'items': items,
        'taxonomy': {
          'income': [
            for (final c in gmimIncome) {'kode': c.kode, 'name': c.name}
          ],
          'expense': [
            for (final c in gmimExpense) {'kode': c.kode, 'name': c.name}
          ],
        },
      }),
    );

    if (res.statusCode == 402) throw RealisasiQuotaException();
    if (res.statusCode != 200) {
      throw Exception('Classifier failed (${res.statusCode})');
    }
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final raw = (body['mapping'] as Map?)?.cast<String, dynamic>() ?? {};
    return RealisasiResult(
      mapping: {for (final e in raw.entries) e.key: e.value as String},
      creditsCharged: (body['credits_charged'] as num?)?.toInt() ?? 0,
      creditsRemaining: (body['credits_remaining'] as num?)?.toInt(),
    );
  }

  /// The transaction text handed to the classifier: working category, merchant,
  /// note, and amount — the signals that let it pick a specific Mata Anggaran.
  static String _itemText(Txn t) {
    final parts = <String>[
      if ((t.category ?? '').isNotEmpty) '[${t.category}]',
      if ((t.merchant ?? '').trim().isNotEmpty) t.merchant!.trim(),
      if ((t.notes ?? '').trim().isNotEmpty) t.notes!.trim(),
    ];
    final label = parts.isEmpty ? 'Transaksi' : parts.join(' — ');
    return '$label (${formatMoney(t.amount.abs(), t.currency)})';
  }

  /// Builds the Realisasi PDF from a completed [mapping] and shares it.
  Future<void> generateAndShare({
    required Map<String, dynamic> orgConfig,
    required String baseCurrency,
    required DateTime start,
    required DateTime end,
    required List<Txn> txns,
    required Map<String, String> mapping,
    bool asCsv = false,
  }) async {
    // Direct amount booked to each kode, split by tree.
    final incomeDirect = <String, double>{};
    final expenseDirect = <String, double>{};
    final unclassified = <Txn>[];
    for (final t in txns) {
      if (t.isTransfer || t.id == null) continue;
      final kode = mapping[t.id];
      if (kode == null || kode == kUnclassified) {
        unclassified.add(t);
        continue;
      }
      final bucket = t.isIncome ? incomeDirect : expenseDirect;
      bucket.update(kode, (v) => v + t.absAmountIn(baseCurrency),
          ifAbsent: () => t.absAmountIn(baseCurrency));
    }

    if (asCsv) {
      await _shareCsv(
          orgConfig, start, end, incomeDirect, expenseDirect, unclassified,
          baseCurrency: baseCurrency);
      return;
    }

    final font = await PdfGoogleFonts.notoSansRegular();
    final bold = await PdfGoogleFonts.notoSansBold();
    String money(num v) => formatMoney(v, baseCurrency);

    final incomeTotal = incomeDirect.values.fold<double>(0, (s, v) => s + v);
    final expenseTotal = expenseDirect.values.fold<double>(0, (s, v) => s + v);

    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        theme: pw.ThemeData.withFont(base: font, bold: bold),
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        build: (context) => [
          _header(orgConfig, _periodLabel(start, end), bold),
          pw.SizedBox(height: 18),
          _treeSection('PENERIMAAN', gmimIncome, incomeDirect, incomeTotal,
              money, bold, totalLabel: 'TOTAL PENERIMAAN'),
          pw.SizedBox(height: 16),
          _treeSection('PENGELUARAN', gmimExpense, expenseDirect, expenseTotal,
              money, bold, totalLabel: 'TOTAL PENGELUARAN'),
          pw.SizedBox(height: 16),
          _saldoRow(incomeTotal - expenseTotal, money, bold),
          if (unclassified.isNotEmpty) ...[
            pw.SizedBox(height: 20),
            _unclassifiedSection(unclassified, baseCurrency, money, bold),
          ],
        ],
      ),
    );

    final bytes = await doc.save();
    final jemaat = (orgConfig['jemaat_name'] as String?)?.trim();
    final slug = (jemaat == null || jemaat.isEmpty ? 'gereja' : jemaat)
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    await Printing.sharePdf(bytes: bytes, filename: 'realisasi_$slug.pdf');
  }

  /// Summary-row CSV twin of the Realisasi PDF: walks both Mata Anggaran trees
  /// via [subtreeTotals], emitting one row per populated node (all levels) with a
  /// group/line/leaf `Tingkat` column and raw integer rupiah. Unplaceable
  /// transactions collapse to one Belum Terklasifikasi lump row.
  Future<void> _shareCsv(
    Map<String, dynamic> orgConfig,
    DateTime start,
    DateTime end,
    Map<String, double> incomeDirect,
    Map<String, double> expenseDirect,
    List<Txn> unclassified, {
    required String baseCurrency,
  }) async {
    final jemaat = (orgConfig['jemaat_name'] as String?)?.trim();
    final name = jemaat == null || jemaat.isEmpty ? 'Gereja' : jemaat;

    List<List<dynamic>> treeRows(
        List<MataAnggaran> tree, Map<String, double> direct) {
      final subtree = subtreeTotals(tree, direct);
      final out = <List<dynamic>>[];
      for (var i = 0; i < tree.length; i++) {
        if (subtree[i] == 0) continue;
        final n = tree[i];
        final tingkat =
            n.depth == 0 ? 'group' : (n.depth == 1 ? 'line' : 'leaf');
        out.add([n.kode, n.name, tingkat, subtree[i].round()]);
      }
      return out;
    }

    final unclTotal = unclassified.fold<double>(
        0, (s, t) => s + t.absAmountIn(baseCurrency));

    final rows = <List<dynamic>>[
      ['Laporan Realisasi Mata Anggaran', name],
      ['Periode', _periodLabel(start, end)],
      [],
      ['Kode', 'Nama', 'Tingkat', 'Jumlah'],
      ...treeRows(gmimIncome, incomeDirect),
      ...treeRows(gmimExpense, expenseDirect),
      if (unclassified.isNotEmpty)
        ['BELUM', 'Belum Terklasifikasi', '', unclTotal.round()],
    ];

    final slug =
        name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    await shareCsvRows(rows, 'realisasi_$slug');
  }

  /// Outline rollup: a node's shown total = its own direct amount + every
  /// deeper node beneath it (until a sibling/shallower row). Zero-total subtrees
  /// are hidden so the PDF lists only populated lines, not the full 300-code chart.
  static pw.Widget _treeSection(
    String title,
    List<MataAnggaran> tree,
    Map<String, double> direct,
    double grandTotal,
    String Function(num) money,
    pw.Font bold, {
    required String totalLabel,
  }) {
    final subtree = subtreeTotals(tree, direct);

    final rows = <pw.Widget>[];
    for (var i = 0; i < tree.length; i++) {
      if (subtree[i] == 0) continue;
      final node = tree[i];
      final isGroup = node.depth == 0;
      rows.add(pw.Padding(
        padding: pw.EdgeInsets.only(
            left: node.depth * 12.0, top: 1.5, bottom: 1.5),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Expanded(
              child: pw.Text('${node.kode}  ${node.name}',
                  style: pw.TextStyle(
                      font: isGroup ? bold : null, fontSize: isGroup ? 10 : 9)),
            ),
            pw.SizedBox(width: 8),
            pw.Text(money(subtree[i]),
                style: pw.TextStyle(
                    font: isGroup ? bold : null, fontSize: isGroup ? 10 : 9)),
          ],
        ),
      ));
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.only(bottom: 4),
          decoration:
              const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(width: 1))),
          child: pw.Text(title, style: pw.TextStyle(font: bold, fontSize: 11)),
        ),
        pw.SizedBox(height: 6),
        if (rows.isEmpty)
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 2),
            child: pw.Text('—', style: const pw.TextStyle(fontSize: 9)),
          )
        else
          ...rows,
        pw.SizedBox(height: 4),
        pw.Container(
          padding: const pw.EdgeInsets.only(top: 4),
          decoration: const pw.BoxDecoration(
              border: pw.Border(top: pw.BorderSide(width: 0.5))),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(totalLabel, style: pw.TextStyle(font: bold, fontSize: 10)),
              pw.Text(money(grandTotal),
                  style: pw.TextStyle(font: bold, fontSize: 10)),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _unclassifiedSection(
    List<Txn> txns,
    String baseCurrency,
    String Function(num) money,
    pw.Font bold,
  ) {
    final fmt = DateFormat('d MMM', 'id');
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.only(bottom: 4),
          decoration:
              const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(width: 1))),
          child: pw.Text('BELUM TERKLASIFIKASI (${txns.length})',
              style: pw.TextStyle(font: bold, fontSize: 11)),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          'Transaksi berikut belum dapat dipetakan ke mata anggaran. '
          'Perjelas catatannya lalu buat ulang laporan.',
          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
        ),
        pw.SizedBox(height: 6),
        for (final t in txns)
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Expanded(
                  child: pw.Text(
                    '${fmt.format(t.createdAt.toLocal())}  '
                    '${_txnTitle(t)}',
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                ),
                pw.SizedBox(width: 8),
                pw.Text(
                  '${t.isIncome ? '+' : '-'}${money(t.absAmountIn(baseCurrency))}',
                  style: const pw.TextStyle(fontSize: 9),
                ),
              ],
            ),
          ),
      ],
    );
  }

  static String _txnTitle(Txn t) {
    final m = (t.merchant ?? '').trim();
    if (m.isNotEmpty) return m;
    final n = (t.notes ?? '').trim();
    if (n.isNotEmpty) return n;
    return t.category ?? 'Transaksi';
  }

  static pw.Widget _header(
      Map<String, dynamic> cfg, String period, pw.Font bold) {
    String? f(String k) {
      final v = cfg[k];
      if (v is String && v.trim().isNotEmpty) return v.trim();
      return null;
    }

    final jemaat = f('jemaat_name') ?? 'Gereja';
    final kota = f('kota_kabupaten');
    final phone = f('phone_number');
    final subLine = kota == null ? period : '$kota — $period';

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Text('LAPORAN REALISASI MATA ANGGARAN',
            style: pw.TextStyle(font: bold, fontSize: 15)),
        pw.SizedBox(height: 4),
        pw.Text(jemaat, style: pw.TextStyle(font: bold, fontSize: 13)),
        pw.SizedBox(height: 2),
        pw.Text(subLine, style: const pw.TextStyle(fontSize: 10)),
        if (phone != null) ...[
          pw.SizedBox(height: 2),
          pw.Text('Kontak: $phone', style: const pw.TextStyle(fontSize: 10)),
        ],
      ],
    );
  }

  static pw.Widget _saldoRow(
      double saldo, String Function(num) money, pw.Font bold) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey200,
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('Saldo Periode', style: pw.TextStyle(font: bold, fontSize: 11)),
          pw.Text(money(saldo), style: pw.TextStyle(font: bold, fontSize: 11)),
        ],
      ),
    );
  }

  static String _periodLabel(DateTime start, DateTime end) {
    final fmt = DateFormat('d MMM yyyy', 'id');
    return '${fmt.format(start)} – ${fmt.format(end)}';
  }
}
