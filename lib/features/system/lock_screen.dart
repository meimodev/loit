import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/services/log_service.dart';
import '../../core/theme/loit_colors.dart';
import '../../core/theme/loit_radius.dart';
import '../../core/theme/loit_typography.dart';
import '../../shared/providers/app_lock_provider.dart';
import '../../shared/providers/preferences_provider.dart';

class LockScreen extends ConsumerStatefulWidget {
  const LockScreen({super.key});

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen> {
  bool _prompting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _authenticate());
  }

  Future<void> _authenticate() async {
    if (_prompting) return;
    setState(() {
      _prompting = true;
      _error = null;
    });
    try {
      final ok = await LocalAuthentication().authenticate(
        localizedReason: 'Unlock LOIT',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );
      if (!mounted) return;
      if (ok) {
        ref.read(appLockedProvider.notifier).unlock();
      } else {
        setState(() {
          _prompting = false;
          _error = 'Authentication cancelled';
        });
      }
    } catch (e, st) {
      Log.e('LockScreen', 'biometric auth failed', error: e, stack: st);
      if (!mounted) return;
      setState(() {
        _prompting = false;
        _error = 'Authentication failed';
      });
    }
  }

  Future<void> _signOut() async {
    try {
      await Supabase.instance.client.auth.signOut();
    } catch (e) {
      Log.w('LockScreen', 'sign out failed', error: e);
    }
    if (!mounted) return;
    // Disable lock so router redirect to /sign-in is visible.
    await ref
        .read(preferencesProvider.notifier)
        .setBool(PrefKeys.biometricLock, false);
    ref.read(appLockedProvider.notifier).unlock();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.loitColors;
    return Scaffold(
      backgroundColor: c.canvas,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Center(
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: c.infoSurface,
                    borderRadius: LoitRadius.brXl,
                  ),
                  child: Icon(Icons.lock_outline,
                      size: 48, color: c.contentPrimary),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'LOIT is locked',
                textAlign: TextAlign.center,
                style: LoitTypography.titleL.copyWith(color: c.contentPrimary),
              ),
              const SizedBox(height: 8),
              Text(
                _error ?? 'Authenticate to continue',
                textAlign: TextAlign.center,
                style: LoitTypography.bodyM.copyWith(
                  color: _error == null ? c.contentSecondary : c.danger,
                ),
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: _prompting ? null : _authenticate,
                icon: const Icon(Icons.fingerprint),
                label: const Text('Unlock'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _prompting ? null : _signOut,
                child: const Text('Sign out'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
