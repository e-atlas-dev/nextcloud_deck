import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:nextcloud_deck/presentation/providers/auth_provider.dart';
import 'package:nextcloud_deck/presentation/providers/settings_provider.dart';
import 'package:nextcloud_deck/presentation/screens/account_screen.dart';
import 'package:nextcloud_deck/presentation/screens/board_kanban_screen.dart';
import 'package:nextcloud_deck/presentation/screens/boards_list_screen.dart';
import 'package:nextcloud_deck/presentation/screens/card_detail_screen.dart';
import 'package:nextcloud_deck/presentation/screens/conflict_resolution_screen.dart';
import 'package:nextcloud_deck/presentation/screens/login_screen.dart';
import 'package:nextcloud_deck/presentation/screens/onboarding_screen.dart';
import 'package:nextcloud_deck/presentation/screens/settings_screen.dart';
import 'package:nextcloud_deck/presentation/screens/splash_screen.dart';
import 'package:nextcloud_deck/presentation/screens/sync_logs_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authListenable = _AuthRouterNotifier(ref);

  return GoRouter(
    refreshListenable: authListenable,
    initialLocation: '/splash',
    redirect: (context, state) {
      final authState = ref.read(authProvider);

      if (authState.isLoading) return '/splash';

      final auth = authState.value;
      if (auth == null) return '/splash';

      final isAuthed = auth.isAuthenticated;
      final location = state.matchedLocation;
      final onSplash = location == '/splash';
      final onLogin = location == '/login';
      final onOnboarding = location == '/onboarding';

      // Unauthenticated → always leave splash / any protected route → login
      if (!isAuthed && (onSplash || (!onLogin && !onOnboarding))) {
        return '/login';
      }

      // Authenticated → leave splash or login
      if (isAuthed && (onSplash || onLogin)) {
        final settings = ref.read(settingsProvider);
        return settings.hasSeenOnboarding ? '/' : '/onboarding';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(
        path: '/onboarding',
        builder: (_, __) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/',
        builder: (_, __) => const BoardsListScreen(),
        routes: [
          GoRoute(
            path: 'board/:boardId',
            builder: (_, state) => BoardKanbanScreen(
              boardId: int.parse(state.pathParameters['boardId']!),
              boardTitle: state.uri.queryParameters['title'] ?? '',
              boardColor: state.uri.queryParameters['color'] ?? '0082C9',
            ),
            routes: [
              GoRoute(
                path: 'card/:cardId',
                builder: (_, state) => CardDetailScreen(
                  boardId: int.parse(state.pathParameters['boardId']!),
                  stackId: int.parse(
                    state.uri.queryParameters['stackId'] ?? '0',
                  ),
                  cardId: int.parse(state.pathParameters['cardId']!),
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/settings',
            builder: (_, __) => const SettingsScreen(),
            routes: [
              // Nested under settings so back button returns to settings
              GoRoute(
                path: 'account',
                builder: (_, __) => const AccountScreen(),
              ),
              GoRoute(
                path: 'sync-logs',
                builder: (_, __) => const SyncLogsScreen(),
              ),
              GoRoute(
                path: 'conflicts',
                builder: (_, __) => const ConflictResolutionScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

class _AuthRouterNotifier extends ChangeNotifier {
  _AuthRouterNotifier(this._ref) {
    _ref.listen(authProvider, (_, __) => notifyListeners());
  }
  final Ref _ref;
}
