import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/marketplace_labels.dart';
import '../../core/models/watch.dart';
import '../../core/providers.dart';
import '../../l10n/app_localizations.dart';

final watchListProvider = FutureProvider.autoDispose<List<Watch>>((ref) {
  return ref.watch(watchServiceProvider).list();
});

class WatchListScreen extends ConsumerWidget {
  const WatchListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final watchesAsync = ref.watch(watchListProvider);
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/watches/new'),
        icon: const Icon(Icons.add),
        label: Text(l10n.navNewWatch),
      ),
      body: watchesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            Center(child: Text(l10n.watchListLoadError(error.toString()))),
        data: (watches) {
          if (watches.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.search_off,
                    size: 48,
                    color: scheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.watchListEmpty,
                    style: TextStyle(color: scheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => context.go('/watches/new'),
                    child: Text(l10n.watchListCreateFirst),
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

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.watchDeleteConfirmTitle),
        content: Text(l10n.watchDeleteConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.watchDeleteConfirmCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: Text(l10n.watchDeleteConfirmConfirm),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ref.read(watchServiceProvider).delete(watch.id);
      ref.invalidate(watchListProvider);
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.watchDeleteError(error.toString()))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final priceLabel =
        'R\$ ${(watch.targetPriceCents / 100).toStringAsFixed(2).replaceAll('.', ',')}';

    return Card(
      child: InkWell(
        onTap: () => context.push('/watches/${watch.id}'),
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
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
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
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    tooltip: l10n.watchEditTooltip,
                    onPressed: () async {
                      await context.push('/watches/${watch.id}/edit');
                      ref.invalidate(watchListProvider);
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    tooltip: l10n.watchDeleteTooltip,
                    onPressed: () => _confirmDelete(context, ref),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Chip(label: Text(priceLabel)),
                  Chip(
                    label: Text(l10n.watchTolerance(watch.tolerancePercent)),
                  ),
                  for (final marketplace in watch.marketplaces)
                    Chip(label: Text(marketplaceLabel(l10n, marketplace))),
                ],
              ),
              if (watch.keywords.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  watch.keywords.join(', '),
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontSize: 13,
                  ),
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
