import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/loit_motion.dart';
import '../../core/theme/loit_spacing.dart';
import 'connectivity_banner.dart';
import 'loit_banner.dart';

class PersistentConnectivityBanner extends ConsumerWidget {
  const PersistentConnectivityBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(connectivityProvider);
    final bool offline = async.maybeWhen(
      data: isOffline,
      orElse: () => false,
    );

    return AnimatedSwitcher(
      duration: LoitMotion.base,
      switchInCurve: LoitMotion.emphasizedCurve,
      switchOutCurve: LoitMotion.easeOut,
      transitionBuilder: (child, animation) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: LoitMotion.emphasizedCurve,
          reverseCurve: LoitMotion.easeOut,
        );
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, -0.2),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
      child: offline
          ? Padding(
              key: const ValueKey('offline'),
              padding: const EdgeInsets.fromLTRB(
                LoitSpacing.s4,
                LoitSpacing.s2,
                LoitSpacing.s4,
                0,
              ),
              child: SafeArea(
                bottom: false,
                child: const LoitBanner(
                  kind: LoitBannerKind.offline,
                  title: "You're offline",
                  body:
                      'Changes are saved locally and will sync when you reconnect.',
                ),
              ),
            )
          : const SizedBox(key: ValueKey('online')),
    );
  }
}
