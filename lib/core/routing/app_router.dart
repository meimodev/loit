import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/auth/auth_screen.dart';
import '../../features/budgets/budgets_screen.dart';
import '../../features/dashboard/dashboard_screen.dart';
import '../../features/reports/reports_screen.dart';
import '../../features/paywall/paywall_screen.dart';
import '../../features/room_detail/room_budgets_screen.dart';
import '../../features/room_detail/room_detail_screen.dart';
import '../../features/rooms/rooms_screen.dart';
import '../../features/scanner/scanner_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/transactions/transaction_form_screen.dart';
import '../../shared/providers/auth_providers.dart';
import '../../shared/widgets/shell_scaffold.dart';

class _AuthRefresh extends ChangeNotifier {
  _AuthRefresh(Ref ref) {
    ref.listen(authStateProvider, (_, __) => notifyListeners());
  }
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final refresh = _AuthRefresh(ref);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: refresh,
    redirect: (context, state) {
      final session = Supabase.instance.client.auth.currentSession;
      final loggedIn = session != null;
      final atAuth = state.matchedLocation == '/auth';
      if (!loggedIn && !atAuth) return '/auth';
      if (loggedIn && atAuth) return '/';
      return null;
    },
    routes: [
      GoRoute(
        path: '/auth',
        builder: (_, __) => const AuthScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => ShellScaffold(child: child),
        routes: [
          GoRoute(path: '/', builder: (_, __) => const DashboardScreen()),
          GoRoute(path: '/rooms', builder: (_, __) => const RoomsScreen()),
          GoRoute(path: '/budgets', builder: (_, __) => const BudgetsScreen()),
          GoRoute(path: '/reports', builder: (_, __) => const ReportsScreen()),
          GoRoute(
              path: '/settings', builder: (_, __) => const SettingsScreen()),
        ],
      ),
      // Room detail (outside shell — no bottom nav)
      GoRoute(
        path: '/rooms/:roomId',
        builder: (_, state) => RoomDetailScreen(
          roomId: state.pathParameters['roomId']!,
        ),
      ),
      GoRoute(
        path: '/rooms/:roomId/budgets',
        builder: (_, state) => RoomBudgetsScreen(
          roomId: state.pathParameters['roomId']!,
        ),
      ),
      GoRoute(
        path: '/transactions/new',
        builder: (_, state) => TransactionFormScreen(
          prefill: state.extra as Map<String, dynamic>?,
        ),
      ),
      GoRoute(
        path: '/scan',
        builder: (_, __) => const ScannerScreen(),
      ),
      GoRoute(
        path: '/paywall',
        builder: (_, state) => PaywallScreen(
          feature: (state.extra as String?) ?? 'general',
        ),
      ),
      // Deep link: invite acceptance
      GoRoute(
        path: '/invite/:token',
        redirect: (context, state) {
          // Handled by deep_link_service — redirect to rooms
          return '/rooms';
        },
      ),
    ],
  );
});
