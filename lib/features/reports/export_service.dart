import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data' show ByteData;

import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../shared/providers/accounts_provider.dart';
import '../../shared/providers/transactions_provider.dart';

class AccountSnapshot {
  const AccountSnapshot({
    required this.name,
    required this.kind,
    required this.balanceHome,
  });
  final String name;
  final AccountKind kind;
  final double balanceHome;
}

class ExportScope {
  const ExportScope({
    required this.label,
    required this.isRoom,
    required this.start,
    required this.end,
    required this.homeCurrency,
    this.accounts = const [],
  });

  final String label;
  final bool isRoom;
  final DateTime start;
  final DateTime end;
  final String homeCurrency;
  final List<AccountSnapshot> accounts;
}

/// ISO 4217 → human currency symbol. Falls back to the code itself.
String currencySymbol(String code) {
  switch (code.toUpperCase()) {
    case 'IDR':
      return 'Rp';
    case 'USD':
      return '\$';
    case 'EUR':
      return '€';
    case 'GBP':
      return '£';
    case 'JPY':
    case 'CNY':
    case 'RMB':
      return '¥';
    case 'KRW':
      return '₩';
    case 'INR':
      return '₹';
    case 'THB':
      return '฿';
    case 'VND':
      return '₫';
    case 'PHP':
      return '₱';
    case 'SGD':
      return 'S\$';
    case 'MYR':
      return 'RM';
    case 'AUD':
      return 'A\$';
    case 'CAD':
      return 'C\$';
    case 'HKD':
      return 'HK\$';
    case 'NZD':
      return 'NZ\$';
    case 'CHF':
      return 'CHF';
    default:
      return code.toUpperCase();
  }
}

String formatMoney(num value, String code, {bool showCode = false}) {
  final f = NumberFormat.decimalPattern();
  final sym = currencySymbol(code);
  final body = f.format(value.abs());
  final neg = value < 0 ? '-' : '';
  final base = '$neg$sym$body';
  return showCode && sym.toUpperCase() != code.toUpperCase()
      ? '$base $code'
      : base;
}

class _PdfFontBytes {
  const _PdfFontBytes({
    required this.regular,
    required this.bold,
    required this.italic,
    required this.boldItalic,
  });
  final ByteData regular;
  final ByteData bold;
  final ByteData italic;
  final ByteData boldItalic;
}

Future<void> _writeCsvIsolate(
  String path,
  List<Txn> transactions,
  ExportScope scope,
) async {
  final dateFmt = DateFormat('yyyy-MM-dd');
  final timeFmt = DateFormat('HH:mm:ss');
  final rows = <List<dynamic>>[
    [
      'LOIT Export',
      scope.label,
      '${dateFmt.format(scope.start)} - ${dateFmt.format(scope.end)}',
    ],
    [],
    ExportService._csvHeaders,
    ...transactions.map((t) {
      final title = (t.notes ?? '').trim();
      return [
        t.id ?? '',
        dateFmt.format(t.createdAt.toLocal()),
        timeFmt.format(t.createdAt.toLocal()),
        t.type,
        title,
        t.category ?? '',
        t.amount,
        t.currency,
        currencySymbol(t.currency),
        formatMoney(t.amount, t.currency),
        t.fxSnapshot.containsKey(scope.homeCurrency)
            ? t.amountIn(scope.homeCurrency)
            : '',
        scope.homeCurrency,
        t.fxSnapshot.containsKey(scope.homeCurrency)
            ? formatMoney(t.amountIn(scope.homeCurrency), scope.homeCurrency)
            : '',
        t.fxSnapshot[scope.homeCurrency] ?? '',
        t.roomName ?? '',
        t.notes ?? '',
        t.receiptUrl ?? '',
        t.aiParsed ? 'yes' : 'no',
      ];
    }),
  ];
  if (scope.accounts.isNotEmpty) {
    rows
      ..add([])
      ..add(['Accounts Standing'])
      ..add(['Account', 'Type', 'Balance', 'Currency', 'Balance Formatted']);
    for (final a in scope.accounts) {
      rows.add([
        a.name,
        a.kind == AccountKind.asset ? 'asset' : 'liability',
        a.balanceHome,
        scope.homeCurrency,
        formatMoney(a.balanceHome, scope.homeCurrency),
      ]);
    }
  }
  final csvString = const ListToCsvConverter().convert(rows);
  await File(path).writeAsString(csvString);
}

