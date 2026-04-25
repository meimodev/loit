import 'package:supabase_flutter/supabase_flutter.dart';

import 'log_service.dart';

/// Logs user interactions to the `interaction_logs` Supabase table.
/// Fire-and-forget — never blocks UI or throws to callers.
class InteractionLog {
  InteractionLog._();

  static const _tag = 'InteractionLog';
  static SupabaseClient get _client => Supabase.instance.client;

  /// Log a successful action.
  static void success({
    required String action,
    required String screen,
    String? message,
    Map<String, dynamic>? metadata,
  }) =>
      _insert(
        action: action,
        screen: screen,
        status: 'success',
        message: message,
        metadata: metadata,
      );

  /// Log an error.
  static void error({
    required String action,
    required String screen,
    String? message,
    Map<String, dynamic>? metadata,
  }) =>
      _insert(
        action: action,
        screen: screen,
        status: 'error',
        message: message,
        metadata: metadata,
      );

  /// Log an informational event.
  static void info({
    required String action,
    required String screen,
    String? message,
    Map<String, dynamic>? metadata,
  }) =>
      _insert(
        action: action,
        screen: screen,
        status: 'info',
        message: message,
        metadata: metadata,
      );

  static Future<void> _insert({
    required String action,
    required String screen,
    required String status,
    String? message,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final uid = _client.auth.currentUser?.id;
      if (uid == null) return;

      await _client.from('interaction_logs').insert({
        'user_id': uid,
        'action': action,
        'screen': screen,
        'status': status,
        if (message != null) 'message': message,
        if (metadata != null) 'metadata': metadata,
      });
    } catch (e) {
      // Never throw — logging failure must not break UX
      Log.w(_tag, 'Failed to log interaction: $e');
    }
  }
}
