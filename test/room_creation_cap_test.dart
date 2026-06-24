import 'package:flutter_test/flutter_test.dart';
import 'package:loit/shared/providers/auth_providers.dart';

// ponytail: one check on the room-creation cap math (ADR 0020). Cap counts
// lifetime-created rooms; effective cap = tier base + purchased slots; slots
// are Pro-only.
UserProfile profile({
  required String tier,
  required int created,
  int slots = 0,
}) =>
    UserProfile(
      id: 'u',
      email: 'e@e',
      name: 'n',
      avatarUrl: null,
      homeCurrency: 'IDR',
      tier: tier,
      scansUsedThisMonth: 0,
      scanTopupBonusThisMonth: 0,
      hasUsedDemoScan: false,
      roomsCreatedTotal: created,
      roomSlotsPurchased: slots,
    );

void main() {
  group('room creation cap', () {
    test('base caps are Free 1 / Lite 3 / Pro 7', () {
      expect(profile(tier: 'free', created: 0).baseRoomCap, 1);
      expect(profile(tier: 'lite', created: 0).baseRoomCap, 3);
      expect(profile(tier: 'pro', created: 0).baseRoomCap, 7);
    });

    test('purchased slots raise only the effective cap', () {
      final p = profile(tier: 'pro', created: 7, slots: 2);
      expect(p.baseRoomCap, 7);
      expect(p.effectiveRoomCap, 9);
    });

    test('canCreateRoom is total < effective cap (monotonic, no refund)', () {
      expect(profile(tier: 'free', created: 0).canCreateRoom, isTrue);
      expect(profile(tier: 'free', created: 1).canCreateRoom, isFalse);
      // Pro at 7 is blocked until a slot is bought; the slot lifts the cap.
      expect(profile(tier: 'pro', created: 7).canCreateRoom, isFalse);
      expect(profile(tier: 'pro', created: 7, slots: 1).canCreateRoom, isTrue);
    });

    test('only Pro can buy room slots', () {
      expect(profile(tier: 'pro', created: 0).canPurchaseRoomSlot, isTrue);
      expect(profile(tier: 'lite', created: 0).canPurchaseRoomSlot, isFalse);
      expect(profile(tier: 'free', created: 0).canPurchaseRoomSlot, isFalse);
    });
  });
}
