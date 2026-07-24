import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/marketplace_labels.dart';
import '../../core/models/offer.dart';
import '../../core/models/watch.dart';
import '../../core/providers.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/status_colors.dart';
import 'watch_list_screen.dart';

final _watchProvider = FutureProvider.autoDispose.family<Watch, String>((
  ref,
  watchId,
) {
  return ref.watch(watchServiceProvider).get(watchId);
});

final _offersProvider = FutureProvider.autoDispose.family<List<Offer>, String>((
  ref,
  watchId,
) {
  return ref.watch(watchServiceProvider).offers(watchId);
});

final _scansProvider = FutureProvider.autoDispose
    .family<List<ScanSummary>, String>((ref, watchId) {
      return ref.watch(watchServiceProvider).scans(watchId);
    });

class WatchDetailScreen extends ConsumerStatefulWidget {
  final String watchId;

  const WatchDetailScreen({super.key, required this.watchId});

  @override
  ConsumerState<WatchDetailScreen> createState() => _WatchDetailScreenState();
}

class _WatchDetailScreenState extends ConsumerState<WatchDetailScreen> {
  bool _deleting = false;

  Future<void> _confirmDelete() async {
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

    setState(() => _deleting = true);
    try {
      await ref.read(watchServiceProvider).delete(widget.watchId);
      ref.invalidate(watchListProvider);
      if (mounted) context.go('/watches');
    } catch (error) {
      if (mounted) {
        setState(() => _deleting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.watchDeleteError(error.toString()))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final watchAsync = ref.watch(_watchProvider(widget.watchId));
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          watchAsync.valueOrNull?.name ?? l10n.watchDetailFallbackTitle,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: l10n.watchEditTooltip,
            onPressed: () async {
              await context.push('/watches/${widget.watchId}/edit');
              ref.invalidate(_watchProvider(widget.watchId));
            },
          ),
          IconButton(
            icon: _deleting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.delete_outline),
            tooltip: l10n.watchDeleteTooltip,
            onPressed: _deleting ? null : _confirmDelete,
          ),
        ],
      ),
      body: watchAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            Center(child: Text(l10n.watchDetailLoadError(error.toString()))),
        data: (watch) => DefaultTabController(
          length: 2,
          child: Column(
            children: [
              _WatchSummaryHeader(watch: watch),
              TabBar(
                tabs: [
                  Tab(text: l10n.watchDetailTabOffers),
                  Tab(text: l10n.watchDetailTabScans),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _OffersTab(watchId: widget.watchId),
                    _ScansTab(watchId: widget.watchId),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WatchSummaryHeader extends StatelessWidget {
  final Watch watch;

  const _WatchSummaryHeader({required this.watch});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final priceLabel =
        'R\$ ${(watch.targetPriceCents / 100).toStringAsFixed(2).replaceAll('.', ',')}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: scheme.outlineVariant)),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Chip(label: Text(l10n.watchDetailTarget(priceLabel))),
          Chip(label: Text(l10n.watchDetailTolerance(watch.tolerancePercent))),
          Chip(
            label: Text(
              l10n.watchDetailDropThreshold(watch.priceDropThresholdPercent),
            ),
          ),
          Chip(label: Text(l10n.watchDetailMaxOffers(watch.maxOffers))),
          Chip(
            label: Text(
              watch.active ? l10n.watchDetailActive : l10n.watchDetailInactive,
              style: TextStyle(
                color: watch.active
                    ? scheme.onPrimaryContainer
                    : scheme.onSurfaceVariant,
              ),
            ),
            backgroundColor: watch.active
                ? scheme.primaryContainer
                : scheme.surfaceContainerHigh,
          ),
          for (final marketplace in watch.marketplaces)
            Chip(label: Text(marketplaceLabel(l10n, marketplace))),
        ],
      ),
    );
  }
}

class _OffersTab extends ConsumerWidget {
  final String watchId;

  const _OffersTab({required this.watchId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offersAsync = ref.watch(_offersProvider(watchId));
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return offersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Text(l10n.watchDetailOffersLoadError(error.toString())),
      ),
      data: (offers) {
        if (offers.isEmpty) {
          return Center(
            child: Text(
              l10n.watchDetailNoOffers,
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: offers.length,
          separatorBuilder: (context, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) => _OfferCard(offer: offers[index]),
        );
      },
    );
  }
}

class _OfferCard extends StatelessWidget {
  final Offer offer;

  const _OfferCard({required this.offer});

  Future<void> _openListing(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final uri = Uri.tryParse(offer.url);
    final launched =
        uri != null && await launchUrl(uri, webOnlyWindowName: '_blank');
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.watchDetailOpenListingError)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final priceLabel =
        'R\$ ${(offer.priceCents / 100).toStringAsFixed(2).replaceAll('.', ',')}';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 64,
                height: 64,
                child: offer.imageUrl.isNotEmpty
                    ? Image.network(
                        offer.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: scheme.surfaceContainerHigh,
                          child: const Icon(Icons.image_not_supported),
                        ),
                      )
                    : Container(
                        color: scheme.surfaceContainerHigh,
                        child: const Icon(Icons.image_not_supported),
                      ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    offer.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    marketplaceLabel(l10n, offer.marketplaceSlug),
                    style: TextStyle(
                      color: scheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        priceLabel,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: scheme.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      if (!offer.available)
                        Chip(
                          label: Text(l10n.watchDetailOfferUnavailable),
                          backgroundColor: scheme.errorContainer,
                          labelStyle: TextStyle(color: scheme.onErrorContainer),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.open_in_new),
              onPressed: () => _openListing(context),
              tooltip: l10n.watchDetailOpenListing,
            ),
          ],
        ),
      ),
    );
  }
}

class _ScansTab extends ConsumerWidget {
  final String watchId;

  const _ScansTab({required this.watchId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scansAsync = ref.watch(_scansProvider(watchId));
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return scansAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) =>
          Center(child: Text(l10n.watchDetailScansLoadError(error.toString()))),
      data: (scans) {
        if (scans.isEmpty) {
          return Center(
            child: Text(
              l10n.watchDetailNoScans,
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: scans.length,
          separatorBuilder: (context, _) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final scan = scans[index];
            return ListTile(
              leading: Tooltip(
                message: _scanStatusLabel(l10n, scan.status),
                child: _StatusIcon(status: scan.status),
              ),
              title: Text(dateFormat.format(scan.startedAt.toLocal())),
              subtitle: Text(
                scan.failedMarketplaces.isNotEmpty
                    ? l10n.watchDetailScanFailures(
                        scan.failedMarketplaces.join(', '),
                      )
                    : _scanStatusLabel(l10n, scan.status),
              ),
              trailing: Text(l10n.watchDetailOffersFound(scan.offersFound)),
            );
          },
        );
      },
    );
  }
}

class _StatusIcon extends StatelessWidget {
  final String status;

  const _StatusIcon({required this.status});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    switch (status) {
      case 'success':
        return const Icon(Icons.check_circle, color: successColor);
      case 'partial':
        return const Icon(Icons.warning_amber, color: warningColor);
      case 'failed':
        return Icon(Icons.error, color: scheme.error);
      default:
        return const Icon(Icons.hourglass_empty);
    }
  }
}

String _scanStatusLabel(AppLocalizations l10n, String status) {
  switch (status) {
    case 'success':
      return l10n.scanStatusSuccess;
    case 'partial':
      return l10n.scanStatusPartial;
    case 'failed':
      return l10n.scanStatusFailed;
    default:
      return l10n.scanStatusPending;
  }
}
