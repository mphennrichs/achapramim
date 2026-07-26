import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/navigation_pages.dart';
import '../../../core/providers.dart';
import '../../../l10n/app_localizations.dart';
import 'nav_tile.dart';

class SideNav extends ConsumerWidget {
  final NavigationPage currentPage;
  final ValueChanged<NavigationPage> onDestinationSelected;
  final VoidCallback onLogout;

  const SideNav({
    super.key,
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
      NavDestination(
        page: NavigationPage.watches,
        icon: Icons.visibility,
        label: l10n.navMyWatches,
      ),
      NavDestination(
        page: NavigationPage.newWatch,
        icon: Icons.search,
        label: l10n.navNewWatch,
      ),
      NavDestination(
        page: NavigationPage.profile,
        icon: Icons.person,
        label: l10n.navProfile,
      ),
      if (isAdmin) ...[
        NavDestination(
          page: NavigationPage.adminUsers,
          icon: Icons.people,
          label: l10n.navAdminUsers,
        ),
        NavDestination(
          page: NavigationPage.adminWatches,
          icon: Icons.admin_panel_settings,
          label: l10n.navAdminAllWatches,
        ),
        NavDestination(
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
            NavTile(
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
