import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/reachability_service.dart';
import '../../core/theme/loit_motion.dart';
import '../../core/theme/loit_spacing.dart';
import '../../l10n/l10n_x.dart';
import 'loit_banner.dart';

/// Floating offline indicator docked above the bottom nav. Slides up + fades in
/// while offline, slides down on reconnect. Backed by [reachabilityProvider] so
/// it agrees with the write-path gate in `transactions_provider`.
class PersistentConnectivityBanner extends ConsumerWidget {
  const PersistentConnectivityBanner({super.key});

  // Approx banner height used to park the card fully off-screen when online.
  static const double _hiddenOffset = 120;

  // Vertical clearance for the bottom-right FAB (56 height + ~16 gap) so the
  // full-width banner floats above it instead of overlapping.
  static const double _fabClearance = 72;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(reachabilityProvider);
    final bool offline =
        async.maybeWhen(data: (online) => !online, orElse: () => false);

    final bottomOffset = 64 +
        MediaQuery.of(context).padding.bottom +
        LoitSpacing.s2 +
        _fabClearance;

    return AnimatedPositioned(
      left: LoitSpacing.s4,
      right: LoitSpacing.s4,
      bottom: offline ? bottomOffset : -_hiddenOffset,
      duration: LoitMotion.base,
      curve: LoitMotion.emphasizedCurve,
      child: IgnorePointer(
        ignoring: !offline,
        child: AnimatedOpacity(
          opacity: offline ? 1.0 : 0.0,
          duration: LoitMotion.short,
          curve: LoitMotion.emphasizedCurve,
          // Banner sits in MaterialApp.builder Stack as a sibling of the router
          // child, with no Scaffold/Material ancestor. Without this Material the
          // Text falls back to the default yellow-underlined debug style.
          child: Material(
            type: MaterialType.transparency,
            child: SafeArea(
              top: false,
              child: LoitBanner(
                kind: LoitBannerKind.offline,
                title: context.l10n.connectivityOfflineTitle,
                body: context.l10n.connectivityOfflineBody,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
