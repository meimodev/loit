import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_providers.dart';

class MessagingLinkStatus {
  const MessagingLinkStatus({
    required this.linked,
    this.externalChatId,
    this.linkedAt,
  });

  final bool linked;
  final String? externalChatId;
  final DateTime? linkedAt;

  factory MessagingLinkStatus.fromRow(Map<String, dynamic> row) {
    return MessagingLinkStatus(
      linked: row['linked'] == true,
      externalChatId: row['external_chat_id'] as String?,
      linkedAt: row['linked_at'] != null
          ? DateTime.tryParse(row['linked_at'].toString())
          : null,
    );
  }
}

final telegramLinkStatusProvider = FutureProvider.autoDispose<MessagingLinkStatus>(
  (ref) async {
    final user = ref.watch(currentUserProvider);
    if (user == null) {
      return const MessagingLinkStatus(linked: false);
    }
    final res = await Supabase.instance.client.rpc(
      'check_messaging_link_status',
      params: {'p_platform': 'telegram'},
    );
    if (res is List && res.isNotEmpty && res.first is Map) {
      return MessagingLinkStatus.fromRow(
        Map<String, dynamic>.from(res.first as Map),
      );
    }
    return const MessagingLinkStatus(linked: false);
  },
);

// Convenience helper — any UI surface that needs to re-check link status
// without restating the provider identifier should call this.
void refreshTelegramLinkStatus(WidgetRef ref) {
  ref.invalidate(telegramLinkStatusProvider);
}

class MessagingLinkService {
  MessagingLinkService(this._client);
  final SupabaseClient _client;

  Future<String> generateTelegramLinkCode() async {
    final code = await _client.rpc('generate_telegram_link_code');
    return code as String;
  }

  Future<int> disconnectTelegram() async {
    final res = await _client.rpc(
      'disconnect_messaging_link',
      params: {'p_platform': 'telegram'},
    );
    return (res as int?) ?? 0;
  }
}

final messagingLinkServiceProvider = Provider<MessagingLinkService>(
  (ref) => MessagingLinkService(Supabase.instance.client),
);
