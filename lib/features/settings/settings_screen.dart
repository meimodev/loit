import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme/loit_colors.dart';
import '../../core/theme/loit_typography.dart';
import '../../core/services/analytics_service.dart';
import '../../core/services/push_service.dart';
import '../../l10n/l10n_x.dart';
import '../../shared/providers/accounts_provider.dart';
import '../../shared/providers/auth_providers.dart';
import '../../shared/providers/budgets_provider.dart';
import '../../shared/providers/preferences_provider.dart';
import '../../shared/providers/transactions_provider.dart';
import '../../shared/widgets/currency_picker_sheet.dart';
import '../../shared/widgets/connectivity_banner.dart';
import '../../shared/widgets/loit_button.dart';
import '_widgets.dart';

const _kLanguageCodes = {'English (US)': 'en', 'Bahasa Indonesia': 'id'};

String _languageLabel(String code) => _kLanguageCodes.entries
    .firstWhere((e) => e.value == code,
        orElse: () => _kLanguageCodes.entries.first)
    .key;

Map<String, ThemeMode> _themeOptions(BuildContext context) => {
      context.l10n.prefsThemeSystem: ThemeMode.system,
      context.l10n.prefsThemeLight: ThemeMode.light,
      context.l10n.prefsThemeDark: ThemeMode.dark,
    };

