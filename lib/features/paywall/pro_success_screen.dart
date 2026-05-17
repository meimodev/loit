import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/loit_colors.dart';
import '../../core/theme/loit_typography.dart';
import '../../l10n/l10n_x.dart';
import '../../shared/providers/auth_providers.dart';
import '../../shared/widgets/loit_button.dart';

class ProSuccessScreen extends ConsumerWidget {
  const ProSuccessScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.loitColors;
    final l10n = context.l10n;
    final profile = ref.watch(userProfileProvider).value;
    final renewal = profile?.tier == 'pro' || profile?.tier == 'lite'
        ? _renewalLabel()
        : null;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [c.successSurface, c.canvas],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          Container(
                            width: 96,
                            height: 96,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [c.brand, c.accent],
                              ),
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: c.brand.withValues(alpha: 0.3),
                                  blurRadius: 32,
                                  offset: const Offset(0, 12),
                                ),
                              ],
                            ),
                            child: const Icon(Icons.check,
                                size: 48, color: Colors.white),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            l10n.pwProSuccessTitle,
                            style: LoitTypography.labelS.copyWith(
                              color: c.brand,
                              letterSpacing: 1.2,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            l10n.pwProSuccessBody,
                            textAlign: TextAlign.center,
                            style: LoitTypography.titleL.copyWith(
                              color: c.contentPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 28,
                              height: 34 / 28,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 10),
                          if (renewal != null)
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 280),
                              child: Text(
                                'Your subscription renews $renewal.',
                                textAlign: TextAlign.center,
                                style: LoitTypography.bodyM.copyWith(
                                  color: c.contentSecondary,
                                  height: 20 / 14,
                                ),
                              ),
                            ),
                          const SizedBox(height: 24),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 320),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: c.surface,
                                borderRadius: BorderRadius.circular(14),
                                border:
                                    Border.all(color: c.borderSubtle),
                              ),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'NOW UNLOCKED',
                                    style: LoitTypography.labelS.copyWith(
                                      color: c.contentSecondary,
                                      letterSpacing: 0.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  for (final f in const [
                                    'Unlimited budgets',
                                    'Unlimited receipt scans',
                                    'CSV & PDF export',
                                    'Multi-currency',
                                    'Advanced insights',
                                  ])
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 5),
                                      child: Row(
                                        children: [
                                          Icon(Icons.check,
                                              size: 16, color: c.brand),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              f,
                                              style: LoitTypography.bodyM
                                                  .copyWith(
                                                color: c.contentPrimary,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                LoitButton.primary(
                  label: l10n.pwProSuccessDone,
                  size: LoitButtonSize.l,
                  fullWidth: true,
                  onPressed: () => context.go('/'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _renewalLabel() {
    final renews = DateTime.now().add(const Duration(days: 365));
    return DateFormat('d MMM y').format(renews);
  }
}
