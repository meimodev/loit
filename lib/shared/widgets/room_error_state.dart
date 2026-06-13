import 'package:flutter/material.dart';

import '../../core/services/reachability_service.dart' show isNetworkError;
import '../../l10n/l10n_x.dart';
import 'loit_empty_state.dart';

/// Shows the canonical "rooms need internet" snackbar after a room write was
/// refused offline (catches [OnlineOnlyActionException]). ADR 0014.
void showRoomOnlineOnlySnack(BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(context.l10n.roomActionOnlineOnly)),
  );
}

/// Read-error state for room surfaces (ADR 0014). Classifies the failure: a
/// network-class error renders an honest "you're offline" state (rooms are
/// online-only and auto-heal on reconnect), anything else renders a generic
/// "couldn't load". Both offer a Retry that re-runs [onRetry].
class RoomErrorState extends StatelessWidget {
  const RoomErrorState({
    super.key,
    required this.error,
    required this.onRetry,
    this.compact = false,
  });

  final Object error;
  final VoidCallback onRetry;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final offline = isNetworkError(error);
    return LoitEmptyState(
      compact: compact,
      icon: offline ? Icons.cloud_off_outlined : Icons.error_outline,
      title: offline ? l.roomsOfflineTitle : l.roomsLoadErrorTitle,
      body: offline ? l.roomsOfflineBody : l.roomsLoadError,
      primaryCta: l.roomsLoadRetry,
      onPrimaryCta: onRetry,
    );
  }
}
