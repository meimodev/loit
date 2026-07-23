import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:showcaseview/showcaseview.dart';

import '../../core/services/coach_mark_store.dart';
import '../../features/rooms/room_colors.dart';
import '../../l10n/l10n_x.dart';
import '../providers/open_room_provider.dart';
import 'loit_sheet.dart';
import 'loit_tab_bar.dart';

/// LOIT bottom-nav shell. Backed by `StatefulShellRoute.indexedStack` so each
/// tab keeps its own navigation stack across switches.
///
/// Branch order: 0=Home, 1=Transactions, 2=Rooms, 3=Settings.
/// LoitTabBar slot 2 (center) is the Scan FAB — pushed on top, not a branch.
class ShellScaffold extends ConsumerStatefulWidget {
  const ShellScaffold({super.key, required this.navigationShell});
  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<ShellScaffold> createState() => _ShellScaffoldState();
}

class _ShellScaffoldState extends ConsumerState<ShellScaffold> {
  /// Map LoitTabBar slot (0..4) to branch index. Slot 2 is FAB → no branch.
  static const _slotToBranch = <int, int>{0: 0, 1: 1, 3: 2, 4: 3};
  static const _branchToSlot = <int, int>{0: 0, 1: 1, 2: 3, 3: 4};

  /// Window during which a second back press exits. Standard Android double-
  /// back-to-exit feel.
  static const _exitWindow = Duration(seconds: 2);

  /// Showcase scope for the **Capture coach mark** (CONTEXT.md). Distinct from
  /// the room-detail scope so the two registrations never collide.
  static const _coachScope = 'shell';
  final _scanCoachKey = GlobalKey();
  final _txCoachKey = GlobalKey();
  final _roomsCoachKey = GlobalKey();

  /// Flags to mark seen when the (possibly combined) shell tour finishes —
  /// populated in the post-frame check to match exactly what was shown.
  final _pendingSeen = <String>[];

  DateTime? _lastBackPress;

  @override
  void initState() {
    super.initState();
    ShowcaseView.register(
      scope: _coachScope,
      onFinish: () {
        for (final key in _pendingSeen) {
          CoachMarkStore.markSeen(key);
        }
      },
    );
    // Fire once per install on first shell render, before the Rooms intro's
    // later value-moment trigger can contend for the screen. Capture FAB, then
    // the Tx + Rooms nav spotlights — as one sequence for a first-time user,
    // or just the unseen portion for someone upgrading from an older build.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final sawCapture = await CoachMarkStore.wasSeen(CoachMarkStore.captureFab);
      final sawNav = await CoachMarkStore.wasSeen(CoachMarkStore.navCoach);
      if (!mounted || (sawCapture && sawNav)) return;
      final keys = <GlobalKey>[];
      if (!sawCapture) {
        keys.add(_scanCoachKey);
        _pendingSeen.add(CoachMarkStore.captureFab);
      }
      if (!sawNav) {
        keys.addAll([_txCoachKey, _roomsCoachKey]);
        _pendingSeen.add(CoachMarkStore.navCoach);
      }
      ShowcaseView.getNamed(_coachScope).startShowCase(keys);
    });
  }

  @override
  void dispose() {
    ShowcaseView.getNamed(_coachScope).unregister();
    super.dispose();
  }

  void _onTap(int slot) {
    final branch = _slotToBranch[slot];
    if (branch == null) return;
    widget.navigationShell.goBranch(
      branch,
      // Tapping the active tab pops to its branch root.
      initialLocation: branch == widget.navigationShell.currentIndex,
    );
  }

  // Center FAB opens a capture-mode chooser (ADR-0022): scan, voice, or manual.
  void _showCaptureSheet(String? roomId) {
    final l = context.l10n;
    final roomQuery = roomId != null ? '?roomId=$roomId' : '';
    showLoitSheet<void>(
      context,
      builder: (sheetCtx) => LoitSheet(
        title: l.captureSheetTitle,
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.document_scanner_outlined),
                title: Text(l.captureScan),
                onTap: () {
                  Navigator.pop(sheetCtx);
                  context.push('/scan$roomQuery');
                },
              ),
              ListTile(
                leading: const Icon(Icons.mic_none_rounded),
                title: Text(l.captureVoice),
                onTap: () {
                  Navigator.pop(sheetCtx);
                  context.push('/voice$roomQuery');
                },
              ),
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: Text(l.captureManual),
                onTap: () {
                  Navigator.pop(sheetCtx);
                  context.push(
                    '/transactions/new',
                    extra: roomId != null ? {'_room_id': roomId} : null,
                  );
                },
              ),
            ],
          ),
        ),
      ),
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
    final activeSlot = _branchToSlot[widget.navigationShell.currentIndex] ?? 0;
    final loc = GoRouterState.of(context).uri.path;
    // Scope capture (and the FAB accent) to a room only while the Rooms branch
    // is the visible screen. indexedStack keeps a room detail alive in the
    // background, so a path match alone leaks room scope onto other tabs — the
    // manual capture would silently become a room transaction (branch 2=Rooms).
    final onRoomsBranch = widget.navigationShell.currentIndex == 2;
    final activeRoomId = onRoomsBranch
        ? RegExp(r'^/rooms/([^/]+)$').firstMatch(loc)?.group(1)
        : null;
    // Rooms tab tint persists while a room detail is alive in any branch, even
    // when it's not the active screen (unlike the path-based FAB accent below,
    // which stays room-scoped only while you're actually viewing the room).
    final openRoomId = ref.watch(openRoomIdProvider);
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
          scanRoomAccent: activeRoomId != null
              ? RoomColors.forId(activeRoomId)
              : null,
          roomsTabAccent:
              openRoomId != null ? RoomColors.forId(openRoomId) : null,
          onTap: _onTap,
          onScan: () => _showCaptureSheet(activeRoomId),
          scanShowcaseKey: _scanCoachKey,
          scanShowcaseScope: _coachScope,
          scanShowcaseDescription: context.l10n.coachCapture,
          txShowcaseKey: _txCoachKey,
          roomsShowcaseKey: _roomsCoachKey,
          txShowcaseDescription: context.l10n.coachNavTx,
          roomsShowcaseDescription: context.l10n.coachNavRooms,
        ),
      ),
    );
  }
}
