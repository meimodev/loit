import 'package:flutter/material.dart';

import '../../core/theme/loit_typography.dart';

/// Compact pill rendered below a transaction subtitle to surface the
/// originating room. Tinted by the room's accent so the row reads as
/// "inherited from room" at a glance.
class LoitRoomOriginBadge extends StatelessWidget {
  const LoitRoomOriginBadge({
    super.key,
    required this.accent,
    required this.name,
  });

  final Color accent;
  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withValues(alpha: 0.32)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 180),
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: LoitTypography.labelS.copyWith(
                color: accent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
