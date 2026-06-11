import 'package:flutter/material.dart';

import '../../core/services/analytics_service.dart';
import '../../core/theme/loit_colors.dart';
import '../../core/theme/loit_radius.dart';
import '../../core/theme/loit_spacing.dart';
import '../../core/theme/loit_typography.dart';
import '../../l10n/l10n_x.dart';

/// Rooms intro bottom sheet. Surfaced once per user by app.dart's engagement
/// trigger (see ADR-0005). Fires a PostHog event on dismissal. Returns `true`
/// when the user tapped the "Create a room" CTA so the caller can route to the
/// create form.
Future<bool> showRoomsIntroDialog(BuildContext context) async {
  final c = context.loitColors;
  final created = await showModalBottomSheet<bool>(
    context: context,
    isDismissible: false,
    enableDrag: false,
    isScrollControlled: true,
    backgroundColor: c.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => const _RoomsIntroSheet(),
  );

  Analytics.roomsIntroSeen();
  return created ?? false;
}

class _RoomsIntroSheet extends StatelessWidget {
  const _RoomsIntroSheet();

  @override
  Widget build(BuildContext context) {
    final c = context.loitColors;
    final l = context.l10n;
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          left: LoitSpacing.s5,
          right: LoitSpacing.s5,
          top: LoitSpacing.s3,
          bottom: LoitSpacing.s5 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: c.borderSubtle,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: LoitSpacing.s4),
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: LoitPalette.teal100,
                borderRadius: LoitRadius.brM,
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.meeting_room_outlined,
                color: LoitPalette.teal700,
                size: 28,
              ),
            ),
            const SizedBox(height: LoitSpacing.s4),
            Text(
              l.roomsIntroTitle,
              style: LoitTypography.titleL.copyWith(
                color: c.contentPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: LoitSpacing.s2),
            Text(
              l.roomsIntroSubtitle,
              style: LoitTypography.bodyM.copyWith(color: c.contentSecondary),
            ),
            const SizedBox(height: LoitSpacing.s4),
            _Bullet(text: l.roomsIntroUseCase1),
            const SizedBox(height: LoitSpacing.s3),
            _Bullet(text: l.roomsIntroUseCase2),
            const SizedBox(height: LoitSpacing.s3),
            _Bullet(text: l.roomsIntroUseCase3),
            const SizedBox(height: LoitSpacing.s5),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(l.roomsIntroCreateCta),
              ),
            ),
            const SizedBox(height: LoitSpacing.s2),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(l.roomsIntroLaterCta),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.loitColors;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: LoitPalette.teal700,
              shape: BoxShape.circle,
            ),
          ),
        ),
        const SizedBox(width: LoitSpacing.s3),
        Expanded(
          child: Text(
            text,
            style: LoitTypography.bodyM.copyWith(color: c.contentPrimary),
          ),
        ),
      ],
    );
  }
}
