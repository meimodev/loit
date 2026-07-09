import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loit/shared/widgets/loit_tab_bar.dart';

// The Rooms slot (index 3) shows a top-edge bar in the open room's color while
// a room detail stays mounted (roomsTabAccent != null), even from another tab.
// No accent => no bar.
void main() {
  Widget harness({int currentIndex = 3, Color? accent}) => MaterialApp(
        home: Scaffold(
          bottomNavigationBar: LoitTabBar(
            currentIndex: currentIndex,
            onTap: (_) {},
            onScan: () {},
            roomsTabAccent: accent,
          ),
        ),
      );

  const roomBar = ValueKey('room-bar');

  testWidgets('shows room-color bar when a room is open', (tester) async {
    const accent = Color(0xFF7A4FBF);
    await tester.pumpWidget(harness(accent: accent));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byKey(roomBar), findsOneWidget);
    final bar = tester.widget<AnimatedContainer>(find.byKey(roomBar));
    expect((bar.decoration as BoxDecoration).color, accent);
  });

  testWidgets('no bar when not inside a room', (tester) async {
    await tester.pumpWidget(harness(accent: null));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byKey(roomBar), findsNothing);
  });
}
