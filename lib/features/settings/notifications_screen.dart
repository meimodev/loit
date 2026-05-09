import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/loit_colors.dart';
import '../../core/theme/loit_typography.dart';
import '../../l10n/l10n_x.dart';
import '../../shared/providers/preferences_provider.dart';
import '_widgets.dart';

class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.loitColors;
    final l = context.l10n;
    final prefs = ref.watch(preferencesProvider).value ?? const AppPreferences();
    final notifier = ref.read(preferencesProvider.notifier);
    void set(String key, bool v) => notifier.setBool(key, v);

    return Scaffold(
      backgroundColor: c.canvas,
      appBar: AppBar(
        title: Text(l.notifTitle),
        backgroundColor: c.canvas,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          SettingsGroup(label: l.notifBudgets, children: [
            SettingsToggleRow(
              label: l.notifApproachingLimit,
              helper: l.notifApproachingLimitHelper,
              value: prefs.notifBudgetAlerts,
              onChanged: (v) => set(PrefKeys.notifBudgetAlerts, v),
            ),
            SettingsToggleRow(
              label: l.notifWeeklyDigest,
              helper: l.notifWeeklyDigestHelper,
              value: prefs.notifBudgetWeeklyDigest,
              onChanged: (v) => set(PrefKeys.notifBudgetWeeklyDigest, v),
            ),
          ]),
          SettingsGroup(label: l.notifRooms, children: [
            SettingsToggleRow(
              label: l.notifNewTransactions,
              value: prefs.notifRoomActivity,
              onChanged: (v) => set(PrefKeys.notifRoomActivity, v),
            ),
            SettingsToggleRow(
              label: l.notifMentionsInvites,
              value: prefs.notifRoomMentions,
              onChanged: (v) => set(PrefKeys.notifRoomMentions, v),
            ),
          ]),
          SettingsGroup(label: l.notifReceipts, children: [
            SettingsToggleRow(
              label: l.notifExpiryReminders,
              helper: l.notifExpiryRemindersHelper,
              value: prefs.notifReceiptExpiry,
              onChanged: (v) => set(PrefKeys.notifReceiptExpiry, v),
            ),
          ]),
          SettingsGroup(label: l.notifDigestsNews, children: [
            SettingsToggleRow(
              label: l.notifMonthlySummary,
              value: prefs.notifMonthlyDigest,
              onChanged: (v) => set(PrefKeys.notifMonthlyDigest, v),
            ),
            SettingsToggleRow(
              label: l.notifProductUpdates,
              value: prefs.notifProductUpdates,
              onChanged: (v) => set(PrefKeys.notifProductUpdates, v),
            ),
          ]),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Text(
              l.notifSystemFooter,
              style: LoitTypography.bodyS.copyWith(color: c.contentTertiary),
            ),
          ),
        ],
      ),
    );
  }
}
