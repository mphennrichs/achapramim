import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/marketplace_labels.dart';
import '../../../core/models/watch.dart';
import '../../../core/providers.dart';
import '../../../l10n/app_localizations.dart';
import '../admin_providers.dart';

class AdminWatchCard extends ConsumerStatefulWidget {
  final Watch watch;

  const AdminWatchCard({super.key, required this.watch});

  @override
  ConsumerState<AdminWatchCard> createState() => _AdminWatchCardState();
}

class _AdminWatchCardState extends ConsumerState<AdminWatchCard> {
  bool _scanning = false;

  Future<void> _triggerScan() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _scanning = true);
    try {
      await ref.read(watchServiceProvider).triggerScan(widget.watch.id);
      ref.invalidate(allWatchesProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.adminWatchesTriggerScanSuccess)),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n.adminWatchesTriggerScanError(error.toString()),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _scanning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final watch = widget.watch;
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
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _scanning ? null : _triggerScan,
                icon: _scanning
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.play_circle_outline),
                label: Text(l10n.adminWatchesTriggerScan),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
