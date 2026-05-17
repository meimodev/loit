import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/auth/otp_screen.dart';
import '../../features/auth/permissions_screen.dart';
import '../../features/auth/sign_in_screen.dart';
import '../../features/auth/splash_screen.dart';
import '../../features/auth/welcome_screen.dart';
import '../../features/accounts/account_form_screen.dart';
import '../../features/accounts/accounts_screen.dart';
import '../../features/billing/manage_subscription_screen.dart';
import '../../features/receipts/receipts_screen.dart';
import '../../features/paywall/pro_success_screen.dart';
import '../../features/budgets/budget_detail_screen.dart';
import '../../features/budgets/budget_form_screen.dart';
import '../../features/budgets/budgets_screen.dart';
import '../../features/categories/categories_screen.dart';
import '../../features/categories/category_form_screen.dart';
import '../../features/system/notifications_screen.dart' as system_notifs;
import '../../features/system/update_required_screen.dart';
import '../../shared/providers/accounts_provider.dart';
import '../../shared/providers/budgets_provider.dart';
import '../../shared/providers/user_categories_provider.dart';
import '../../features/dashboard/dashboard_screen.dart';
import '../../features/reports/export_screen.dart';
import '../../features/reports/reports_screen.dart';
import '../../features/paywall/paywall_screen.dart';
import '../../features/room_detail/room_budget_form_screen.dart';
import '../../features/room_detail/room_budgets_screen.dart';
import '../../features/room_detail/room_detail_screen.dart';
import '../../features/room_detail/room_transaction_detail_screen.dart';
import '../../features/rooms/room_create_screen.dart';
import '../../features/rooms/room_invite_screen.dart';
import '../../features/rooms/room_join_screen.dart';
import '../../features/rooms/rooms_screen.dart';
import '../../features/scanner/scanner_screen.dart';
import '../../features/settings/about_screen.dart';
import '../../features/settings/notifications_screen.dart';
import '../../features/settings/preferences_screen.dart';
import '../../features/settings/scanning_screen.dart';
import '../../features/settings/profile_screen.dart';
import '../../features/settings/security_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/transactions/transaction_detail_screen.dart';
import '../../features/transactions/quick_add_screen.dart';
import '../../features/transactions/transaction_form_screen.dart';
import '../../features/transactions/transaction_search_screen.dart';
import '../../features/transactions/transactions_screen.dart';
import '../../shared/providers/auth_providers.dart';
import '../../shared/providers/transactions_provider.dart';
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
        '/splash',
        '/welcome',
        '/sign-in',
        '/otp',
        '/permissions',
        '/update-required',
      };
      final isPublic = publicPaths.contains(loc);
      if (!loggedIn && !isPublic) return '/welcome';
      if (loggedIn &&
          (loc == '/welcome' || loc == '/sign-in')) {
        return '/';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/welcome', builder: (_, __) => const WelcomeScreen()),
      GoRoute(path: '/sign-in', builder: (_, __) => const SignInScreen()),
      GoRoute(
          path: '/otp',
          builder: (_, state) =>
              OtpScreen(email: (state.extra as String?) ?? '')),
      GoRoute(
          path: '/permissions',
          builder: (_, __) => const PermissionsScreen()),
      GoRoute(
          path: '/update-required',
          builder: (_, __) => const UpdateRequiredScreen()),
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
                  builder: (_, state) => TransactionsScreen(
                        highlightTxId:
                            state.uri.queryParameters['highlight'],
                      )),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/rooms',
                builder: (_, __) => const RoomsScreen(),
                routes: [
                  // Static segments must precede the `:roomId` parameter
                  // route so `/rooms/new` and `/rooms/join` don't get
                  // captured as room ids (which would be sent to Postgres
                  // as a uuid and 22p02 out).
                  GoRoute(
                    path: 'new',
                    builder: (_, __) => const RoomCreateScreen(),
                  ),
                  GoRoute(
                    path: 'join',
                    builder: (_, __) => const RoomJoinScreen(),
                  ),
                  GoRoute(
                    path: ':roomId',
                    builder: (_, state) => RoomDetailScreen(
                      roomId: state.pathParameters['roomId']!,
                      initialTab: int.tryParse(
                              state.uri.queryParameters['tab'] ?? '') ??
                          0,
                      highlightTxId: state.uri.queryParameters['highlight'],
                      fromTab: state.uri.queryParameters['from'],
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
        path: '/settings/scanning',
        builder: (_, __) => const ScanningScreen(),
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
      GoRoute(
        path: '/categories',
        builder: (_, __) => const CategoriesScreen(),
      ),
      GoRoute(
        path: '/categories/new',
        builder: (_, __) => const CategoryFormScreen(),
      ),
      GoRoute(
        path: '/categories/:id/edit',
        builder: (_, state) =>
            CategoryFormScreen(category: state.extra as UserCategory?),
      ),
      GoRoute(
        path: '/rooms/:roomId/categories/new',
        builder: (_, state) => CategoryFormScreen(
          roomId: state.pathParameters['roomId']!,
        ),
      ),
      GoRoute(
        path: '/rooms/:roomId/categories/:id/edit',
        builder: (_, state) => CategoryFormScreen(
          roomId: state.pathParameters['roomId']!,
          category: state.extra as UserCategory?,
        ),
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
          txn: state.extra as Txn?,
        ),
      ),
      // Room flows (outside shell — no bottom nav)
      // /rooms/new and /rooms/join now live inside the /rooms shell branch
      // so the shell's `:roomId` matcher doesn't capture the literal "new".
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
        path: '/rooms/:roomId/reports',
        builder: (_, state) => ReportsScreen(
          roomId: state.pathParameters['roomId']!,
        ),
      ),
      GoRoute(
        path: '/rooms/:roomId/reports/export',
        builder: (_, state) => ExportScreen(
          roomId: state.pathParameters['roomId']!,
        ),
      ),
      GoRoute(
        path: '/rooms/:roomId/budgets/new',
        builder: (_, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return RoomBudgetFormScreen(
            roomId: state.pathParameters['roomId']!,
            currency: extra?['currency'] as String?,
          );
        },
      ),
      GoRoute(
        path: '/rooms/:roomId/budgets/:budgetId/edit',
        builder: (_, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return RoomBudgetFormScreen(
            roomId: state.pathParameters['roomId']!,
            budgetId: state.pathParameters['budgetId']!,
            currency: extra?['currency'] as String?,
            budget: extra?['budget'] as Map<String, dynamic>?,
          );
        },
      ),
      GoRoute(
        path: '/rooms/:roomId/transactions/:transactionId',
        builder: (_, state) => RoomTransactionDetailScreen(
          roomId: state.pathParameters['roomId']!,
          transactionId: state.pathParameters['transactionId']!,
          txn: state.extra as Map<String, dynamic>?,
        ),
      ),
      GoRoute(
        path: '/scan',
        builder: (_, state) => ScannerScreen(
          roomId: state.uri.queryParameters['roomId'],
        ),
      ),
      GoRoute(
        path: '/receipts',
        builder: (_, __) => const ReceiptsScreen(),
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
