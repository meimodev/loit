import 'package:flutter_test/flutter_test.dart';
import 'package:loit/features/rooms/church/church_cash_journal_service.dart';
import 'package:loit/shared/providers/accounts_provider.dart';
import 'package:loit/shared/providers/transactions_provider.dart';

Account _acct(String id, String name, double initial) => Account(
      id: id,
      roomId: 'room1',
      name: name,
      kind: AccountKind.asset,
      currency: 'IDR',
      initialBalance: initial,
      createdAt: DateTime(2026, 1, 1),
    );

Txn _txn({
  required String id,
  required double amount,
  required String type,
  required DateTime date,
  String? accountId,
  String? toAccountId,
}) =>
    Txn(
      id: id,
      amount: amount,
      currency: 'IDR',
      fxSnapshot: const {},
      category: 'cat',
      notes: null,
      receiptUrl: null,
      aiParsed: false,
      isManualFallback: false,
      createdAt: date,
      roomId: 'room1',
      type: type,
      accountId: accountId,
      toAccountId: toAccountId,
    );

void main() {
  test('BKU: carry-forward opening, transfer two legs, out-of-pocket excluded',
      () {
    final accounts = [
      _acct('tunai', 'Tunai', 500000),
      _acct('bank1', 'Bank 1', 0),
      _acct('bank2', 'Bank 2', 0), // never funded → omitted
    ];
    final txns = [
      // pre-range income into Tunai → part of Saldo Awal, not a row
      _txn(id: 'p1', amount: 100000, type: 'income', date: DateTime(2026, 6, 1), accountId: 'tunai'),
      _txn(id: 't1', amount: 1200000, type: 'income', date: DateTime(2026, 7, 3), accountId: 'tunai'),
      // transfer Tunai → Bank 1 (one row, two legs)
      _txn(id: 't2', amount: 1000000, type: 'transfer', date: DateTime(2026, 7, 12), accountId: 'tunai', toAccountId: 'bank1'),
      _txn(id: 't3', amount: 200000, type: 'expense', date: DateTime(2026, 7, 20), accountId: 'tunai'),
      // out-of-pocket: personal account, touches no room account → excluded
      _txn(id: 'oop', amount: 50000, type: 'expense', date: DateTime(2026, 7, 5), accountId: 'personal'),
    ];

    final sections = ChurchCashJournalService().buildSections(
      accounts: accounts,
      allTxns: txns,
      start: DateTime(2026, 7, 1),
      rangeEnd: DateTime(2026, 7, 31, 23, 59, 59),
      baseCurrency: 'IDR',
      categoryNames: const {},
    );

    // Bank 2 dropped (no movement, zero saldo).
    expect(sections.map((s) => s.accountName), ['Tunai', 'Bank 1']);

    final tunai = sections[0];
    expect(tunai.opening, 600000); // 500000 initial + 100000 pre-range
    expect(tunai.rows.length, 3); // out-of-pocket not counted
    expect(tunai.rows[0].penerimaan, 1200000);
    expect(tunai.rows[0].saldo, 1800000);
    expect(tunai.rows[1].pengeluaran, 1000000);
    expect(tunai.rows[1].uraian, 'Transfer ke Bank 1');
    expect(tunai.rows[1].saldo, 800000);
    expect(tunai.rows[2].pengeluaran, 200000);
    expect(tunai.closing, 600000);

    final bank1 = sections[1];
    expect(bank1.opening, 0);
    expect(bank1.rows.single.penerimaan, 1000000);
    expect(bank1.rows.single.uraian, 'Transfer dari Tunai');
    expect(bank1.closing, 1000000);
  });
}
