import 'package:flutter/material.dart';

import '../../core/theme/loit_colors.dart';
import '../../core/theme/loit_motion.dart';
import '../../core/theme/loit_radius.dart';
import '../../core/theme/loit_spacing.dart';
import '../../core/theme/loit_typography.dart';

enum LoitButtonSize { s, m, l }

enum _LoitButtonVariant { primary, secondary, tertiary, destructive, destructiveSolid, ghost }

class LoitButton extends StatefulWidget {
  const LoitButton.primary({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.trailingIcon,
    this.size = LoitButtonSize.m,
    this.loading = false,
    this.fullWidth = false,
  }) : _variant = _LoitButtonVariant.primary;

  const LoitButton.secondary({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.trailingIcon,
    this.size = LoitButtonSize.m,
    this.loading = false,
    this.fullWidth = false,
  }) : _variant = _LoitButtonVariant.secondary;

  const LoitButton.tertiary({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.trailingIcon,
    this.size = LoitButtonSize.m,
    this.loading = false,
    this.fullWidth = false,
  }) : _variant = _LoitButtonVariant.tertiary;

  const LoitButton.destructive({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.trailingIcon,
    this.size = LoitButtonSize.m,
    this.loading = false,
    this.fullWidth = false,
  }) : _variant = _LoitButtonVariant.destructive;

  const LoitButton.destructiveSolid({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.trailingIcon,
    this.size = LoitButtonSize.m,
    this.loading = false,
    this.fullWidth = false,
  }) : _variant = _LoitButtonVariant.destructiveSolid;

  const LoitButton.ghost({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.trailingIcon,
    this.size = LoitButtonSize.m,
    this.loading = false,
    this.fullWidth = false,
  }) : _variant = _LoitButtonVariant.ghost;

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final IconData? trailingIcon;
  final LoitButtonSize size;
  final bool loading;
  final bool fullWidth;
  final _LoitButtonVariant _variant;

  @override
  State<LoitButton> createState() => _LoitButtonState();
}

class _LoitButtonState extends State<LoitButton> {
  bool _pressed = false;

  double get _height => switch (widget.size) {
        LoitButtonSize.s => 36,
        LoitButtonSize.m => 44,
        LoitButtonSize.l => 52,
      };

  double get _padH => switch (widget.size) {
        LoitButtonSize.s => LoitSpacing.s3,
        LoitButtonSize.m => LoitSpacing.s4,
        LoitButtonSize.l => LoitSpacing.s5,
      };

  double get _iconSize => switch (widget.size) {
        LoitButtonSize.s => 16,
        LoitButtonSize.m => 18,
        LoitButtonSize.l => 20,
      };

  TextStyle get _labelStyle => switch (widget.size) {
        LoitButtonSize.s => LoitTypography.bodyM.copyWith(fontWeight: FontWeight.w600),
        _ => LoitTypography.bodyL.copyWith(fontWeight: FontWeight.w600),
      };

  @override
  Widget build(BuildContext context) {
    final c = context.loitColors;
    final disabled = widget.onPressed == null || widget.loading;
    final (bg, fg, border) = _variantColors(c);

    final content = widget.loading
        ? SizedBox(
            width: _iconSize,
            height: _iconSize,
            child: CircularProgressIndicator(strokeWidth: 2, color: fg),
          )
        : Row(
            mainAxisSize: widget.fullWidth ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, size: _iconSize, color: fg),
                const SizedBox(width: LoitSpacing.s2),
              ],
              Flexible(
                child: Text(
                  widget.label,
                  style: _labelStyle.copyWith(color: fg),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              if (widget.trailingIcon != null) ...[
                const SizedBox(width: LoitSpacing.s2),
                Icon(widget.trailingIcon, size: _iconSize, color: fg),
              ],
            ],
          );

    return Semantics(
      button: true,
      enabled: !disabled,
      label: widget.loading ? 'Loading' : widget.label,
      child: Opacity(
        opacity: disabled ? 0.4 : 1.0,
        child: GestureDetector(
          onTapDown: disabled ? null : (_) => setState(() => _pressed = true),
          onTapUp: disabled ? null : (_) => setState(() => _pressed = false),
          onTapCancel: disabled ? null : () => setState(() => _pressed = false),
          onTap: disabled ? null : widget.onPressed,
          child: AnimatedScale(
            scale: _pressed ? 0.97 : 1.0,
            duration: LoitMotion.instant,
            curve: LoitMotion.easeInOut,
            child: AnimatedContainer(
              duration: LoitMotion.instant,
              height: _height,
              width: widget.fullWidth ? double.infinity : null,
              padding: EdgeInsets.symmetric(horizontal: _padH),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: LoitRadius.brM,
                border: border,
              ),
              child: Center(child: content),
            ),
          ),
        ),
      ),
    );
  }

  (Color bg, Color fg, BoxBorder? border) _variantColors(LoitColors c) {
    switch (widget._variant) {
      case _LoitButtonVariant.primary:
        return (c.brand, c.contentInverse, null);
      case _LoitButtonVariant.secondary:
        return (
          c.surface,
          c.brand,
          Border.all(color: c.borderStrong, width: 1.5),
        );
      case _LoitButtonVariant.tertiary:
        return (Colors.transparent, c.brand, null);
      case _LoitButtonVariant.destructive:
        return (c.dangerSurface, c.danger, null);
      case _LoitButtonVariant.destructiveSolid:
        return (c.danger, c.contentInverse, null);
      case _LoitButtonVariant.ghost:
        return (Colors.transparent, c.contentPrimary, null);
    }
  }
}
