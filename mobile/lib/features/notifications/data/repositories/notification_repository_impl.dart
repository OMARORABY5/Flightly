import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flightly/core/network/dio_client.dart';
import 'package:flightly/features/notifications/domain/models/app_notification.dart';
import 'package:flightly/features/notifications/domain/models/notification_preferences.dart';
import 'package:flightly/features/notifications/domain/repositories/notification_repository.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  final DioClient _dioClient;

  NotificationRepositoryImpl(this._dioClient);

  @override
  Future<(List<AppNotification> notifications, int unreadCount)> getNotifications({
    int limit = 50,
    int offset = 0,
    bool unreadOnly = false,
  }) async {
    final response = await _dioClient.get(
      '/notifications/',
      queryParams: {
        'limit': limit,
        'offset': offset,
        'unread_only': unreadOnly,
      },
    );

    final data = response.data['data'] as Map<String, dynamic>;
    final notificationsList = data['notifications'] as List;
    final notifications = notificationsList.map((n) => AppNotification.fromJson(n)).toList();
    final unreadCount = data['unread_count'] as int;

    return (notifications, unreadCount);
  }

  @override
  Future<void> markAsRead(String id) async {
    await _dioClient.put('/notifications/$id/read');
  }

  @override
  Future<void> markAllAsRead() async {
    await _dioClient.put('/notifications/read-all');
  }

  @override
  Future<void> deleteNotification(String id) async {
    await _dioClient.delete('/notifications/$id');
  }

  @override
  Future<void> registerFcmToken(String token) async {
    await _dioClient.post(
      '/notifications/fcm-token',
      data: {'token': token},
    );
  }

  @override
  Future<NotificationPreferences> getPreferences() async {
    final response = await _dioClient.get('/notifications/preferences');
    return NotificationPreferences.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  @override
  Future<void> updatePreferences(NotificationPreferences preferences) async {
    await _dioClient.put(
      '/notifications/preferences',
      data: preferences.toJson(),
    );
  }
}

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return NotificationRepositoryImpl(dioClient);
});
