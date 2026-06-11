import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/reachability_service.dart';
import '../../core/theme/loit_colors.dart';
import '../../core/theme/loit_elevation.dart';
import '../../core/theme/loit_motion.dart';
import '../../core/theme/loit_spacing.dart';
import '../../l10n/l10n_x.dart';
import 'loit_banner.dart';

class PersistentConnectivityBanner extends ConsumerStatefulWidget {
  const PersistentConnectivityBanner({super.key});

  @override
  ConsumerState<PersistentConnectivityBanner> createState() =>
      _PersistentConnectivityBannerState();
}

class _PersistentConnectivityBannerState
    extends ConsumerState<PersistentConnectivityBanner> {
  bool _minimized = false;
  Timer? _autoMinimizeTimer;

  void _startAutoMinimizeTimer() {
    _cancelTimer();
    _autoMinimizeTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _minimized = true);
    });
  }

  void _cancelTimer() {
    _autoMinimizeTimer?.cancel();
    _autoMinimizeTimer = null;
  }

  @override
  void dispose() {
    _cancelTimer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(reachabilityProvider, (prev, next) {
      final wasOffline =
          prev?.maybeWhen(data: (online) => !online, orElse: () => false) ??
              false;
      final isOfflineNow =
          next.maybeWhen(data: (online) => !online, orElse: () => false);
      if (isOfflineNow && !wasOffline) {
        _minimized = false;
        _startAutoMinimizeTimer();
      } else if (!isOfflineNow) {
        _minimized = false;
        _cancelTimer();
      }
    });

    final async = ref.watch(reachabilityProvider);
    final bool offline =
        async.maybeWhen(data: (online) => !online, orElse: () => false);

    final bottomOffset =
        64 + MediaQuery.of(context).padding.bottom + LoitSpacing.s2;
    final screenWidth = MediaQuery.of(context).size.width;
    final double right = _minimized
        ? screenWidth - LoitSpacing.s4 - 44
        : LoitSpacing.s4;

    return AnimatedPositioned(
      left: LoitSpacing.s4,
      right: right,
      bottom: offline ? bottomOffset : -(96 + bottomOffset),
      duration: LoitMotion.base,
      curve: LoitMotion.emphasizedCurve,
      child: IgnorePointer(
        ignoring: !offline,
        child: AnimatedOpacity(
          opacity: offline ? 1.0 : 0.0,
          duration: LoitMotion.short,
          curve: LoitMotion.emphasizedCurve,
          child: AnimatedSwitcher(
            duration: LoitMotion.base,
            switchInCurve: LoitMotion.emphasizedCurve,
            switchOutCurve: LoitMotion.easeOut,
            transitionBuilder: (child, animation) {
              final curved = CurvedAnimation(
                parent: animation,
                curve: LoitMotion.emphasizedCurve,
              );
              return FadeTransition(
                opacity: curved,
                child: ScaleTransition(
                  scale: Tween<double>(begin: 0.85, end: 1).animate(curved),
                  child: child,
                ),
              );
            },
            child: _minimized ? _iconButton() : _banner(),
          ),
        ),
      ),
    );
  }

  Widget _banner() {
    return SafeArea(
      top: false,
      child: LoitBanner(
        key: const ValueKey('banner'),
        kind: LoitBannerKind.offline,
        title: context.l10n.connectivityOfflineTitle,
        body: context.l10n.connectivityOfflineBody,
        onDismiss: () {
          _cancelTimer();
          setState(() => _minimized = true);
        },
      ),
    );
  }

  Widget _iconButton() {
    final c = context.loitColors;
    return Container(
      key: const ValueKey('icon'),
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: c.surface,
        shape: BoxShape.circle,
        border: Border.all(color: c.borderSubtle, width: 1),
        boxShadow: LoitElevation.e2,
      ),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () {
            _cancelTimer();
            setState(() => _minimized = false);
          },
          child: Icon(Icons.cloud_off_rounded, size: 20, color: c.warning),
        ),
      ),
    );
  }
}
