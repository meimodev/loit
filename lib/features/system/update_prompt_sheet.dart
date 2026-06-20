import 'package:flutter/material.dart';

import '../../core/theme/loit_colors.dart';
import '../../core/theme/loit_spacing.dart';
import '../../core/theme/loit_typography.dart';
import '../../l10n/l10n_x.dart';
import '../../shared/widgets/loit_sheet.dart';

/// Dismissible update prompt for the Recommended and Optional update states
/// (ADR-0015). Returns `true` if the user chose to update, `false`/`null` if
/// dismissed. Copy is local l10n only — never server-driven.
Future<bool?> showUpdatePromptSheet(BuildContext context) {
  return showLoitSheet<bool>(
    context,
    useRootNavigator: true,
    builder: (ctx) {
      final c = ctx.loitColors;
      final l10n = ctx.l10n;
      return LoitSheet(
        title: l10n.updatePromptTitle,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: LoitSpacing.s2),
            Text(
              l10n.updatePromptBody,
              style: LoitTypography.bodyM
                  .copyWith(color: c.contentSecondary, height: 1.4),
            ),
            const SizedBox(height: LoitSpacing.s5),
            SizedBox(
              height: 52,
              child: FilledButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: Text(l10n.updatePromptUpdate),
              ),
            ),
            const SizedBox(height: LoitSpacing.s2),
            SizedBox(
              height: 48,
              child: TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text(l10n.updatePromptLater),
              ),
            ),
          ],
        ),
      );
    },
  );
}
