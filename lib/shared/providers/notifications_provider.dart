import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_providers.dart';

enum NotificationKind {
  budgetAlert,
  roomActivity,
  receipt,
  subscription,
  invite,
  info;

  static NotificationKind fromString(String? s) => switch (s) {
        'budget_alert' => NotificationKind.budgetAlert,
        'room_activity' => NotificationKind.roomActivity,
        'receipt' => NotificationKind.receipt,
        'subscription' => NotificationKind.subscription,
        'invite' => NotificationKind.invite,
        _ => NotificationKind.info,
      };
}

class NotificationItem {
  final String id;
  final NotificationKind kind;
  final String title;
  final String? body;
  final String? deepLink;
  final Map<String, dynamic> metadata;
  final DateTime? readAt;
  final DateTime createdAt;

  const NotificationItem({
    required this.id,
    required this.kind,
    required this.title,
    required this.createdAt,
    this.body,
    this.deepLink,
    this.metadata = const {},
    this.readAt,
  });

  bool get isUnread => readAt == null;

  factory NotificationItem.fromRow(Map<String, dynamic> r) => NotificationItem(
        id: r['id'] as String,
        kind: NotificationKind.fromString(r['kind'] as String?),
        title: (r['title'] as String?) ?? '',
        body: r['body'] as String?,
        deepLink: r['deep_link'] as String?,
        metadata: (r['metadata'] as Map?)?.cast<String, dynamic>() ?? const {},
        readAt: r['read_at'] != null
            ? DateTime.tryParse(r['read_at'] as String)
            : null,
        createdAt: DateTime.tryParse(r['created_at'] as String? ?? '') ??
            DateTime.now(),
      );

  NotificationItem copyWith({DateTime? readAt}) => NotificationItem(
        id: id,
        kind: kind,
        title: title,
        body: body,
        deepLink: deepLink,
        metadata: metadata,
        readAt: readAt ?? this.readAt,
        createdAt: createdAt,
      );
}

class NotificationsNotifier extends AsyncNotifier<List<NotificationItem>> {
  RealtimeChannel? _channel;

  @override
  Future<List<NotificationItem>> build() async {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const [];

    ref.onDispose(() {
      _channel?.unsubscribe();
      _channel = null;
    });

    _subscribeRealtime(user.id);

    final rows = await Supabase.instance.client
        .from('notifications')
        .select()
        .eq('user_id', user.id)
        .order('created_at', ascending: false)
        .limit(50);
    return (rows as List)
        .map((r) => NotificationItem.fromRow(r as Map<String, dynamic>))
        .toList();
  }

  void _subscribeRealtime(String userId) {
    _channel?.unsubscribe();
    _channel = Supabase.instance.client
        .channel('public:notifications:$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            final newRow = payload.newRecord;
            final item = NotificationItem.fromRow(newRow);
            final cur = state.value ?? const <NotificationItem>[];
            state = AsyncData([item, ...cur]);
          },
        )
        .subscribe();
  }

  Future<int> get unreadCount async {
    final list = state.value ?? const [];
    return list.where((n) => n.isUnread).length;
  }

  Future<void> markAllRead() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    final now = DateTime.now().toUtc();
    await Supabase.instance.client
        .from('notifications')
        .update({'read_at': now.toIso8601String()})
        .eq('user_id', user.id)
        .filter('read_at', 'is', null);
    final cur = state.value ?? const <NotificationItem>[];
    state = AsyncData(
      cur.map((n) => n.isUnread ? n.copyWith(readAt: now) : n).toList(),
    );
  }

  Future<void> markRead(String id) async {
    final now = DateTime.now().toUtc();
    await Supabase.instance.client
        .from('notifications')
        .update({'read_at': now.toIso8601String()}).eq('id', id);
    final cur = state.value ?? const <NotificationItem>[];
    state = AsyncData(
      cur.map((n) => n.id == id ? n.copyWith(readAt: now) : n).toList(),
    );
  }

  Future<void> dismiss(String id) async {
    await Supabase.instance.client.from('notifications').delete().eq('id', id);
    final cur = state.value ?? const <NotificationItem>[];
    state = AsyncData(cur.where((n) => n.id != id).toList());
  }
}

final notificationsProvider =
    AsyncNotifierProvider<NotificationsNotifier, List<NotificationItem>>(
        NotificationsNotifier.new);

final unreadNotificationCountProvider = Provider<int>((ref) {
  final list = ref.watch(notificationsProvider).value ?? const [];
  return list.where((n) => n.isUnread).length;
});
