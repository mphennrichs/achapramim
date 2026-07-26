import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth_state.dart';
import '../../core/navigation_pages.dart';
import '../../l10n/app_localizations.dart';
import 'widgets/notification_bell.dart';
import 'widgets/side_nav.dart';

/// Casco persistente das telas autenticadas: sidebar fixa em telas largas
/// (desktop/tablet), drawer em telas estreitas (mobile). Diferente do
/// AppShell antigo (montado por rota via Navigator.pushNamed, recriado a
/// cada navegação), este widget é o `builder` de um StatefulShellRoute — só
/// o conteúdo de `navigationShell` troca ao navegar entre branches, a
/// sidebar e o restante do casco permanecem montados (replica o padrão do
/// trupesound: router_provider.dart + base_page.dart).
class BasePage extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const BasePage({super.key, required this.navigationShell});

  /// Índice de branch (ordem física em router_provider.dart: newWatch=0,
  /// watches=1, profile=2, adminUsers=3, adminWatches=4, adminSettings=5 —
  /// newWatch precisa vir antes de watches ali para não colidir com a
  /// sub-rota `:watchId` de watches) por página. A ordem *visual* do menu é
  /// definida em `SideNav.destinations` e é independente desta.
  static const _branchIndexByPage = {
    NavigationPage.newWatch: 0,
    NavigationPage.watches: 1,
    NavigationPage.profile: 2,
    NavigationPage.adminUsers: 3,
    NavigationPage.adminWatches: 4,
    NavigationPage.adminSettings: 5,
  };

  static const _pageByBranchIndex = {
    0: NavigationPage.newWatch,
    1: NavigationPage.watches,
    2: NavigationPage.profile,
    3: NavigationPage.adminUsers,
    4: NavigationPage.adminWatches,
    5: NavigationPage.adminSettings,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isWide = MediaQuery.of(context).size.width >= 900;
    final navigation = SideNav(
      currentPage: _pageByBranchIndex[navigationShell.currentIndex]!,
      onDestinationSelected: (page) {
        final index = _branchIndexByPage[page]!;
        navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        );
      },
      onLogout: () => ref.read(authStateProvider.notifier).logout(),
    );

    final title = _titleFor(
      context,
      _pageByBranchIndex[navigationShell.currentIndex]!,
    );
    // Uma sub-rota do branch (hoje só watch detail, /watches/:watchId) traz
    // seu próprio Scaffold+AppBar — some com o cabeçalho fixo do Shell aqui
    // pra não duplicar título/voltar. Compara contra os paths exatos dos
    // branches em vez de contar segmentos: contar segmentos classificaria
    // erroneamente /watches/new (branch newWatch, 2 segmentos) como sub-rota.
    final currentLocation = GoRouterState.of(context).uri.toString();
    const branchPaths = {
      '/watches',
      '/watches/new',
      '/profile',
      '/admin/users',
      '/admin/watches',
      '/admin/settings',
    };
    final isSubRoute = !branchPaths.contains(currentLocation);

    return Scaffold(
      appBar: (isWide || isSubRoute)
          ? null
          : AppBar(title: Text(title), actions: const [NotificationBell()]),
      drawer: isWide ? null : Drawer(child: navigation),
      body: Row(
        children: [
          if (isWide) SizedBox(width: 260, child: navigation),
          Expanded(
            child: Column(
              children: [
                if (isWide && !isSubRoute)
                  Container(
                    height: 64,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    alignment: Alignment.centerLeft,
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerLowest,
                      border: Border(
                        bottom: BorderSide(
                          color: Theme.of(context).colorScheme.outlineVariant,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        const NotificationBell(),
                      ],
                    ),
                  ),
                Expanded(child: navigationShell),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _titleFor(BuildContext context, NavigationPage page) {
    final l10n = AppLocalizations.of(context)!;
    return switch (page) {
      NavigationPage.watches => l10n.watchListTitle,
      NavigationPage.newWatch => l10n.newWatchTitle,
      NavigationPage.profile => l10n.profileTitle,
      NavigationPage.adminUsers => l10n.adminUsersTitle,
      NavigationPage.adminWatches => l10n.adminWatchesTitle,
      NavigationPage.adminSettings => l10n.adminSettingsTitle,
      _ => '',
    };
  }
}
