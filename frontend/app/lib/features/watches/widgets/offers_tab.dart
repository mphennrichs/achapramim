import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/offer.dart';
import '../../../l10n/app_localizations.dart';
import '../watch_providers.dart';
import 'offer_card.dart';

enum _OfferSortCriterion { recommended, score, priceAsc, priceDesc, newest }

class OffersTab extends ConsumerStatefulWidget {
  final String watchId;

  const OffersTab({super.key, required this.watchId});

  @override
  ConsumerState<OffersTab> createState() => _OffersTabState();
}

class _OffersTabState extends ConsumerState<OffersTab> {
  _OfferSortCriterion _sort = _OfferSortCriterion.recommended;

  List<Offer> _sorted(List<Offer> offers) {
    final sorted = List.of(offers);
    switch (_sort) {
      case _OfferSortCriterion.recommended:
        sorted.sort(
          (a, b) => b.classificationValue.compareTo(a.classificationValue),
        );
      case _OfferSortCriterion.score:
        sorted.sort((a, b) => b.score100.compareTo(a.score100));
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
      _OfferSortCriterion.score => l10n.watchDetailSortScore,
      _OfferSortCriterion.priceAsc => l10n.watchDetailSortPriceAsc,
      _OfferSortCriterion.priceDesc => l10n.watchDetailSortPriceDesc,
      _OfferSortCriterion.newest => l10n.watchDetailSortNewest,
    };
  }

  @override
  Widget build(BuildContext context) {
    final offersAsync = ref.watch(offersProvider(widget.watchId));
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
                itemBuilder: (context, index) => OfferCard(
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
