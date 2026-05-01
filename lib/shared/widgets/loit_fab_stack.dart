import 'package:flutter/material.dart';

import '../../core/theme/loit_colors.dart';
import '../../core/theme/loit_elevation.dart';

/// Vertical FAB stack: large primary (ochre) + small secondary above.
class LoitFabStack extends StatelessWidget {
  const LoitFabStack({
    super.key,
    required this.onPrimary,
    required this.onSecondary,
    this.primaryIcon = Icons.add,
    this.secondaryIcon = Icons.receipt_long_outlined,
    this.primaryTooltip,
    this.secondaryTooltip,
  });

  final VoidCallback onPrimary;
  final VoidCallback onSecondary;
  final IconData primaryIcon;
  final IconData secondaryIcon;
  final String? primaryTooltip;
  final String? secondaryTooltip;

  @override
  Widget build(BuildContext context) {
    final c = context.loitColors;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          decoration: BoxDecoration(
            color: c.surface,
            shape: BoxShape.circle,
            border: Border.all(color: c.borderSubtle),
            boxShadow: LoitElevation.e2,
          ),
          child: IconButton(
            onPressed: onSecondary,
            icon: Icon(secondaryIcon, color: c.contentPrimary, size: 20),
            tooltip: secondaryTooltip,
            iconSize: 20,
          ),
        ),
        const SizedBox(height: 10),
        FloatingActionButton(
          heroTag: null,
          onPressed: onPrimary,
          tooltip: primaryTooltip,
          child: Icon(primaryIcon, size: 26),
        ),
      ],
    );
  }
}
