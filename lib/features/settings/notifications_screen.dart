import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/loit_colors.dart';
import '../../core/theme/loit_typography.dart';
import '../../shared/providers/preferences_provider.dart';
import '_widgets.dart';

class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.loitColors;
    final prefs = ref.watch(preferencesProvider).value ?? const AppPreferences();
    final notifier = ref.read(preferencesProvider.notifier);
    void set(String key, bool v) => notifier.setBool(key, v);

    return Scaffold(
      backgroundColor: c.canvas,
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: c.canvas,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          SettingsGroup(label: 'Budgets', children: [
            SettingsToggleRow(
              label: 'Approaching limit',
              helper: 'When you reach 80% of a budget.',
              value: prefs.notifBudgetAlerts,
              onChanged: (v) => set(PrefKeys.notifBudgetAlerts, v),
            ),
            SettingsToggleRow(
              label: 'Weekly digest',
              helper: 'Summary of last week budget progress.',
              value: prefs.notifBudgetWeeklyDigest,
              onChanged: (v) => set(PrefKeys.notifBudgetWeeklyDigest, v),
            ),
          ]),
          SettingsGroup(label: 'Rooms', children: [
            SettingsToggleRow(
              label: 'New transactions',
              value: prefs.notifRoomActivity,
              onChanged: (v) => set(PrefKeys.notifRoomActivity, v),
            ),
            SettingsToggleRow(
              label: 'Mentions & invites',
              value: prefs.notifRoomMentions,
              onChanged: (v) => set(PrefKeys.notifRoomMentions, v),
            ),
          ]),
          SettingsGroup(label: 'Receipts', children: [
            SettingsToggleRow(
              label: 'Expiry reminders',
              helper: 'Free tier · receipts auto-delete after 90 days.',
              value: prefs.notifReceiptExpiry,
              onChanged: (v) => set(PrefKeys.notifReceiptExpiry, v),
            ),
          ]),
          SettingsGroup(label: 'Digests & news', children: [
            SettingsToggleRow(
              label: 'Monthly summary',
              value: prefs.notifMonthlyDigest,
              onChanged: (v) => set(PrefKeys.notifMonthlyDigest, v),
            ),
            SettingsToggleRow(
              label: 'Product updates',
              value: prefs.notifProductUpdates,
              onChanged: (v) => set(PrefKeys.notifProductUpdates, v),
            ),
          ]),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Text(
              'System push permission is managed in your device settings.',
              style: LoitTypography.bodyS
                  .copyWith(color: c.contentTertiary),
            ),
          ),
        ],
      ),
    );
  }
}
