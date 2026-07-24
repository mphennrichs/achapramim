import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth_state.dart';
import '../../core/navigation_pages.dart';
import '../../l10n/app_localizations.dart';

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
  /// watches=1, profile=2 — newWatch precisa vir primeiro ali para não
  /// colidir com a sub-rota `:watchId` de watches) por página. A ordem
  /// *visual* do menu (Meus Watches, Nova Consulta, Perfil) é definida em
  /// `_SideNav.destinations` e é independente desta.
  static const _branchIndexByPage = {
    NavigationPage.newWatch: 0,
    NavigationPage.watches: 1,
    NavigationPage.profile: 2,
  };

  static const _pageByBranchIndex = {
    0: NavigationPage.newWatch,
    1: NavigationPage.watches,
    2: NavigationPage.profile,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isWide = MediaQuery.of(context).size.width >= 900;
    final navigation = _SideNav(
      currentPage: _pageByBranchIndex[navigationShell.currentIndex]!,
      onDestinationSelected: (page) {
        final index = _branchIndexByPage[page]!;
        navigationShell.goBranch(index, initialLocation: index == navigationShell.currentIndex);
      },
      onLogout: () => ref.read(authStateProvider.notifier).logout(),
    );

    final title = _titleFor(context, _pageByBranchIndex[navigationShell.currentIndex]!);
    // Uma sub-rota do branch (ex.: watch detail em /watches/:watchId) traz
    // seu próprio Scaffold+AppBar — some com o cabeçalho fixo do Shell aqui
    // pra não duplicar título/voltar. Detecta por profundidade de segmentos
    // além do path base do branch (`/watches` = 1 segmento).
    final currentLocation = GoRouterState.of(context).uri.toString();
    final isSubRoute = currentLocation.split('/').where((s) => s.isNotEmpty).length > 1;

    return Scaffold(
      appBar: (isWide || isSubRoute) ? null : AppBar(title: Text(title)),
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
                      color: Theme.of(context).colorScheme.surfaceContainerLowest,
                      border: Border(
                        bottom: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
                      ),
                    ),
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
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
      _ => '',
    };
  }
}

class _SideNav extends StatelessWidget {
  final NavigationPage currentPage;
  final ValueChanged<NavigationPage> onDestinationSelected;
  final VoidCallback onLogout;

  const _SideNav({
    required this.currentPage,
    required this.onDestinationSelected,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    // Ordem visual do menu — independente da ordem de branches no router.
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
    ];

    return Container(
      color: scheme.surfaceContainerLowest,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            child: Row(
              children: [
                Image.asset('assets/images/logo.png', width: 44, height: 44),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.appTitle,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      Text(
                        l10n.navUserDashboard,
                        style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
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

  const _NavDestination({required this.page, required this.icon, required this.label});
}

class _NavTile extends StatelessWidget {
  final _NavDestination destination;
  final bool selected;
  final VoidCallback onTap;

  const _NavTile({required this.destination, required this.selected, required this.onTap});

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
                  color: selected ? scheme.onPrimaryContainer : scheme.onSurfaceVariant,
                ),
                const SizedBox(width: 12),
                Text(
                  destination.label,
                  style: TextStyle(
                    color: selected ? scheme.onPrimaryContainer : scheme.onSurfaceVariant,
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
