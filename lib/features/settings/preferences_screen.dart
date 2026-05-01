import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/categories.dart';
import '../../core/theme/loit_colors.dart';
import '../../core/theme/loit_typography.dart';
import '../../shared/providers/auth_providers.dart';
import '../../shared/providers/preferences_provider.dart';
import '_widgets.dart';

const _kLanguageCodes = {'English (US)': 'en', 'Bahasa Indonesia': 'id'};
const _kRegionCodes = {
  'Indonesia': 'ID',
  'Singapore': 'SG',
  'Malaysia': 'MY',
  'Other': 'XX',
};

String _languageLabel(String code) => _kLanguageCodes.entries
    .firstWhere((e) => e.value == code, orElse: () => _kLanguageCodes.entries.first)
    .key;

String _regionLabel(String code) => _kRegionCodes.entries
    .firstWhere((e) => e.value == code, orElse: () => _kRegionCodes.entries.first)
    .key;

class PreferencesScreen extends ConsumerWidget {
  const PreferencesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.loitColors;
    final profile = ref.watch(userProfileProvider).value;
    final prefs = ref.watch(preferencesProvider).value ?? const AppPreferences();
    final notifier = ref.read(preferencesProvider.notifier);

    return Scaffold(
      backgroundColor: c.canvas,
      appBar: AppBar(
        title: const Text('Preferences'),
        backgroundColor: c.canvas,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          SettingsGroup(label: 'Language', children: [
            SettingsRow(
              label: 'App language',
              value: _languageLabel(prefs.language == 'system' ? 'en' : prefs.language),
              onTap: () => _pick(
                context: context,
                title: 'Language',
                options: _kLanguageCodes.keys.toList(),
                current: _languageLabel(prefs.language == 'system' ? 'en' : prefs.language),
                onChosen: (v) => notifier.setLanguage(_kLanguageCodes[v] ?? 'en'),
              ),
            ),
          ]),
          SettingsGroup(label: 'Currency', children: [
            SettingsRow(
              label: 'Home currency',
              value: profile?.homeCurrency ?? 'IDR',
              onTap: () => _pickCurrency(context, ref, profile?.homeCurrency ?? 'IDR'),
            ),
          ]),
          SettingsGroup(label: 'Region', children: [
            SettingsRow(
              label: 'Country',
              value: _regionLabel(prefs.region),
              onTap: () => _pick(
                context: context,
                title: 'Region',
                options: _kRegionCodes.keys.toList(),
                current: _regionLabel(prefs.region),
                onChosen: (v) => notifier.setRegion(_kRegionCodes[v] ?? 'ID'),
              ),
            ),
          ]),
          SettingsGroup(label: 'Appearance', children: [
            SettingsRow(
              label: 'Theme',
              value: _themeLabel(prefs.themeMode),
              onTap: () => _pick(
                context: context,
                title: 'Theme',
                options: const ['System', 'Light', 'Dark'],
                current: _themeLabel(prefs.themeMode),
                onChosen: (v) => notifier.setThemeMode(_themeFrom(v)),
              ),
            ),
          ]),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Text(
              'Theme + language preferences will sync across devices in a future release.',
              style: LoitTypography.bodyS
                  .copyWith(color: c.contentTertiary),
            ),
          ),
        ],
      ),
    );
  }

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
            for (final o in options)
              InkWell(
                onTap: () => Navigator.pop(ctx, o),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(o,
                            style: LoitTypography.bodyL
                                .copyWith(color: c.contentPrimary)),
                      ),
                      if (o == current)
                        Icon(Icons.check, size: 20, color: c.brand),
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
}
