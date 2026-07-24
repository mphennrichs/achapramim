import '../models/notification.dart';
import 'api_client.dart';

class NotificationService {
  final ApiClient _client;

  NotificationService(this._client);

  Future<List<AppNotification>> list() async {
    final response = await _client.dio.get('/api/notifications');
    return (response.data as List<dynamic>)
        .map((json) => AppNotification.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<int> unreadCount() async {
    final response = await _client.dio.get('/api/notifications/unread-count');
    return (response.data as Map<String, dynamic>)['count'] as int;
  }

  Future<void> markRead(String id) =>
      _client.dio.patch('/api/notifications/$id/read');

  Future<void> markAllRead() =>
      _client.dio.post('/api/notifications/read-all');
}
