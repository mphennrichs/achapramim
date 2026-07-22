import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/models/offer.dart';
import '../../core/models/watch.dart';
import '../../core/providers.dart';
import 'app_shell.dart';

final _watchProvider =
    FutureProvider.autoDispose.family<Watch, String>((ref, watchId) {
  return ref.watch(watchServiceProvider).get(watchId);
});

final _offersProvider =
    FutureProvider.autoDispose.family<List<Offer>, String>((ref, watchId) {
  return ref.watch(watchServiceProvider).offers(watchId);
});

final _scansProvider =
    FutureProvider.autoDispose.family<List<ScanSummary>, String>((ref, watchId) {
  return ref.watch(watchServiceProvider).scans(watchId);
});

class WatchDetailScreen extends ConsumerWidget {
  final String watchId;

  const WatchDetailScreen({super.key, required this.watchId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final watchAsync = ref.watch(_watchProvider(watchId));

    return AppShell(
      title: watchAsync.valueOrNull?.name ?? 'Watch',
      selectedIndex: 0,
      body: watchAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Falha ao carregar Watch: $error')),
        data: (watch) => DefaultTabController(
          length: 2,
          child: Column(
            children: [
              _WatchSummaryHeader(watch: watch),
              const TabBar(
                tabs: [
                  Tab(text: 'Offers'),
                  Tab(text: 'Histórico de Scans'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _OffersTab(watchId: watchId),
                    _ScansTab(watchId: watchId),
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
          Chip(label: Text('Alvo: $priceLabel')),
          Chip(label: Text('Tolerância: ${watch.tolerancePercent}%')),
          Chip(label: Text('Gatilho de queda: ${watch.priceDropThresholdPercent}%')),
          Chip(label: Text('Máx. ofertas: ${watch.maxOffers}')),
          Chip(
            label: Text(watch.active ? 'Ativo' : 'Inativo'),
            backgroundColor: watch.active
                ? scheme.primaryContainer
                : scheme.surfaceContainerHigh,
          ),
          for (final marketplace in watch.marketplaces) Chip(label: Text(marketplace)),
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

    return offersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Falha ao carregar Offers: $error')),
      data: (offers) {
        if (offers.isEmpty) {
          return Center(
            child: Text(
              'Nenhuma Offer encontrada ainda.',
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

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
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
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    offer.marketplaceSlug,
                    style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
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
                          label: const Text('Indisponível'),
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
              onPressed: () {},
              tooltip: 'Abrir anúncio',
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
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return scansAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Falha ao carregar Scans: $error')),
      data: (scans) {
        if (scans.isEmpty) {
          return Center(
            child: Text(
              'Nenhum Scan executado ainda.',
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
              leading: _StatusIcon(status: scan.status),
              title: Text(dateFormat.format(scan.startedAt.toLocal())),
              subtitle: scan.failedMarketplaces.isNotEmpty
                  ? Text('Falhas: ${scan.failedMarketplaces.join(', ')}')
                  : null,
              trailing: Text('${scan.offersFound} ofertas'),
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
    switch (status) {
      case 'success':
        return const Icon(Icons.check_circle, color: Colors.green);
      case 'partial':
        return const Icon(Icons.warning_amber, color: Colors.orange);
      case 'failed':
        return const Icon(Icons.error, color: Colors.red);
      default:
        return const Icon(Icons.hourglass_empty);
    }
  }
}
