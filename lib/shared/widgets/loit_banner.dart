import 'package:flutter/material.dart';

import '../../core/theme/loit_colors.dart';
import '../../core/theme/loit_radius.dart';
import '../../core/theme/loit_spacing.dart';
import '../../core/theme/loit_typography.dart';

enum LoitBannerKind { info, warning, error, offline, success }

/// Inline banner with status side-bar, icon, title/body, optional action.
class LoitBanner extends StatelessWidget {
  const LoitBanner({
    super.key,
    required this.kind,
    required this.title,
    this.body,
    this.actionLabel,
    this.onAction,
    this.onDismiss,
    this.icon,
  });

  final LoitBannerKind kind;
  final String title;
  final String? body;
  final String? actionLabel;
  final VoidCallback? onAction;
  final VoidCallback? onDismiss;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final c = context.loitColors;
    final (Color tint, Color surf, IconData defaultIcon) = switch (kind) {
      LoitBannerKind.info => (c.info, c.infoSurface, Icons.info_outline),
      LoitBannerKind.warning => (
          c.warning,
          c.warningSurface,
          Icons.warning_amber_rounded
        ),
      LoitBannerKind.error => (
          c.danger,
          c.dangerSurface,
          Icons.error_outline_rounded
        ),
      LoitBannerKind.offline => (
          c.contentSecondary,
          c.muted,
          Icons.cloud_off_rounded
        ),
      LoitBannerKind.success => (
          c.success,
          c.successSurface,
          Icons.check_circle_outline_rounded
        ),
    };

    return Container(
      decoration: BoxDecoration(
        color: surf,
        borderRadius: LoitRadius.brM,
        border: Border.all(color: tint.withValues(alpha: 0.25)),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 4, color: tint),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  LoitSpacing.s4,
                  LoitSpacing.s4,
                  LoitSpacing.s3,
                  LoitSpacing.s4,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(icon ?? defaultIcon, color: tint, size: 20),
                    const SizedBox(width: LoitSpacing.s3),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title,
                              style: LoitTypography.bodyM.copyWith(
                                color: c.contentPrimary,
                                fontWeight: FontWeight.w600,
                              )),
                          if (body != null) ...[
                            const SizedBox(height: 2),
                            Text(body!,
                                style: LoitTypography.bodyS
                                    .copyWith(color: c.contentSecondary)),
                          ],
                          if (actionLabel != null) ...[
                            const SizedBox(height: LoitSpacing.s3),
                            GestureDetector(
                              onTap: onAction,
                              child: Text(actionLabel!,
                                  style: LoitTypography.bodyM.copyWith(
                                    color: tint,
                                    fontWeight: FontWeight.w600,
                                  )),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (onDismiss != null)
                      GestureDetector(
                        onTap: onDismiss,
                        child: Icon(Icons.close,
                            size: 18, color: c.contentTertiary),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
