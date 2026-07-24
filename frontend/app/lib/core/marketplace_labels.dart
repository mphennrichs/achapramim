import '../l10n/app_localizations.dart';

/// Marketplaces com Fetcher viável hoje (ver ADR 0006) — Mercado Livre segue
/// sem Fetcher (ver ADR 0003).
const availableMarketplaces = ['olx', 'facebook_marketplace'];

String marketplaceLabel(AppLocalizations l10n, String slug) {
  switch (slug) {
    case 'olx':
      return l10n.marketplaceOlx;
    case 'facebook_marketplace':
      return l10n.marketplaceFacebook;
    default:
      return slug;
  }
}
