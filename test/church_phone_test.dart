import 'package:flutter_test/flutter_test.dart';
import 'package:loit/features/rooms/church/church_onboarding_screen.dart';

// ponytail: one check on the phone normalize/group path (ADR 0019). Strict
// Indonesian mobile: 08xx / +62xx folded to national 08, 10–13 digits, stored
// as raw digits; display grouped every 4.
void main() {
  group('normalizeIndoMobile', () {
    test('accepts 08xx and strips formatting', () {
      expect(normalizeIndoMobile('0812 3456 7890'), '081234567890');
      expect(normalizeIndoMobile('0812-3456-78'), '0812345678'); // 10 digits
    });

    test('folds +62 / 62 country code to national 0', () {
      expect(normalizeIndoMobile('+62 812 3456 7890'), '081234567890');
      expect(normalizeIndoMobile('62812345678'), '0812345678');
    });

    test('rejects out-of-range length', () {
      expect(normalizeIndoMobile('0812345'), isNull); // too short
      expect(normalizeIndoMobile('081234567890123'), isNull); // too long
    });

    test('rejects non-08 numbers', () {
      expect(normalizeIndoMobile('0211234567'), isNull); // landline 021
      expect(normalizeIndoMobile('1234567890'), isNull);
      expect(normalizeIndoMobile(''), isNull);
    });
  });

  test('groupDigits4 inserts a space every 4 digits', () {
    expect(groupDigits4('081234567890'), '0812 3456 7890');
    expect(groupDigits4('0812'), '0812');
    expect(groupDigits4('08123'), '0812 3');
  });
}
