import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme/loit_colors.dart';
import '../../core/theme/loit_typography.dart';
import '../../core/services/analytics_service.dart';
import '../../core/services/push_service.dart';
import '../../shared/providers/auth_providers.dart';
import '../../shared/providers/budgets_provider.dart';
import '../../shared/widgets/loit_button.dart';
import '_widgets.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.loitColors;
    final profile = ref.watch(userProfileProvider).value;
    final budgets = ref.watch(budgetsProvider).value ?? const [];

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
              value: 'English (US)',
              onTap: () => context.push('/settings/preferences'),
            ),
            SettingsRow(
              label: 'Currency',
              value: '${profile?.homeCurrency ?? 'IDR'} · ${_symbol(profile?.homeCurrency ?? 'IDR')}',
              onTap: () => context.push('/settings/preferences'),
            ),
            SettingsRow(
              label: 'Region',
              value: 'Indonesia',
              onTap: () => context.push('/settings/preferences'),
            ),
          ]),

          SettingsGroup(label: 'Money', children: [
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
