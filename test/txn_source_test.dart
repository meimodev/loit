import 'package:flutter_test/flutter_test.dart';
import 'package:loit/shared/providers/transactions_provider.dart';

Txn _row(String? source, {bool aiParsed = true}) => Txn.fromRow({
      'amount': 1000,
      'currency': 'IDR',
      'ai_parsed': aiParsed,
      'source': source,
      'created_at': '2026-07-09T00:00:00Z',
    });

void main() {
  test('each canonical value maps to its own source (ADR-0029)', () {
    expect(_row('manual', aiParsed: false).source, TxnSource.manual);
    expect(_row('image').source, TxnSource.image);
    expect(_row('voice').source, TxnSource.voice);
    expect(_row('telegram_text').source, TxnSource.telegramText);
    expect(_row('telegram_image').source, TxnSource.telegramImage);
    expect(_row('telegram_voice').source, TxnSource.telegramVoice);
  });

  test('legacy spellings still read, for offline rows queued pre-rename', () {
    expect(_row('scanned').source, TxnSource.image);
    expect(_row('bot_chat').source, TxnSource.telegramText);
    expect(_row('bot_image').source, TxnSource.telegramImage);
    expect(_row('bot_voice').source, TxnSource.telegramVoice);
  });

  test('null falls back to the ai_parsed guess; unknown does not', () {
    // Locally-queued rows predating the column: the guess is the backfill rule.
    expect(_row(null).source, TxnSource.image);
    expect(_row(null, aiParsed: false).source, TxnSource.manual);
    // The server answered with a value this build cannot read. Guessing here is
    // the defect that made 'voice' render as "Scanned".
    expect(_row('bot_carrier_pigeon').source, TxnSource.unknown);
  });

  test('unrecognised sources round-trip verbatim', () {
    // Undo-delete rewrites the whole row; it must not downgrade what it could
    // not parse.
    expect(_row('bot_carrier_pigeon').sourceRaw, 'bot_carrier_pigeon');
    expect(_row(null).sourceRaw, 'image');
  });

  test('export labels are canonical, and name the raw value when unknown', () {
    expect(txnSourceCanonicalLabel(TxnSource.image), 'Image');
    expect(txnSourceCanonicalLabel(TxnSource.telegramVoice), 'Telegram Voice');
    expect(
      txnSourceCanonicalLabel(TxnSource.unknown, raw: 'bot_carrier_pigeon'),
      'bot_carrier_pigeon',
    );
  });
}
