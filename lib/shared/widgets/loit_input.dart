import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/loit_colors.dart';
import '../../core/theme/loit_radius.dart';
import '../../core/theme/loit_typography.dart';

enum LoitInputSize { s, m, l }

/// Themed text input matching LOIT spec: 12 radius, 1px border default,
/// 2px brand border on focus, 2px danger on error.
class LoitInput extends StatefulWidget {
  const LoitInput({
    super.key,
    this.controller,
    this.label,
    this.placeholder,
    this.helper,
    this.error,
    this.leading,
    this.trailing,
    this.size = LoitInputSize.m,
    this.enabled = true,
    this.obscureText = false,
    this.keyboardType,
    this.inputFormatters,
    this.onChanged,
    this.onSubmitted,
    this.maxLines = 1,
    this.autofocus = false,
  });

  final TextEditingController? controller;
  final String? label;
  final String? placeholder;
  final String? helper;
  final String? error;
  final Widget? leading;
  final Widget? trailing;
  final LoitInputSize size;
  final bool enabled;
  final bool obscureText;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final int maxLines;
  final bool autofocus;

  @override
  State<LoitInput> createState() => _LoitInputState();
}

class _LoitInputState extends State<LoitInput> {
  final FocusNode _focus = FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() => _focused = _focus.hasFocus));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  double get _height => switch (widget.size) {
        LoitInputSize.s => 36,
        LoitInputSize.m => 44,
        LoitInputSize.l => 52,
      };

  @override
  Widget build(BuildContext context) {
    final c = context.loitColors;
    final hasError = widget.error != null;
    final disabled = !widget.enabled;

    Color borderColor;
    double borderWidth;
    if (disabled) {
      borderColor = c.borderSubtle;
      borderWidth = 1;
    } else if (hasError) {
      borderColor = c.borderDanger;
      borderWidth = 2;
    } else if (_focused) {
      borderColor = c.borderFocus;
      borderWidth = 2;
    } else {
      borderColor = c.borderDefault;
      borderWidth = 1;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null) ...[
          Text(widget.label!,
              style: LoitTypography.bodyM.copyWith(
                color: c.contentPrimary,
                fontWeight: FontWeight.w600,
              )),
          const SizedBox(height: 6),
        ],
        Container(
          constraints: BoxConstraints(minHeight: _height),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: disabled ? c.muted : c.surface,
            borderRadius: LoitRadius.brM,
            border: Border.all(color: borderColor, width: borderWidth),
          ),
          child: Row(
            children: [
              if (widget.leading != null) ...[
                IconTheme(
                    data: IconThemeData(color: c.contentSecondary, size: 18),
                    child: widget.leading!),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  focusNode: _focus,
                  enabled: widget.enabled,
                  obscureText: widget.obscureText,
                  keyboardType: widget.keyboardType,
                  inputFormatters: widget.inputFormatters,
                  onChanged: widget.onChanged,
                  onSubmitted: widget.onSubmitted,
                  maxLines: widget.maxLines,
                  autofocus: widget.autofocus,
                  cursorColor: c.brand,
                  style: LoitTypography.bodyL.copyWith(color: c.contentPrimary),
                  decoration: InputDecoration(
                    isCollapsed: true,
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    focusedErrorBorder: InputBorder.none,
                    hintText: widget.placeholder,
                    hintStyle:
                        LoitTypography.bodyL.copyWith(color: c.contentTertiary),
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              if (widget.trailing != null) ...[
                const SizedBox(width: 10),
                IconTheme(
                    data: IconThemeData(color: c.contentSecondary, size: 18),
                    child: widget.trailing!),
              ],
            ],
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 6),
          Text(widget.error!,
              style: LoitTypography.bodyS.copyWith(
                color: c.danger,
                fontWeight: FontWeight.w500,
              )),
        ] else if (widget.helper != null) ...[
          const SizedBox(height: 6),
          Text(widget.helper!,
              style: LoitTypography.bodyS
                  .copyWith(color: c.contentSecondary)),
        ],
      ],
    );
  }
}
