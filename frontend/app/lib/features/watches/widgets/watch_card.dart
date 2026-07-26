import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/marketplace_labels.dart';
import '../../../core/models/watch.dart';
import '../../../core/providers.dart';
import '../../../l10n/app_localizations.dart';
import '../watch_providers.dart';

class WatchCard extends ConsumerWidget {
  final Watch watch;

  const WatchCard({super.key, required this.watch});

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

    final title = Text(
      watch.name,
      style: Theme.of(
        context,
      ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
    );

    final controls = [
      Switch(
        value: watch.active,
        onChanged: (value) async {
          await ref.read(watchServiceProvider).setActive(watch.id, value);
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
    ];

    // Em telas estreitas, título + Switch + 2 IconButtons numa única Row
    // espremem o título até truncar cedo demais (ou estourar) — abaixo do
    // breakpoint o título ocupa a linha inteira e os controles descem para
    // uma segunda linha alinhada à direita.
    final isNarrow = MediaQuery.of(context).size.width < 600;

    return Card(
      child: InkWell(
        onTap: () => context.push('/watches/${watch.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isNarrow) ...[
                title,
                Row(mainAxisAlignment: MainAxisAlignment.end, children: controls),
              ] else
                Row(children: [Expanded(child: title), ...controls]),
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
