import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/marketplace_labels.dart';
import '../../core/models/watch.dart';
import '../../core/providers.dart';
import '../../l10n/app_localizations.dart';

final _allWatchesProvider = FutureProvider.autoDispose<List<Watch>>((ref) {
  return ref.watch(watchServiceProvider).listAll();
});

class AdminWatchesScreen extends ConsumerWidget {
  const AdminWatchesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final watchesAsync = ref.watch(_allWatchesProvider);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: watchesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            Center(child: Text(l10n.adminWatchesLoadError(error.toString()))),
        data: (watches) {
          if (watches.isEmpty) {
            return Center(
              child: Text(
                l10n.adminWatchesEmpty,
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: watches.length,
            separatorBuilder: (context, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) =>
                _AdminWatchCard(watch: watches[index]),
          );
        },
      ),
    );
  }
}

class _AdminWatchCard extends StatelessWidget {
  final Watch watch;

  const _AdminWatchCard({required this.watch});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final priceLabel =
        'R\$ ${(watch.targetPriceCents / 100).toStringAsFixed(2).replaceAll('.', ',')}';

    return Card(
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
                Icon(
                  watch.active ? Icons.check_circle : Icons.pause_circle,
                  color: watch.active
                      ? scheme.primary
                      : scheme.onSurfaceVariant,
                ),
              ],
            ),
            if (watch.ownerName != null && watch.ownerEmail != null) ...[
              const SizedBox(height: 4),
              Text(
                l10n.adminWatchesOwnerLabel(
                  watch.ownerName!,
                  watch.ownerEmail!,
                ),
                style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
              ),
            ],
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(label: Text(priceLabel)),
                Chip(label: Text(l10n.watchTolerance(watch.tolerancePercent))),
                for (final marketplace in watch.marketplaces)
                  Chip(label: Text(marketplaceLabel(l10n, marketplace))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
