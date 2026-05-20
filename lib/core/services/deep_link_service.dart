import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'log_service.dart';

const _pendingInviteKey = 'pending_invite_token';

/// Quick-actions notification URIs (`loit://`) routed straight through the
/// app router. Held as a broadcast stream so multiple listeners (the app
/// shell, tests) can subscribe.
final quickActionsDeepLinkProvider = StreamProvider<String>((ref) {
  final controller = StreamController<String>.broadcast();
  ref.onDispose(controller.close);
  return controller.stream;
});

String? _quickActionsPathFor(Uri uri) {
  if (uri.scheme != 'loit') return null;
  // Preserve `?highlight=...` (used by bot deep links).
  String withQuery(String path) {
    if (uri.queryParameters.isEmpty) return path;
    final qp = Uri(queryParameters: uri.queryParameters).query;
    return qp.isEmpty ? path : '$path?$qp';
  }
  switch (uri.host) {
    case 'scan':
      return '/scan';
    case 'transactions':
      // `loit://transactions/add`            → `/transactions/new`
      // `loit://transactions/{id}`           → `/transactions/{id}`
      // `loit://transactions?highlight=...`  → `/transactions?highlight=...`
      if (uri.pathSegments.isNotEmpty) {
        final first = uri.pathSegments.first;
        if (first == 'add') return '/transactions/new';
        return withQuery('/transactions/$first');
      }
      return withQuery('/transactions');
    case 'rooms':
      // `loit://rooms`                                              → `/rooms`
      // `loit://rooms/{roomId}`                                     → `/rooms/{roomId}`
      // `loit://rooms/{roomId}/transactions/{txnId}`                → `/rooms/{roomId}/transactions/{txnId}`
      if (uri.pathSegments.isEmpty) return '/rooms';
      return withQuery('/${(<String>['rooms', ...uri.pathSegments]).join('/')}');
  }
  return null;
}

final deepLinkRoomIdProvider = StreamProvider<String>((ref) {
  final controller = StreamController<String>();
  final appLinks = AppLinks();
  StreamSubscription<Uri>? sub;

  Future<String?> handle(Uri uri) async {
    Log.d('DeepLink', 'Received: $uri');
    Log.breadcrumb('deep-link', 'received', data: {
      'scheme': uri.scheme,
      'host': uri.host,
      'path': uri.path,
      'hasCode': uri.queryParameters.containsKey('code'),
    });
    // Quick-actions deep links: hand off via the dedicated provider's stream
    // controller. We can't drive `quickActionsDeepLinkProvider` from outside
    // its closure, so we send via a static singleton instead.
    final quickPath = _quickActionsPathFor(uri);
    if (quickPath != null) {
      QuickActionsDeepLinkBus.instance.emit(quickPath);
      return null;
    }
    // Matches https://loit.app/invite/{token} (path starts with /invite/)
    // and id.activid.loit://invite/{token} (host == 'invite').
    final isHttpsInvite = uri.path.startsWith('/invite/');
    final isCustomSchemeInvite = uri.host == 'invite';
    if (!isHttpsInvite && !isCustomSchemeInvite) return null;
    final token = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : '';
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

/// Singleton bus for quick-actions deep links. The router shell subscribes
/// in `app.dart` and forwards each event to `GoRouter.go`.
class QuickActionsDeepLinkBus {
  QuickActionsDeepLinkBus._();
  static final instance = QuickActionsDeepLinkBus._();

  final _controller = StreamController<String>.broadcast();

  Stream<String> get stream => _controller.stream;

  void emit(String path) => _controller.add(path);
}

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
