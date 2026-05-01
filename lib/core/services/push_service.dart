import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'log_service.dart';

class PushService {
  static const _tag = 'PushService';

  PushService({FirebaseMessaging? messaging, SupabaseClient? supabase})
    : _messaging = messaging ?? FirebaseMessaging.instance,
      _supabase = supabase ?? Supabase.instance.client;

  final FirebaseMessaging _messaging;
  final SupabaseClient _supabase;

  StreamSubscription<String>? _tokenRefreshSubscription;

  Future<bool> initialize() async {
    Log.i(_tag, 'Requesting notification permission');
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    final status = settings.authorizationStatus;
    if (status == AuthorizationStatus.denied) {
      Log.w(_tag, 'Notification permission denied');
      return false;
    }
    Log.i(_tag, 'Permission granted: $status');

    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    await syncCurrentToken();

    await _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription = _messaging.onTokenRefresh.listen((token) {
      Log.i(_tag, 'FCM token refreshed');
      unawaited(_upsertToken(token));
    });

    return true;
  }

  Future<void> syncCurrentToken() async {
    final token = await _messaging.getToken();
    Log.d(_tag, 'FCM token: ${token != null ? '${token.substring(0, 12)}...' : 'null'}');
    await _upsertToken(token);
  }

  Future<void> unregisterCurrentDevice() async {
    final user = _supabase.auth.currentUser;
    final token = await _messaging.getToken();
    if (user == null || token == null) {
      Log.w(_tag, 'Cannot unregister: user or token null');
      return;
    }

    Log.i(_tag, 'Unregistering device token');
    await _supabase
        .from('push_tokens')
        .delete()
        .eq('user_id', user.id)
        .eq('token', token);
  }

  /// Resolve a deep-link path from a push payload. Prefer explicit `deep_link`,
  /// fall back to legacy `room_id` so older payloads still navigate.
  String? _deepLinkOf(RemoteMessage? message) {
    if (message == null) return null;
    final dl = message.data['deep_link'];
    if (dl is String && dl.isNotEmpty) return dl;
    final roomId = message.data['room_id'];
    if (roomId is String && roomId.isNotEmpty) return '/rooms/$roomId';
    return null;
  }

  Future<String?> getInitialDeepLink() async {
    final message = await _messaging.getInitialMessage();
    return _deepLinkOf(message);
  }

  Stream<String> openedDeepLinks() {
    return FirebaseMessaging.onMessageOpenedApp
        .map(_deepLinkOf)
        .where((dl) => dl != null)
        .cast<String>();
  }

  /// Backwards-compatible helpers — extract roomId from deep_link if it
  /// matches `/rooms/<id>`, otherwise from legacy `room_id` field.
  Future<String?> getInitialRoomId() async {
    final dl = await getInitialDeepLink();
    return _roomIdFromPath(dl);
  }

  Stream<String> openedRoomIds() {
    return openedDeepLinks()
        .map(_roomIdFromPath)
        .where((id) => id != null)
        .cast<String>();
  }

  static String? _roomIdFromPath(String? path) {
    if (path == null) return null;
    final m = RegExp(r'^/rooms/([^/?]+)').firstMatch(path);
    return m?.group(1);
  }

  Future<void> dispose() async {
    await _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription = null;
  }

  Future<void> _upsertToken(String? token) async {
    final user = _supabase.auth.currentUser;
    final platform = _platformName();
    if (user == null || token == null || platform == null) {
      Log.w(_tag, 'Skip upsert: user=${user?.id} token=${token != null} platform=$platform');
      return;
    }

    try {
      await _supabase.from('push_tokens').upsert({
        'user_id': user.id,
        'token': token,
        'platform': platform,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }, onConflict: 'token');
      Log.i(_tag, 'Upserted push token for user=${user.id}');
    } catch (e, st) {
      Log.e(_tag, 'Failed to upsert push token', error: e, stack: st);
      rethrow;
    }
  }

  String? _platformName() => 'android';
}
