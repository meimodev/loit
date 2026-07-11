import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/loit_colors.dart';
import '../../core/theme/loit_motion.dart';
import '../../core/theme/loit_radius.dart';
import '../../core/theme/loit_spacing.dart';
import '../../core/theme/loit_typography.dart';
import '../../l10n/l10n_x.dart';
import '../../l10n/gen/app_localizations.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  final _pc = PageController();
  late final AnimationController _entrance;
  late final AnimationController _bob;
  late final AnimationController _heroSwap;
  late final AnimationController _idle;
  int _idx = 0;
  bool _pressed = false;

  List<(IconData, String, String)> _slides(AppLocalizations l) => [
        (
          Icons.savings_outlined,
          l.welcomeSlide1Title,
          l.welcomeSlide1Body,
        ),
        (
          Icons.visibility_outlined,
          l.welcomeSlide2Title,
          l.welcomeSlide2Body,
        ),
        (
          Icons.camera_alt_outlined,
          l.welcomeSlide3Title,
          l.welcomeSlide3Body,
        ),
        (
          Icons.mic_none_outlined,
          l.welcomeSlide4Title,
          l.welcomeSlide4Body,
        ),
        (
          Icons.insights_outlined,
          l.welcomeSlide5Title,
          l.welcomeSlide5Body,
        ),
      ];

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    _bob = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat(reverse: true);
    _heroSwap = AnimationController(
      vsync: this,
      duration: LoitMotion.emphasized,
      value: 1,
    );
    _idle = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
  }

  @override
  void dispose() {
    _pc.dispose();
    _entrance.dispose();
    _bob.dispose();
    _heroSwap.dispose();
    _idle.dispose();
    super.dispose();
  }

  void _next() {
    final l = context.l10n;
    final slides = _slides(l);
    if (_idx < slides.length - 1) {
      _pc.nextPage(
        duration: LoitMotion.emphasized,
        curve: LoitMotion.easeOutQuint,
      );
      return;
    }
    context.go('/sign-in');
  }

  Widget _fadeSlide(Widget child, Animation<double> anim) {
    return FadeTransition(
      opacity: anim,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.1),
          end: Offset.zero,
        ).animate(anim),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.loitColors;
    final l = context.l10n;
    final slides = _slides(l);
    final isLast = _idx == slides.length - 1;
    final reduced = MediaQuery.disableAnimationsOf(context);

    return Scaffold(
      backgroundColor: c.canvas,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            Expanded(
              flex: 3,
              child: PageView.builder(
                controller: _pc,
                onPageChanged: (i) => setState(() => _idx = i),
                itemCount: slides.length,
                itemBuilder: (_, i) {
                  final (icon, title, body) = slides[i];
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Transform.translate(
                        offset: Offset(
                            0, math.sin(_bob.value * math.pi * 2) * 4),
                        child: _StaggeredEntrance(
                          controller: _entrance,
                          start: 0.05,
                          end: 0.60,
                          reduced: reduced,
                          child: _AnimatedHero(
                            index: i,
                            icon: icon,
                            idle: _idle,
                            reduced: reduced,
                          ),
                        ),
                      ),
                      const SizedBox(height: LoitSpacing.s5),
                      _StaggeredEntrance(
                        controller: _entrance,
                        start: 0.15,
                        end: 0.70,
                        reduced: reduced,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: LoitSpacing.s5),
                          child: AnimatedSwitcher(
                            duration: LoitMotion.emphasized,
                            switchInCurve: LoitMotion.easeOutQuint,
                            transitionBuilder: _fadeSlide,
                            child: Text(
                              title,
                              key: ValueKey('t$i'),
                              textAlign: TextAlign.center,
                              style: LoitTypography.titleL.copyWith(
                                color: c.contentPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      _StaggeredEntrance(
                        controller: _entrance,
                        start: 0.25,
                        end: 0.80,
                        reduced: reduced,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 280),
                          child: AnimatedSwitcher(
                            duration: LoitMotion.emphasized,
                            switchInCurve: LoitMotion.easeOutQuint,
                            transitionBuilder: _fadeSlide,
                            child: Text(
                              body,
                              key: ValueKey('b$i'),
                              textAlign: TextAlign.center,
                              style: LoitTypography.bodyM
                                  .copyWith(color: c.contentSecondary),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            _StaggeredEntrance(
              controller: _entrance,
              start: 0.35,
              end: 0.85,
              reduced: reduced,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  slides.length,
                  (i) => AnimatedContainer(
                    duration: LoitMotion.base,
                    curve: LoitMotion.easeOutQuart,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: i == _idx ? 24 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: i == _idx ? c.brand : c.borderDefault,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: LoitSpacing.s5),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: LoitSpacing.s5),
              child: _StaggeredEntrance(
              controller: _entrance,
              start: 0.45,
              end: 0.95,
              reduced: reduced,
              child: GestureDetector(
                onTapDown: (_) => setState(() => _pressed = true),
                onTapCancel: () => setState(() => _pressed = false),
                onTapUp: (_) => setState(() => _pressed = false),
                child: AnimatedScale(
                  scale: _pressed ? 0.97 : 1,
                  duration: LoitMotion.instant,
                  curve: LoitMotion.easeOutQuart,
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton(
                      onPressed: _next,
                      child: AnimatedSwitcher(
                        duration: LoitMotion.short,
                        transitionBuilder: (child, anim) => FadeTransition(
                          opacity: anim,
                          child: ScaleTransition(
                            scale: Tween<double>(begin: 0.9, end: 1)
                                .animate(anim),
                            child: child,
                          ),
                        ),
                        child: Builder(
                          builder: (_) {
                            final label = _idx == 0
                                ? l.welcomeStart
                                : isLast
                                    ? l.welcomeGetStarted
                                    : l.welcomeNext;
                            return Text(label, key: ValueKey(label));
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            ),
            const SizedBox(height: LoitSpacing.s5),
          ],
        ),
      ),
    );
  }
}

class _AnimatedHero extends StatelessWidget {
  const _AnimatedHero({
    required this.index,
    required this.icon,
    required this.idle,
    required this.reduced,
  });

  final int index;
  final IconData icon;
  final Animation<double> idle;
  final bool reduced;

  @override
  Widget build(BuildContext context) {
    final base = Container(
      width: 88,
      height: 88,
      decoration: BoxDecoration(
        color: LoitPalette.teal100,
        borderRadius: LoitRadius.brL,
      ),
      alignment: Alignment.center,
      child: Icon(icon, size: 40, color: LoitPalette.teal700),
    );
    if (reduced) return base;
    return SizedBox(
      width: 88,
      height: 88,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Positioned.fill(child: _decor()),
          base,
          if (index == 2) Positioned.fill(child: _CameraGlint(idle: idle)),
        ],
      ),
    );
  }

  Widget _decor() {
    switch (index) {
      case 0:
        return _OrbitDots(idle: idle);
      case 1:
        return _RevealRings(idle: idle);
      case 2:
        return _CameraRings(idle: idle);
      case 3:
        return _RevealRings(idle: idle); // voice: pulse reads as sound waves
      case 4:
      default:
        return _OrbitDots(idle: idle);
    }
  }
}

class _CameraRings extends StatelessWidget {
  const _CameraRings({required this.idle});
  final Animation<double> idle;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: idle,
        builder: (_, __) => CustomPaint(
          painter: _CameraRingsPainter(phase: idle.value),
        ),
      ),
    );
  }
}

class _CameraRingsPainter extends CustomPainter {
  _CameraRingsPainter({required this.phase});
  final double phase;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    for (var i = 0; i < 3; i++) {
      final t = (phase + i / 3) % 1.0;
      final half = 44.0 + t * 24.0;
      final opacity = ((1 - t).clamp(0.0, 1.0)) * 0.42;
      if (opacity <= 0) continue;
      final paint = Paint()
        ..color = LoitPalette.teal400.withValues(alpha: opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
              center: center, width: half * 2, height: half * 2),
          Radius.circular(18 + t * 10),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_CameraRingsPainter old) => old.phase != phase;
}

class _CameraGlint extends StatelessWidget {
  const _CameraGlint({required this.idle});
  final Animation<double> idle;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: idle,
        builder: (_, __) {
          final t = (math.sin(idle.value * math.pi * 2) * 0.5 + 0.5);
          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                right: 6,
                top: 6,
                child: Opacity(
                  opacity: 0.35 + t * 0.55,
                  child: Transform.scale(
                    scale: 0.6 + t * 0.6,
                    child: Icon(
                      Icons.auto_awesome,
                      size: 16,
                      color: LoitPalette.ochre400,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _OrbitDots extends StatelessWidget {
  const _OrbitDots({required this.idle});
  final Animation<double> idle;

  @override
  Widget build(BuildContext context) {
    const radius = 52.0;
    const colors = [
      LoitPalette.teal500,
      LoitPalette.ochre400,
      LoitPalette.teal300,
    ];
    return AnimatedBuilder(
      animation: idle,
      builder: (_, __) {
        final base = idle.value * 2 * math.pi;
        return Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: List.generate(3, (i) {
            final a = base + i * (2 * math.pi / 3);
            final dx = math.cos(a) * radius;
            final dy = math.sin(a) * radius;
            final depth = (math.sin(a) + 1) / 2;
            final scale = 0.75 + depth * 0.5;
            return Transform.translate(
              offset: Offset(dx, dy),
              child: Transform.scale(
                scale: scale,
                child: Container(
                  width: 11,
                  height: 11,
                  decoration: BoxDecoration(
                    color: colors[i],
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: colors[i].withValues(alpha: 0.35),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

class _RevealRings extends StatelessWidget {
  const _RevealRings({required this.idle});
  final Animation<double> idle;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: idle,
        builder: (_, __) => CustomPaint(
          painter: _RevealRingsPainter(phase: idle.value),
        ),
      ),
    );
  }
}

class _RevealRingsPainter extends CustomPainter {
  _RevealRingsPainter({required this.phase});
  final double phase;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    for (var i = 0; i < 3; i++) {
      final t = (phase + i / 3) % 1.0;
      final r = 44.0 + t * 26.0;
      final opacity = ((1 - t).clamp(0.0, 1.0)) * 0.40;
      if (opacity <= 0) continue;
      canvas.drawCircle(
        center,
        r,
        Paint()
          ..color = LoitPalette.teal400.withValues(alpha: opacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6,
      );
    }
  }

  @override
  bool shouldRepaint(_RevealRingsPainter old) => old.phase != phase;
}

class _StaggeredEntrance extends StatelessWidget {
  const _StaggeredEntrance({
    required this.controller,
    required this.start,
    required this.end,
    required this.reduced,
    required this.child,
  });

  final AnimationController controller;
  final double start;
  final double end;
  final bool reduced;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (reduced) return child;
    return AnimatedBuilder(
      animation: CurvedAnimation(
        parent: controller,
        curve: Interval(start, end, curve: LoitMotion.easeOutQuint),
      ),
      builder: (_, c) {
        final v = controller.value.clamp(start, end);
        final t = (v - start) / (end - start);
        return Opacity(
          opacity: t.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, (1 - t) * 16),
            child: c,
          ),
        );
      },
      child: child,
    );
  }
}
