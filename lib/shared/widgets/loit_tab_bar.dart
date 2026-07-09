import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:showcaseview/showcaseview.dart';

import '../../core/theme/loit_colors.dart';
import '../../core/theme/loit_elevation.dart';
import '../../core/theme/loit_typography.dart';

/// 5-slot bottom nav per LOIT spec: Home · Transactions · Scan · Rooms · Settings.
/// The center slot is a raised accent button (scan). Side items behave as tabs.
class LoitTabBar extends StatelessWidget {
  const LoitTabBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.onScan,
    this.scanRoomAccent,
    this.roomsTabAccent,
    this.scanShowcaseKey,
    this.scanShowcaseScope,
    this.scanShowcaseDescription,
    this.txShowcaseKey,
    this.roomsShowcaseKey,
    this.txShowcaseDescription,
    this.roomsShowcaseDescription,
  });

  /// 0=Home, 1=Tx, 3=Rooms, 4=Settings. Index 2 is reserved for the scan FAB.
  final int currentIndex;
  final ValueChanged<int> onTap;
  final VoidCallback onScan;

  /// When non-null the user is inside a specific room, so the scan FAB is
  /// re-skinned with this accent + a group-context badge to signal the scan
  /// will land in that room rather than the personal feed.
  final Color? scanRoomAccent;

  /// When non-null, the Rooms nav tab (slot 3) carries a top-edge bar in this
  /// room's identity color. Unlike [scanRoomAccent] this persists across tab
  /// switches while a room detail stays mounted — a "you have this room open"
  /// marker, not the scan-target accent.
  final Color? roomsTabAccent;

  /// When set, the scan FAB is wrapped in a one-time discovery **coach mark**
  /// (CONTEXT.md "Capture coach mark") bound to [scanShowcaseScope].
  final GlobalKey? scanShowcaseKey;
  final String? scanShowcaseScope;
  final String? scanShowcaseDescription;

  /// **Nav coach mark** (CONTEXT.md) — Transactions + Rooms nav tabs, wrapped
  /// in the same [scanShowcaseScope] and sequenced after the capture FAB.
  final GlobalKey? txShowcaseKey;
  final GlobalKey? roomsShowcaseKey;
  final String? txShowcaseDescription;
  final String? roomsShowcaseDescription;

  @override
  Widget build(BuildContext context) {
    final c = context.loitColors;
    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(top: BorderSide(color: c.borderSubtle)),
        boxShadow: LoitElevation.e1,
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              _item(context, 0, Icons.home_outlined, Icons.home_rounded, 'Home'),
              _item(context, 1, Icons.receipt_long_outlined,
                  Icons.receipt_long_rounded, 'Tx',
                  showcaseKey: txShowcaseKey,
                  showcaseDescription: txShowcaseDescription),
              _buildScanFab(),
              _item(context, 3, Icons.groups_outlined, Icons.groups_rounded,
                  'Rooms',
                  showcaseKey: roomsShowcaseKey,
                  showcaseDescription: roomsShowcaseDescription),
              _item(context, 4, Icons.settings_outlined, Icons.settings_rounded,
                  'Settings'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScanFab() {
    final fab = _ScanFab(onTap: onScan, roomAccent: scanRoomAccent);
    final key = scanShowcaseKey;
    if (key == null) return fab;
    return Showcase(
      key: key,
      scope: scanShowcaseScope,
      description: scanShowcaseDescription,
      child: fab,
    );
  }

  Widget _item(BuildContext context, int idx, IconData off, IconData on,
      String label,
      {GlobalKey? showcaseKey, String? showcaseDescription}) {
    final c = context.loitColors;
    final selected = currentIndex == idx;
    final color = selected ? c.brand : c.contentSecondary;
    // Rooms slot (3) carries a top-edge bar in the open room's identity color
    // (persists across tab switches while the room stays open). Icon/label stay
    // `c.brand` for guaranteed contrast; the bar is the accent.
    final roomAccent = idx == 3 ? roomsTabAccent : null;
    Widget child = InkWell(
      onTap: () => onTap(idx),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(selected ? on : off, size: 24, color: color),
          const SizedBox(height: 2),
          Text(label,
              style: LoitTypography.labelM.copyWith(
                color: color,
                fontSize: 11,
              )),
        ],
      ),
    );
    if (showcaseKey != null) {
      child = Showcase(
        key: showcaseKey,
        scope: scanShowcaseScope,
        description: showcaseDescription,
        // Default gestures ON: the showcase overlay absorbs the tap to advance
        // the tour, so tapping the highlighted tab never switches branch.
        child: child,
      );
    }
    child = Stack(
      // Pass the slot's tight constraints through so the icon/label column
      // still fills the 64px height; the bar rides on top as a positioned peer.
      fit: StackFit.passthrough,
      children: [
        child,
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Center(
            // Enter/leave (null↔room) swaps the key → fade+scale. A room→room
            // change keeps the 'room-bar' key → AnimatedContainer cross-fades
            // the color instead. Both ~240ms, matching the FAB context swap.
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 240),
              transitionBuilder: (widget, anim) => FadeTransition(
                opacity: anim,
                child: ScaleTransition(scale: anim, child: widget),
              ),
              child: roomAccent == null
                  ? const SizedBox(key: ValueKey('no-room-bar'))
                  : AnimatedContainer(
                      key: const ValueKey('room-bar'),
                      duration: const Duration(milliseconds: 240),
                      width: 28,
                      height: 3,
                      decoration: BoxDecoration(
                        color: roomAccent,
                        borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(3),
                        ),
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
    return Expanded(child: child);
  }
}

/// Center scan FAB with a continuous idle pulse + animated transitions when
/// the room context (color/badge) changes.
class _ScanFab extends StatefulWidget {
  const _ScanFab({required this.onTap, this.roomAccent});
  final VoidCallback onTap;
  final Color? roomAccent;

  @override
  State<_ScanFab> createState() => _ScanFabState();
}

class _ScanFabState extends State<_ScanFab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _idle;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _idle = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
  }

  @override
  void dispose() {
    _idle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.loitColors;
    final inRoom = widget.roomAccent != null;
    final fill = inRoom ? widget.roomAccent! : c.accent;
    return SizedBox(
      width: 72,
      child: Center(
        child: GestureDetector(
          onTap: widget.onTap,
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) => setState(() => _pressed = false),
          onTapCancel: () => setState(() => _pressed = false),
          child: SizedBox(
            width: 72,
            height: 64,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                // Expanding halo — fades out as it grows. One pulse per cycle.
                AnimatedBuilder(
                  animation: _idle,
                  builder: (_, __) {
                    final t = _idle.value;
                    final size = 52 + 18 * t;
                    return Container(
                      width: size,
                      height: size,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: fill.withValues(alpha: 0.20 * (1 - t)),
                      ),
                    );
                  },
                ),
                // Core button — gentle sine breathe + press-down scale.
                AnimatedBuilder(
                  animation: _idle,
                  builder: (_, child) {
                    final breathe =
                        1.0 + 0.025 * math.sin(_idle.value * math.pi * 2);
                    final pressScale = _pressed ? 0.94 : 1.0;
                    return Transform.scale(
                      scale: breathe * pressScale,
                      child: child,
                    );
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeOut,
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: fill,
                      shape: BoxShape.circle,
                      boxShadow: LoitElevation.e2,
                    ),
                    child: Icon(Icons.qr_code_scanner_rounded,
                        color: c.contentInverse, size: 26),
                  ),
                ),
                // Group-context badge: scale+fade in/out on context swap.
                Positioned(
                  right: 6,
                  top: 4,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 240),
                    transitionBuilder: (child, anim) => ScaleTransition(
                      scale: anim,
                      child: FadeTransition(opacity: anim, child: child),
                    ),
                    child: inRoom
                        ? Container(
                            key: const ValueKey('room-badge'),
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: c.surface,
                              shape: BoxShape.circle,
                              border: Border.all(color: fill, width: 1.5),
                            ),
                            alignment: Alignment.center,
                            child: Icon(Icons.groups_rounded,
                                size: 12, color: fill),
                          )
                        : const SizedBox(
                            key: ValueKey('no-badge'),
                            width: 0,
                            height: 0,
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
