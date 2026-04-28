import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flightly/features/notifications/domain/models/notification_preferences.dart';
import 'package:flightly/features/notifications/data/repositories/notification_repository_impl.dart';

part 'notification_preferences_provider.g.dart';

@riverpod
class NotificationPreferencesNotifier extends _$NotificationPreferencesNotifier {
  @override
  FutureOr<NotificationPreferences> build() async {
    final repo = ref.read(notificationRepositoryProvider);
    return await repo.getPreferences();
  }

  Future<void> updatePreferences(NotificationPreferences newPrefs) async {
    // Optimistic update
    state = AsyncData(newPrefs);
    
    try {
      final repo = ref.read(notificationRepositoryProvider);
      await repo.updatePreferences(newPrefs);
    } catch (e) {
      // Refresh on failure
      ref.invalidateSelf();
    }
  }
}
