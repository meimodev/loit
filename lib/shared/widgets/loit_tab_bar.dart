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
  });

  /// 0=Home, 1=Tx, 3=Rooms, 4=Settings. Index 2 is reserved for the scan FAB.
  final int currentIndex;
  final ValueChanged<int> onTap;
  final VoidCallback onScan;

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
              _scan(context),
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

  Widget _scan(BuildContext context) {
    final c = context.loitColors;
    return SizedBox(
      width: 72,
      child: Center(
        child: GestureDetector(
          onTap: onScan,
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: c.accent,
              shape: BoxShape.circle,
              boxShadow: LoitElevation.e2,
            ),
            child: Icon(Icons.qr_code_scanner_rounded,
                color: c.contentInverse, size: 26),
          ),
        ),
      ),
    );
  }
}
