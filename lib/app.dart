import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/routing/app_router.dart';
import 'core/theme/loit_theme.dart';
import 'core/services/analytics_service.dart';
import 'core/services/deep_link_service.dart';
import 'core/services/log_service.dart';
import 'core/services/push_service.dart';
import 'core/services/revenuecat_payment_service.dart';
import 'shared/widgets/persistent_connectivity_banner.dart';
import 'shared/widgets/persistent_export_banner.dart';
import 'shared/providers/auth_providers.dart';
import 'shared/providers/export_task_provider.dart';
import 'shared/providers/notifications_provider.dart';
import 'shared/providers/preferences_provider.dart';
import 'shared/providers/presence_provider.dart';
import 'shared/providers/room_providers.dart';
import 'shared/providers/services_providers.dart';

class LoitApp extends ConsumerStatefulWidget {
  const LoitApp({super.key});

  @override
  ConsumerState<LoitApp> createState() => _LoitAppState();
}

class _LoitAppState extends ConsumerState<LoitApp> with WidgetsBindingObserver {
  final _pushService = PushService();
  final _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
  StreamSubscription<void>? _entitlementSub;
  StreamSubscription<RemoteMessage>? _foregroundPushSub;
  RealtimeChannel? _userRowChannel;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(syncServiceProvider).startAutoSync();
      // Listen for any entitlement-state shift surfaced by the payment SDK
      // (purchase, refund, billing issue, expiration). Refunds-with-revoke on
      // Play Console fire here without a corresponding PurchaseUpdate, so we
      // re-pull the server profile to catch tier downgrades.
      final pay = ref.read(paymentServiceProvider);
      _entitlementSub = pay.entitlementChanged.listen((_) {
        ref.invalidate(userProfileProvider);
      });
      // Foreground FCM: refresh notifications feed so new pushes appear
      // without waiting on the realtime channel round-trip.
      _foregroundPushSub = FirebaseMessaging.onMessage.listen((_) {
        ref.invalidate(notificationsProvider);
      });
      // Cold-start case: session may already exist from cached auth before
      // authStateProvider emits its first event. Subscribe immediately if so.
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) _subscribeUserRow(user.id);
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        Supabase.instance.client.auth.currentUser != null) {
      _pushService.syncCurrentToken().catchError((Object e, StackTrace st) {
        Log.e('App', 'Push token sync on resume failed', error: e, stack: st);
      });
      // Force RC to re-pull CustomerInfo on resume — covers refunds issued
      // while the app was backgrounded. The CustomerInfo listener will then
      // fire entitlementChanged, which invalidates userProfileProvider.
      Purchases.invalidateCustomerInfoCache().catchError((Object _) {});
      Purchases.getCustomerInfo().catchError((Object _) {});
      // Also refresh profile directly in case the webhook already landed.
      ref.invalidate(userProfileProvider);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _entitlementSub?.cancel();
    _foregroundPushSub?.cancel();
    _userRowChannel?.unsubscribe();
    _pushService.dispose();
    super.dispose();
  }

  void _subscribeUserRow(String userId) {
    _userRowChannel?.unsubscribe();
    // Realtime UPDATE on the user's own public.users row. Catches any
    // server-side tier mutation (webhook revoke, admin grant, cron downgrade)
    // without waiting on the next app resume.
    _userRowChannel = Supabase.instance.client
        .channel('user:$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'users',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: userId,
          ),
          callback: (_) {
            ref.invalidate(userProfileProvider);
          },
        )
        .subscribe();
  }

  @override
  Widget build(BuildContext context) {
    // Identify/reset PostHog + init push on auth transitions
    ref.listen<AsyncValue<AuthState>>(authStateProvider, (_, next) {
      final session = next.value?.session;
      if (session != null) {
        Log.i('App', 'User signed in: ${session.user.id}');
        Analytics.identify(session.user.id, email: session.user.email);
        _subscribeUserRow(session.user.id);
        // Bind RevenueCat customer to Supabase user so webhook events carry
        // the correct app_user_id. Without this, purchases land on whichever
        // anon ID RC generated at first init.
        final pay = ref.read(paymentServiceProvider);
        if (pay is RevenueCatPaymentService) {
          pay.identify(session.user.id).catchError((Object e, StackTrace st) {
            Log.e('App', 'RC identify failed', error: e, stack: st);
          });
        }
        _pushService.initialize().then((ok) {
          Log.i('App', 'PushService.initialize result: $ok');
        }).catchError((Object e, StackTrace st) {
          Log.e('App', 'PushService.initialize failed', error: e, stack: st);
        });
        acceptPendingInviteIfAny().then((roomId) {
          if (roomId != null && mounted) {
            Log.i('App', 'Pending invite accepted: room=$roomId');
            Analytics.roomJoined();
            ref.invalidate(myRoomsProvider);
            final router = ref.read(appRouterProvider);
            router.go('/rooms/$roomId');
          }
        });
      } else {
        Log.i('App', 'User signed out');
        Analytics.reset();
        _userRowChannel?.unsubscribe();
        _userRowChannel = null;
        final pay = ref.read(paymentServiceProvider);
        if (pay is RevenueCatPaymentService) {
          pay.logout().catchError((Object e, StackTrace st) {
            Log.e('App', 'RC logout failed', error: e, stack: st);
          });
        }
      }
    });

    // Mirror DB-canonical home_currency into the SharedPreferences cache so
    // local reads stay in sync after webhook/multi-device edits.
    ref.listen<AsyncValue<UserProfile?>>(userProfileProvider, (_, next) {
      final profile = next.value;
      if (profile == null) return;
      final notifier = ref.read(preferencesProvider.notifier);
      notifier.syncCurrencyFromDb(profile.homeCurrency).catchError(
        (Object e, StackTrace st) {
          Log.w('App', 'home_currency local sync failed', error: e);
        },
      );
    });

    // Deep link → navigate to joined room
    ref.listen(deepLinkRoomIdProvider, (_, next) {
      next.whenData((roomId) {
        Analytics.roomJoined();
        ref.invalidate(myRoomsProvider);
        final router = ref.read(appRouterProvider);
        router.go('/rooms/$roomId');
      });
    });

    // Background export task → trigger share sheet from anywhere when ready,
    // or surface SnackBar on failure. Either resolves back to Idle so the
    // export screen can start a new export.
    ref.listen<ExportTaskState>(exportTaskProvider, (_, next) {
      if (next is ExportTaskReady) {
        Share.shareXFiles(
          [XFile(next.file.path)],
          subject: next.isPdf ? 'LOIT report' : 'LOIT export',
        ).whenComplete(
            () => ref.read(exportTaskProvider.notifier).consume());
      } else if (next is ExportTaskFailed) {
        _scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(content: Text('Export failed: ${next.message}')),
        );
        ref.read(exportTaskProvider.notifier).consume();
      }
    });

    // Push notification open → navigate to room
    _wirePushNavigation();

    // Keep presence channel alive app-wide so the user appears online to
    // room members regardless of which screen is currently mounted.
    ref.watch(onlineUsersProvider);

    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      scaffoldMessengerKey: _scaffoldMessengerKey,
      builder: (context, child) => Stack(
        children: [
          child!,
          const PersistentExportBanner(),
          const PersistentConnectivityBanner(),
        ],
      ),
      title: 'LOIT',
      debugShowCheckedModeBanner: false,
      theme: LoitTheme.light(),
      darkTheme: LoitTheme.dark(),
      themeMode: ref.watch(themeModePrefProvider),
      routerConfig: router,
    );
  }

  void _wirePushNavigation() {
    // Cold start: app was killed, opened via notification
    _pushService.getInitialDeepLink().then((deepLink) {
      if (deepLink != null && mounted) {
        final router = ref.read(appRouterProvider);
        router.go(deepLink);
      }
    });

    // Warm: notification tapped while app is running
    _pushService.openedDeepLinks().listen((deepLink) {
      if (mounted) {
        final router = ref.read(appRouterProvider);
        router.go(deepLink);
      }
    });
  }
}
