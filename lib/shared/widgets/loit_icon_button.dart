import 'package:flutter/material.dart';

import '../../core/theme/loit_colors.dart';
import '../../core/theme/loit_motion.dart';

enum _LoitIconButtonVariant { defaultV, tonal, filled }

class LoitIconButton extends StatefulWidget {
  const LoitIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.tooltip,
    required this.semanticLabel,
    this.size = 44,
    this.iconSize = 20,
  }) : _variant = _LoitIconButtonVariant.defaultV;

  const LoitIconButton.tonal({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.tooltip,
    required this.semanticLabel,
    this.size = 44,
    this.iconSize = 20,
  }) : _variant = _LoitIconButtonVariant.tonal;

  const LoitIconButton.filled({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.tooltip,
    required this.semanticLabel,
    this.size = 44,
    this.iconSize = 20,
  }) : _variant = _LoitIconButtonVariant.filled;

  final IconData icon;
  final VoidCallback? onPressed;
  final String tooltip;
  final String semanticLabel;
  final double size;
  final double iconSize;
  final _LoitIconButtonVariant _variant;

  @override
  State<LoitIconButton> createState() => _LoitIconButtonState();
}

class _LoitIconButtonState extends State<LoitIconButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final c = context.loitColors;
    final disabled = widget.onPressed == null;
    final (bg, fg) = _variantColors(c);
    final pressedBg = widget._variant == _LoitIconButtonVariant.defaultV
        ? c.contentPrimary.withValues(alpha: 0.08)
        : bg;

    return Semantics(
      button: true,
      enabled: !disabled,
      label: widget.semanticLabel,
      child: Tooltip(
        message: widget.tooltip,
        child: Opacity(
          opacity: disabled ? 0.4 : 1.0,
          child: GestureDetector(
            onTapDown: disabled ? null : (_) => setState(() => _pressed = true),
            onTapUp: disabled ? null : (_) => setState(() => _pressed = false),
            onTapCancel: disabled ? null : () => setState(() => _pressed = false),
            onTap: disabled ? null : widget.onPressed,
            child: AnimatedContainer(
              duration: LoitMotion.instant,
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                color: _pressed ? pressedBg : bg,
                shape: BoxShape.circle,
              ),
              child: Icon(widget.icon, size: widget.iconSize, color: fg),
            ),
          ),
        ),
      ),
    );
  }

  (Color bg, Color fg) _variantColors(LoitColors c) {
    switch (widget._variant) {
      case _LoitIconButtonVariant.defaultV:
        return (Colors.transparent, c.contentPrimary);
      case _LoitIconButtonVariant.tonal:
        return (c.muted, c.contentPrimary);
      case _LoitIconButtonVariant.filled:
        return (c.brand, c.contentInverse);
    }
  }
}
