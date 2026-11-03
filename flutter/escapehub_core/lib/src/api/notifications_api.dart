part of 'api_client.dart';

class NotificationsApi {
  NotificationsApi._(this._client);

  final ApiClient _client;

  Future<Paged<NotificationDto>> list({bool unreadOnly = false, int page = 1, int pageSize = 20}) => _client._getPaged(
    '/api/notifications',
    NotificationDto.fromJson,
    {'unreadOnly': unreadOnly, 'page': page, 'pageSize': pageSize},
  );

  Future<int> unreadCount() => _client._get('/api/notifications/unread-count', _count);

  Future<void> markRead(int id) => _client._command('/api/notifications/$id/read');

  Future<int> markAllRead() => _client._post('/api/notifications/read-all', _count);
}
