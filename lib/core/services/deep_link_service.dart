import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'log_service.dart';

const _pendingInviteKey = 'pending_invite_token';

final deepLinkRoomIdProvider = StreamProvider<String>((ref) {
  final controller = StreamController<String>();
  final appLinks = AppLinks();
  StreamSubscription<Uri>? sub;

  Future<String?> handle(Uri uri) async {
    Log.d('DeepLink', 'Received: $uri');
    if (!uri.path.startsWith('/invite/')) return null;
    final token = uri.pathSegments.last;
    if (token.isEmpty) return null;

    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) {
      Log.i('DeepLink', 'Not signed in, stashing invite token');
      const storage = FlutterSecureStorage();
      await storage.write(key: _pendingInviteKey, value: token);
      return null;
    }

    Log.i('DeepLink', 'Accepting invite via deep link');
    final roomId = await Supabase.instance.client
        .rpc('accept_room_invite', params: {'p_invite_token': token});
    Log.i('DeepLink', 'Invite accepted: roomId=$roomId');
    return roomId as String?;
  }

  // Cold start
  appLinks.getInitialLink().then((uri) async {
    if (uri != null) {
      final roomId = await handle(uri);
      if (roomId != null) controller.add(roomId);
    }
  });

  // Warm state
  sub = appLinks.uriLinkStream.listen((uri) async {
    final roomId = await handle(uri);
    if (roomId != null) controller.add(roomId);
  });

  ref.onDispose(() {
    sub?.cancel();
    controller.close();
  });

  return controller.stream;
});

/// Call after login to accept any pending invite stored during cold-start
/// when user wasn't authenticated.
Future<String?> acceptPendingInviteIfAny() async {
  const storage = FlutterSecureStorage();
  final token = await storage.read(key: _pendingInviteKey);
  if (token == null) return null;

  await storage.delete(key: _pendingInviteKey);
  final roomId = await Supabase.instance.client
      .rpc('accept_room_invite', params: {'p_invite_token': token});
  return roomId as String?;
}