String _themeLabel(BuildContext context, ThemeMode m) =>
    _themeOptions(context)
        .entries
        .firstWhere((e) => e.value == m, orElse: () => _themeOptions(context).entries.first)
        .key;

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.loitColors;
    final l = context.l10n;
    final profile = ref.watch(userProfileProvider).value;
    final budgets = ref.watch(budgetsProvider).value ?? const [];
    final prefs = ref.watch(preferencesProvider).value ?? const AppPreferences();
    final prefsNotifier = ref.read(preferencesProvider.notifier);

    return Scaffold(
      backgroundColor: c.canvas,
      appBar: AppBar(
        title: Text(l.settingsTitle),
        backgroundColor: c.canvas,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          if (profile != null)
            InkWell(
              onTap: () => context.push('/settings/profile'),
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                decoration: BoxDecoration(
                  color: c.surface,
                  border: Border(
                    bottom: BorderSide(color: c.borderSubtle, width: 1),
                  ),
                ),
                child: Row(
                  children: [
                    SettingsAvatar(
                      initials: _initials(profile.name, profile.email),
                      color: c.brand,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            profile.name.isEmpty
                                ? profile.email
                                : profile.name,
                            style: LoitTypography.titleM.copyWith(
                              color: c.contentPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(profile.email,
                              style: LoitTypography.bodyS
                                  .copyWith(color: c.contentSecondary)),
                          const SizedBox(height: 6),
                          SettingsTierChip(tier: profile.tier),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right,
                        size: 18, color: c.contentTertiary),
                  ],
                ),
              ),
            ),

          SettingsGroup(label: l.settingsGeneral, children: [
            SettingsRow(
              label: l.settingsLanguage,
              value: _languageLabel(
                  prefs.language == 'system' ? 'en' : prefs.language),
              onTap: () => _pick(
                context: context,
                title: l.settingsLanguage,
                options: _kLanguageCodes.keys.toList(),
                current: _languageLabel(
                    prefs.language == 'system' ? 'en' : prefs.language),
                onChosen: (v) =>
                    prefsNotifier.setLanguage(_kLanguageCodes[v] ?? 'en'),
              ),
            ),
            SettingsRow(
              label: l.settingsCurrency,
              value: profile?.homeCurrency ?? 'IDR',
              onTap: () => _pickCurrency(
                  context, ref, profile?.homeCurrency ?? 'IDR'),
            ),
            SettingsRow(
              label: l.settingsTheme,
              value: _themeLabel(context, prefs.themeMode),
              onTap: () => _pickTheme(
                context: context,
                current: prefs.themeMode,
                onChosen: (m) => prefsNotifier.setThemeMode(m),
              ),
            ),
            SettingsRow(
              label: l.settingsCategories,
              value: l.settingsCustomize,
              onTap: () => context.push('/categories'),
            ),
          ]),

          SettingsGroup(label: l.settingsMoney, children: [
            SettingsRow(
              label: l.settingsAccounts,
              onTap: () => context.push('/accounts'),
            ),
            SettingsRow(
              label: l.settingsBudgets,
              value: l.settingsBudgetsActive(budgets.length),
              onTap: () => context.push('/budgets'),
            ),
            SettingsRow(
              label: l.settingsScansThisMonth,
              value: profile == null
                  ? '—'
                  : profile.hasUnlimitedScans
                      ? l.settingsUnlimited
                      : '${profile.scansUsedThisMonth} / ${profile.scanQuota}',
              showChevron: false,
              onTap: null,
            ),
          ]),

          SettingsGroup(label: l.settingsSubscription, children: [
            SettingsRow(
              label: l.settingsPlan,
              value: profile?.tier.toUpperCase() ?? 'FREE',
              onTap: () => context.push('/billing/manage'),
            ),
            SettingsRow(
              label: l.settingsReceipts,
              onTap: () => context.push('/receipts'),
            ),
          ]),

          SettingsGroup(label: l.settingsPrivacyData, children: [
            SettingsRow(
              label: l.settingsSecurity,
              onTap: () => context.push('/settings/security'),
            ),
            SettingsRow(
              label: l.settingsNotifications,
              onTap: () => context.push('/settings/notifications'),
            ),
            SettingsRow(
              label: l.settingsExportData,
              value: l.settingsCsvPdf,
              onTap: () => context.push('/reports/export'),
            ),
            SettingsRow(
              label: l.settingsDeleteAccount,
              destructive: true,
              showChevron: false,
              onTap: () => _confirmDelete(context),
            ),
          ]),

          SettingsGroup(label: l.settingsAbout, children: [
            SettingsRow(
              label: l.settingsHelpSupport,
              onTap: () => context.push('/settings/about'),
            ),
            SettingsRow(
              label: l.settingsTermsPrivacy,
              onTap: () => context.push('/settings/about'),
            ),
            SettingsRow(
              label: l.settingsVersion,
              value: '1.0.0',
              showChevron: false,
            ),
          ]),

          const SizedBox(height: 24),
          SettingsGroup(label: l.settingsDebug, children: [
            _OfflineToggle(),
          ]),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: LoitButton.secondary(
              label: l.settingsSignOut,
              fullWidth: true,
              onPressed: () => _signOut(context),
            ),
          ),
        ],
      ),
    );
  }

  static String _initials(String name, String email) {
    final src = name.isNotEmpty ? name : email;
    return src.isEmpty ? '?' : src[0].toUpperCase();
  }

  Future<void> _pick({
    required BuildContext context,
    required String title,
    required List<String> options,
    required String current,
    required ValueChanged<String> onChosen,
  }) async {
    final v = await _pickValue(
        context: context, title: title, options: options, current: current);
    if (v != null) onChosen(v);
  }

  Future<void> _pickCurrency(
      BuildContext context, WidgetRef ref, String current) async {
    final v = await pickCurrency(
      context,
      selected: current,
      title: context.l10n.settingsHomeCurrency,
    );
    if (v == null || v == current) return;
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    await Supabase.instance.client
        .from('users')
        .update({'home_currency': v}).eq('id', user.id);
    await ref.read(preferencesProvider.notifier).setCurrency(v);
    ref.invalidate(userProfileProvider);
    ref.invalidate(transactionsProvider);
    ref.invalidate(accountsProvider);
  }

  Future<void> _pickTheme({
    required BuildContext context,
    required ThemeMode current,
    required ValueChanged<ThemeMode> onChosen,
  }) async {
    final l = context.l10n;
    final opts = _themeOptions(context);
    final v = await _pickValue(
      context: context,
      title: l.prefsTheme,
      options: opts.keys.toList(),
      current: _themeLabel(context, current),
    );
    if (v != null) {
      final mode = opts[v];
      if (mode != null) onChosen(mode);
    }
  }

  Future<String?> _pickValue({
    required BuildContext context,
    required String title,
    required List<String> options,
    required String current,
  }) async {
    final c = context.loitColors;
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: c.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: c.borderStrong,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(title,
                  style: LoitTypography.titleM.copyWith(
                    color: c.contentPrimary,
                    fontWeight: FontWeight.w600,
                  )),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final o in options)
                      InkWell(
                        onTap: () => Navigator.pop(ctx, o),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 14),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(o,
                                    style: LoitTypography.bodyL.copyWith(
                                        color: c.contentPrimary)),
                              ),
                              if (o == current)
                                Icon(Icons.check, size: 20, color: c.brand),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  static Future<void> _confirmDelete(BuildContext context) async {
    final l = context.l10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.settingsDeleteAccountTitle),
        content: Text(l.settingsDeleteAccountMessage),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l.settingsCancel)),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(l.settingsDelete),
          ),
        ],
      ),
    );
    if (ok != true) return;
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l.settingsDeleteAccountSnackbar)),
    );
  }

  static Future<void> _signOut(BuildContext context) async {
    try {
      await PushService().unregisterCurrentDevice();
    } catch (_) {}
    await Supabase.instance.client.auth.signOut();
    await Analytics.reset();
  }
}

class _OfflineToggle extends ConsumerWidget {
  const _OfflineToggle();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final override = ref.watch(offlineDebugOverrideProvider);
    return SettingsToggleRow(
      label: l.debugSimulateOffline,
      helper: l.debugSimulateOfflineHelper,
      value: override == true,
      onChanged: (v) =>
          ref.read(offlineDebugOverrideProvider.notifier).set(v ? true : null),
    );
  }
}
