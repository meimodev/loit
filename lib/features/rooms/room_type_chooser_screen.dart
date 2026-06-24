import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/loit_colors.dart';
import '../../core/theme/loit_radius.dart';
import '../../core/theme/loit_spacing.dart';
import '../../core/theme/loit_typography.dart';
import '../../shared/providers/auth_providers.dart';
import '../paywall/paywall_screen.dart';

/// Create entry point: pick the room flavour (Org type, ADR 0019). General
/// routes to the existing create form unchanged; Church is Pro-gated and routes
/// to the church onboarding flow.
///
// ponytail: copy hardcoded Indonesian — church domain (denominasi, jemaat,
// penerimaan) is Indonesian-only; bilingual l10n for it would be busywork.
class RoomTypeChooserScreen extends ConsumerWidget {
  const RoomTypeChooserScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.loitColors;
    return Scaffold(
      backgroundColor: c.canvas,
      appBar: AppBar(
        title: const Text('Jenis Room'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(LoitSpacing.s4),
        children: [
          _TypeCard(
            icon: Icons.groups_outlined,
            title: 'Room Umum',
            subtitle: 'Bagi pengeluaran bareng — keluarga, trip, kos.',
            onTap: () => context.push('/rooms/new/general'),
          ),
          const SizedBox(height: LoitSpacing.s3),
          _TypeCard(
            icon: Icons.church_outlined,
            title: 'Room Gereja',
            subtitle:
                'Catat keuangan jemaat — kategori sesuai denominasi, laporan siap cetak.',
            badge: 'PRO',
            onTap: () => _onChurch(context, ref),
          ),
        ],
      ),
    );
  }

  void _onChurch(BuildContext context, WidgetRef ref) {
    final tier = ref.read(userProfileProvider).value?.tier;
    if (tier != 'pro') {
      showPaywallSheet(context, feature: 'church_room');
      return;
    }
    context.push('/rooms/new/church');
  }
}

class _TypeCard extends StatelessWidget {
  const _TypeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.badge,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.loitColors;
    return InkWell(
      borderRadius: LoitRadius.brM,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(LoitSpacing.s4),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: LoitRadius.brM,
          border: Border.all(color: c.borderSubtle),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: c.muted,
                borderRadius: LoitRadius.brM,
              ),
              alignment: Alignment.center,
              child: Icon(icon, color: c.brand, size: 24),
            ),
            const SizedBox(width: LoitSpacing.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(title,
                          style: LoitTypography.titleM.copyWith(
                              color: c.contentPrimary,
                              fontWeight: FontWeight.w600)),
                      if (badge != null) ...[
                        const SizedBox(width: LoitSpacing.s2),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: c.brand,
                            borderRadius: LoitRadius.brS,
                          ),
                          child: Text(badge!,
                              style: LoitTypography.labelS.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5)),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: LoitSpacing.s1),
                  Text(subtitle,
                      style: LoitTypography.bodyS
                          .copyWith(color: c.contentSecondary)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, size: 18, color: c.contentTertiary),
          ],
        ),
      ),
    );
  }
}
