import 'package:flutter_test/flutter_test.dart';
import 'package:loit/core/services/room_service.dart';
import 'package:loit/features/rooms/church/church_presets.dart';

// ponytail: one check on the key-generation path — a church category whose
// slug breaks `room_categories_key_format` would fail the batch insert at
// runtime (ADR 0019). Mirrors the SQL regex: ^room:<id>:[a-z0-9_]+$.
void main() {
  final keyBody = RegExp(r'^[a-z0-9_]+$');

  test('every preset category slugs to a valid room_categories key body', () {
    for (final entry in denominationPresets.entries) {
      for (final name in entry.value.penerimaan) {
        final slug = RoomService.categorySlug(name, 'income');
        expect(keyBody.hasMatch(slug), isTrue,
            reason: '${entry.key} income "$name" -> "$slug"');
        expect(slug.startsWith('income_'), isTrue);
      }
      for (final name in entry.value.pengeluaran) {
        final slug = RoomService.categorySlug(name, 'expense');
        expect(keyBody.hasMatch(slug), isTrue,
            reason: '${entry.key} expense "$name" -> "$slug"');
      }
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
