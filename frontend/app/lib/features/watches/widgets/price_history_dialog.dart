import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/offer.dart';
import '../../../l10n/app_localizations.dart';
import '../watch_providers.dart';
import 'price_history_chart.dart';

class PriceHistoryDialog extends ConsumerWidget {
  final String watchId;
  final Offer offer;

  const PriceHistoryDialog({
    super.key,
    required this.watchId,
    required this.offer,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final historyAsync = ref.watch(
      priceHistoryProvider((watchId: watchId, offerId: offer.id)),
    );

    // Largura fixa (400) estoura em telas estreitas — limitada ao espaço
    // disponível descontando o insetPadding padrão do AlertDialog (40 de
    // cada lado).
    final maxWidth = MediaQuery.sizeOf(context).width - 80;

    return AlertDialog(
      title: Text(l10n.watchDetailPriceHistoryTitle),
      content: SizedBox(
        width: maxWidth < 400 ? maxWidth : 400,
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
            return PriceHistoryChart(points: points);
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
