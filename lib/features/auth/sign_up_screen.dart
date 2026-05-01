import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme/loit_colors.dart';
import '../../core/theme/loit_radius.dart';
import '../../core/theme/loit_spacing.dart';
import '../../core/theme/loit_typography.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  bool _busy = false;
  String? _error;

  Future<void> _google() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await Supabase.instance.client.auth
          .signInWithOAuth(OAuthProvider.google);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _apple() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await Supabase.instance.client.auth.signInWithOAuth(OAuthProvider.apple);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.loitColors;
    return Scaffold(
      backgroundColor: c.canvas,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('LOIT',
                  style: LoitTypography.bodyS.copyWith(
                    color: c.contentSecondary,
                    fontWeight: FontWeight.w600,
                  )),
              const Spacer(),
              Text("Let's get you\nstarted.",
                  style: LoitTypography.displayM.copyWith(
                    color: c.contentPrimary,
                    fontWeight: FontWeight.w600,
                    height: 1.15,
                  )),
              const SizedBox(height: 8),
              Text('Free forever. Upgrade anytime.',
                  style: LoitTypography.bodyM
                      .copyWith(color: c.contentSecondary)),
              const SizedBox(height: LoitSpacing.s6),
              _socialButton(
                context,
                onTap: _busy ? null : _google,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFFEA4335),
                            Color(0xFF4285F4),
                            Color(0xFF34A853),
                            Color(0xFFFBBC05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text('Continue with Google',
                        style: LoitTypography.bodyL.copyWith(
                          color: c.contentPrimary,
                          fontWeight: FontWeight.w600,
                        )),
                  ],
                ),
                bordered: true,
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 52,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: LoitPalette.n900,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: LoitRadius.brM),
                  ),
                  onPressed: _busy ? null : _apple,
                  child: const Text('Continue with Apple'),
                ),
              ),
              const SizedBox(height: 10),
              _socialButton(
                context,
                onTap: () => context.go('/auth'),
                child: Text('Continue with email',
                    style: LoitTypography.bodyL.copyWith(
                      color: c.contentPrimary,
                      fontWeight: FontWeight.w600,
                    )),
                bordered: false,
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!,
                    textAlign: TextAlign.center,
                    style: LoitTypography.bodyS.copyWith(color: c.danger)),
              ],
              const SizedBox(height: LoitSpacing.s5),
              Text.rich(
                TextSpan(
                  text: 'By continuing you agree to our ',
                  style: LoitTypography.bodyS
                      .copyWith(color: c.contentTertiary),
                  children: [
                    TextSpan(
                      text: 'Terms',
                      style: TextStyle(
                          color: c.brand, fontWeight: FontWeight.w600),
                    ),
                    const TextSpan(text: ' and '),
                    TextSpan(
                      text: 'Privacy',
                      style: TextStyle(
                          color: c.brand, fontWeight: FontWeight.w600),
                    ),
                    const TextSpan(text: '.'),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: LoitSpacing.s4),
              GestureDetector(
                onTap: () => context.go('/sign-in'),
                child: Text.rich(
                  TextSpan(
                    text: 'Already have an account? ',
                    style: LoitTypography.bodyM
                        .copyWith(color: c.contentSecondary),
                    children: [
                      TextSpan(
                        text: 'Sign in',
                        style: TextStyle(
                            color: c.brand, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _socialButton(
    BuildContext context, {
    required VoidCallback? onTap,
    required Widget child,
    required bool bordered,
  }) {
    final c = context.loitColors;
    return InkWell(
      onTap: onTap,
      borderRadius: LoitRadius.brM,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: LoitRadius.brM,
          border: Border.all(
            color: bordered ? c.borderStrong : c.borderDefault,
            width: bordered ? 1.5 : 1,
          ),
        ),
        child: Center(child: child),
      ),
    );
  }
}
