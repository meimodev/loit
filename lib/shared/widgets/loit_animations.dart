import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/loit_motion.dart';

bool _reduceMotion(BuildContext context) =>
    MediaQuery.of(context).disableAnimations;

class LoitFadeSlideIn extends StatefulWidget {
  const LoitFadeSlideIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = LoitMotion.entrance,
    this.offset = 12,
    this.curve = LoitMotion.easeOutQuint,
  });

  final Widget child;
  final Duration delay;
  final Duration duration;
  final double offset;
  final Curve curve;

  @override
  State<LoitFadeSlideIn> createState() => _LoitFadeSlideInState();
}

class _LoitFadeSlideInState extends State<LoitFadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: widget.duration,
  );

  @override
  void initState() {
    super.initState();
    if (widget.delay == Duration.zero) {
      _ctrl.forward();
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) _ctrl.forward();
      });
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_reduceMotion(context)) return widget.child;
    final curved = CurvedAnimation(parent: _ctrl, curve: widget.curve);
    return AnimatedBuilder(
      animation: curved,
      builder: (_, child) {
        final t = curved.value;
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, (1 - t) * widget.offset),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}

class LoitPressScale extends StatefulWidget {
  const LoitPressScale({
    super.key,
    required this.child,
    this.onTap,
    this.scale = 0.97,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double scale;

  @override
  State<LoitPressScale> createState() => _LoitPressScaleState();
}

class _LoitPressScaleState extends State<LoitPressScale> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final reduce = _reduceMotion(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) => setState(() => _down = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _down && !reduce ? widget.scale : 1.0,
        duration: LoitMotion.short,
        curve: LoitMotion.easeOutQuart,
        child: widget.child,
      ),
    );
  }
}

class LoitPulseDot extends StatefulWidget {
  const LoitPulseDot({
    super.key,
    required this.color,
    this.size = 8,
    this.maxRing = 14,
  });

  final Color color;
  final double size;
  final double maxRing;

  @override
  State<LoitPulseDot> createState() => _LoitPulseDotState();
}

class _LoitPulseDotState extends State<LoitPulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduce = _reduceMotion(context);
    final dot = Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
    );
    if (reduce) return dot;
    return SizedBox(
      width: widget.maxRing,
      height: widget.maxRing,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) {
          final t = Curves.easeOut.transform(_ctrl.value);
          final ringSize = widget.size + (widget.maxRing - widget.size) * t;
          return Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: ringSize,
                height: ringSize,
                decoration: BoxDecoration(
                  color: widget.color.withValues(alpha: (1 - t) * 0.55),
                  shape: BoxShape.circle,
                ),
              ),
              dot,
            ],
          );
        },
      ),
    );
  }
}

class LoitAnimatedCount extends StatelessWidget {
  const LoitAnimatedCount({
    super.key,
    required this.value,
    required this.builder,
    this.duration = LoitMotion.entrance,
    this.curve = LoitMotion.easeOutQuart,
  });

  final double value;
  final Widget Function(BuildContext, double) builder;
  final Duration duration;
  final Curve curve;

  @override
  Widget build(BuildContext context) {
    if (_reduceMotion(context)) return builder(context, value);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value),
      duration: duration,
      curve: curve,
      builder: (ctx, v, _) => builder(ctx, v),
    );
  }
}

class LoitAnimatedProgress extends StatelessWidget {
  const LoitAnimatedProgress({
    super.key,
    required this.value,
    required this.color,
    this.background,
    this.minHeight = 6,
    this.borderRadius = const BorderRadius.all(Radius.circular(999)),
    this.duration = LoitMotion.emphasized,
  });

  final double value;
  final Color color;
  final Color? background;
  final double minHeight;
  final BorderRadius borderRadius;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final clamped = value.clamp(0.0, 1.0);
    final reduce = _reduceMotion(context);
    return ClipRRect(
      borderRadius: borderRadius,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: clamped),
        duration: reduce ? Duration.zero : duration,
        curve: LoitMotion.easeOutQuart,
        builder: (_, v, __) => LinearProgressIndicator(
          value: v,
          minHeight: minHeight,
          backgroundColor: background,
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      ),
    );
  }
}

/// Gentle Y-axis bob loop. Use for empty-state illustrations/icons.
class LoitFloating extends StatefulWidget {
  const LoitFloating({
    super.key,
    required this.child,
    this.amplitude = 5,
    this.period = const Duration(milliseconds: 2600),
  });

  final Widget child;
  final double amplitude;
  final Duration period;

  @override
  State<LoitFloating> createState() => _LoitFloatingState();
}

class _LoitFloatingState extends State<LoitFloating>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl =
      AnimationController(vsync: this, duration: widget.period)..repeat();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_reduceMotion(context)) return widget.child;
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) {
        final dy = math.sin(_ctrl.value * 2 * math.pi) * widget.amplitude;
        return Transform.translate(offset: Offset(0, dy), child: child);
      },
      child: widget.child,
    );
  }
}

/// Passive press-scale via pointer events. Does NOT consume taps —
/// safe to wrap around an `InkWell`/`GestureDetector`/`Dismissible`.
class LoitTapScale extends StatefulWidget {
  const LoitTapScale({
    super.key,
    required this.child,
    this.scale = 0.97,
  });

  final Widget child;
  final double scale;

  @override
  State<LoitTapScale> createState() => _LoitTapScaleState();
}

class _LoitTapScaleState extends State<LoitTapScale> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final reduce = _reduceMotion(context);
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) {
        if (!_down) setState(() => _down = true);
      },
      onPointerUp: (_) {
        if (_down) setState(() => _down = false);
      },
      onPointerCancel: (_) {
        if (_down) setState(() => _down = false);
      },
      child: AnimatedScale(
        scale: _down && !reduce ? widget.scale : 1.0,
        duration: LoitMotion.short,
        curve: LoitMotion.easeOutQuart,
        child: widget.child,
      ),
    );
  }
}

class LoitAnimatedReveal extends StatelessWidget {
  const LoitAnimatedReveal({
    super.key,
    required this.visible,
    required this.child,
    this.duration = LoitMotion.emphasized,
  });

  final bool visible;
  final Widget child;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: duration,
      curve: LoitMotion.easeOutQuart,
      alignment: Alignment.topCenter,
      child: AnimatedOpacity(
        duration: duration,
        opacity: visible ? 1 : 0,
        child: visible ? child : const SizedBox(width: double.infinity),
      ),
    );
  }
}
