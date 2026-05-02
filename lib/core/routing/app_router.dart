import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/auth/auth_screen.dart';
import '../../features/auth/otp_screen.dart';
import '../../features/auth/permissions_screen.dart';
import '../../features/auth/region_screen.dart';
import '../../features/auth/sign_in_screen.dart';
import '../../features/auth/sign_up_screen.dart';
import '../../features/auth/splash_screen.dart';
import '../../features/auth/welcome_screen.dart';
import '../../features/accounts/account_form_screen.dart';
import '../../features/accounts/accounts_screen.dart';
import '../../features/billing/billing_history_screen.dart';
import '../../features/billing/manage_subscription_screen.dart';
import '../../features/paywall/pro_success_screen.dart';
import '../../features/budgets/budget_detail_screen.dart';
import '../../features/budgets/budget_form_screen.dart';
import '../../features/budgets/budgets_screen.dart';
import '../../features/system/notifications_screen.dart' as system_notifs;
import '../../features/system/update_required_screen.dart';
import '../../shared/providers/accounts_provider.dart';
import '../../shared/providers/budgets_provider.dart';
import '../../features/dashboard/dashboard_screen.dart';
import '../../features/reports/export_screen.dart';
import '../../features/reports/reports_screen.dart';
import '../../features/paywall/paywall_screen.dart';
import '../../features/room_detail/room_budgets_screen.dart';
import '../../features/room_detail/room_detail_screen.dart';
import '../../features/rooms/room_create_screen.dart';
import '../../features/rooms/room_invite_screen.dart';
import '../../features/rooms/room_join_screen.dart';
import '../../features/rooms/rooms_screen.dart';
import '../../features/scanner/scanner_screen.dart';
import '../../features/settings/about_screen.dart';
import '../../features/settings/notifications_screen.dart';
import '../../features/settings/preferences_screen.dart';
import '../../features/settings/profile_screen.dart';
import '../../features/settings/security_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/transactions/transaction_detail_screen.dart';
import '../../features/transactions/quick_add_screen.dart';
import '../../features/transactions/transaction_form_screen.dart';
import '../../features/transactions/transaction_search_screen.dart';
import '../../features/transactions/transactions_screen.dart';
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
      final loc = state.matchedLocation;
      const publicPaths = {
        '/auth',
        '/splash',
        '/welcome',
        '/sign-in',
        '/sign-up',
        '/otp',
        '/region',
        '/permissions',
        '/update-required',
      };
      final isPublic = publicPaths.contains(loc);
      if (!loggedIn && !isPublic) return '/welcome';
      if (loggedIn &&
          (loc == '/auth' || loc == '/welcome' ||
              loc == '/sign-in' || loc == '/sign-up')) {
        return '/';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/welcome', builder: (_, __) => const WelcomeScreen()),
      GoRoute(path: '/sign-up', builder: (_, __) => const SignUpScreen()),
      GoRoute(path: '/sign-in', builder: (_, __) => const SignInScreen()),
      GoRoute(
          path: '/otp',
          builder: (_, state) =>
              OtpScreen(email: (state.extra as String?) ?? '')),
      GoRoute(path: '/region', builder: (_, __) => const RegionScreen()),
      GoRoute(
          path: '/permissions',
          builder: (_, __) => const PermissionsScreen()),
      GoRoute(
          path: '/update-required',
          builder: (_, __) => const UpdateRequiredScreen()),
      GoRoute(
        path: '/auth',
        builder: (_, __) => const AuthScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            ShellScaffold(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/', builder: (_, __) => const DashboardScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                  path: '/transactions',
                  builder: (_, __) => const TransactionsScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/rooms',
                builder: (_, __) => const RoomsScreen(),
                routes: [
                  GoRoute(
                    path: ':roomId',
                    builder: (_, state) => RoomDetailScreen(
                      roomId: state.pathParameters['roomId']!,
                      initialTab: int.tryParse(
                              state.uri.queryParameters['tab'] ?? '') ??
                          0,
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                  path: '/settings',
                  builder: (_, __) => const SettingsScreen()),
            ],
          ),
        ],
      ),
      // Deep routes (outside shell — no bottom nav)
      GoRoute(
        path: '/settings/profile',
        builder: (_, __) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/settings/preferences',
        builder: (_, __) => const PreferencesScreen(),
      ),
      GoRoute(
        path: '/settings/security',
        builder: (_, __) => const SecurityScreen(),
      ),
      GoRoute(
        path: '/settings/notifications',
        builder: (_, __) => const NotificationSettingsScreen(),
      ),
      GoRoute(
        path: '/settings/about',
        builder: (_, __) => const AboutScreen(),
      ),
      GoRoute(path: '/accounts', builder: (_, __) => const AccountsScreen()),
      GoRoute(
        path: '/accounts/new',
        builder: (_, __) => const AccountFormScreen(),
      ),
      GoRoute(
        path: '/accounts/:id/edit',
        builder: (_, state) =>
            AccountFormScreen(account: state.extra as Account?),
      ),
      GoRoute(path: '/budgets', builder: (_, __) => const BudgetsScreen()),
      GoRoute(
        path: '/budgets/new',
        builder: (_, __) => const BudgetFormScreen(),
      ),
      GoRoute(
        path: '/budgets/:id',
        builder: (_, state) => BudgetDetailScreen(
          budgetId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/budgets/:id/edit',
        builder: (_, state) =>
            BudgetFormScreen(budget: state.extra as Budget?),
      ),
      GoRoute(path: '/reports', builder: (_, __) => const ReportsScreen()),
      GoRoute(
        path: '/reports/export',
        builder: (_, __) => const ExportScreen(),
      ),
      GoRoute(
        path: '/transactions/search',
        builder: (_, __) => const TransactionSearchScreen(),
      ),
      GoRoute(
        path: '/transactions/quick',
        builder: (_, __) => const QuickAddScreen(),
      ),
      GoRoute(
        path: '/transactions/new',
        builder: (_, state) => TransactionFormScreen(
          prefill: state.extra as Map<String, dynamic>?,
        ),
      ),
      GoRoute(
        path: '/transactions/:id',
        builder: (_, state) => TransactionDetailScreen(
          transactionId: state.pathParameters['id']!,
        ),
      ),
      // Room flows (outside shell — no bottom nav)
      GoRoute(path: '/rooms/new', builder: (_, __) => const RoomCreateScreen()),
      GoRoute(path: '/rooms/join', builder: (_, __) => const RoomJoinScreen()),
      GoRoute(
        path: '/rooms/:roomId/invite',
        builder: (_, state) => RoomInviteScreen(
          roomId: state.pathParameters['roomId']!,
        ),
      ),
      GoRoute(
        path: '/rooms/:roomId/settle',
        redirect: (_, state) =>
            '/rooms/${state.pathParameters['roomId']}?tab=2',
      ),
      GoRoute(
        path: '/rooms/:roomId/budgets',
        builder: (_, state) => RoomBudgetsScreen(
          roomId: state.pathParameters['roomId']!,
        ),
      ),
      GoRoute(
        path: '/scan',
        builder: (_, __) => const ScannerScreen(),
      ),
      GoRoute(
        path: '/billing',
        builder: (_, __) => const BillingHistoryScreen(),
      ),
      GoRoute(
        path: '/paywall',
        builder: (_, state) => PaywallScreen(
          feature: (state.extra as String?) ?? 'general',
        ),
      ),
      GoRoute(
        path: '/pro/success',
        builder: (_, __) => const ProSuccessScreen(),
      ),
      GoRoute(
        path: '/billing/manage',
        builder: (_, __) => const ManageSubscriptionScreen(),
      ),
      GoRoute(
        path: '/notifications',
        builder: (_, __) => const system_notifs.SystemNotificationsScreen(),
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
