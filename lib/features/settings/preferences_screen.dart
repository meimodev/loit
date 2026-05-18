import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme/loit_colors.dart';
import '../../core/theme/loit_typography.dart';
import '../../l10n/l10n_x.dart';
import '../../shared/providers/accounts_provider.dart';
import '../../shared/providers/auth_providers.dart';
import '../../shared/providers/preferences_provider.dart';
import '../../shared/providers/transactions_provider.dart';
import '../../shared/widgets/currency_picker_sheet.dart';
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

class PreferencesScreen extends ConsumerWidget {
  const PreferencesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.loitColors;
    final l = context.l10n;
    final profile = ref.watch(userProfileProvider).value;
    final prefs = ref.watch(preferencesProvider).value ?? const AppPreferences();
    final notifier = ref.read(preferencesProvider.notifier);

    return Scaffold(
      backgroundColor: c.canvas,
      appBar: AppBar(
        title: Text(l.prefsTitle),
        backgroundColor: c.canvas,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(userProfileProvider);
          ref.invalidate(preferencesProvider);
          await ref.read(userProfileProvider.future);
        },
        child: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SettingsGroup(label: l.prefsLanguage, children: [
            SettingsRow(
              label: l.prefsAppLanguage,
              value: _languageLabel(prefs.language == 'system' ? 'en' : prefs.language),
              onTap: () => _pick(
                context: context,
                title: l.prefsLanguage,
                options: _kLanguageCodes.keys.toList(),
                current: _languageLabel(prefs.language == 'system' ? 'en' : prefs.language),
                onChosen: (v) => notifier.setLanguage(_kLanguageCodes[v] ?? 'en'),
              ),
            ),
          ]),
          SettingsGroup(label: l.prefsCurrency, children: [
            SettingsRow(
              label: l.prefsHomeCurrency,
              value: profile?.homeCurrency ?? 'IDR',
              onTap: () => _pickCurrency(context, ref, profile?.homeCurrency ?? 'IDR'),
            ),
          ]),
          SettingsGroup(label: l.prefsRegion, children: [
            SettingsRow(
              label: l.prefsCountry,
              value: _regionLabel(prefs.region),
              onTap: () => _pick(
                context: context,
                title: l.prefsRegion,
                options: _kRegionCodes.keys.toList(),
                current: _regionLabel(prefs.region),
                onChosen: (v) => notifier.setRegion(_kRegionCodes[v] ?? 'ID'),
              ),
            ),
          ]),
          SettingsGroup(label: l.prefsCategory, children: [
            SettingsRow(
              label: l.prefsManageCategories,
              value: l.prefsCustomize,
              onTap: () => context.push('/categories'),
            ),
          ]),
          SettingsGroup(label: l.prefsAppearance, children: [
            SettingsRow(
              label: l.prefsTheme,
              value: _themeLabel(context, prefs.themeMode),
              onTap: () => _pickTheme(
                context: context,
                current: prefs.themeMode,
                onChosen: (m) => notifier.setThemeMode(m),
              ),
            ),
          ]),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Text(
              l.prefsSyncFooter,
              style: LoitTypography.bodyS.copyWith(color: c.contentTertiary),
            ),
          ),
        ],
      ),
      ),
    );
  }

  Future<void> _pickCurrency(
      BuildContext context, WidgetRef ref, String current) async {
    final l = context.l10n;
    final v = await pickCurrency(
      context,
      selected: current,
      title: l.prefsHomeCurrency,
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

  Future<void> _pickTheme({
    required BuildContext context,
    required ThemeMode current,
    required ValueChanged<ThemeMode> onChosen,
  }) async {
    final opts = _themeOptions(context);
    final v = await _pickValue(
      context: context,
      title: context.l10n.prefsTheme,
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
