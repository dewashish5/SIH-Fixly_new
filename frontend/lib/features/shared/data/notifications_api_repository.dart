import '../../../core/network/api_client.dart';
import '../../../core/network/api_enpoints.dart';
import '../../../shared/models/models.dart';

class NotificationsApiRepository {
  NotificationsApiRepository({ApiClient? client})
    : _client = client ?? ApiServices.client;

  final ApiClient _client;

  Future<List<NotificationItem>> list({int page = 1, int limit = 20}) async {
    final response = await _client.get(
      ApiEndpoints.notifications,
      query: {'page': page, 'limit': limit},
      forceNetwork: true,
    );
    final rawItems = response['data'];
    if (rawItems is! List) return const [];
    return rawItems
        .whereType<Map>()
        .map(
          (item) => NotificationItem.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList();
  }

  Future<void> markRead(String id) async {
    await _client.patch(ApiEndpoints.markNotificationRead(id));
  }

  Future<void> markAllRead() async {
    await _client.patch(ApiEndpoints.markAllNotificationsRead);
  }

  Future<void> delete(String id) async {
    await _client.delete(ApiEndpoints.deleteNotification(id));
  }
}
