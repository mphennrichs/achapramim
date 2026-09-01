import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
  bool _busy = false;

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
            content: Text(l10n.adminWatchesTriggerScanError(error.toString())),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _scanning = false);
    }
  }

  Future<void> _setActive(bool active) async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _busy = true);
    try {
      await ref.read(watchServiceProvider).setActive(widget.watch.id, active);
      ref.invalidate(allWatchesProvider);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.adminWatchesSetActiveError(error.toString())),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirmDelete() async {
    final l10n = AppLocalizations.of(context)!;
    final watch = widget.watch;
    final owner = watch.ownerName ?? watch.ownerEmail ?? '';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.adminWatchesDeleteConfirmTitle),
        content: Text(l10n.adminWatchesDeleteConfirmMessage(watch.name, owner)),
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

    setState(() => _busy = true);
    try {
      await ref.read(watchServiceProvider).delete(watch.id);
      ref.invalidate(allWatchesProvider);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.adminWatchesDeleteError(error.toString())),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
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
      child: InkWell(
        onTap: () => context.push('/admin/watches/${watch.id}'),
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
                    onChanged: _busy ? null : _setActive,
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    tooltip: l10n.adminWatchesDeleteTooltip,
                    onPressed: _busy ? null : _confirmDelete,
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
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontSize: 13,
                  ),
                ),
              ],
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
      ),
    );
  }
}
