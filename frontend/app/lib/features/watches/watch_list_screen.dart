import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/watch.dart';
import '../../core/providers.dart';
import 'app_shell.dart';

final watchListProvider = FutureProvider.autoDispose<List<Watch>>((ref) {
  return ref.watch(watchServiceProvider).list();
});

class WatchListScreen extends ConsumerWidget {
  const WatchListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final watchesAsync = ref.watch(watchListProvider);
    final scheme = Theme.of(context).colorScheme;

    return AppShell(
      title: 'Meus Watches',
      selectedIndex: 0,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).pushNamed('/watches/new'),
        icon: const Icon(Icons.add),
        label: const Text('Nova Consulta'),
      ),
      body: watchesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Text('Falha ao carregar Watches: $error'),
        ),
        data: (watches) {
          if (watches.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.search_off, size: 48, color: scheme.onSurfaceVariant),
                  const SizedBox(height: 12),
                  Text(
                    'Nenhum Watch cadastrado ainda.',
                    style: TextStyle(color: scheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pushNamed('/watches/new'),
                    child: const Text('Criar o primeiro Watch'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.refresh(watchListProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: watches.length,
              separatorBuilder: (context, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final watch = watches[index];
                return _WatchCard(watch: watch);
              },
            ),
          );
        },
      ),
    );
  }
}

class _WatchCard extends ConsumerWidget {
  final Watch watch;

  const _WatchCard({required this.watch});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final priceLabel =
        'R\$ ${(watch.targetPriceCents / 100).toStringAsFixed(2).replaceAll('.', ',')}';

    return Card(
      child: InkWell(
        onTap: () => Navigator.of(context).pushNamed('/watches/${watch.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      watch.name,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                  Switch(
                    value: watch.active,
                    onChanged: (value) async {
                      await ref
                          .read(watchServiceProvider)
                          .setActive(watch.id, value);
                      ref.invalidate(watchListProvider);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Chip(label: Text(priceLabel)),
                  Chip(label: Text('Tolerância ${watch.tolerancePercent}%')),
                  for (final marketplace in watch.marketplaces)
                    Chip(label: Text(marketplace)),
                ],
              ),
              if (watch.keywords.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  watch.keywords.join(', '),
                  style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
