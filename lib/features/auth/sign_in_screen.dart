import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/env.dart';
import '../../core/services/analytics_service.dart';
import '../../core/services/log_service.dart';
import '../../core/theme/loit_colors.dart';
import '../../core/theme/loit_motion.dart';
import '../../core/theme/loit_radius.dart';
import '../../core/theme/loit_spacing.dart';
import '../../core/theme/loit_typography.dart';
import '../../l10n/l10n_x.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen>
    with TickerProviderStateMixin {
  bool _busy = false;
  bool _pressed = false;
  String? _error;

  late final AnimationController _entrance;
  late final AnimationController _shake;

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    _shake = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
  }

  @override
  void dispose() {
    _entrance.dispose();
    _shake.dispose();
    super.dispose();
  }

  Future<void> _google() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    Log.breadcrumb('auth', 'sign-in tapped', data: {'provider': 'google'});
    Log.event('SignIn', 'native flow started', data: {'provider': 'google'});
    try {
      final googleSignIn = GoogleSignIn(
        serverClientId: Env.googleWebClientId,
        scopes: const ['email', 'profile', 'openid'],
      );
      await googleSignIn.signOut(); // force fresh account picker
      final account = await googleSignIn.signIn();
      if (account == null) {
        Log.breadcrumb('auth', 'user cancelled picker');
        return;
      }
      Log.breadcrumb('auth', 'google account selected', data: {
        'email': account.email,
      });
      final auth = await account.authentication;
      final idToken = auth.idToken;
      final accessToken = auth.accessToken;
      if (idToken == null) {
        throw const AuthException(
          'Google did not return an ID token. Check Web Client ID config.',
        );
      }
      await Supabase.instance.client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );
      Log.breadcrumb('auth', 'supabase signInWithIdToken ok');
      await Analytics.login('google');
    } on AuthException catch (e) {
      Log.e('SignIn', 'AuthException: ${e.message}', error: e);
      if (mounted) {
        setState(() => _error = e.message);
        _shake.forward(from: 0);
      }
    } catch (e, st) {
      Log.e('SignIn', 'native sign-in error', error: e, stack: st);
      if (mounted) {
        setState(() => _error = e.toString());
        _shake.forward(from: 0);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.loitColors;
    final l10n = context.l10n;
    final reduced = MediaQuery.of(context).disableAnimations;

    return Scaffold(
      backgroundColor: c.canvas,
      appBar: AppBar(
        title: Text(l10n.authSignInTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/welcome'),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              _Stagger(
                controller: _entrance,
                start: 0.00,
                end: 0.55,
                reduced: reduced,
                child: Text(
                  l10n.authWelcomeTitle,
                  style: LoitTypography.titleL.copyWith(
                    color: c.contentPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              _Stagger(
                controller: _entrance,
                start: 0.10,
                end: 0.65,
                reduced: reduced,
                child: Text(
                  l10n.authWelcomeSubtitle,
                  style: LoitTypography.bodyM
                      .copyWith(color: c.contentSecondary),
                ),
              ),
              const SizedBox(height: LoitSpacing.s6),
              _Stagger(
                controller: _entrance,
                start: 0.25,
                end: 0.80,
                reduced: reduced,
                child: GestureDetector(
                  onTapDown: (_) {
                    if (!_busy) setState(() => _pressed = true);
                  },
                  onTapCancel: () => setState(() => _pressed = false),
                  onTapUp: (_) => setState(() => _pressed = false),
                  child: AnimatedScale(
                    scale: _pressed ? 0.98 : 1,
                    duration: LoitMotion.instant,
                    curve: LoitMotion.easeOutQuart,
                    child: InkWell(
                      onTap: _busy ? null : _google,
                      borderRadius: LoitRadius.brM,
                      child: Container(
                        height: 52,
                        decoration: BoxDecoration(
                          color: c.surface,
                          borderRadius: LoitRadius.brM,
                          border:
                              Border.all(color: c.borderStrong, width: 1.5),
                        ),
                        child: Center(
                          child: AnimatedSwitcher(
                            duration: LoitMotion.short,
                            transitionBuilder: (child, anim) => FadeTransition(
                              opacity: anim,
                              child: ScaleTransition(
                                scale: Tween<double>(begin: 0.92, end: 1)
                                    .animate(anim),
                                child: child,
                              ),
                            ),
                            child: _busy
                                ? const _LoadingDots(key: ValueKey('busy'))
                                : Row(
                                    key: const ValueKey('idle'),
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: [
                                      const _GoogleMark(),
                                      const SizedBox(width: 10),
                                      Text(
                                        l10n.authWelcomeContinue,
                                        style: LoitTypography.bodyL.copyWith(
                                          color: c.contentPrimary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              AnimatedSize(
                duration: LoitMotion.base,
                curve: LoitMotion.easeOutQuart,
                child: _error != null
                    ? Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: AnimatedBuilder(
                          animation: _shake,
                          builder: (_, child) {
                            final t = _shake.value;
                            final dx = reduced
                                ? 0.0
                                : math.sin(t * math.pi * 6) * (1 - t) * 8;
                            return Transform.translate(
                              offset: Offset(dx, 0),
                              child: child,
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: c.dangerSurface,
                              borderRadius: LoitRadius.brM,
                            ),
                            child: Text(
                              _error!,
                              style: LoitTypography.bodyS
                                  .copyWith(color: c.danger),
                            ),
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
              const SizedBox(height: LoitSpacing.s5),
              _Stagger(
                controller: _entrance,
                start: 0.40,
                end: 1.00,
                reduced: reduced,
                child: Text(
                  l10n.authWelcomeTerms,
                  textAlign: TextAlign.center,
                  style: LoitTypography.bodyS
                      .copyWith(color: c.contentTertiary),
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

class _GoogleMark extends StatelessWidget {
  const _GoogleMark();

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/icons/google-logo.svg',
      width: 20,
      height: 20,
    );
  }
}

class _LoadingDots extends StatefulWidget {
  const _LoadingDots({super.key});

  @override
  State<_LoadingDots> createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<_LoadingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = context.loitColors.contentSecondary;
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final phase = (_c.value - i * 0.18) % 1.0;
            final eased = math.sin(phase * math.pi).clamp(0.0, 1.0);
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Opacity(
                opacity: 0.4 + 0.6 * eased,
                child: Transform.translate(
                  offset: Offset(0, -3 * eased),
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
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

class _Stagger extends StatelessWidget {
  const _Stagger({
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
