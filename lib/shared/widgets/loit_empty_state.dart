import 'package:flutter/material.dart';

import '../../core/theme/loit_colors.dart';
import '../../core/theme/loit_radius.dart';
import '../../core/theme/loit_spacing.dart';
import '../../core/theme/loit_typography.dart';
import 'loit_animations.dart';

/// Empty-state slot: icon bubble + title + body + optional CTA.
class LoitEmptyState extends StatelessWidget {
  const LoitEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.body,
    this.primaryCta,
    this.onPrimaryCta,
    this.secondaryCta,
    this.onSecondaryCta,
    this.compact = false,
  });

  final IconData icon;
  final String title;
  final String? body;
  final String? primaryCta;
  final VoidCallback? onPrimaryCta;
  final String? secondaryCta;
  final VoidCallback? onSecondaryCta;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final c = context.loitColors;
    final size = compact ? 56.0 : 72.0;
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: LoitSpacing.s7,
        vertical: compact ? LoitSpacing.s6 : LoitSpacing.s8,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          LoitFloating(
            amplitude: 4,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: c.muted,
                borderRadius: LoitRadius.brFull,
              ),
              child: Icon(icon, size: size * 0.45, color: c.contentTertiary),
            ),
          ),
          const SizedBox(height: LoitSpacing.s5),
          Text(title,
              textAlign: TextAlign.center,
              style: LoitTypography.titleM.copyWith(color: c.contentPrimary)),
          if (body != null) ...[
            const SizedBox(height: LoitSpacing.s3),
            Text(body!,
                textAlign: TextAlign.center,
                style: LoitTypography.bodyM
                    .copyWith(color: c.contentSecondary)),
          ],
          if (primaryCta != null) ...[
            const SizedBox(height: LoitSpacing.s5),
            FilledButton(
              onPressed: onPrimaryCta,
              child: Text(primaryCta!),
            ),
          ],
          if (secondaryCta != null) ...[
            const SizedBox(height: LoitSpacing.s3),
            TextButton(
              onPressed: onSecondaryCta,
              child: Text(secondaryCta!),
            ),
          ],
        ],
      ),
    );
  }
}