Future<void> _buildPdfIsolate(
  String path,
  List<Txn> transactions,
  ExportScope scope,
  _PdfFontBytes fonts,
) =>
    ExportService._buildPdfDocument(path, transactions, scope, fonts);

class ExportService {
  static const int maxPdfMonths = 12;

  static const _csvHeaders = [
    'ID',
    'Date',
    'Time',
    'Type',
    'Title',
    'Category',
    'Amount',
    'Currency',
    'Currency Symbol',
    'Amount Formatted',
    'Amount (Home)',
    'Home Currency',
    'Home Formatted',
    'FX Rate',
    'Room',
    'Notes',
    'Receipt URL',
    'AI Parsed',
  ];

  Future<File> exportCsv(List<Txn> transactions, ExportScope scope) async {
    final dir = await getTemporaryDirectory();
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final scopeSlug = scope.isRoom ? 'room' : 'personal';
    final path = '${dir.path}/loit_${scopeSlug}_export_$stamp.csv';
    await Isolate.run(() => _writeCsvIsolate(path, transactions, scope));
    return File(path);
  }

  /// [transactions] must span at most [maxPdfMonths] months -enforce in UI.
  Future<File> exportPdf(
    List<Txn> transactions,
    ExportScope scope,
  ) async {
    final dir = await getTemporaryDirectory();
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final scopeSlug = scope.isRoom ? 'room' : 'personal';
    final path = '${dir.path}/loit_${scopeSlug}_report_$stamp.pdf';

    // Load Unicode-capable fonts on main isolate (printing's cache uses
    // path_provider which is platform-channel only). Pass raw bytes into
    // the worker isolate so font cache + PDF build run off the UI thread.
    final regular = await PdfGoogleFonts.notoSansRegular() as pw.TtfFont;
    final bold = await PdfGoogleFonts.notoSansBold() as pw.TtfFont;
    final italic = await PdfGoogleFonts.notoSansItalic() as pw.TtfFont;
    final boldItalic =
        await PdfGoogleFonts.notoSansBoldItalic() as pw.TtfFont;
    final fonts = _PdfFontBytes(
      regular: regular.data,
      bold: bold.data,
      italic: italic.data,
      boldItalic: boldItalic.data,
    );

    await Isolate.run(
      () => _buildPdfIsolate(path, transactions, scope, fonts),
    );
    return File(path);
  }

