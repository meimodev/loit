import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

import '../../core/theme/loit_colors.dart';
import '../../core/theme/loit_typography.dart';
import '../../shared/providers/preferences_provider.dart';
import '_widgets.dart';

final _biometricSupportedProvider = FutureProvider<bool>((ref) async {
  final auth = LocalAuthentication();
  try {
    final supported = await auth.isDeviceSupported();
    final canCheck = await auth.canCheckBiometrics;
    return supported && canCheck;
  } catch (_) {
    return false;
  }
});

class SecurityScreen extends ConsumerWidget {
  const SecurityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.loitColors;
    final prefs = ref.watch(preferencesProvider).value ?? const AppPreferences();
    final notifier = ref.read(preferencesProvider.notifier);
    final supported = ref.watch(_biometricSupportedProvider).value ?? false;

    Future<void> toggleBiometric(bool v) async {
      if (!v) {
        await notifier.setBool(PrefKeys.biometricLock, false);
        return;
      }
      try {
        final ok = await LocalAuthentication().authenticate(
          localizedReason: 'Enable biometric lock for LOIT',
          options: const AuthenticationOptions(stickyAuth: true),
        );
        await notifier.setBool(PrefKeys.biometricLock, ok);
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Biometric setup failed: $e')),
        );
      }
    }

    return Scaffold(
      backgroundColor: c.canvas,
      appBar: AppBar(
        title: const Text('Security'),
        backgroundColor: c.canvas,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          SettingsGroup(label: 'Lock', children: [
            SettingsToggleRow(
              label: 'Biometric unlock',
              helper: supported
                  ? 'Use Face / fingerprint to open LOIT'
                  : 'Not available on this device',
              value: prefs.biometricLock,
              onChanged: supported ? toggleBiometric : (_) {},
            ),
            SettingsToggleRow(
              label: 'Require unlock on app open',
              value: prefs.appLock,
              onChanged: (v) => notifier.setBool(PrefKeys.appLock, v),
            ),
          ]),
          SettingsGroup(label: 'Privacy', children: [
            SettingsToggleRow(
              label: 'Hide amounts on lock screen',
              helper: 'Replace amounts with •••• in notifications.',
              value: prefs.hideAmounts,
              onChanged: (v) => notifier.setBool(PrefKeys.hideAmounts, v),
            ),
          ]),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Text(
              'Sessions are managed by your auth provider. Sign out from Settings to revoke access on this device.',
              style: LoitTypography.bodyS
                  .copyWith(color: c.contentTertiary),
            ),
          ),
        ],
      ),
    );
  }
}
