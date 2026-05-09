import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme/loit_colors.dart';
import '../../core/theme/loit_typography.dart';
import '../../l10n/l10n_x.dart';
import '../../shared/providers/auth_providers.dart';
import '../../shared/providers/preferences_provider.dart';
import '../../shared/widgets/loit_button.dart';
import '../../shared/widgets/loit_input.dart';
import '_widgets.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  bool _saving = false;
  bool _hydrated = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    super.dispose();
  }

  void _hydrate(UserProfile p) {
    _name.text = p.name;
    _email.text = p.email;
    _hydrated = true;
  }

  Future<void> _save() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    setState(() => _saving = true);
    final l = context.l10n;
    try {
      await Supabase.instance.client
          .from('users')
          .update({'name': _name.text.trim()}).eq('id', user.id);
      ref.invalidate(userProfileProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.profileSaved)),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.profileSaveFailed(e.toString()))),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.loitColors;
    final l = context.l10n;
    final profileAsync = ref.watch(userProfileProvider);
    final profile = profileAsync.value;
    if (profile != null && !_hydrated) _hydrate(profile);
    final prefs = ref.watch(preferencesProvider).value ?? const AppPreferences();
    final notifier = ref.read(preferencesProvider.notifier);

    return Scaffold(
      backgroundColor: c.canvas,
      appBar: AppBar(
        title: Text(l.profileTitle),
        backgroundColor: c.canvas,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Center(
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      SettingsAvatar(
                        initials:
                            (profile?.name.isNotEmpty ?? false)
                                ? profile!.name[0].toUpperCase()
                                : '?',
                        color: c.brand,
                        size: 88,
                      ),
                      Positioned(
                        right: -4,
                        bottom: -4,
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: c.brand,
                            shape: BoxShape.circle,
                            border: Border.all(color: c.canvas, width: 3),
                          ),
                          child: const Icon(Icons.camera_alt,
                              size: 16, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                LoitInput(controller: _name, label: l.profileName),
                const SizedBox(height: 10),
                LoitInput(
                  controller: _email,
                  label: l.profileEmail,
                  enabled: false,
                  helper: l.profileEmailHelper,
                ),
                const SizedBox(height: 10),
                LoitInput(
                    controller: _phone,
                    label: l.profilePhone,
                    keyboardType: TextInputType.phone),
                const SizedBox(height: 18),
                Text(
                  l.profileNotifications,
                  style: LoitTypography.labelS.copyWith(
                    color: c.contentSecondary,
                    letterSpacing: 0.8,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: c.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: c.borderSubtle),
                  ),
                  child: Column(
                    children: [
                      SettingsToggleRow(
                        label: l.profileBudgetAlerts,
                        value: prefs.notifBudgetAlerts,
                        onChanged: (v) =>
                            notifier.setBool(PrefKeys.notifBudgetAlerts, v),
                      ),
                      SettingsToggleRow(
                        label: l.profileRoomActivity,
                        value: prefs.notifRoomActivity,
                        onChanged: (v) =>
                            notifier.setBool(PrefKeys.notifRoomActivity, v),
                      ),
                      SettingsToggleRow(
                        label: l.notifWeeklyDigest,
                        value: prefs.notifBudgetWeeklyDigest,
                        onChanged: (v) => notifier.setBool(
                            PrefKeys.notifBudgetWeeklyDigest, v),
                      ),
                      SettingsToggleRow(
                        label: l.notifProductUpdates,
                        value: prefs.notifProductUpdates,
                        onChanged: (v) =>
                            notifier.setBool(PrefKeys.notifProductUpdates, v),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: c.surface,
              border: Border(
                top: BorderSide(color: c.borderSubtle, width: 1),
              ),
            ),
            child: SafeArea(
              top: false,
              child: LoitButton.primary(
                label: l.profileSaveChanges,
                size: LoitButtonSize.l,
                fullWidth: true,
                loading: _saving,
                onPressed: _saving ? null : _save,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