  static Future<void> _buildPdfDocument(
    String path,
    List<Txn> transactions,
    ExportScope scope,
    _PdfFontBytes fonts,
  ) async {
    String fmtHome(num v) => formatMoney(v, scope.homeCurrency);
    final dateFmt = DateFormat('MMM d, yyyy');
    final shortDate = DateFormat('MMM d');

    double income = 0, expenses = 0, transfers = 0;
    for (final t in transactions) {
      final v = t.absAmountIn(scope.homeCurrency);
      if (t.isTransfer) {
        transfers += v;
      } else if (t.isIncome) {
        income += v;
      } else {
        expenses += v;
      }
    }
    final net = income - expenses;

    final categoryTotals = <String, double>{};
    final categoryCounts = <String, int>{};
    for (final t in transactions) {
      if (t.isTransfer || t.isIncome) continue;
      final k = t.category ?? 'other';
      categoryTotals[k] = (categoryTotals[k] ?? 0) + t.absAmountIn(scope.homeCurrency);
      categoryCounts[k] = (categoryCounts[k] ?? 0) + 1;
    }
    final catEntries = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final sorted = [...transactions]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    const brand = PdfColor.fromInt(0xFF0E6B5C);
    const ink = PdfColor.fromInt(0xFF101418);
    const muted = PdfColor.fromInt(0xFF6B7280);
    const subtle = PdfColor.fromInt(0xFFE5E7EB);
    const surface = PdfColor.fromInt(0xFFF9FAFB);
    const danger = PdfColor.fromInt(0xFFB42318);
    const success = PdfColor.fromInt(0xFF067647);

    final regularFont = pw.Font.ttf(fonts.regular);
    final boldFont = pw.Font.ttf(fonts.bold);
    final italicFont = pw.Font.ttf(fonts.italic);
    final boldItalicFont = pw.Font.ttf(fonts.boldItalic);
    final theme = pw.ThemeData.withFont(
      base: regularFont,
      bold: boldFont,
      italic: italicFont,
      boldItalic: boldItalicFont,
    );

    final doc = pw.Document(theme: theme);
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: theme,
        margin: const pw.EdgeInsets.fromLTRB(32, 36, 32, 36),
        header: (ctx) => ctx.pageNumber == 1
            ? pw.SizedBox()
            : pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 12),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('LOIT -${scope.label}',
                        style: pw.TextStyle(color: muted, fontSize: 9)),
                    pw.Text(
                        '${dateFmt.format(scope.start)} - ${dateFmt.format(scope.end)}',
                        style: pw.TextStyle(color: muted, fontSize: 9)),
                  ],
                ),
              ),
        footer: (ctx) => pw.Container(
          alignment: pw.Alignment.centerRight,
          margin: const pw.EdgeInsets.only(top: 12),
          child: pw.Text(
            'Page ${ctx.pageNumber} / ${ctx.pagesCount}',
            style: pw.TextStyle(color: muted, fontSize: 9),
          ),
        ),
        build: (ctx) => [
          pw.Container(
            padding: const pw.EdgeInsets.all(20),
            decoration: pw.BoxDecoration(
              color: brand,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('LOIT',
                    style: pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                        letterSpacing: 2)),
                pw.SizedBox(height: 4),
                pw.Text(
                    scope.isRoom
                        ? 'Room Expense Report'
                        : 'Personal Expense Report',
                    style: pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 22,
                        fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 6),
                pw.Text(scope.label,
                    style: pw.TextStyle(
                        color: PdfColors.white, fontSize: 12)),
                pw.SizedBox(height: 14),
                pw.Row(
                  children: [
                    _coverField('Period',
                        '${dateFmt.format(scope.start)} - ${dateFmt.format(scope.end)}'),
                    pw.SizedBox(width: 24),
                    _coverField('Currency',
                        '${currencySymbol(scope.homeCurrency)}  ${scope.homeCurrency}'),
                    pw.SizedBox(width: 24),
                    _coverField(
                        'Generated', dateFmt.format(DateTime.now())),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 18),

          if (scope.accounts.isNotEmpty) ...[
            _sectionTitle('Accounts Standing', ink),
            pw.SizedBox(height: 6),
            ..._accountsBlock(
                scope.accounts, scope.homeCurrency, surface, subtle, ink, muted, success, danger),
            pw.SizedBox(height: 18),
          ],

          _sectionTitle('Period Summary', ink),
          pw.SizedBox(height: 6),
          pw.Row(
            children: [
              pw.Expanded(
                  child: _summaryCard('Transactions',
                      '${transactions.length}', ink, surface, subtle)),
              pw.SizedBox(width: 8),
              pw.Expanded(
                  child: _summaryCard('Income', fmtHome(income), success,
                      surface, subtle)),
              pw.SizedBox(width: 8),
              pw.Expanded(
                  child: _summaryCard('Expenses', fmtHome(expenses),
                      danger, surface, subtle)),
              pw.SizedBox(width: 8),
              pw.Expanded(
                  child: _summaryCard(
                      'Net',
                      fmtHome(net),
                      net >= 0 ? success : danger,
                      surface,
                      subtle)),
            ],
          ),
          if (transfers > 0) ...[
            pw.SizedBox(height: 8),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                  horizontal: 10, vertical: 6),
              decoration: pw.BoxDecoration(
                color: surface,
                border: pw.Border.all(color: subtle),
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Row(children: [
                pw.Text('Transfers',
                    style: pw.TextStyle(color: muted, fontSize: 9)),
                pw.SizedBox(width: 8),
                pw.Text(fmtHome(transfers),
                    style: pw.TextStyle(
                        color: ink,
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold)),
              ]),
            ),
          ],
          pw.SizedBox(height: 18),

          if (catEntries.isNotEmpty) ...[
            _sectionTitle('Spending by Category', ink),
            pw.SizedBox(height: 6),
            pw.TableHelper.fromTextArray(
              cellAlignment: pw.Alignment.centerLeft,
              cellAlignments: {
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.centerRight,
                2: pw.Alignment.centerRight,
                3: pw.Alignment.centerRight,
              },
              headerStyle: pw.TextStyle(
                  color: muted,
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold),
              headerDecoration: const pw.BoxDecoration(color: surface),
              cellStyle: pw.TextStyle(color: ink, fontSize: 10),
              cellPadding: const pw.EdgeInsets.symmetric(
                  horizontal: 8, vertical: 6),
              border: pw.TableBorder(
                horizontalInside:
                    pw.BorderSide(color: subtle, width: 0.5),
                top: pw.BorderSide(color: subtle, width: 0.5),
                bottom: pw.BorderSide(color: subtle, width: 0.5),
              ),
              headers: const ['Category', 'Count', 'Total', 'Share'],
              data: [
                for (final e in catEntries)
                  [
                    _humanizeCategory(e.key),
                    '${categoryCounts[e.key] ?? 0}',
                    fmtHome(e.value),
                    expenses <= 0
                        ? '-'
                        : '${((e.value / expenses) * 100).toStringAsFixed(1)}%',
                  ],
              ],
            ),
            pw.SizedBox(height: 18),
          ],

          _sectionTitle('Transactions (${transactions.length})', ink),
          pw.SizedBox(height: 6),
          pw.TableHelper.fromTextArray(
            cellAlignments: {
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.centerLeft,
              2: pw.Alignment.centerLeft,
              3: pw.Alignment.centerLeft,
              4: pw.Alignment.centerLeft,
              5: pw.Alignment.centerRight,
              6: pw.Alignment.centerRight,
            },
            headerStyle: pw.TextStyle(
                color: muted,
                fontSize: 9,
                fontWeight: pw.FontWeight.bold),
            headerDecoration: const pw.BoxDecoration(color: surface),
            cellStyle: pw.TextStyle(color: ink, fontSize: 9),
            cellPadding:
                const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
            border: pw.TableBorder(
              horizontalInside:
                  pw.BorderSide(color: subtle, width: 0.5),
              top: pw.BorderSide(color: subtle, width: 0.5),
              bottom: pw.BorderSide(color: subtle, width: 0.5),
            ),
            columnWidths: {
              0: const pw.FixedColumnWidth(54),
              1: const pw.FixedColumnWidth(48),
              2: const pw.FlexColumnWidth(2.4),
              3: const pw.FlexColumnWidth(1.4),
              4: const pw.FlexColumnWidth(1.6),
              5: const pw.FlexColumnWidth(1.5),
              6: const pw.FlexColumnWidth(1.5),
            },
            headers: scope.isRoom
                ? const [
                    'Date',
                    'Type',
                    'Title',
                    'Category',
                    'Member',
                    'Amount',
                    'Home',
                  ]
                : const [
                    'Date',
                    'Type',
                    'Title',
                    'Category',
                    'Room',
                    'Amount',
                    'Home',
                  ],
            data: [
              for (final t in sorted)
                [
                  shortDate.format(t.createdAt.toLocal()),
                  _typeBadge(t.type),
                  (t.notes ?? '').trim(),
                  _humanizeCategory(t.category ?? '-'),
                  t.roomName ?? (scope.isRoom ? '-' : 'Personal'),
                  _signedAmount(t),
                  t.fxSnapshot.containsKey(scope.homeCurrency)
                      ? _signedHome(t, scope.homeCurrency)
                      : '-',
                ],
            ],
          ),
          pw.SizedBox(height: 12),
          pw.Text(
            'Amounts shown in their original currency. "Home" column is converted to ${currencySymbol(scope.homeCurrency)} ${scope.homeCurrency}.',
            style: pw.TextStyle(color: muted, fontSize: 8),
          ),
        ],
      ),
    );
    final bytes = await doc.save();
    await File(path).writeAsBytes(bytes);
  }

  static pw.Widget _coverField(String label, String value) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(label.toUpperCase(),
            style: pw.TextStyle(
                color: PdfColors.white,
                fontSize: 8,
                letterSpacing: 1)),
        pw.SizedBox(height: 2),
        pw.Text(value,
            style: pw.TextStyle(
                color: PdfColors.white,
                fontSize: 11,
                fontWeight: pw.FontWeight.bold)),
      ],
    );
  }

  static pw.Widget _summaryCard(String label, String value,
      PdfColor accent, PdfColor surface, PdfColor border) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: surface,
        border: pw.Border.all(color: border),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(label.toUpperCase(),
              style: pw.TextStyle(
                  color: const PdfColor.fromInt(0xFF6B7280),
                  fontSize: 8,
                  letterSpacing: 1)),
          pw.SizedBox(height: 4),
          pw.Text(value,
              style: pw.TextStyle(
                  color: accent,
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }

  static pw.Widget _sectionTitle(String text, PdfColor color) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 4),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(
              color: PdfColor.fromInt(0xFFE5E7EB), width: 1),
        ),
      ),
      child: pw.Text(text,
          style: pw.TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: pw.FontWeight.bold)),
    );
  }

  static List<pw.Widget> _accountsBlock(
    List<AccountSnapshot> accounts,
    String home,
    PdfColor surface,
    PdfColor border,
    PdfColor ink,
    PdfColor muted,
    PdfColor success,
    PdfColor danger,
  ) {
    final assets = accounts.where((a) => a.kind == AccountKind.asset).toList()
      ..sort((a, b) => b.balanceHome.compareTo(a.balanceHome));
    final liabilities = accounts
        .where((a) => a.kind == AccountKind.liability)
        .toList()
      ..sort((a, b) => a.balanceHome.compareTo(b.balanceHome));
    final assetTotal =
        assets.fold<double>(0, (s, a) => s + a.balanceHome);
    final liabTotal =
        liabilities.fold<double>(0, (s, a) => s + a.balanceHome);
    final netWorth = assetTotal + liabTotal;

    String fmt(num v) => formatMoney(v, home);

    return [
      pw.Row(
        children: [
          pw.Expanded(
              child: _summaryCard(
                  'Assets', fmt(assetTotal), success, surface, border)),
          pw.SizedBox(width: 8),
          pw.Expanded(
              child: _summaryCard('Liabilities', fmt(liabTotal),
                  danger, surface, border)),
          pw.SizedBox(width: 8),
          pw.Expanded(
              child: _summaryCard(
                  'Net Worth',
                  fmt(netWorth),
                  netWorth >= 0 ? success : danger,
                  surface,
                  border)),
        ],
      ),
      pw.SizedBox(height: 8),
      pw.TableHelper.fromTextArray(
        cellAlignments: {
          0: pw.Alignment.centerLeft,
          1: pw.Alignment.centerLeft,
          2: pw.Alignment.centerRight,
        },
        headerStyle: pw.TextStyle(
            color: muted,
            fontSize: 9,
            fontWeight: pw.FontWeight.bold),
        headerDecoration: pw.BoxDecoration(color: surface),
        cellStyle: pw.TextStyle(color: ink, fontSize: 10),
        cellPadding:
            const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        border: pw.TableBorder(
          horizontalInside: pw.BorderSide(color: border, width: 0.5),
          top: pw.BorderSide(color: border, width: 0.5),
          bottom: pw.BorderSide(color: border, width: 0.5),
        ),
        columnWidths: {
          0: const pw.FlexColumnWidth(2.4),
          1: const pw.FlexColumnWidth(1.2),
          2: const pw.FlexColumnWidth(1.4),
        },
        headers: const ['Account', 'Type', 'Balance'],
        data: [
          for (final a in [...assets, ...liabilities])
            [
              a.name,
              a.kind == AccountKind.asset ? 'Asset' : 'Liability',
              fmt(a.balanceHome),
            ],
        ],
      ),
    ];
  }

  static String _humanizeCategory(String key) {
    if (key.isEmpty || key == '-') return key;
    return key
        .split('_')
        .map((w) =>
            w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  static String _typeBadge(String type) {
    switch (type) {
      case 'income':
        return '+ Income';
      case 'transfer':
        return '~ Transfer';
      default:
        return '- Expense';
    }
  }

  static String _signedAmount(Txn t) {
    final body = formatMoney(t.amount.abs(), t.currency);
    if (t.isIncome) return '+$body';
    if (t.isTransfer) return body;
    return '-$body';
  }

  static String _signedHome(Txn t, String home) {
    final body = formatMoney(t.absAmountIn(home), home);
    if (t.isIncome) return '+$body';
    if (t.isTransfer) return body;
    return '-$body';
  }
}
