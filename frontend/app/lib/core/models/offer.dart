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
  /// Postgres) — parseada aqui só para permitir ordenação numérica na UI,
  /// sem afetar a exibição (que usa o campo String original, se exibida).
  double get classificationValue => double.tryParse(classification) ?? 0;

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
  final List<String> failedMarketplaces;

  ScanSummary({
    required this.id,
    required this.status,
    required this.startedAt,
    required this.finishedAt,
    required this.offersFound,
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
      failedMarketplaces: (json['failed_marketplaces'] as List<dynamic>? ?? [])
          .cast<String>(),
    );
  }
}
