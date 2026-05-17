import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme/loit_colors.dart';
import '../../core/theme/loit_motion.dart';
import '../../core/theme/loit_radius.dart';
import '../../core/theme/loit_spacing.dart';
import '../../core/theme/loit_typography.dart';

/// Step 7 — auto-confirm primary button for high-confidence scans.
///
/// Ticks a [seconds]-long countdown; when it reaches 0, calls [onConfirm].
/// User may tap "Cancel auto-save" to disarm and review manually.
class LoitCountdownButton extends StatefulWidget {
  final String confirmLabel;
  final String cancelLabel;
  final String Function(int secondsRemaining) labelFor;
  final VoidCallback onConfirm;
  final int seconds;
  final bool enabled;

  const LoitCountdownButton({
    super.key,
    required this.confirmLabel,
    required this.cancelLabel,
    required this.labelFor,
    required this.onConfirm,
    this.seconds = 3,
    this.enabled = true,
  });

  @override
  State<LoitCountdownButton> createState() => _LoitCountdownButtonState();
}

class _LoitCountdownButtonState extends State<LoitCountdownButton> {
  Timer? _timer;
  late int _remaining = widget.seconds;
  bool _armed = true;

  @override
  void initState() {
    super.initState();
    if (widget.enabled) _start();
  }

  void _start() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _remaining -= 1);
      if (_remaining <= 0) {
        _timer?.cancel();
        if (_armed) widget.onConfirm();
      }
    });
  }

  void _disarm() {
    _timer?.cancel();
    setState(() => _armed = false);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.loitColors;
    final label = _armed
        ? widget.labelFor(_remaining < 0 ? 0 : _remaining)
        : widget.confirmLabel;

    return AnimatedContainer(
      duration: LoitMotion.emphasized,
      curve: LoitMotion.easeOutQuart,
      width: double.infinity,
      decoration: BoxDecoration(
        color: c.success,
        borderRadius: BorderRadius.circular(LoitRadius.m),
      ),
      child: Material(
        color: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              onTap: () {
                _timer?.cancel();
                widget.onConfirm();
              },
              borderRadius: BorderRadius.circular(LoitRadius.m),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: LoitSpacing.s5,
                  vertical: LoitSpacing.s4,
                ),
                child: Center(
                  child: Text(
                    label,
                    style: LoitTypography.labelL.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
            if (_armed)
              InkWell(
                onTap: _disarm,
                child: Padding(
                  padding: const EdgeInsets.only(
                    bottom: LoitSpacing.s3,
                    top: LoitSpacing.s1,
                  ),
                  child: Text(
                    widget.cancelLabel,
                    style: LoitTypography.labelM.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
