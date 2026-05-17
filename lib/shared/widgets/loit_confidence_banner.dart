import 'package:flutter/material.dart';

import '../../core/services/scanner_service.dart';
import '../../core/theme/loit_colors.dart';
import '../../core/theme/loit_radius.dart';
import '../../core/theme/loit_spacing.dart';
import '../../core/theme/loit_typography.dart';

/// Step 7 — review-screen tone marker.
///
/// High confidence: subtle green success chip ("Looks good").
/// Medium: invisible (returns SizedBox.shrink — review screen stays neutral).
/// Low: amber warning ("Some details may need correction").
class LoitConfidenceBanner extends StatelessWidget {
  final ConfidenceBucket bucket;
  final String highLabel;
  final String lowLabel;

  const LoitConfidenceBanner({
    super.key,
    required this.bucket,
    required this.highLabel,
    required this.lowLabel,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.loitColors;
    switch (bucket) {
      case ConfidenceBucket.medium:
        return const SizedBox.shrink();
      case ConfidenceBucket.high:
        return _wrap(
          icon: Icons.check_circle,
          label: highLabel,
          fg: c.success,
          bg: c.successSurface,
        );
      case ConfidenceBucket.low:
        return _wrap(
          icon: Icons.warning_amber_rounded,
          label: lowLabel,
          fg: c.warning,
          bg: c.warningSurface,
        );
    }
  }

  Widget _wrap({
    required IconData icon,
    required String label,
    required Color fg,
    required Color bg,
  }) {
    return Builder(builder: (context) {
      return Container(
        margin: const EdgeInsets.fromLTRB(
          LoitSpacing.s4,
          LoitSpacing.s3,
          LoitSpacing.s4,
          LoitSpacing.s2,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: LoitSpacing.s3,
          vertical: LoitSpacing.s2,
        ),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(LoitRadius.m),
        ),
        child: Row(
          children: [
            Icon(icon, color: fg, size: 18),
            const SizedBox(width: LoitSpacing.s2),
            Expanded(
              child: Text(
                label,
                style: LoitTypography.bodyM.copyWith(color: fg),
              ),
            ),
          ],
        ),
      );
    });
  }
}
