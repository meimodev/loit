import 'dart:io';

int maxLines = 10;

void main(List<String> args) {
  if (args.isNotEmpty) {
    final n = int.tryParse(args.first);
    if (n != null && n >= 0) maxLines = n;
  }

  final rawStrings = <String>[];
  final entries = Directory('lib/features').listSync(recursive: true).whereType<File>();

  for (final file in entries) {
    if (!file.path.endsWith('.dart')) continue;
    if (file.path.contains('test') || file.path.contains('_test.dart')) continue;

    final content = file.readAsStringSync();
    final regex = RegExp(r"Text\('([A-Z][^']*)'\)");
    for (final match in regex.allMatches(content)) {
      rawStrings.add('${file.path}: ${match.group(1)}');
    }
    // Also catch "const Text('...')"
    final constRegex = RegExp(r"const Text\('([A-Z][^']*)'\)");
    for (final match in constRegex.allMatches(content)) {
      rawStrings.add('${file.path}: ${match.group(1)}');
    }
  }

  if (rawStrings.isEmpty) {
    stderr.writeln('✅ No unlocalized hardcoded English strings found.');
    exit(0);
  }

  stderr.writeln('⚠️  Found ${rawStrings.length} potential unlocalized string(s):');
  for (final s in rawStrings.take(maxLines)) {
    stderr.writeln('  $s');
  }
  if (rawStrings.length > maxLines) {
    stderr.writeln('  ... and ${rawStrings.length - maxLines} more.');
  }

  exit(rawStrings.length <= 10 ? 0 : 1);
}
