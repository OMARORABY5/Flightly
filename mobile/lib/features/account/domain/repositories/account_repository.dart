// account_repository.dart — FLIGHTLY Account Repository Interface

import 'package:flightly/features/account/domain/models/profile.dart';
import 'package:flightly/features/account/domain/models/settings.dart';

abstract class AccountRepository {
  Future<Profile> getProfile();
  Future<Profile> updateProfile(Profile profile);
  Future<String> updateProfilePhoto(String photoUrl);
  
  Future<Settings> getSettings();
  Future<Settings> updateSettings(Settings settings);
  
  Future<bool> changePassword(String currentPassword, String newPassword);
}
