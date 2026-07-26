import 'package:flutter/material.dart';

import '../../../core/marketplace_labels.dart';
import '../../../core/models/watch.dart';
import '../../../l10n/app_localizations.dart';

class WatchSummaryHeader extends StatelessWidget {
  final Watch watch;

  const WatchSummaryHeader({super.key, required this.watch});

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
