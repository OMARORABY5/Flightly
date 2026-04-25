import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  final SharedPreferences _prefs;

  StorageService(this._prefs);

  static const String _onboardingKey = 'onboardingCompleted';
  static const String _notificationKey = 'notificationPermissionStatus';

  bool get isOnboardingCompleted {
    return _prefs.getBool(_onboardingKey) ?? false;
  }

  Future<void> setOnboardingCompleted(bool value) async {
    await _prefs.setBool(_onboardingKey, value);
  }

  String get notificationPermissionStatus {
    return _prefs.getString(_notificationKey) ?? 'not_requested';
  }

  Future<void> setNotificationPermissionStatus(String status) async {
    await _prefs.setString(_notificationKey, status);
  }
}
