import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/routing/app_router.dart';
import 'core/services/analytics_service.dart';
import 'core/services/deep_link_service.dart';
import 'core/services/log_service.dart';
import 'core/services/push_service.dart';
import 'core/services/revenuecat_payment_service.dart';
import 'shared/providers/auth_providers.dart';
import 'shared/providers/room_providers.dart';
import 'shared/providers/services_providers.dart';

class LoitApp extends ConsumerStatefulWidget {
  const LoitApp({super.key});

  @override
  ConsumerState<LoitApp> createState() => _LoitAppState();
}

class _LoitAppState extends ConsumerState<LoitApp> with WidgetsBindingObserver {
  final _pushService = PushService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(syncServiceProvider).startAutoSync();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        Supabase.instance.client.auth.currentUser != null) {
      _pushService.syncCurrentToken().catchError((Object e, StackTrace st) {
        Log.e('App', 'Push token sync on resume failed', error: e, stack: st);
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pushService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Identify/reset PostHog + init push on auth transitions
    ref.listen<AsyncValue<AuthState>>(authStateProvider, (_, next) {
      final session = next.value?.session;
      if (session != null) {
        Log.i('App', 'User signed in: ${session.user.id}');
        Analytics.identify(session.user.id, email: session.user.email);
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
        final pay = ref.read(paymentServiceProvider);
        if (pay is RevenueCatPaymentService) {
          pay.logout().catchError((Object e, StackTrace st) {
            Log.e('App', 'RC logout failed', error: e, stack: st);
          });
        }
      }
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

    // Push notification open → navigate to room
    _wirePushNavigation();

    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: 'LOIT',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.dark,
        ),
      ),
      routerConfig: router,
    );
  }

  void _wirePushNavigation() {
    // Cold start: app was killed, opened via notification
    _pushService.getInitialRoomId().then((roomId) {
      if (roomId != null && mounted) {
        final router = ref.read(appRouterProvider);
        router.go('/rooms/$roomId');
      }
    });

    // Warm: notification tapped while app is running
    _pushService.openedRoomIds().listen((roomId) {
      if (mounted) {
        final router = ref.read(appRouterProvider);
        router.go('/rooms/$roomId');
      }
    });
  }
}
