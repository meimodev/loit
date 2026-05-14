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
  int _idx = 0;
  bool _pressed = false;

  List<(IconData, String, String)> _slides(AppLocalizations l) => [
        (
          Icons.camera_alt_outlined,
          l.welcomeSlide1Title,
          l.welcomeSlide1Body,
        ),
        (
          Icons.group_outlined,
          l.welcomeSlide2Title,
          l.welcomeSlide2Body,
        ),
        (
          Icons.check_circle_outline,
          l.welcomeSlide3Title,
          l.welcomeSlide3Body,
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
                          child: Container(
                            width: 88,
                            height: 88,
                            decoration: BoxDecoration(
                              color: LoitPalette.teal100,
                              borderRadius: LoitRadius.brL,
                            ),
                            alignment: Alignment.center,
                            child: Icon(icon,
                                size: 40, color: LoitPalette.teal700),
                          ),
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
                        child: Text(
                          isLast ? l.welcomeGetStarted : l.welcomeNext,
                          key: ValueKey(isLast),
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
