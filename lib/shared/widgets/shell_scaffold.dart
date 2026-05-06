import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'loit_tab_bar.dart';

/// LOIT bottom-nav shell. Backed by `StatefulShellRoute.indexedStack` so each
/// tab keeps its own navigation stack across switches.
///
/// Branch order: 0=Home, 1=Transactions, 2=Rooms, 3=Settings.
/// LoitTabBar slot 2 (center) is the Scan FAB — pushed on top, not a branch.
class ShellScaffold extends StatelessWidget {
  const ShellScaffold({super.key, required this.navigationShell});
  final StatefulNavigationShell navigationShell;

  /// Map LoitTabBar slot (0..4) to branch index. Slot 2 is FAB → no branch.
  static const _slotToBranch = <int, int>{0: 0, 1: 1, 3: 2, 4: 3};
  static const _branchToSlot = <int, int>{0: 0, 1: 1, 2: 3, 3: 4};

  void _onTap(BuildContext context, int slot) {
    final branch = _slotToBranch[slot];
    if (branch == null) return;
    navigationShell.goBranch(
      branch,
      // Tapping the active tab pops to its branch root.
      initialLocation: branch == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeSlot =
        _branchToSlot[navigationShell.currentIndex] ?? 0;
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: LoitTabBar(
        currentIndex: activeSlot,
        onTap: (slot) => _onTap(context, slot),
        onScan: () {
          // Detect if user is currently inside a specific room — if so,
          // forward roomId so scanner locks to that room.
          final loc = GoRouterState.of(context).uri.path;
          final m = RegExp(r'^/rooms/([^/]+)$').firstMatch(loc);
          final roomId = m?.group(1);
          context.push(
            roomId != null ? '/scan?roomId=$roomId' : '/scan',
          );
        },
      ),
    );
  }
}
