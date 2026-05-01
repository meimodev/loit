import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/loit_colors.dart';
import '../../core/theme/loit_radius.dart';
import '../../core/theme/loit_spacing.dart';
import '../../core/theme/loit_typography.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final PageController _pc = PageController();
  int _idx = 0;

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
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  void _next() {
    if (_idx < _slides.length - 1) {
      _pc.nextPage(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic);
    } else {
      context.go('/sign-up');
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.loitColors;
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
                  onPageChanged: (i) => setState(() => _idx = i),
                  itemCount: _slides.length,
                  itemBuilder: (_, i) {
                    final (icon, title, body) = _slides[i];
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 240,
                          height: 240,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [LoitPalette.teal50, LoitPalette.ochre50],
                            ),
                            borderRadius: LoitRadius.brXl,
                            border: Border.all(color: c.borderSubtle),
                          ),
                          child: Icon(icon, size: 96, color: c.brand),
                        ),
                        const SizedBox(height: LoitSpacing.s5),
                        Text(title,
                            textAlign: TextAlign.center,
                            style: LoitTypography.titleL.copyWith(
                              color: c.contentPrimary,
                              fontWeight: FontWeight.w600,
                            )),
                        const SizedBox(height: 8),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 280),
                          child: Text(body,
                              textAlign: TextAlign.center,
                              style: LoitTypography.bodyM
                                  .copyWith(color: c.contentSecondary)),
                        ),
                      ],
                    );
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _slides.length,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 240),
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
              const SizedBox(height: LoitSpacing.s5),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: _next,
                  child: Text(_idx == 2 ? 'Get started' : 'Next'),
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => context.go('/sign-in'),
                child: Text(_idx < 2 ? 'Skip' : 'Sign in instead',
                    style: LoitTypography.bodyM.copyWith(
                      color: c.contentSecondary,
                      fontWeight: FontWeight.w600,
                    )),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
