import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flightly/features/notifications/domain/models/app_notification.dart';
import 'package:flightly/features/notifications/data/repositories/notification_repository_impl.dart';

part 'notification_provider.g.dart';

class NotificationState {
  final List<AppNotification> notifications;
  final int unreadCount;
  final bool isLoading;
  final String? error;

  NotificationState({
    this.notifications = const [],
    this.unreadCount = 0,
    this.isLoading = false,
    this.error,
  });

  NotificationState copyWith({
    List<AppNotification>? notifications,
    int? unreadCount,
    bool? isLoading,
    String? error,
  }) {
    return NotificationState(
      notifications: notifications ?? this.notifications,
      unreadCount: unreadCount ?? this.unreadCount,
      isLoading: isLoading ?? this.isLoading,
      error: error, // Can be null to clear error
    );
  }
}

@riverpod
class NotificationNotifier extends _$NotificationNotifier {
  @override
  NotificationState build() {
    _fetchNotifications();
    return NotificationState(isLoading: true);
  }

  Future<void> _fetchNotifications() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final repo = ref.read(notificationRepositoryProvider);
      final result = await repo.getNotifications();
      state = state.copyWith(
        notifications: result.$1,
        unreadCount: result.$2,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> refresh() async {
    await _fetchNotifications();
  }

  Future<void> markAsRead(String id) async {
    try {
      final repo = ref.read(notificationRepositoryProvider);
      await repo.markAsRead(id);
      
      // Update local state optimistically
      final updatedNotifications = state.notifications.map((n) {
        if (n.id == id && !n.isRead) {
          return n.copyWith(isRead: true);
        }
        return n;
      }).toList();
      
      final newUnreadCount = updatedNotifications.where((n) => !n.isRead).length;
      state = state.copyWith(notifications: updatedNotifications, unreadCount: newUnreadCount);
    } catch (e) {
      // Revert on error or just show error toast (handled by UI usually)
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> markAllAsRead() async {
    try {
      final repo = ref.read(notificationRepositoryProvider);
      await repo.markAllAsRead();
      
      // Update local state optimistically
      final updatedNotifications = state.notifications.map((n) => n.copyWith(isRead: true)).toList();
      state = state.copyWith(notifications: updatedNotifications, unreadCount: 0);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> deleteNotification(String id) async {
    try {
      final repo = ref.read(notificationRepositoryProvider);
      await repo.deleteNotification(id);
      
      // Update local state optimistically
      final updatedNotifications = state.notifications.where((n) => n.id != id).toList();
      final newUnreadCount = updatedNotifications.where((n) => !n.isRead).length;
      
      state = state.copyWith(notifications: updatedNotifications, unreadCount: newUnreadCount);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}
