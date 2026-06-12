import 'package:flutter/material.dart';

import '../../core/theme/loit_colors.dart';
import '../../core/theme/loit_palette_aliases.dart';
import '../../core/theme/loit_spacing.dart';
import '../../core/theme/loit_typography.dart';
import 'loit_category_avatar.dart';

/// Edge-to-edge transaction row.
/// 60pt min-height per design; bordered bottom unless last in group.
class LoitTxRow extends StatefulWidget {
  const LoitTxRow({
    super.key,
    required this.title,
    required this.amount,
    this.subAmount,
    this.categoryKey,
    this.subtitle,
    this.isIncome = false,
    this.isTransfer = false,
    this.accountLabel,
    this.amountColor,
    this.showDivider = true,
    this.onTap,
    this.onLongPress,
    this.trailingBadge,
    this.leadingSelector,
    this.roomBadge,
    this.accentStripeColor,
    this.leadingBadge,
  });

  final String title;
  final String amount;
  final String? subAmount;
  final String? categoryKey;
  final String? subtitle;
  final bool isIncome;
  final bool isTransfer;
  final String? accountLabel;
  final Color? amountColor;
  final bool showDivider;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Widget? trailingBadge;

  /// Optional widget shown at the very start of the row, ahead of the
  /// category avatar. Slides in/out horizontally via AnimatedSwitcher when
  /// it changes, used for the multi-select checkbox.
  final Widget? leadingSelector;

  /// Optional badge rendered below the subtitle. Used to surface the
  /// originating room for transactions inherited from a shared room.
  final Widget? roomBadge;

  /// Optional accent color rendered as a thin vertical stripe along the
  /// leading edge. Used to visually mark room-inherited transactions with
  /// the room's accent.
  final Color? accentStripeColor;

  /// Optional small widget overlaid on the bottom-right corner of the
  /// category avatar. Used in a room's Transactions tab to show the payer's
  /// avatar (who logged the room-account movement).
  final Widget? leadingBadge;

  @override
  State<LoitTxRow> createState() => _LoitTxRowState();
}

class _LoitTxRowState extends State<LoitTxRow> {
  bool _pressed = false;

  Widget _buildAvatar(LoitColors c) {
    final avatar = widget.isTransfer
        ? Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: c.contentSecondary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Icon(Icons.swap_horiz, size: 18, color: c.contentSecondary),
          )
        : LoitCategoryAvatar(categoryKey: widget.categoryKey, size: 36);
    if (widget.leadingBadge == null) return avatar;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        avatar,
        Positioned(right: -3, bottom: -3, child: widget.leadingBadge!),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.loitColors;
    final colorAmount = widget.amountColor ??
        (widget.isTransfer
            ? c.contentSecondary
            : widget.isIncome
                ? LoitStatusAliases.income(c)
                : LoitStatusAliases.expense(c));
    final effectiveSubtitle = widget.accountLabel != null
        ? (widget.subtitle != null
            ? '${widget.subtitle} · ${widget.accountLabel}'
            : widget.accountLabel)
        : widget.subtitle;
    final rowBody = Container(
      color: c.surface,
      padding: const EdgeInsets.symmetric(
        horizontal: LoitSpacing.s5,
        vertical: LoitSpacing.s4,
      ),
      child: Row(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            transitionBuilder: (child, anim) => SizeTransition(
              sizeFactor: anim,
              axis: Axis.horizontal,
              axisAlignment: -1,
              child: FadeTransition(opacity: anim, child: child),
            ),
            child: widget.leadingSelector ??
                const SizedBox.shrink(key: ValueKey('no-sel')),
          ),
          _buildAvatar(c),
          const SizedBox(width: LoitSpacing.s4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  softWrap: true,
                  style: LoitTypography.bodyM.copyWith(
                    color: c.contentPrimary,
                    fontWeight: FontWeight.w500,
                    height: 1.25,
                  ),
                ),
                if (effectiveSubtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    effectiveSubtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: LoitTypography.bodyS.copyWith(
                      color: c.contentTertiary,
                    ),
                  ),
                ],
                if (widget.roomBadge != null) ...[
                  const SizedBox(height: 4),
                  widget.roomBadge!,
                ],
              ],
            ),
          ),
          if (widget.trailingBadge != null) ...[
            widget.trailingBadge!,
            const SizedBox(width: LoitSpacing.s3),
          ],
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.amount,
                style:
                    LoitTypography.amountDefault.copyWith(color: colorAmount),
              ),
              if (widget.subAmount != null) ...[
                const SizedBox(height: 2),
                Text(
                  widget.subAmount!,
                  style: LoitTypography.bodyS
                      .copyWith(color: c.contentTertiary),
                ),
              ],
            ],
          ),
        ],
      ),
    );

    final row = widget.accentStripeColor == null
        ? rowBody
        : Stack(
            children: [
              rowBody,
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: Container(
                  width: 3,
                  color: widget.accentStripeColor,
                ),
              ),
            ],
          );

    final hasInteraction =
        widget.onTap != null || widget.onLongPress != null;
    final inkRow = !hasInteraction
        ? row
        : Material(
            color: c.surface,
            child: InkWell(
              onTap: widget.onTap,
              onLongPress: widget.onLongPress,
              onHighlightChanged: (v) {
                if (mounted) setState(() => _pressed = v);
              },
              child: AnimatedScale(
                scale: _pressed ? 0.97 : 1.0,
                duration: const Duration(milliseconds: 140),
                curve: Curves.easeOut,
                child: row,
              ),
            ),
          );

    if (!widget.showDivider) return inkRow;
    return Column(
      children: [
        inkRow,
        Container(
          height: 1,
          color: c.borderSubtle,
          margin: const EdgeInsets.only(left: LoitSpacing.s5 + 36 + LoitSpacing.s4),
        ),
      ],
    );
  }
}
