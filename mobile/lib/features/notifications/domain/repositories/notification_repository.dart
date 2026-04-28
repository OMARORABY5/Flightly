import 'package:flightly/features/notifications/domain/models/app_notification.dart';
import 'package:flightly/features/notifications/domain/models/notification_preferences.dart';

abstract class NotificationRepository {
  Future<(List<AppNotification> notifications, int unreadCount)> getNotifications({int limit = 50, int offset = 0, bool unreadOnly = false});
  Future<void> markAsRead(String id);
  Future<void> markAllAsRead();
  Future<void> deleteNotification(String id);
  Future<void> registerFcmToken(String token);
  Future<NotificationPreferences> getPreferences();
  Future<void> updatePreferences(NotificationPreferences preferences);
}
