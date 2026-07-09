import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/routing/app_router.dart';
import 'core/services/app_update_service.dart';
import 'core/theme/loit_theme.dart';
import 'core/services/analytics_service.dart';
import 'core/services/deep_link_service.dart';
import 'core/services/log_service.dart';
import 'core/services/notifications/quick_actions_notification.dart';
import 'core/services/push_service.dart';
import 'core/services/revenuecat_payment_service.dart';
import 'shared/utils/amount_input.dart';
import 'features/rooms/rooms_intro_dialog.dart';
import 'features/system/lock_screen.dart';
import 'features/system/update_prompt_sheet.dart';
import 'features/system/update_required_screen.dart';
import 'l10n/gen/app_localizations.dart';
import 'l10n/l10n_x.dart';
import 'shared/widgets/persistent_connectivity_banner.dart';
import 'shared/widgets/persistent_export_banner.dart';
import 'shared/providers/app_lock_provider.dart';
import 'shared/providers/auth_providers.dart';
import 'shared/providers/export_task_provider.dart';
import 'shared/providers/notifications_provider.dart';
import 'shared/providers/home_currency_provider.dart';
import 'shared/providers/preferences_provider.dart';
import 'shared/providers/presence_provider.dart';
import 'shared/providers/room_providers.dart';
import 'shared/providers/services_providers.dart';
import 'shared/providers/today_expense_provider.dart';
import 'shared/providers/transactions_provider.dart';
import 'shared/providers/update_gate_provider.dart';

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
  DateTime? _pausedAt;
  // Session guard against double-showing the Rooms intro before the persistent
  // `has_seen_rooms_intro` write lands. The once-ever authority is the DB flag;
  // see ADR-0005.
  bool _roomsIntroShown = false;
  // Per-session guard so the Recommended/Optional update sheet shows at most
  // once per app launch (resume invalidates the gate provider, which re-fires
  // the listener). "Every launch" for Recommended is satisfied by cold starts.
  bool _updatePromptShown = false;
  static const _lockBackgroundThreshold = Duration(seconds: 15);
  // Rooms intro engagement trigger thresholds (ADR-0005).
  static const _roomsIntroMinTxns = 3;
  static const _roomsIntroDayTwo = Duration(hours: 20);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Persistent quick-actions notification: install tap handler so taps
      // both warm and cold-start route through the same `appRouterProvider`.
      QuickActionsNotification.init(
        onTap: (path) {
          if (!mounted) return;
          ref.read(appRouterProvider).go(path);
        },
      );

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
      if (user != null) {
        _syncAvatarFromAuth(user);
        _subscribeUserRow(user.id);
        _maybeLockOnColdStart();
      }

      // Initial paint of the persistent notification.
      unawaited(_refreshQuickActions());
    });
  }

  /// Show / refresh / cancel the persistent quick-actions notification based
  /// on current auth + prefs + today's expense. Idempotent — safe to invoke
  /// from any provider listener.
  Future<void> _refreshQuickActions() async {
    if (!mounted) return;
    final user = Supabase.instance.client.auth.currentUser;
    final prefs = ref.read(preferencesProvider).value;
    if (user == null || prefs == null || !prefs.quickActionsNotifEnabled) {
      await QuickActionsNotification.cancel();
      await QuickActionsNotification.cancelMidnightRollover();
      return;
    }
    if (!await QuickActionsNotification.hasNotificationPermission()) {
      // Will show once permission is granted via the FCM permission flow.
      return;
    }

    final locale = ref.read(localePrefProvider) ?? const Locale('id');
    final l = await AppLocalizations.delegate.load(locale);
    final today = ref.read(todayExpenseProvider);
    final currency = ref.read(homeCurrencyProvider);

    final String body;
    if (prefs.hideAmounts) {
      body = l.quickActionsBodyHidden;
    } else if (today <= 0) {
      body = l.quickActionsBodyLauncher;
    } else {
      body =
          l.quickActionsBodyTodayExpense(formatMoney(today, currency));
    }

    try {
      await QuickActionsNotification.show(
        title: l.quickActionsNotificationTitle,
        body: body,
        channelName: l.quickActionsChannelName,
        channelDescription: l.quickActionsChannelDescription,
        scanLabel: l.quickActionsScan,
        addLabel: l.quickActionsAdd,
        viewTransactionsLabel: l.quickActionsViewTransactions,
        viewRoomsLabel: l.quickActionsViewRooms,
        hideAmounts: prefs.hideAmounts,
        amountForAnalytics: today,
      );
      await mirrorChannelStringsForAlarm(
        title: l.quickActionsNotificationTitle,
        launcherBody: l.quickActionsBodyLauncher,
        channelName: l.quickActionsChannelName,
        channelDescription: l.quickActionsChannelDescription,
        scan: l.quickActionsScan,
        add: l.quickActionsAdd,
        viewTransactions: l.quickActionsViewTransactions,
        viewRooms: l.quickActionsViewRooms,
      );
      await QuickActionsNotification.scheduleMidnightRollover();
    } catch (e, st) {
      Log.e('App', 'quick-actions notif refresh failed',
          error: e, stack: st);
    }
  }

  Future<void> _maybeLockOnColdStart() async {
    try {
      final prefs = await ref.read(preferencesProvider.future);
      if (!mounted || !prefs.biometricLock) return;
      if (Supabase.instance.client.auth.currentUser == null) return;
      ref.read(appLockedProvider.notifier).lock();
    } catch (e) {
      Log.w('App', 'cold-start lock check failed', error: e);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden) {
      _pausedAt ??= DateTime.now();
      return;
    }
    if (state == AppLifecycleState.resumed) {
      final pausedAt = _pausedAt;
      _pausedAt = null;
      // Re-evaluate the Update gate on resume (covers a user who backgrounded
      // for days then returned on a now-blocked build). Runs regardless of auth.
      ref.invalidate(updateGateProvider);
      if (Supabase.instance.client.auth.currentUser == null) return;

      // Lock gate: re-prompt if backgrounded long enough.
      final prefs = ref.read(preferencesProvider).value;
      if (prefs?.biometricLock == true &&
          pausedAt != null &&
          DateTime.now().difference(pausedAt) >= _lockBackgroundThreshold) {
        ref.read(appLockedProvider.notifier).lock();
      }

      _pushService.syncCurrentToken().catchError((Object e, StackTrace st) {
        Log.e('App', 'Push token sync on resume failed', error: e, stack: st);
      });
      // Force RC to re-pull CustomerInfo on resume — covers refunds issued
      // while the app was backgrounded. The CustomerInfo listener will then
      // fire entitlementChanged, which invalidates userProfileProvider.
      Purchases.invalidateCustomerInfoCache().catchError((Object _) {});
      Purchases.getCustomerInfo().then((_) {}, onError: (Object _) {});
      // Also refresh profile directly in case the webhook already landed.
      ref.invalidate(userProfileProvider);
      // Resume refresh — covers aggressive OEMs that suppressed the
      // midnight alarm while backgrounded.
      unawaited(_refreshQuickActions());
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

  Future<void> _syncAvatarFromAuth(User user) async {
    final meta = user.userMetadata ?? const <String, dynamic>{};
    final url = (meta['avatar_url'] as String?) ?? (meta['picture'] as String?);
    if (url == null || url.isEmpty) return;
    try {
      final row = await Supabase.instance.client
          .from('users')
          .select('avatar_url')
          .eq('id', user.id)
          .maybeSingle();
      if (row == null) return;
      final current = row['avatar_url'] as String?;
      if (current == url) return;
      await Supabase.instance.client
          .from('users')
          .update({'avatar_url': url}).eq('id', user.id);
      ref.invalidate(userProfileProvider);
    } catch (e) {
      Log.w('App', 'avatar sync failed', error: e);
    }
  }

  /// Engagement-gated Rooms intro (ADR-0005). Shows the intro sheet exactly
  /// once per user, when a zero-room user has felt personal value (≥3 logged
  /// transactions OR their day-2 session). Idempotent — safe to call from
  /// every profile/transaction tick; all guards bail cheaply.
  Future<void> _maybeShowRoomsIntro() async {
    if (_roomsIntroShown) return;
    if (ref.read(appLockedProvider)) return; // don't surface under lock screen

    final profile = ref.read(userProfileProvider).value;
    if (profile == null || profile.hasSeenRoomsIntro) return;

    // Only loaded data counts; a null means "not ready", re-evaluated later.
    final rooms = ref.read(myRoomsProvider).value;
    if (rooms == null) return;
    if (rooms.isNotEmpty) return; // already adopted — nothing to discover

    final txnCount = ref.read(transactionsProvider).value?.length ?? 0;
    final firstSeen = ref.read(preferencesProvider.notifier).firstSeen;
    final dayTwo = firstSeen != null &&
        DateTime.now().difference(firstSeen) >= _roomsIntroDayTwo;
    if (txnCount < _roomsIntroMinTxns && !dayTwo) return;

    _roomsIntroShown = true;
    // Two frames so any pending locale/theme propagation settles before the
    // sheet mounts (avoids a one-frame stale-locale flash).
    await WidgetsBinding.instance.endOfFrame;
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    final router = ref.read(appRouterProvider);
    final ctx = router.routerDelegate.navigatorKey.currentContext;
    if (ctx == null) return;
    // ignore: use_build_context_synchronously
    final wantsCreate = await showRoomsIntroDialog(ctx);
    await _markRoomsIntroSeen();
    if (wantsCreate && mounted) router.push('/rooms/new');
  }

  /// Persist the once-ever Rooms intro contract. The DB flag is the authority;
  /// failures degrade to the per-session [_roomsIntroShown] guard.
  Future<void> _markRoomsIntroSeen() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    try {
      await Supabase.instance.client
          .from('users')
          .update({'has_seen_rooms_intro': true}).eq('id', user.id);
      ref.invalidate(userProfileProvider);
    } catch (e) {
      Log.w('App', 'rooms intro seen-flag write failed', error: e);
    }
  }

  /// Surface the dismissible update sheet for the Recommended / Optional /
  /// Stranded states (ADR-0015, ADR-0030). Recommended and Stranded re-nag every
  /// launch; Optional shows once per release (persisted by `latest_version`).
  /// Blocked is handled by the overlay in [build], not here. Idempotent — all
  /// guards bail cheaply.
  Future<void> _maybeShowUpdatePrompt(UpdateGateStatus status) async {
    if (_updatePromptShown) return;
    if (status.state != UpdateState.recommended &&
        status.state != UpdateState.optional &&
        status.state != UpdateState.stranded) {
      return;
    }
    if (ref.read(appLockedProvider)) return; // don't stack over the lock screen

    final prefs = await SharedPreferences.getInstance();
    if (status.state == UpdateState.optional &&
        prefs.getString(updateOptionalDismissedKey) ==
            status.gate.latestVersion) {
      return; // Optional already shown once for this release.
    }

    _updatePromptShown = true;
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    final router = ref.read(appRouterProvider);
    final ctx = router.routerDelegate.navigatorKey.currentContext;
    if (ctx == null) {
      _updatePromptShown = false;
      return;
    }
    // Persist the Optional once-per-release marker up front so it never re-nags
    // even if the user dismisses without updating.
    if (status.state == UpdateState.optional) {
      await prefs.setString(
          updateOptionalDismissedKey, status.gate.latestVersion);
    }
    // Stranded resolves `false` always — the sheet offers no update action.
    final wantsUpdate = await showUpdatePromptSheet(
      // ignore: use_build_context_synchronously
      ctx,
      stranded: status.state == UpdateState.stranded,
    );
    if (wantsUpdate == true) {
      await appUpdateService.performUpdate(
        immediate: false,
        storeUrl: status.gate.storeUrl,
      );
    }
  }

  void _subscribeUserRow(String userId) {
    _userRowChannel?.unsubscribe();
    final client = Supabase.instance.client;
    // Private Broadcast on the user's own row (ADR-0018). Catches any
    // server-side tier/credit mutation (webhook revoke, admin grant, cron
    // downgrade) live, without waiting on the next app resume. Migrated off
    // Postgres Changes, which silently dropped events. setAuth is required so
    // the private join passes the realtime.messages RLS check.
    final token = client.auth.currentSession?.accessToken;
    if (token != null) client.realtime.setAuth(token);
    _userRowChannel = client
        .channel(
          'user:$userId',
          opts: const RealtimeChannelConfig(private: true),
        )
        .onBroadcast(
          event: 'profile',
          callback: (p) {
            Log.i('App', 'user broadcast feed event $p');
            ref.invalidate(userProfileProvider);
          },
        )
        .subscribe((status, err) {
          Log.i('App', 'user broadcast subscribe status=$status err=$err');
        });
  }

  @override
  Widget build(BuildContext context) {
    // Keep the Broadcast-from-database transaction feed (ADR-0018) alive
    // app-wide while signed in, so bot-originated writes refresh the list even
    // when the user isn't on the Transactions tab.
    ref.watch(transactionsRealtimeProvider);

    // Identify/reset PostHog + init push on auth transitions
    ref.listen<AsyncValue<AuthState>>(authStateProvider, (_, next) {
      final event = next.value?.event;
      final session = next.value?.session;
      Log.breadcrumb('auth', 'authStateProvider emit', data: {
        'event': event?.name,
        'hasSession': session != null,
      });
      if (session != null) {
        Log.i('App', 'User signed in: ${session.user.id}');
        Log.setUser(id: session.user.id, email: session.user.email);
        Log.event('Auth', 'signed in', data: {
          'event': event?.name,
          'uid': session.user.id,
          'provider': session.user.appMetadata['provider'],
        });
        Analytics.identify(session.user.id, email: session.user.email);
        _syncAvatarFromAuth(session.user);
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
          // Refresh quick-actions notif now that POST_NOTIFICATIONS may
          // have just been granted by the FCM permission flow.
          unawaited(_refreshQuickActions());
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
        _roomsIntroShown = false;
        Log.event('Auth', 'signed out', data: {'event': event?.name});
        Log.setUser(id: null);
        Analytics.reset();
        _userRowChannel?.unsubscribe();
        _userRowChannel = null;
        ref.read(appLockedProvider.notifier).unlock();
        // Drop the persistent notification — it belongs to the previous user.
        unawaited(QuickActionsNotification.cancel());
        unawaited(QuickActionsNotification.cancelMidnightRollover());
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
      // Only mirror settled data. On invalidate/refresh the provider emits
      // AsyncLoading that RETAINS the previous (stale) profile; acting on it
      // would clobber a just-applied local optimistic change (e.g. a theme
      // switch) with the old DB value and then re-apply the new one — a
      // visible dark->light->dark flicker. Wait for the fresh value.
      if (next.isLoading) return;
      final profile = next.value;
      if (profile == null) return;
      final notifier = ref.read(preferencesProvider.notifier);
      notifier.syncCurrencyFromDb(profile.homeCurrency).catchError(
        (Object e, StackTrace st) {
          Log.w('App', 'home_currency local sync failed', error: e);
        },
      );
      notifier.syncHideAmountsFromDb(profile.hideAmounts).catchError(
        (Object e, StackTrace st) {
          Log.w('App', 'hide_amounts local sync failed', error: e);
        },
      );
      notifier.syncLanguageFromDb(profile.language).catchError(
        (Object e, StackTrace st) {
          Log.w('App', 'language local sync failed', error: e);
        },
      );
      notifier.syncThemeFromDb(profile.theme).catchError(
        (Object e, StackTrace st) {
          Log.w('App', 'theme local sync failed', error: e);
        },
      );

      // Profile load is one of the two evaluation points for the Rooms intro
      // (the other is a new transaction); see ADR-0005.
      unawaited(_maybeShowRoomsIntro());
    });

    // Re-evaluate the Rooms intro when the transaction feed changes — catches
    // the user crossing the ≥3-transactions threshold mid-session.
    ref.listen<AsyncValue<List<Txn>>>(transactionsProvider, (_, __) {
      unawaited(_maybeShowRoomsIntro());
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

    // Quick-actions notification: refresh on any input change.
    ref.listen<AsyncValue<AppPreferences>>(preferencesProvider, (_, __) {
      unawaited(_refreshQuickActions());
    });
    ref.listen<double>(todayExpenseProvider, (_, __) {
      unawaited(_refreshQuickActions());
    });
    ref.listen<String>(homeCurrencyProvider, (_, __) {
      unawaited(_refreshQuickActions());
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
          SnackBar(content: Text(context.l10n.exportFailed(next.message))),
        );
        ref.read(exportTaskProvider.notifier).consume();
      }
    });

    // Update gate (ADR-0015): surface the dismissible sheet for Recommended /
    // Optional states when the gate resolves. Blocked is handled by the overlay
    // below, not here.
    ref.listen<AsyncValue<UpdateGateStatus>>(updateGateProvider, (_, next) {
      final status = next.value;
      if (status == null) return;
      unawaited(_maybeShowUpdatePrompt(status));
    });

    // Push notification open → navigate to room
    _wirePushNavigation();

    // Keep presence channel alive app-wide so the user appears online to
    // room members regardless of which screen is currently mounted.
    ref.watch(onlineUsersProvider);

    final router = ref.watch(appRouterProvider);
    final locked = ref.watch(appLockedProvider);
    // Blocked Update state (ADR-0015): paint a non-dismissible overlay above
    // everything — even the lock screen — so a too-old client can't be used.
    final blockedGate = ref.watch(updateGateProvider).value;
    final blocked = blockedGate?.state == UpdateState.blocked;
    return MaterialApp.router(
      scaffoldMessengerKey: _scaffoldMessengerKey,
      builder: (context, child) => Stack(
        children: [
          child!,
          const PersistentExportBanner(),
          const PersistentConnectivityBanner(),
          if (locked)
            const Positioned.fill(
              child: Material(child: LockScreen()),
            ),
          if (blocked)
            Positioned.fill(
              child: Material(
                child: UpdateRequiredScreen(
                  onUpdate: () => appUpdateService.performUpdate(
                    immediate: true,
                    storeUrl: blockedGate!.gate.storeUrl,
                  ),
                ),
              ),
            ),
        ],
      ),
      title: 'LOIT',
      debugShowCheckedModeBanner: false,
      theme: LoitTheme.light(),
      darkTheme: LoitTheme.dark(),
      themeMode: ref.watch(themeModePrefProvider),
      // Switch themes instantly. MaterialApp's default 200ms AnimatedTheme
      // cross-fade lerps continuous colors but holds discrete props (brightness,
      // overlay style, icon themes) at the OLD value until the midpoint, then
      // snaps — which reads as a "wrong theme, then snap" flicker on a
      // light<->dark flip. Zero duration removes the half-lerped frame.
      themeAnimationDuration: Duration.zero,
      locale: ref.watch(localePrefProvider),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      localeResolutionCallback: (device, supported) {
        if (device == null) return const Locale('id');
        for (final s in supported) {
          if (s.languageCode == device.languageCode) return s;
        }
        return const Locale('id');
      },
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

    // Quick-actions notification taps that arrived through the `loit://`
    // intent — `DeepLinkService` parses and routes them via this bus.
    QuickActionsDeepLinkBus.instance.stream.listen((path) {
      if (mounted) ref.read(appRouterProvider).go(path);
    });
  }
}
