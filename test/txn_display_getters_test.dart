import 'package:flutter_test/flutter_test.dart';
import 'package:loit/shared/providers/transactions_provider.dart';

// ADR-0025: display getters read structured columns first and fall back to
// parsing the legacy canonical notes text.
void main() {
  Txn row(Map<String, dynamic> extra) => Txn.fromRow({
        'id': 'x',
        'amount': -35000,
        'currency': 'IDR',
        'created_at': '2026-07-05T10:00:00Z',
        ...extra,
      });

  test('structured row: merchant column + items join + pure note', () {
    final t = row({
      'merchant': 'Indomaret',
      'notes': 'buat meeting kantor',
      'transaction_items': [
        {'name': 'Kopi', 'qty': 2, 'unit_price': 12500, 'total_price': 25000},
        {'name': 'Roti', 'total_price': 10000},
      ],
    });
    expect(t.displayTitle, 'Indomaret');
    expect(t.displayNote, 'buat meeting kantor');
    expect(t.displayItems, hasLength(2));
    expect(t.displayItems.first.name, 'Kopi');
  });

  test('legacy canonical row: everything parsed from notes', () {
    final t = row({
      'notes':
          'Warung\n- Nasi : 2 × Rp 15.000 = Rp 30.000\nTotal: Rp 30.000\nCatatan: makan siang tim',
    });
    expect(t.displayTitle, 'Warung');
    expect(t.displayNote, 'makan siang tim');
    expect(t.displayItems, hasLength(1));
  });

  test('legacy plain-note row: notes is the note and the title fallback', () {
    final t = row({'notes': 'bayar parkir'});
    expect(t.displayTitle, 'bayar parkir');
    expect(t.displayNote, 'bayar parkir');
    expect(t.displayItems, isEmpty);
  });

  test('structured note-only row: no items, no breakdown', () {
    final t = row({'merchant': 'parkir', 'notes': 'buat acara kantor'});
    expect(t.displayTitle, 'parkir');
    expect(t.displayNote, 'buat acara kantor');
    expect(t.displayItems, isEmpty);
  });

  test('queued offline payload uses items key', () {
    final t = row({
      'items': [
        {'name': 'Ayam', 'total_price': 20000},
      ],
    });
    expect(t.displayItems, hasLength(1));
  });
}
