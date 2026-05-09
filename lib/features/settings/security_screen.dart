import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

import '../../core/theme/loit_colors.dart';
import '../../core/theme/loit_typography.dart';
import '../../l10n/l10n_x.dart';
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
    final l = context.l10n;
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
          localizedReason: l.securityBiometricReason,
          options: const AuthenticationOptions(stickyAuth: true),
        );
        await notifier.setBool(PrefKeys.biometricLock, ok);
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.securityBiometricSetupFailed(e.toString()))),
        );
      }
    }

    return Scaffold(
      backgroundColor: c.canvas,
      appBar: AppBar(
        title: Text(l.securityTitle),
        backgroundColor: c.canvas,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          SettingsGroup(label: l.securityLock, children: [
            SettingsToggleRow(
              label: l.securityBiometricUnlock,
              helper: supported
                  ? l.securityBiometricHelper
                  : l.securityBiometricNotAvailable,
              value: prefs.biometricLock,
              onChanged: supported ? toggleBiometric : (_) {},
            ),
          ]),
          SettingsGroup(label: l.securityPrivacy, children: [
            SettingsToggleRow(
              label: l.securityHideAmounts,
              helper: l.securityHideAmountsHelper,
              value: prefs.hideAmounts,
              onChanged: (v) => notifier.setBool(PrefKeys.hideAmounts, v),
            ),
          ]),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Text(
              l.securitySessionFooter,
              style: LoitTypography.bodyS.copyWith(color: c.contentTertiary),
            ),
          ),
        ],
      ),
    );
  }
}
