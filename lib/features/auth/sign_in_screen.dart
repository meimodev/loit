import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme/loit_colors.dart';
import '../../core/theme/loit_radius.dart';
import '../../core/theme/loit_spacing.dart';
import '../../core/theme/loit_typography.dart';
import '../../shared/widgets/loit_input.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _obscure = true;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: _email.text.trim(),
        password: _pass.text,
      );
    } on AuthException catch (e) {
      if (mounted) setState(() => _error = e.message);
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
      appBar: AppBar(
        title: const Text('Sign in'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.canPop() ? context.pop() : context.go('/welcome'),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text('Welcome back',
                    style: LoitTypography.titleL.copyWith(
                      color: c.contentPrimary,
                      fontWeight: FontWeight.w600,
                    )),
                const SizedBox(height: 6),
                Text('Sign in to your account',
                    style: LoitTypography.bodyM
                        .copyWith(color: c.contentSecondary)),
                const SizedBox(height: LoitSpacing.s6),
                LoitInput(
                  controller: _email,
                  label: 'Email',
                  placeholder: 'you@example.com',
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                LoitInput(
                  controller: _pass,
                  label: 'Password',
                  placeholder: '••••••••',
                  obscureText: _obscure,
                  trailing: GestureDetector(
                    onTap: () => setState(() => _obscure = !_obscure),
                    child: Icon(
                      _obscure ? Icons.visibility_off : Icons.visibility,
                      size: 18,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {},
                    child: Text('Forgot password?',
                        style: LoitTypography.bodyS.copyWith(
                          color: c.brand,
                          fontWeight: FontWeight.w600,
                        )),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: c.dangerSurface,
                      borderRadius: LoitRadius.brM,
                    ),
                    child: Text(_error!,
                        style: LoitTypography.bodyS.copyWith(color: c.danger)),
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: c.surface,
              border: Border(top: BorderSide(color: c.borderSubtle)),
            ),
            child: SafeArea(
              top: false,
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: _busy ? null : _signIn,
                  child: _busy
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Text('Sign in'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
