import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/categories.dart';
import '../../core/theme/loit_colors.dart';
import '../../core/theme/loit_typography.dart';
import '../../core/services/analytics_service.dart';
import '../../core/services/push_service.dart';
import '../../shared/providers/auth_providers.dart';
import '../../shared/providers/budgets_provider.dart';
import '../../shared/providers/preferences_provider.dart';
import '../../shared/widgets/connectivity_banner.dart';
import '../../shared/widgets/loit_button.dart';
import '_widgets.dart';

const _kLanguageCodes = {'English (US)': 'en', 'Bahasa Indonesia': 'id'};
const _kRegionCodes = {
  'Indonesia': 'ID',
  'Singapore': 'SG',
  'Malaysia': 'MY',
  'Other': 'XX',
};

String _languageLabel(String code) => _kLanguageCodes.entries
    .firstWhere((e) => e.value == code,
        orElse: () => _kLanguageCodes.entries.first)
    .key;

String _regionLabel(String code) => _kRegionCodes.entries
    .firstWhere((e) => e.value == code,
        orElse: () => _kRegionCodes.entries.first)
    .key;

String _themeLabel(ThemeMode m) => switch (m) {
      ThemeMode.light => 'Light',
      ThemeMode.dark => 'Dark',
      ThemeMode.system => 'System',
    };

ThemeMode _themeFrom(String s) => switch (s) {
      'Light' => ThemeMode.light,
      'Dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.loitColors;
    final profile = ref.watch(userProfileProvider).value;
    final budgets = ref.watch(budgetsProvider).value ?? const [];
    final prefs = ref.watch(preferencesProvider).value ?? const AppPreferences();
    final prefsNotifier = ref.read(preferencesProvider.notifier);

    return Scaffold(
      backgroundColor: c.canvas,
      appBar: AppBar(
        title: const Text('Settings'),
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

          SettingsGroup(label: 'General', children: [
            SettingsRow(
              label: 'Language',
              value: _languageLabel(
                  prefs.language == 'system' ? 'en' : prefs.language),
              onTap: () => _pick(
                context: context,
                title: 'Language',
                options: _kLanguageCodes.keys.toList(),
                current: _languageLabel(
                    prefs.language == 'system' ? 'en' : prefs.language),
                onChosen: (v) =>
                    prefsNotifier.setLanguage(_kLanguageCodes[v] ?? 'en'),
              ),
            ),
            SettingsRow(
              label: 'Currency',
              value:
                  '${profile?.homeCurrency ?? 'IDR'} · ${_symbol(profile?.homeCurrency ?? 'IDR')}',
              onTap: () => _pickCurrency(
                  context, ref, profile?.homeCurrency ?? 'IDR'),
            ),
            SettingsRow(
              label: 'Region',
              value: _regionLabel(prefs.region),
              onTap: () => _pick(
                context: context,
                title: 'Region',
                options: _kRegionCodes.keys.toList(),
                current: _regionLabel(prefs.region),
                onChosen: (v) =>
                    prefsNotifier.setRegion(_kRegionCodes[v] ?? 'ID'),
              ),
            ),
            SettingsRow(
              label: 'Theme',
              value: _themeLabel(prefs.themeMode),
              onTap: () => _pick(
                context: context,
                title: 'Theme',
                options: const ['System', 'Light', 'Dark'],
                current: _themeLabel(prefs.themeMode),
                onChosen: (v) => prefsNotifier.setThemeMode(_themeFrom(v)),
              ),
            ),
            SettingsRow(
              label: 'Categories',
              value: 'Customize',
              onTap: () => context.push('/categories'),
            ),
          ]),

          SettingsGroup(label: 'Money', children: [
            SettingsRow(
              label: 'Accounts',
              onTap: () => context.push('/accounts'),
            ),
            SettingsRow(
              label: 'Budgets',
              value: '${budgets.length} active',
              onTap: () => context.push('/budgets'),
            ),
            SettingsRow(
              label: 'Scans this month',
              value: profile == null
                  ? '—'
                  : profile.hasUnlimitedScans
                      ? 'Unlimited'
                      : '${profile.scansUsedThisMonth} / ${profile.scanQuota}',
              showChevron: false,
              onTap: null,
            ),
          ]),

          SettingsGroup(label: 'Subscription', children: [
            SettingsRow(
              label: 'Plan',
              value: profile?.tier.toUpperCase() ?? 'FREE',
              onTap: () => context.push('/billing/manage'),
            ),
            SettingsRow(
              label: 'Billing & receipts',
              onTap: () => context.push('/billing'),
            ),
          ]),

          SettingsGroup(label: 'Privacy & data', children: [
            SettingsRow(
              label: 'Security',
              onTap: () => context.push('/settings/security'),
            ),
            SettingsRow(
              label: 'Notifications',
              onTap: () => context.push('/settings/notifications'),
            ),
            SettingsRow(
              label: 'Export data',
              value: 'CSV / PDF',
              onTap: () => context.push('/reports/export'),
            ),
            SettingsRow(
              label: 'Delete account',
              destructive: true,
              showChevron: false,
              onTap: () => _confirmDelete(context),
            ),
          ]),

          SettingsGroup(label: 'About', children: [
            SettingsRow(
              label: 'Help & support',
              onTap: () => context.push('/settings/about'),
            ),
            SettingsRow(
              label: 'Terms & privacy',
              onTap: () => context.push('/settings/about'),
            ),
            const SettingsRow(
              label: 'Version',
              value: '1.0.0',
              showChevron: false,
            ),
          ]),

          const SizedBox(height: 24),
          SettingsGroup(label: 'Debug', children: [
            _OfflineToggle(),
          ]),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: LoitButton.secondary(
              label: 'Sign out',
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

  static String _symbol(String code) {
    switch (code) {
      case 'IDR':
        return 'Rp';
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      case 'JPY':
        return '¥';
      case 'SGD':
        return 'S\$';
      case 'MYR':
        return 'RM';
      default:
        return code;
    }
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
    final v = await _pickValue(
      context: context,
      title: 'Home currency',
      options: kCommonCurrencies,
      current: current,
    );
    if (v == null || v == current) return;
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    await Supabase.instance.client
        .from('users')
        .update({'home_currency': v}).eq('id', user.id);
    await ref.read(preferencesProvider.notifier).setCurrency(v);
    ref.invalidate(userProfileProvider);
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
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete account?'),
        content: const Text(
          'All your data will be permanently removed. This cannot be undone.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Account deletion requires email to support.'),
      ),
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
    final override = ref.watch(offlineDebugOverrideProvider);
    return SettingsToggleRow(
      label: 'Simulate offline',
      helper: 'Show the offline banner for testing',
      value: override == true,
      onChanged: (v) =>
          ref.read(offlineDebugOverrideProvider.notifier).set(v ? true : null),
    );
  }
}
