import 'dart:math' as math;

import 'package:flutter/material.dart';

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
  });

  /// 0=Home, 1=Tx, 3=Rooms, 4=Settings. Index 2 is reserved for the scan FAB.
  final int currentIndex;
  final ValueChanged<int> onTap;
  final VoidCallback onScan;

  /// When non-null the user is inside a specific room, so the scan FAB is
  /// re-skinned with this accent + a group-context badge to signal the scan
  /// will land in that room rather than the personal feed.
  final Color? scanRoomAccent;

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
                  Icons.receipt_long_rounded, 'Tx'),
              _ScanFab(onTap: onScan, roomAccent: scanRoomAccent),
              _item(context, 3, Icons.groups_outlined, Icons.groups_rounded,
                  'Rooms'),
              _item(context, 4, Icons.settings_outlined, Icons.settings_rounded,
                  'Settings'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _item(BuildContext context, int idx, IconData off, IconData on,
      String label) {
    final c = context.loitColors;
    final selected = currentIndex == idx;
    final color = selected ? c.brand : c.contentSecondary;
    return Expanded(
      child: InkWell(
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
      ),
    );
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
