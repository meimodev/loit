import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/loit_colors.dart';
import '../../core/theme/loit_motion.dart';
import '../../core/theme/loit_radius.dart';
import '../../core/theme/loit_spacing.dart';
import '../../core/theme/loit_typography.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  final PageController _pc = PageController();
  int _idx = 0;
  late final AnimationController _entrance;
  late final AnimationController _bob;
  late final AnimationController _heroSwap;
  bool _pressed = false;

  static const _slides = [
    (
      Icons.camera_alt_outlined,
      'Track spending in seconds.',
      'Snap a receipt or tap in an amount. We do the math.',
    ),
    (
      Icons.group_outlined,
      'Share with friends, privately.',
      'Create a room for trips or the apartment. No one sees the rest.',
    ),
    (
      Icons.check_circle_outline,
      'Budgets that make sense.',
      'Category limits, gentle alerts, real insight.',
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
  }

  @override
  void dispose() {
    _pc.dispose();
    _entrance.dispose();
    _bob.dispose();
    _heroSwap.dispose();
    super.dispose();
  }

  void _next() {
    if (_idx < _slides.length - 1) {
      _pc.nextPage(
        duration: LoitMotion.emphasized,
        curve: LoitMotion.easeOutQuart,
      );
    } else {
      context.go('/sign-in');
    }
  }

  void _onPageChanged(int i) {
    setState(() => _idx = i);
    _heroSwap
      ..value = 0
      ..forward();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.loitColors;
    final reduced = MediaQuery.of(context).disableAnimations;
    final isLast = _idx == _slides.length - 1;

    return Scaffold(
      backgroundColor: c.canvas,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
          child: Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _pc,
                  onPageChanged: _onPageChanged,
                  itemCount: _slides.length,
                  itemBuilder: (_, i) {
                    final (icon, title, body) = _slides[i];
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _StaggeredEntrance(
                          controller: _entrance,
                          start: 0.00,
                          end: 0.55,
                          reduced: reduced,
                          child: _HeroIcon(
                            icon: icon,
                            color: c.brand,
                            border: c.borderSubtle,
                            bob: _bob,
                            swap: _heroSwap,
                            reduced: reduced,
                          ),
                        ),
                        const SizedBox(height: LoitSpacing.s5),
                        _StaggeredEntrance(
                          controller: _entrance,
                          start: 0.15,
                          end: 0.70,
                          reduced: reduced,
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
                    _slides.length,
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
              _StaggeredEntrance(
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
                          child: Text(
                            isLast ? 'Get started' : 'Next',
                            key: ValueKey(isLast),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _fadeSlide(Widget child, Animation<double> anim) {
    final slide = Tween<Offset>(
      begin: const Offset(0, 0.18),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: anim, curve: LoitMotion.easeOutQuint));
    return FadeTransition(
      opacity: anim,
      child: SlideTransition(position: slide, child: child),
    );
  }
}

class _HeroIcon extends StatelessWidget {
  const _HeroIcon({
    required this.icon,
    required this.color,
    required this.border,
    required this.bob,
    required this.swap,
    required this.reduced,
  });

  final IconData icon;
  final Color color;
  final Color border;
  final AnimationController bob;
  final AnimationController swap;
  final bool reduced;

  @override
  Widget build(BuildContext context) {
    final container = Container(
      width: 240,
      height: 240,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [LoitPalette.teal50, LoitPalette.ochre50],
        ),
        borderRadius: LoitRadius.brXl,
        border: Border.all(color: border),
      ),
      child: AnimatedSwitcher(
        duration: LoitMotion.emphasized,
        switchInCurve: LoitMotion.easeOutQuint,
        transitionBuilder: (child, anim) {
          final scale = Tween<double>(begin: 0.7, end: 1)
              .animate(CurvedAnimation(parent: anim, curve: LoitMotion.easeOutExpo));
          return FadeTransition(
            opacity: anim,
            child: ScaleTransition(scale: scale, child: child),
          );
        },
        child: Icon(icon, key: ValueKey(icon.codePoint), size: 96, color: color),
      ),
    );
    if (reduced) return container;
    return AnimatedBuilder(
      animation: Listenable.merge([bob, swap]),
      builder: (_, child) {
        final t = bob.value;
        final dy = math.sin(t * math.pi * 2) * 4;
        final rot = math.sin(t * math.pi * 2) * 0.012;
        final swapScale = 0.96 + (swap.value * 0.04);
        return Transform.translate(
          offset: Offset(0, dy),
          child: Transform.rotate(
            angle: rot,
            child: Transform.scale(scale: swapScale, child: child),
          ),
        );
      },
      child: container,
    );
  }
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
    final curved = CurvedAnimation(
      parent: controller,
      curve: Interval(start, end, curve: LoitMotion.easeOutQuint),
    );
    return AnimatedBuilder(
      animation: curved,
      builder: (_, c) {
        final v = curved.value;
        return Opacity(
          opacity: v,
          child: Transform.translate(
            offset: Offset(0, (1 - v) * 16),
            child: c,
          ),
        );
      },
      child: child,
    );
  }
}
