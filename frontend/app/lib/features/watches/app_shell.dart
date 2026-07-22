import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';

/// Casco compartilhado das telas de usuário: sidebar fixa em telas largas
/// (desktop/tablet), drawer em telas estreitas (mobile) — replica a
/// SideNavBar dos mockups (frontend/mockups/nova_consulta_light).
class AppShell extends ConsumerWidget {
  final String title;
  final int selectedIndex;
  final Widget body;
  final Widget? floatingActionButton;

  const AppShell({
    super.key,
    required this.title,
    required this.selectedIndex,
    required this.body,
    this.floatingActionButton,
  });

  static const _destinations = [
    _NavDestination(icon: Icons.visibility, label: 'Meus Watches', route: '/watches'),
    _NavDestination(icon: Icons.search, label: 'Nova Consulta', route: '/watches/new'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isWide = MediaQuery.of(context).size.width >= 900;
    final navigation = _SideNav(selectedIndex: selectedIndex, onLogout: () => _logout(context, ref));

    return Scaffold(
      appBar: isWide
          ? null
          : AppBar(
              title: Text(title),
            ),
      drawer: isWide ? null : Drawer(child: navigation),
      floatingActionButton: floatingActionButton,
      body: Row(
        children: [
          if (isWide)
            SizedBox(
              width: 260,
              child: navigation,
            ),
          Expanded(
            child: Column(
              children: [
                if (isWide)
                  Container(
                    height: 64,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerLowest,
                      border: Border(
                        bottom: BorderSide(
                          color: Theme.of(context).colorScheme.outlineVariant,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ],
                    ),
                  ),
                Expanded(child: body),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    await ref.read(authServiceProvider).logout();
    if (context.mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }
}

class _NavDestination {
  final IconData icon;
  final String label;
  final String route;

  const _NavDestination({required this.icon, required this.label, required this.route});
}

class _SideNav extends StatelessWidget {
  final int selectedIndex;
  final VoidCallback onLogout;

  const _SideNav({required this.selectedIndex, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

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
                Icon(Icons.visibility, color: scheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Achapramim',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      Text(
                        'User Dashboard',
                        style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          for (var i = 0; i < AppShell._destinations.length; i++)
            _NavTile(
              destination: AppShell._destinations[i],
              selected: i == selectedIndex,
            ),
          const Spacer(),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: onLogout,
          ),
        ],
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  final _NavDestination destination;
  final bool selected;

  const _NavTile({required this.destination, required this.selected});

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
          onTap: () {
            if (!selected) {
              Navigator.of(context).pushReplacementNamed(destination.route);
            }
          },
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
