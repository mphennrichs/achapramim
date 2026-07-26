import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/marketplace_labels.dart';
import '../../../core/models/offer.dart';
import '../../../core/providers.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/status_colors.dart';
import '../watch_providers.dart';
import 'price_history_dialog.dart';

class OfferCard extends ConsumerStatefulWidget {
  final String watchId;
  final Offer offer;

  const OfferCard({super.key, required this.watchId, required this.offer});

  @override
  ConsumerState<OfferCard> createState() => _OfferCardState();
}

class _OfferCardState extends ConsumerState<OfferCard> {
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
      ref.invalidate(offersProvider(widget.watchId));
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
          PriceHistoryDialog(watchId: widget.watchId, offer: widget.offer),
    );
  }

  @override
  Widget build(BuildContext context) {
    final offer = widget.offer;
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final priceLabel =
        'R\$ ${(offer.priceCents / 100).toStringAsFixed(2).replaceAll('.', ',')}';

    final thumbnail = ClipRRect(
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
    );

    final details = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          offer.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Text(
          marketplaceLabel(l10n, offer.marketplaceSlug),
          style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              priceLabel,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: scheme.primary,
              ),
            ),
            Chip(
              label: Text(l10n.watchDetailScoreLabel(offer.score100)),
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            if (!offer.available)
              Chip(
                label: Text(l10n.watchDetailOfferUnavailable),
                backgroundColor: scheme.errorContainer,
                labelStyle: TextStyle(color: scheme.onErrorContainer),
              ),
          ],
        ),
      ],
    );

    final actions = [
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
    ];

    // Em telas estreitas os 3 IconButtons ao lado do texto espremem demais
    // título/preço/chips — abaixo do breakpoint eles descem para uma linha
    // própria no rodapé do card, alinhados à direita, em vez de dividir a
    // largura com o conteúdo.
    final isNarrow = MediaQuery.of(context).size.width < 600;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: isNarrow
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      thumbnail,
                      const SizedBox(width: 16),
                      Expanded(child: details),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: actions,
                  ),
                ],
              )
            : Row(
                children: [
                  thumbnail,
                  const SizedBox(width: 16),
                  Expanded(child: details),
                  ...actions,
                ],
              ),
      ),
    );
  }
}
