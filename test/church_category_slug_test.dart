import 'package:flutter_test/flutter_test.dart';
import 'package:loit/core/services/room_service.dart';
import 'package:loit/features/rooms/church/church_presets.dart';

// ponytail: one check on the key-generation path — a church category whose
// slug breaks `room_categories_key_format` would fail the batch insert at
// runtime (ADR 0021). Mirrors the SQL regex: ^room:<id>:[a-z0-9_]+$.
void main() {
  final keyBody = RegExp(r'^[a-z0-9_]+$');

  test('every chart-of-accounts category slugs to a valid key body', () {
    for (final cat in churchChartOfAccounts.penerimaan) {
      final slug = RoomService.categorySlug(cat.name, 'income');
      expect(keyBody.hasMatch(slug), isTrue,
          reason: 'income "${cat.name}" -> "$slug"');
      expect(slug.startsWith('income_'), isTrue);
    }
    for (final cat in churchChartOfAccounts.pengeluaran) {
      final slug = RoomService.categorySlug(cat.name, 'expense');
      expect(keyBody.hasMatch(slug), isTrue,
          reason: 'expense "${cat.name}" -> "$slug"');
    }
  });

  test('punctuation and spacing collapse to single underscores, trimmed', () {
    expect(RoomService.categorySlug('Kolekte Khusus (APP, dll)', 'expense'),
        'kolekte_khusus_app_dll');
    expect(RoomService.categorySlug('Dana Sosial / Diakonia', 'expense'),
        'dana_sosial_diakonia');
    expect(RoomService.categorySlug('Persepuluhan', 'income'),
        'income_persepuluhan');
  });
}
