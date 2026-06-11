import 'package:flutter/material.dart';

import '../../core/theme/loit_colors.dart';
import '../../core/theme/loit_elevation.dart';
import '../../core/theme/loit_radius.dart';
import '../../core/theme/loit_spacing.dart';
import '../../core/theme/loit_typography.dart';

/// LOIT bottom sheet shell. Top-rounded (24), drag handle, optional title row.
/// Wrap child content; use with `showModalBottomSheet(isScrollControlled: true)`.
class LoitSheet extends StatelessWidget {
  const LoitSheet({
    super.key,
    required this.child,
    this.title,
    this.trailing,
    this.padding = const EdgeInsets.fromLTRB(
      LoitSpacing.s5,
      LoitSpacing.s4,
      LoitSpacing.s5,
      LoitSpacing.s6,
    ),
    this.maxHeightFactor = 0.92,
  });

  final Widget child;
  final String? title;
  final Widget? trailing;
  final EdgeInsets padding;
  final double maxHeightFactor;

  @override
  Widget build(BuildContext context) {
    final c = context.loitColors;
    final media = MediaQuery.of(context);
    return Container(
      constraints: BoxConstraints(
        maxHeight: media.size.height * maxHeightFactor,
      ),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: LoitRadius.brSheet,
        boxShadow: LoitElevation.e3,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: c.borderDefault,
                borderRadius: LoitRadius.brFull,
              ),
            ),
            if (title != null) ...[
              const SizedBox(height: LoitSpacing.s4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: LoitSpacing.s5),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(title!,
                          style: LoitTypography.titleM
                              .copyWith(color: c.contentPrimary)),
                    ),
                    if (trailing != null) trailing!,
                  ],
                ),
              ),
            ],
            Flexible(
              child: SingleChildScrollView(
                padding: padding,
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<T?> showLoitSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  bool isDismissible = true,
  bool enableDrag = true,
  bool useRootNavigator = false,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    isDismissible: isDismissible,
    enableDrag: enableDrag,
    // Root navigator so the sheet overlays a persistent shell bottom navbar
    // instead of rendering behind it.
    useRootNavigator: useRootNavigator,
    builder: builder,
  );
}
