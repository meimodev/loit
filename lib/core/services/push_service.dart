import 'dart:async';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PushService {
  PushService({FirebaseMessaging? messaging, SupabaseClient? supabase})
    : _messaging = messaging ?? FirebaseMessaging.instance,
      _supabase = supabase ?? Supabase.instance.client;

  final FirebaseMessaging _messaging;
  final SupabaseClient _supabase;

  StreamSubscription<String>? _tokenRefreshSubscription;

  Future<bool> initialize() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    final status = settings.authorizationStatus;
    if (status == AuthorizationStatus.denied) {
      return false;
    }

    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    await syncCurrentToken();

    await _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription = _messaging.onTokenRefresh.listen(
      (token) => unawaited(_upsertToken(token)),
    );

    return true;
  }

  Future<void> syncCurrentToken() async {
    final token = await _messaging.getToken();
    await _upsertToken(token);
  }

  Future<void> unregisterCurrentDevice() async {
    final user = _supabase.auth.currentUser;
    final token = await _messaging.getToken();
    if (user == null || token == null) {
      return;
    }

    await _supabase
        .from('push_tokens')
        .delete()
        .eq('user_id', user.id)
        .eq('token', token);
  }

  Future<String?> getInitialRoomId() async {
    final message = await _messaging.getInitialMessage();
    return message?.data['room_id'];
  }

  Stream<String> openedRoomIds() {
    return FirebaseMessaging.onMessageOpenedApp
        .map((message) => message.data['room_id'])
        .where((roomId) => roomId != null)
        .cast<String>();
  }

  Future<void> dispose() async {
    await _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription = null;
  }

  Future<void> _upsertToken(String? token) async {
    final user = _supabase.auth.currentUser;
    final platform = _platformName();
    if (user == null || token == null || platform == null) {
      return;
    }

    await _supabase.from('push_tokens').upsert({
      'user_id': user.id,
      'token': token,
      'platform': platform,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }, onConflict: 'token');
  }

  String? _platformName() {
    if (Platform.isIOS) {
      return 'ios';
    }
    if (Platform.isAndroid) {
      return 'android';
    }
    return null;
  }
}
