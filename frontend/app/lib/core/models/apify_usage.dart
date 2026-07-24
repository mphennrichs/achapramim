class ApifyRun {
  final String id;
  final String actorId;
  final String status;
  final DateTime startedAt;
  final DateTime finishedAt;
  final double usageUsd;

  ApifyRun({
    required this.id,
    required this.actorId,
    required this.status,
    required this.startedAt,
    required this.finishedAt,
    required this.usageUsd,
  });

  factory ApifyRun.fromJson(Map<String, dynamic> json) {
    return ApifyRun(
      id: json['id'] as String,
      actorId: json['actor_id'] as String,
      status: json['status'] as String,
      startedAt: DateTime.parse(json['started_at'] as String),
      finishedAt: DateTime.parse(json['finished_at'] as String),
      usageUsd: (json['usage_usd'] as num).toDouble(),
    );
  }
}

class ApifyUsage {
  final double totalUsd;
  final List<ApifyRun> runs;

  ApifyUsage({required this.totalUsd, required this.runs});

  factory ApifyUsage.fromJson(Map<String, dynamic> json) {
    return ApifyUsage(
      totalUsd: (json['total_usd'] as num).toDouble(),
      runs: (json['runs'] as List<dynamic>)
          .map((item) => ApifyRun.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}
