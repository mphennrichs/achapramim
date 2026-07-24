import 'package:fl_chart/fl_chart.dart';
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

final _priceHistoryProvider = FutureProvider.autoDispose
    .family<List<PricePoint>, ({String watchId, String offerId})>((ref, args) {
      return ref
          .watch(watchServiceProvider)
          .priceHistory(args.watchId, args.offerId);
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

enum _OfferSortCriterion { recommended, priceAsc, priceDesc, newest }

class _OffersTab extends ConsumerStatefulWidget {
  final String watchId;

  const _OffersTab({required this.watchId});

  @override
  ConsumerState<_OffersTab> createState() => _OffersTabState();
}

class _OffersTabState extends ConsumerState<_OffersTab> {
  _OfferSortCriterion _sort = _OfferSortCriterion.recommended;

  List<Offer> _sorted(List<Offer> offers) {
    final sorted = List.of(offers);
    switch (_sort) {
      case _OfferSortCriterion.recommended:
        sorted.sort(
          (a, b) => b.classificationValue.compareTo(a.classificationValue),
        );
      case _OfferSortCriterion.priceAsc:
        sorted.sort((a, b) => a.priceCents.compareTo(b.priceCents));
      case _OfferSortCriterion.priceDesc:
        sorted.sort((a, b) => b.priceCents.compareTo(a.priceCents));
      case _OfferSortCriterion.newest:
        sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
    // Offers monitoradas sempre no topo, independente do critério de
    // ordenação escolhido — dentro do grupo (monitoradas / não monitoradas)
    // a ordenação acima é preservada (sort estável).
    sorted.sort((a, b) {
      if (a.monitored == b.monitored) return 0;
      return a.monitored ? -1 : 1;
    });
    return sorted;
  }

  String _sortLabel(AppLocalizations l10n, _OfferSortCriterion criterion) {
    return switch (criterion) {
      _OfferSortCriterion.recommended => l10n.watchDetailSortRecommended,
      _OfferSortCriterion.priceAsc => l10n.watchDetailSortPriceAsc,
      _OfferSortCriterion.priceDesc => l10n.watchDetailSortPriceDesc,
      _OfferSortCriterion.newest => l10n.watchDetailSortNewest,
    };
  }

  @override
  Widget build(BuildContext context) {
    final offersAsync = ref.watch(_offersProvider(widget.watchId));
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
        final sortedOffers = _sorted(offers);
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  Text(
                    l10n.watchDetailSortLabel,
                    style: TextStyle(color: scheme.onSurfaceVariant),
                  ),
                  const SizedBox(width: 12),
                  DropdownButton<_OfferSortCriterion>(
                    value: _sort,
                    underline: const SizedBox.shrink(),
                    items: [
                      for (final criterion in _OfferSortCriterion.values)
                        DropdownMenuItem(
                          value: criterion,
                          child: Text(_sortLabel(l10n, criterion)),
                        ),
                    ],
                    onChanged: (value) {
                      if (value != null) setState(() => _sort = value);
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: sortedOffers.length,
                separatorBuilder: (context, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) => _OfferCard(
                  watchId: widget.watchId,
                  offer: sortedOffers[index],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _OfferCard extends ConsumerStatefulWidget {
  final String watchId;
  final Offer offer;

  const _OfferCard({required this.watchId, required this.offer});

  @override
  ConsumerState<_OfferCard> createState() => _OfferCardState();
}

class _OfferCardState extends ConsumerState<_OfferCard> {
  bool _togglingMonitor = false;

  Future<void> _openListing(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final uri = Uri.tryParse(widget.offer.url);
    final launched =
        uri != null && await launchUrl(uri, webOnlyWindowName: '_blank');
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.watchDetailOpenListingError)));
    }
  }

  Future<void> _toggleMonitored() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _togglingMonitor = true);
    try {
      await ref
          .read(watchServiceProvider)
          .setOfferMonitored(
            widget.watchId,
            widget.offer.id,
            !widget.offer.monitored,
          );
      ref.invalidate(_offersProvider(widget.watchId));
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.watchDetailMonitorError(error.toString()))),
        );
      }
    } finally {
      if (mounted) setState(() => _togglingMonitor = false);
    }
  }

  void _openPriceHistory() {
    showDialog<void>(
      context: context,
      builder: (context) =>
          _PriceHistoryDialog(watchId: widget.watchId, offer: widget.offer),
    );
  }

  @override
  Widget build(BuildContext context) {
    final offer = widget.offer;
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
              icon: _togglingMonitor
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(
                      offer.monitored ? Icons.star : Icons.star_border,
                      color: offer.monitored ? warningColor : null,
                    ),
              onPressed: _togglingMonitor ? null : _toggleMonitored,
              tooltip: offer.monitored
                  ? l10n.watchDetailUnmonitorOffer
                  : l10n.watchDetailMonitorOffer,
            ),
            IconButton(
              icon: const Icon(Icons.show_chart),
              onPressed: _openPriceHistory,
              tooltip: l10n.watchDetailPriceHistoryTooltip,
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

class _PriceHistoryDialog extends ConsumerWidget {
  final String watchId;
  final Offer offer;

  const _PriceHistoryDialog({required this.watchId, required this.offer});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final historyAsync = ref.watch(
      _priceHistoryProvider((watchId: watchId, offerId: offer.id)),
    );

    return AlertDialog(
      title: Text(l10n.watchDetailPriceHistoryTitle),
      content: SizedBox(
        width: 400,
        height: 260,
        child: historyAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Text(
              l10n.watchDetailPriceHistoryLoadError(error.toString()),
            ),
          ),
          data: (points) {
            if (points.isEmpty) {
              return Center(
                child: Text(
                  l10n.watchDetailPriceHistoryEmpty,
                  style: TextStyle(color: scheme.onSurfaceVariant),
                ),
              );
            }
            return _PriceHistoryChart(points: points);
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.watchDetailPriceHistoryClose),
        ),
      ],
    );
  }
}

class _PriceHistoryChart extends StatelessWidget {
  final List<PricePoint> points;

  const _PriceHistoryChart({required this.points});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dateFormat = DateFormat('dd/MM');
    final spots = [
      for (var i = 0; i < points.length; i++)
        FlSpot(i.toDouble(), points[i].priceCents / 100),
    ];
    final minY = spots.map((s) => s.y).reduce((a, b) => a < b ? a : b);
    final maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    final padding = (maxY - minY) * 0.1 + 1;

    return LineChart(
      LineChartData(
        minY: minY - padding,
        maxY: maxY + padding,
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) {
              return [
                for (final spot in touchedSpots)
                  LineTooltipItem(
                    'R\$ ${spot.y.toStringAsFixed(2).replaceAll('.', ',')}\n'
                    '${dateFormat.format(points[spot.x.toInt()].observedAt.toLocal())}',
                    TextStyle(color: scheme.onInverseSurface),
                  ),
              ];
            },
          ),
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: (points.length / 4).clamp(1, double.infinity),
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= points.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    dateFormat.format(points[index].observedAt.toLocal()),
                    style: TextStyle(
                      fontSize: 10,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 48,
              getTitlesWidget: (value, meta) => Text(
                value.toStringAsFixed(0),
                style: TextStyle(fontSize: 10, color: scheme.onSurfaceVariant),
              ),
            ),
          ),
        ),
        gridData: const FlGridData(show: true),
        borderData: FlBorderData(show: true),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: false,
            color: scheme.primary,
            barWidth: 2,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: scheme.primary.withValues(alpha: 0.15),
            ),
          ),
        ],
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
