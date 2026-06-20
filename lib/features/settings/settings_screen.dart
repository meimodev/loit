import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/loit_colors.dart';
import '../../core/theme/loit_motion.dart';
import '../../core/theme/loit_typography.dart';
import '../../core/services/analytics_service.dart';
import '../../core/services/app_update_service.dart';
import '../../core/services/push_service.dart';
import '../../l10n/l10n_x.dart';
import '../../shared/providers/accounts_provider.dart';
import '../../shared/providers/auth_providers.dart';
import '../../shared/providers/budgets_provider.dart';
import '../../shared/providers/messaging_link_provider.dart';
import '../../shared/providers/preferences_provider.dart';
import '../../shared/providers/transactions_provider.dart';
import '../../shared/providers/update_gate_provider.dart';
import '../../shared/widgets/currency_picker_sheet.dart';
import '../../shared/widgets/connectivity_banner.dart';
import '../../shared/widgets/loit_animations.dart';
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
            LoitFadeSlideIn(
              duration: LoitMotion.entrance,
              offset: 14,
              child: LoitTapScale(
                scale: 0.99,
                child: InkWell(
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
                          imageUrl: profile.avatarUrl,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              LoitFadeSlideIn(
                                delay: const Duration(milliseconds: 80),
                                offset: 6,
                                child: Text(
                                  profile.name.isEmpty
                                      ? profile.email
                                      : profile.name,
                                  style: LoitTypography.titleM.copyWith(
                                    color: c.contentPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 2),
                              LoitFadeSlideIn(
                                delay: const Duration(milliseconds: 140),
                                offset: 6,
                                child: Text(profile.email,
                                    style: LoitTypography.bodyS.copyWith(
                                        color: c.contentSecondary)),
                              ),
                              const SizedBox(height: 6),
                              LoitFadeSlideIn(
                                delay: const Duration(milliseconds: 220),
                                offset: 6,
                                child: SettingsTierChip(tier: profile.tier),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right,
                            size: 18, color: c.contentTertiary),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          LoitFadeSlideIn(
            delay: const Duration(milliseconds: 120),
            offset: 10,
            child: SettingsGroup(label: l.settingsGeneral, children: [
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
          ),

          LoitFadeSlideIn(
            delay: const Duration(milliseconds: 200),
            offset: 10,
            child: SettingsGroup(label: l.settingsMoney, children: [
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
                onTap: () => context.push('/settings/scanning'),
              ),
            ]),
          ),

          LoitFadeSlideIn(
            delay: const Duration(milliseconds: 280),
            offset: 10,
            child: SettingsGroup(label: l.settingsSubscription, children: [
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
          ),

          LoitFadeSlideIn(
            delay: const Duration(milliseconds: 320),
            offset: 10,
            child: SettingsGroup(label: l.settingsConnections, children: [
              const _TelegramConnectionRow(),
            ]),
          ),

          LoitFadeSlideIn(
            delay: const Duration(milliseconds: 360),
            offset: 10,
            child: SettingsGroup(label: l.settingsPrivacyData, children: [
              SettingsRow(
                label: l.settingsSecurity,
                onTap: () => context.push('/settings/security'),
              ),
              SettingsRow(
                label: l.settingsNotifications,
                onTap: () => context.push('/settings/notifications'),
              ),
              SettingsRow(
                label: l.scanSettingsSection,
                onTap: () => context.push('/settings/scanning'),
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
          ),

          LoitFadeSlideIn(
            delay: const Duration(milliseconds: 440),
            offset: 10,
              child: SettingsGroup(label: l.settingsAbout, children: [
                const _UpdateAvailableRow(),
                SettingsRow(
                  label: l.settingsHelpSupport,
                  onTap: () => context.push('/settings/about'),
                ),
                FutureBuilder<PackageInfo>(
                  future: PackageInfo.fromPlatform(),
                  builder: (context, snap) {
                    final info = snap.data;
                    final value = info == null
                        ? '…'
                        : '${info.version} (${info.buildNumber})';
                    return SettingsRow(
                      label: l.settingsVersion,
                      value: value,
                      showChevron: false,
                    );
                  },
                ),
              ]),
          ),

          if (kDebugMode) ...[
            const SizedBox(height: 24),
            LoitFadeSlideIn(
              delay: const Duration(milliseconds: 520),
              offset: 10,
              child: SettingsGroup(label: l.settingsDebug, children: [
                _OfflineToggle(),
              ]),
            ),
          ],
          LoitFadeSlideIn(
            delay: const Duration(milliseconds: 600),
            offset: 12,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: LoitTapScale(
                scale: 0.98,
                child: LoitButton.secondary(
                  label: l.settingsSignOut,
                  fullWidth: true,
                  onPressed: () => _signOut(context),
                ),
              ),
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
              child: LoitFadeSlideIn(
                offset: 4,
                duration: LoitMotion.base,
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: c.borderStrong,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            LoitFadeSlideIn(
              delay: const Duration(milliseconds: 60),
              offset: 8,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(title,
                    style: LoitTypography.titleM.copyWith(
                      color: c.contentPrimary,
                      fontWeight: FontWeight.w600,
                    )),
              ),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < options.length; i++)
                      LoitFadeSlideIn(
                        delay: Duration(milliseconds: 120 + i * 50),
                        offset: 10,
                        duration: LoitMotion.emphasized,
                        child: _PickerOption(
                          label: options[i],
                          selected: options[i] == current,
                          onTap: () => Navigator.pop(ctx, options[i]),
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
    await launchUrl(
      Uri.parse('https://www.activid.id/account-deletion'),
      mode: LaunchMode.externalApplication,
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

/// Passive "update available" marker (ADR-0015) for the Optional / Recommended
/// update states. Hidden when the client is Current; Blocked is handled by the
/// full-screen overlay in `app.dart`, not here. Tapping runs the flexible update
/// flow (in-app update + store fallback).
class _UpdateAvailableRow extends ConsumerWidget {
  const _UpdateAvailableRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(updateGateProvider).value;
    final state = status?.state;
    if (state != UpdateState.optional && state != UpdateState.recommended) {
      return const SizedBox.shrink();
    }
    final c = context.loitColors;
    return SettingsRow(
      label: context.l10n.updatePromptTitle,
      onTap: () => appUpdateService.performUpdate(
        immediate: false,
        storeUrl: status!.gate.storeUrl,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: c.brand, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Icon(Icons.chevron_right, size: 18, color: c.contentTertiary),
        ],
      ),
    );
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

class _PickerOption extends StatefulWidget {
  const _PickerOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_PickerOption> createState() => _PickerOptionState();
}

class _PickerOptionState extends State<_PickerOption> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final c = context.loitColors;
    return LoitTapScale(
      scale: 0.985,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: LoitMotion.short,
          curve: LoitMotion.easeOutQuart,
          padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          color: _pressed
              ? Color.alphaBlend(c.brand.withValues(alpha: 0.08), c.surface)
              : (widget.selected
                  ? Color.alphaBlend(c.brand.withValues(alpha: 0.04), c.surface)
                  : c.surface),
          child: Row(
            children: [
              Expanded(
                child: AnimatedDefaultTextStyle(
                  duration: LoitMotion.short,
                  curve: LoitMotion.easeOutQuart,
                  style: LoitTypography.bodyL.copyWith(
                    color: c.contentPrimary,
                    fontWeight: widget.selected
                        ? FontWeight.w600
                        : FontWeight.w400,
                  ),
                  child: Text(widget.label),
                ),
              ),
              AnimatedSwitcher(
                duration: LoitMotion.base,
                switchInCurve: LoitMotion.easeOutExpo,
                switchOutCurve: LoitMotion.easeOutQuart,
                transitionBuilder: (child, anim) {
                  return ScaleTransition(
                    scale: anim,
                    child: FadeTransition(opacity: anim, child: child),
                  );
                },
                child: widget.selected
                    ? Icon(Icons.check,
                        key: const ValueKey('check'),
                        size: 20,
                        color: c.brand)
                    : const SizedBox(
                        key: ValueKey('empty'), width: 20, height: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TelegramConnectionRow extends ConsumerStatefulWidget {
  const _TelegramConnectionRow();

  @override
  ConsumerState<_TelegramConnectionRow> createState() =>
      _TelegramConnectionRowState();
}

class _TelegramConnectionRowState extends ConsumerState<_TelegramConnectionRow>
    with WidgetsBindingObserver {
  Timer? _refresh;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Catch `/end` sent from Telegram while Settings is visible.
    _refresh = Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted) ref.invalidate(telegramLinkStatusProvider);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _refresh?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.invalidate(telegramLinkStatusProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final status = ref.watch(telegramLinkStatusProvider).value;
    final connected = status?.linked ?? false;
    return SettingsRow(
      label: l.settingsTelegram,
      value: connected
          ? l.settingsTelegramConnected
          : l.settingsTelegramNotConnected,
      onTap: () => context.push('/settings/telegram'),
    );
  }
}
