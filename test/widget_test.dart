import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:loit/app.dart';

void main() {
  testWidgets('LoitApp bootstraps and renders the placeholder shell', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: LoitApp()));
    await tester.pump();

    expect(find.text('LOIT'), findsOneWidget);
  });
}
