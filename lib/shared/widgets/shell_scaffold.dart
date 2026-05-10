import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../features/rooms/room_colors.dart';
import '../../l10n/l10n_x.dart';
import 'loit_tab_bar.dart';

/// LOIT bottom-nav shell. Backed by `StatefulShellRoute.indexedStack` so each
/// tab keeps its own navigation stack across switches.
///
/// Branch order: 0=Home, 1=Transactions, 2=Rooms, 3=Settings.
/// LoitTabBar slot 2 (center) is the Scan FAB — pushed on top, not a branch.
class ShellScaffold extends StatefulWidget {
  const ShellScaffold({super.key, required this.navigationShell});
  final StatefulNavigationShell navigationShell;

  @override
  State<ShellScaffold> createState() => _ShellScaffoldState();
}

class _ShellScaffoldState extends State<ShellScaffold> {
  /// Map LoitTabBar slot (0..4) to branch index. Slot 2 is FAB → no branch.
  static const _slotToBranch = <int, int>{0: 0, 1: 1, 3: 2, 4: 3};
  static const _branchToSlot = <int, int>{0: 0, 1: 1, 2: 3, 3: 4};

  /// Window during which a second back press exits. Standard Android double-
  /// back-to-exit feel.
  static const _exitWindow = Duration(seconds: 2);

  DateTime? _lastBackPress;

  void _onTap(int slot) {
    final branch = _slotToBranch[slot];
    if (branch == null) return;
    widget.navigationShell.goBranch(
      branch,
      // Tapping the active tab pops to its branch root.
      initialLocation: branch == widget.navigationShell.currentIndex,
    );
  }

  void _handleRootBack() {
    final now = DateTime.now();
    final last = _lastBackPress;
    if (last != null && now.difference(last) < _exitWindow) {
      SystemNavigator.pop();
      return;
    }
    _lastBackPress = now;
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        duration: _exitWindow,
        content: Text(context.l10n.shellPressBack),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeSlot =
        _branchToSlot[widget.navigationShell.currentIndex] ?? 0;
    final loc = GoRouterState.of(context).uri.path;
    final activeRoomId =
        RegExp(r'^/rooms/([^/]+)$').firstMatch(loc)?.group(1);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _handleRootBack();
      },
      child: Scaffold(
        body: widget.navigationShell,
        bottomNavigationBar: LoitTabBar(
          currentIndex: activeSlot,
          scanRoomAccent:
              activeRoomId != null ? RoomColors.forId(activeRoomId) : null,
          onTap: _onTap,
          onScan: () {
            context.push(
              activeRoomId != null ? '/scan?roomId=$activeRoomId' : '/scan',
            );
          },
        ),
      ),
    );
  }
}
