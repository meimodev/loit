import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_providers.dart';

/// Stream of currently-online user ids based on Supabase Realtime presence.
///
/// All app users join a single global "online-users" channel keyed by their
/// user id. The presence state across that channel is the set of online
/// users — surfaced to the UI as a `Set<String>` of user ids.
///
/// The provider auto-tracks the current user when subscribed and untracks
/// on dispose, so simply watching this provider is enough to be "online".
final onlineUsersProvider = StreamProvider<Set<String>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value(const <String>{});

  final controller = StreamController<Set<String>>();
  final channel = Supabase.instance.client.channel(
    'online-users',
    opts: RealtimeChannelConfig(key: user.id),
  );

  void emit() {
    if (controller.isClosed) return;
    final state = channel.presenceState();
    final ids = state.map((s) => s.key).toSet();
    controller.add(ids);
  }

  channel
      .onPresenceSync((_) => emit())
      .onPresenceJoin((_) => emit())
      .onPresenceLeave((_) => emit())
      .subscribe((status, [_]) async {
    if (status == RealtimeSubscribeStatus.subscribed) {
      try {
        await channel.track({
          'user_id': user.id,
          'online_at': DateTime.now().toUtc().toIso8601String(),
        });
      } catch (_) {
        /* ignore — presence is best-effort */
      }
    }
  });

  ref.onDispose(() async {
    try {
      await channel.untrack();
    } catch (_) {}
    await channel.unsubscribe();
    await controller.close();
  });

  return controller.stream;
});
