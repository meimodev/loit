import 'dart:convert';
import 'dart:io';

void main() {
  final en = jsonDecode(File('lib/l10n/app_en.arb').readAsStringSync()) as Map<String, dynamic>;
  final id = jsonDecode(File('lib/l10n/app_id.arb').readAsStringSync()) as Map<String, dynamic>;

  final enKeys = en.keys.where((k) => !k.startsWith('@')).toSet();
  final idKeys = id.keys.where((k) => !k.startsWith('@')).toSet();

  final missingInId = enKeys.difference(idKeys);
  final extraInId = idKeys.difference(enKeys);

  if (missingInId.isNotEmpty) {
    stderr.writeln('❌ Keys in app_en.arb missing from app_id.arb:');
    for (final k in missingInId) stderr.writeln('  - $k');
  }
  if (extraInId.isNotEmpty) {
    stderr.writeln('⚠️  Keys in app_id.arb not present in app_en.arb:');
    for (final k in extraInId) stderr.writeln('  - $k');
  }

  if (missingInId.isEmpty && extraInId.isEmpty) {
    print('✅ ARB parity OK: ${enKeys.length} keys in both locales.');
    exit(0);
  }

  exit(1);
}
