class ScanSettings {
  final int minIntervalMinutes;
  final int maxIntervalMinutes;
  // Região padrão usada por um Alerta quando não define cidade/estado
  // próprios (ver NewWatchScreen).
  final String defaultCity;
  final String defaultState;
  // Seed de palavras bloqueadas copiado para todo Alerta novo na criação —
  // não retroage sobre Alertas já criados.
  final List<String> defaultBlockedWords;

  ScanSettings({
    required this.minIntervalMinutes,
    required this.maxIntervalMinutes,
    required this.defaultCity,
    required this.defaultState,
    required this.defaultBlockedWords,
  });

  factory ScanSettings.fromJson(Map<String, dynamic> json) {
    return ScanSettings(
      minIntervalMinutes: json['min_interval_minutes'] as int,
      maxIntervalMinutes: json['max_interval_minutes'] as int,
      defaultCity: json['default_city'] as String,
      defaultState: json['default_state'] as String,
      defaultBlockedWords:
          (json['default_blocked_words'] as List<dynamic>? ?? [])
              .cast<String>(),
    );
  }
}
