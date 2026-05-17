import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Stream of Supabase auth state. Emits on login/logout/session refresh.
final authStateProvider = StreamProvider<AuthState>((ref) {
  return Supabase.instance.client.auth.onAuthStateChange;
});

/// Current Supabase user (nullable). Reactively updates with auth state.
final currentUserProvider = Provider<User?>((ref) {
  ref.watch(authStateProvider);
  return Supabase.instance.client.auth.currentUser;
});

/// Current public.users row (tier, scans_used, home_currency, etc.).
class UserProfile {
  final String id;
  final String email;
  final String name;
  final String? avatarUrl;
  final String homeCurrency;
  final String tier;
  final int scansUsedThisMonth;
  final int scanTopupBonusThisMonth;
  final bool hasUsedDemoScan;
  final DateTime? nextReceiptExpiryAt;
  final DateTime? tierExpiresAt;
  final bool hideAmounts;
  final String language;
  final String theme; // 'system' | 'light' | 'dark'
  final bool hasSeenRoomsIntro;

  const UserProfile({
    required this.id,
    required this.email,
    required this.name,
    required this.avatarUrl,
    required this.homeCurrency,
    required this.tier,
    required this.scansUsedThisMonth,
    required this.scanTopupBonusThisMonth,
    required this.hasUsedDemoScan,
    this.nextReceiptExpiryAt,
    this.tierExpiresAt,
    this.hideAmounts = false,
    this.language = 'id',
    this.theme = 'system',
    this.hasSeenRoomsIntro = false,
  });

  factory UserProfile.fromRow(Map<String, dynamic> r) => UserProfile(
    id: r['id'] as String,
    email: r['email'] as String,
    name: (r['name'] as String?) ?? '',
    avatarUrl: r['avatar_url'] as String?,
    homeCurrency: (r['home_currency'] as String?) ?? 'IDR',
    tier: (r['tier'] as String?) ?? 'free',
    scansUsedThisMonth: (r['scans_used_this_month'] as int?) ?? 0,
    scanTopupBonusThisMonth:
        (r['scan_topup_bonus_this_month'] as int?) ?? 0,
    hasUsedDemoScan: (r['has_used_demo_scan'] as bool?) ?? false,
    nextReceiptExpiryAt: r['next_receipt_expiry_at'] == null
        ? null
        : DateTime.parse(r['next_receipt_expiry_at'] as String).toLocal(),
    tierExpiresAt: r['tier_expires_at'] == null
        ? null
        : DateTime.parse(r['tier_expires_at'] as String).toLocal(),
    hideAmounts: (r['hide_amounts'] as bool?) ?? false,
    language: (r['language'] as String?) ?? 'id',
    theme: (r['theme'] as String?) ?? 'system',
    hasSeenRoomsIntro: (r['has_seen_rooms_intro'] as bool?) ?? false,
  );

  /// Tier base cap. Free 5 / Lite 30 / Pro 150 scans/month.
  int? get baseScanQuota => switch (tier) {
    'pro' => 150,
    'lite' => 30,
    _ => 5,
  };

  /// Effective monthly cap = tier base + accumulated top-up bonus. `null`
  /// reserved for future unlimited tier.
  int? get scanQuota {
    final base = baseScanQuota;
    if (base == null) return null;
    return base + scanTopupBonusThisMonth;
  }

  bool get hasUnlimitedScans => scanQuota == null;

  /// Scan top-up is a consumable (`loit_scan_topup_15` — 15 scans for Rp 9k).
  /// All tiers may purchase it. v2 scheme retired the previous Free-only gate.
  bool get canPurchaseScanTopUp => true;
  int get budgetLimit => switch (tier) {
    'pro' || 'lite' => 999,
    _ => 3,
  };
}

final userProfileProvider = FutureProvider<UserProfile?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;
  try {
    // ignore: avoid_print
    print('[userProfileProvider] querying public.users id=${user.id}');
    final row = await Supabase.instance.client
        .from('users')
        .select()
        .eq('id', user.id)
        .maybeSingle();
    // ignore: avoid_print
    print('[userProfileProvider] result: $row');
    if (row == null) return null;
    return UserProfile.fromRow(row);
  } on PostgrestException catch (e, st) {
    // ignore: avoid_print
    print(
      '[userProfileProvider] PostgrestException code=${e.code} '
      'message=${e.message} details=${e.details} hint=${e.hint}',
    );
    // ignore: avoid_print
    print(st);
    rethrow;
  }
});
