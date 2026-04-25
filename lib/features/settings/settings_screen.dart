import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/categories.dart';
import '../../core/services/analytics_service.dart';
import '../../shared/providers/auth_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider).value;
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          if (profile != null)
            ListTile(
              leading: CircleAvatar(
                backgroundImage: profile.avatarUrl != null
                    ? NetworkImage(profile.avatarUrl!)
                    : null,
                child: profile.avatarUrl == null
                    ? Text(profile.name.isEmpty
                        ? '?'
                        : profile.name[0].toUpperCase())
                    : null,
              ),
              title: Text(profile.name.isEmpty ? profile.email : profile.name),
              subtitle: Text(profile.email),
              trailing: Chip(label: Text(profile.tier.toUpperCase())),
            ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.language),
            title: const Text('Home currency'),
            subtitle: Text(profile?.homeCurrency ?? 'IDR'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _pickCurrency(context, ref, profile),
          ),
          ListTile(
            leading: const Icon(Icons.document_scanner_outlined),
            title: const Text('Scans used this month'),
            subtitle: profile == null
                ? const Text('—')
                : Text('${profile.scansUsedThisMonth} / ${profile.scanQuota}'),
          ),
          ListTile(
            leading: const Icon(Icons.workspace_premium),
            title: const Text('Subscription'),
            subtitle: Text(profile?.tier.toUpperCase() ?? 'FREE'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/paywall', extra: 'general'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Sign out'),
            onTap: () async {
              await Supabase.instance.client.auth.signOut();
              await Analytics.reset();
            },
          ),
        ],
      ),
    );
  }

  void _pickCurrency(
    BuildContext context,
    WidgetRef ref,
    UserProfile? profile,
  ) {
    final current = profile?.homeCurrency ?? 'IDR';
    showDialog(
      context: context,
      builder: (_) => SimpleDialog(
        title: const Text('Home currency'),
        children: [
          for (final c in kCommonCurrencies)
            SimpleDialogOption(
              onPressed: () async {
                Navigator.pop(context);
                if (c == current) return;
                final user = Supabase.instance.client.auth.currentUser;
                if (user == null) return;
                await Supabase.instance.client
                    .from('users')
                    .update({'home_currency': c}).eq('id', user.id);
                ref.invalidate(userProfileProvider);
              },
              child: Row(
                children: [
                  if (c == current)
                    const Icon(Icons.check, size: 20)
                  else
                    const SizedBox(width: 20),
                  const SizedBox(width: 12),
                  Text(c),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
