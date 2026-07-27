class MarketplaceScanInterval {
  final String marketplaceSlug;
  final int minIntervalMinutes;
  final int maxIntervalMinutes;

  MarketplaceScanInterval({
    required this.marketplaceSlug,
    required this.minIntervalMinutes,
    required this.maxIntervalMinutes,
  });

  factory MarketplaceScanInterval.fromJson(Map<String, dynamic> json) {
    return MarketplaceScanInterval(
      marketplaceSlug: json['marketplace_slug'] as String,
      minIntervalMinutes: json['min_interval_minutes'] as int,
      maxIntervalMinutes: json['max_interval_minutes'] as int,
    );
  }

  Map<String, dynamic> toRequestJson() {
    return {
      'marketplace_slug': marketplaceSlug,
      'min_interval_minutes': minIntervalMinutes,
      'max_interval_minutes': maxIntervalMinutes,
    };
  }
}

class ScanSettings {
  // Região padrão usada por um Alerta quando não define cidade/estado
  // próprios (ver NewWatchScreen).
  final String defaultCity;
  final String defaultState;
  // Seed de palavras bloqueadas copiado para todo Alerta novo na criação —
  // não retroage sobre Alertas já criados.
  final List<String> defaultBlockedWords;
  // Intervalo de Scan por marketplace (ex: OLX a cada 1-2h, Facebook 1x/dia)
  // — todo marketplace em availableMarketplaces tem uma entrada própria
  // aqui, sem fallback global (ver ADR sobre intervalo de Scan por engine).
  final List<MarketplaceScanInterval> marketplaceIntervals;

  ScanSettings({
    required this.defaultCity,
    required this.defaultState,
    required this.defaultBlockedWords,
    required this.marketplaceIntervals,
  });

  factory ScanSettings.fromJson(Map<String, dynamic> json) {
    return ScanSettings(
      defaultCity: json['default_city'] as String,
      defaultState: json['default_state'] as String,
      defaultBlockedWords:
          (json['default_blocked_words'] as List<dynamic>? ?? [])
              .cast<String>(),
      marketplaceIntervals:
          (json['marketplace_intervals'] as List<dynamic>? ?? [])
              .map(
                (e) =>
                    MarketplaceScanInterval.fromJson(e as Map<String, dynamic>),
              )
              .toList(),
    );
  }

  Map<String, dynamic> toRequestJson() {
    return {
      'default_city': defaultCity,
      'default_state': defaultState,
      'default_blocked_words': defaultBlockedWords,
      'marketplace_intervals': marketplaceIntervals
          .map((e) => e.toRequestJson())
          .toList(),
    };
  }
}
