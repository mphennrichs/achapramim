class AppNotification {
  final String id;
  final String trigger;
  final DateTime createdAt;
  final DateTime? readAt;
  final String offerId;
  final String offerTitle;
  final int offerPriceCents;
  final String offerUrl;
  final String watchId;
  final String watchName;

  AppNotification({
    required this.id,
    required this.trigger,
    required this.createdAt,
    required this.readAt,
    required this.offerId,
    required this.offerTitle,
    required this.offerPriceCents,
    required this.offerUrl,
    required this.watchId,
    required this.watchName,
  });

  bool get isRead => readAt != null;

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String,
      trigger: json['trigger'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      readAt: json['read_at'] != null
          ? DateTime.parse(json['read_at'] as String)
          : null,
      offerId: json['offer_id'] as String,
      offerTitle: json['offer_title'] as String,
      offerPriceCents: json['offer_price_cents'] as int,
      offerUrl: json['offer_url'] as String,
      watchId: json['watch_id'] as String,
      watchName: json['watch_name'] as String,
    );
  }
}
