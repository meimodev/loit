import 'package:flutter_test/flutter_test.dart';
import 'package:loit/features/transactions/notes_breakdown.dart';

// Canonical notes text with a Catatan line (ADR-0024): the Note must survive
// format → parse round trips, alone or alongside an item breakdown.
void main() {
  test('itemized breakdown with note round-trips', () {
    final text = formatBreakdown(const NotesBreakdown(
      merchant: 'Indomaret',
      items: [
        NotesBreakdownItem(name: 'Kopi', qty: 2, unitPrice: 12500, totalPrice: 25000),
        NotesBreakdownItem(name: 'Roti', totalPrice: 10000),
      ],
      total: 35000,
      currency: 'IDR',
      note: 'buat meeting kantor',
    ));
    final parsed = parseBreakdown(text);
    expect(parsed, isNotNull);
    expect(parsed!.merchant, 'Indomaret');
    expect(parsed.items, hasLength(2));
    expect(parsed.total, 35000);
    expect(parsed.note, 'buat meeting kantor');
  });

  test('note-only canonical parses (no items)', () {
    final text = formatBreakdown(const NotesBreakdown(
      merchant: 'parkir',
      items: [],
      note: 'buat acara kantor',
    ));
    expect(text, 'parkir\nCatatan: buat acara kantor');
    final parsed = parseBreakdown(text);
    expect(parsed, isNotNull);
    expect(parsed!.merchant, 'parkir');
    expect(parsed.items, isEmpty);
    expect(parsed.note, 'buat acara kantor');
  });

  test('parser accepts Note:/Notes: markers case-insensitively', () {
    for (final marker in ['Note', 'Notes', 'catatan', 'NOTE']) {
      final parsed = parseBreakdown('Warung\n- Nasi = Rp 15.000\n$marker: enak');
      expect(parsed?.note, 'enak', reason: marker);
    }
  });

  test('plain multi-line notes still not canonical', () {
    expect(parseBreakdown('just a note\nsecond line'), isNull);
  });

  test('breakdown without note keeps note null (legacy rows)', () {
    final parsed = parseBreakdown('Toko\n- Ayam = Rp 20.000\nTotal: Rp 20.000');
    expect(parsed, isNotNull);
    expect(parsed!.note, isNull);
  });
}
