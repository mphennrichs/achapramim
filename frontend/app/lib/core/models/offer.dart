class Offer {
  final String id;
  final String marketplaceSlug;
  final String url;
  final String title;
  final String imageUrl;
  final int priceCents;
  final String classification;
  final bool available;
  // Quando a Offer foi vista pela primeira vez — usado para ordenar por
  // "mais recentes" na tela de detalhes do Alerta.
  final DateTime createdAt;
  final bool monitored;

  Offer({
    required this.id,
    required this.marketplaceSlug,
    required this.url,
    required this.title,
    required this.imageUrl,
    required this.priceCents,
    required this.classification,
    required this.available,
    required this.createdAt,
    required this.monitored,
  });

  /// Classification vem do backend como string decimal (NUMERIC do
  /// Postgres, 0 a 1) — parseada aqui para permitir ordenação numérica e
  /// exibição na UI.
  double get classificationValue => double.tryParse(classification) ?? 0;

  /// Nota na escala 0-100, mais fácil de entender que a fração 0-1 crua
  /// vinda do backend — só uma reescala para exibição, sem mudar a lógica
  /// de cálculo (ver scan/classification.go).
  int get score100 => (classificationValue * 100).round();

  factory Offer.fromJson(Map<String, dynamic> json) {
    return Offer(
      id: json['id'] as String,
      marketplaceSlug: json['marketplace_slug'] as String,
      url: json['url'] as String,
      title: json['title'] as String,
      imageUrl: json['image_url'] as String,
      priceCents: json['price_cents'] as int,
      classification: json['classification'] as String,
      available: json['available'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
      monitored: json['monitored'] as bool? ?? false,
    );
  }
}

class PricePoint {
  final int priceCents;
  final DateTime observedAt;

  PricePoint({required this.priceCents, required this.observedAt});

  factory PricePoint.fromJson(Map<String, dynamic> json) {
    return PricePoint(
      priceCents: json['price_cents'] as int,
      observedAt: DateTime.parse(json['observed_at'] as String),
    );
  }
}

class ScanSummary {
  final String id;
  final String status;
  final DateTime startedAt;
  final DateTime? finishedAt;
  final int offersFound;
  final int newOffersCount;
  final int seenOffersCount;
  final List<String> failedMarketplaces;

  ScanSummary({
    required this.id,
    required this.status,
    required this.startedAt,
    required this.finishedAt,
    required this.offersFound,
    required this.newOffersCount,
    required this.seenOffersCount,
    required this.failedMarketplaces,
  });

  factory ScanSummary.fromJson(Map<String, dynamic> json) {
    return ScanSummary(
      id: json['id'] as String,
      status: json['status'] as String,
      startedAt: DateTime.parse(json['started_at'] as String),
      finishedAt: json['finished_at'] != null
          ? DateTime.parse(json['finished_at'] as String)
          : null,
      offersFound: json['offers_found'] as int,
      newOffersCount: json['new_offers_count'] as int? ?? 0,
      seenOffersCount: json['seen_offers_count'] as int? ?? 0,
      failedMarketplaces: (json['failed_marketplaces'] as List<dynamic>? ?? [])
          .cast<String>(),
    );
  }
}
