class Watch {
  final String id;
  final String userId;
  final String name;
  final int targetPriceCents;
  final String tolerancePercent;
  final int maxOffers;
  final String priceDropThresholdPercent;
  final bool active;
  final List<String> keywords;
  final List<String> blockedWords;
  final List<String> marketplaces;

  Watch({
    required this.id,
    required this.userId,
    required this.name,
    required this.targetPriceCents,
    required this.tolerancePercent,
    required this.maxOffers,
    required this.priceDropThresholdPercent,
    required this.active,
    required this.keywords,
    required this.blockedWords,
    required this.marketplaces,
  });

  factory Watch.fromJson(Map<String, dynamic> json) {
    return Watch(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      targetPriceCents: json['target_price_cents'] as int,
      tolerancePercent: json['tolerance_percent'] as String,
      maxOffers: json['max_offers'] as int,
      priceDropThresholdPercent: json['price_drop_threshold_percent'] as String,
      active: json['active'] as bool,
      keywords: (json['keywords'] as List<dynamic>? ?? []).cast<String>(),
      blockedWords: (json['blocked_words'] as List<dynamic>? ?? []).cast<String>(),
      marketplaces: (json['marketplaces'] as List<dynamic>? ?? []).cast<String>(),
    );
  }

  Map<String, dynamic> toRequestJson() {
    return {
      'name': name,
      'target_price_cents': targetPriceCents,
      'tolerance_percent': tolerancePercent,
      'max_offers': maxOffers,
      'price_drop_threshold_percent': priceDropThresholdPercent,
      'keywords': keywords,
      'blocked_words': blockedWords,
      'marketplaces': marketplaces,
    };
  }
}
