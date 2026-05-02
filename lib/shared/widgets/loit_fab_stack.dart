import 'package:flutter/material.dart';

/// Vertical FAB stack: large primary (ochre) + small secondary above.
class LoitFabStack extends StatelessWidget {
  const LoitFabStack({
    super.key,
    required this.onPrimary,
    this.primaryIcon = Icons.add,
    this.primaryTooltip,
  });

  final VoidCallback onPrimary;
  final IconData primaryIcon;
  final String? primaryTooltip;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
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
