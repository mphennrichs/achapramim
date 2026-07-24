import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/admin/admin_settings_screen.dart';
import '../features/admin/admin_users_screen.dart';
import '../features/admin/admin_watches_screen.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/set_username_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/shell/base_page.dart';
import '../features/watches/new_watch_screen.dart';
import '../features/watches/watch_detail_screen.dart';
import '../features/watches/watch_list_screen.dart';
import 'auth_router_refresh.dart';
import 'auth_state.dart';
import 'navigation_pages.dart';
import 'providers.dart';

const _splashPath = '/splash';
const _adminPathPrefix = '/admin/';

/// Router único do app. `ref.read`, não `watch`: o GoRouter deve ser criado
/// uma vez e permanecer estável — `refreshListenable` (não uma dependência de
/// `watch`) é o que avisa o go_router para reavaliar `redirect` quando o
/// estado de sessão muda; usar `ref.watch(authStateProvider)` aqui dentro
/// recriaria este provider inteiro (e um GoRouter novo) a cada mudança de
/// estado, remontando toda a árvore de páginas.
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: _splashPath,
    refreshListenable: ref.read(authRouterRefreshProvider),
    redirect: (context, state) {
      final status = ref.read(authStateProvider).status;
      final isSplashRoute = state.matchedLocation == _splashPath;
      final isAuthRoute = state.matchedLocation == '/login';
      final isSetUsernameRoute = state.matchedLocation == '/set-username';

      switch (status) {
        case SessionStatus.unknown:
          // Ainda checando a sessão — mantém a Splash, evita um flash para
          // /login antes de saber se há sessão válida.
          return isSplashRoute ? null : _splashPath;
        case SessionStatus.unauthenticated:
          return isAuthRoute ? null : '/login';
        case SessionStatus.usernamePending:
          return isSetUsernameRoute ? null : '/set-username';
        case SessionStatus.authenticated:
          if (isSplashRoute || isAuthRoute || isSetUsernameRoute) {
            return NavigationPage.watches.path;
          }
          // Bloqueia acesso direto por URL às rotas /admin/* para quem não é
          // admin — a sidebar já esconde esses itens, mas alguém pode digitar
          // a URL diretamente. Enquanto o perfil ainda carrega (valueOrNull
          // null), deixa passar sem bloquear; AuthRouterRefresh reavalia este
          // redirect assim que currentUserProfileProvider resolver a role real.
          final isAdminRoute = state.matchedLocation.startsWith(
            _adminPathPrefix,
          );
          if (isAdminRoute) {
            final profile = ref.read(currentUserProfileProvider).valueOrNull;
            if (profile != null && profile.role != 'admin') {
              return NavigationPage.watches.path;
            }
          }
          return null;
      }
    },
    routes: [
      GoRoute(
        path: _splashPath,
        builder: (context, state) =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/set-username',
        builder: (context, state) => const SetUsernameScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            BasePage(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                // Precisa vir antes do branch `watches` abaixo: o go_router
                // resolve o primeiro branch cujo path casa, e `/watches/new`
                // colidiria com a sub-rota `:watchId` de `watches` se este
                // branch viesse depois (viraria GET /api/watches/new).
                path: NavigationPage.newWatch.path,
                builder: (context, state) => const NewWatchScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: NavigationPage.watches.path,
                builder: (context, state) => const WatchListScreen(),
                routes: [
                  GoRoute(
                    path: NavigationPage.watchDetail.path,
                    builder: (context, state) {
                      final watchId = state.pathParameters['watchId']!;
                      return WatchDetailScreen(watchId: watchId);
                    },
                  ),
                  GoRoute(
                    path: ':watchId/edit',
                    builder: (context, state) {
                      final watchId = state.pathParameters['watchId']!;
                      return EditWatchScreen(watchId: watchId);
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: NavigationPage.profile.path,
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: NavigationPage.adminUsers.path,
                builder: (context, state) => const AdminUsersScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: NavigationPage.adminWatches.path,
                builder: (context, state) => const AdminWatchesScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: NavigationPage.adminSettings.path,
                builder: (context, state) => const AdminSettingsScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
