class ScanSettings {
  final int minIntervalMinutes;
  final int maxIntervalMinutes;

  ScanSettings({required this.minIntervalMinutes, required this.maxIntervalMinutes});

  factory ScanSettings.fromJson(Map<String, dynamic> json) {
    return ScanSettings(
      minIntervalMinutes: json['min_interval_minutes'] as int,
      maxIntervalMinutes: json['max_interval_minutes'] as int,
    );
  }
}
