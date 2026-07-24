import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth_state.dart';
import '../../core/navigation_pages.dart';
import '../../core/providers.dart';
import '../../l10n/app_localizations.dart';
import '../notifications/notifications_dialog.dart';

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
  /// definida em `_SideNav.destinations` e é independente desta.
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
    final navigation = _SideNav(
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
          : AppBar(title: Text(title), actions: const [_NotificationBell()]),
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
                        const _NotificationBell(),
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

class _SideNav extends ConsumerWidget {
  final NavigationPage currentPage;
  final ValueChanged<NavigationPage> onDestinationSelected;
  final VoidCallback onLogout;

  const _SideNav({
    required this.currentPage,
    required this.onDestinationSelected,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final userProfile = ref.watch(currentUserProfileProvider).valueOrNull;
    final isAdmin = userProfile?.role == 'admin';
    // Ordem visual do menu — independente da ordem de branches no router.
    // Itens de admin só aparecem depois que o perfil confirma role=admin —
    // enquanto carrega ou para User comum, a sidebar mostra só os 3 itens
    // padrão (não pisca os itens de admin e depois some).
    final destinations = [
      _NavDestination(
        page: NavigationPage.watches,
        icon: Icons.visibility,
        label: l10n.navMyWatches,
      ),
      _NavDestination(
        page: NavigationPage.newWatch,
        icon: Icons.search,
        label: l10n.navNewWatch,
      ),
      _NavDestination(
        page: NavigationPage.profile,
        icon: Icons.person,
        label: l10n.navProfile,
      ),
      if (isAdmin) ...[
        _NavDestination(
          page: NavigationPage.adminUsers,
          icon: Icons.people,
          label: l10n.navAdminUsers,
        ),
        _NavDestination(
          page: NavigationPage.adminWatches,
          icon: Icons.admin_panel_settings,
          label: l10n.navAdminAllWatches,
        ),
        _NavDestination(
          page: NavigationPage.adminSettings,
          icon: Icons.settings,
          label: l10n.navAdminSettings,
        ),
      ],
    ];

    return Container(
      color: scheme.surfaceContainerLowest,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: Row(
              children: [
                Image.asset('assets/images/logo.png', width: 88, height: 88),
                const SizedBox(width: 5),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.appTitle,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        userProfile?.name ?? l10n.navUserDashboard,
                        style: TextStyle(
                          color: scheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          for (final destination in destinations)
            _NavTile(
              destination: destination,
              selected: destination.page == currentPage,
              onTap: () => onDestinationSelected(destination.page),
            ),
          const Spacer(),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: Text(l10n.navLogout),
            onTap: onLogout,
          ),
        ],
      ),
    );
  }
}

class _NavDestination {
  final NavigationPage page;
  final IconData icon;
  final String label;

  const _NavDestination({
    required this.page,
    required this.icon,
    required this.label,
  });
}

class _NavTile extends StatelessWidget {
  final _NavDestination destination;
  final bool selected;
  final VoidCallback onTap;

  const _NavTile({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: selected ? scheme.primaryContainer : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: selected ? null : onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Icon(
                  destination.icon,
                  size: 20,
                  color: selected
                      ? scheme.onPrimaryContainer
                      : scheme.onSurfaceVariant,
                ),
                const SizedBox(width: 12),
                Text(
                  destination.label,
                  style: TextStyle(
                    color: selected
                        ? scheme.onPrimaryContainer
                        : scheme.onSurfaceVariant,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NotificationBell extends ConsumerWidget {
  const _NotificationBell();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final unreadCount = ref.watch(unreadNotificationCountProvider).valueOrNull ?? 0;

    return IconButton(
      tooltip: l10n.notificationsTooltip,
      onPressed: () => showNotificationsDialog(context),
      icon: Badge(
        isLabelVisible: unreadCount > 0,
        label: Text('$unreadCount'),
        child: const Icon(Icons.notifications_outlined),
      ),
    );
  }
}
