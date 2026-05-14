// account_repository_impl.dart — FLIGHTLY Account Repository Implementation

import 'package:dio/dio.dart';
import 'package:flightly/core/network/dio_client.dart';
import 'package:flightly/features/account/domain/models/profile.dart';
import 'package:flightly/features/account/domain/models/settings.dart';
import 'package:flightly/features/account/domain/repositories/account_repository.dart';

class AccountRepositoryImpl implements AccountRepository {
  final DioClient _dioClient;

  AccountRepositoryImpl({required DioClient dioClient}) : _dioClient = dioClient;

  @override
  Future<Profile> getProfile() async {
    final response = await _dioClient.get('/users/profile');
    if (response.data['success'] == true) {
      return Profile.fromJson(response.data['data']);
    }
    throw Exception(response.data['message'] ?? 'Failed to get profile');
  }

  @override
  Future<Profile> updateProfile(Profile profile) async {
    final response = await _dioClient.put(
      '/users/profile',
      data: profile.toJson(),
    );
    if (response.data['success'] == true) {
      return Profile.fromJson(response.data['data']);
    }
    throw Exception(response.data['message'] ?? 'Failed to update profile');
  }

  @override
  Future<String> updateProfilePhoto(String photoUrl) async {
    final response = await _dioClient.post(
      '/users/profile/photo',
      data: {'photo_url': photoUrl},
    );
    if (response.data['success'] == true) {
      return response.data['data']['photo_url'] ?? photoUrl;
    }
    throw Exception(response.data['message'] ?? 'Failed to update photo');
  }

  @override
  Future<String> uploadProfilePhotoFile(List<int> bytes, String filename) async {
    final formData = FormData.fromMap({
      'photo': MultipartFile.fromBytes(bytes, filename: filename),
    });

    final response = await _dioClient.post(
      '/users/profile/photo/upload',
      data: formData,
    );
    if (response.data['success'] == true) {
      return response.data['data']['photo_url'];
    }
    throw Exception(response.data['message'] ?? 'Failed to upload photo');
  }

  @override
  Future<void> deleteProfilePhoto() async {
    final response = await _dioClient.post(
      '/users/profile/photo',
      data: {'photo_url': null},
    );
    if (response.data['success'] != true) {
      throw Exception(response.data['message'] ?? 'Failed to delete photo');
    }
  }

  @override
  Future<Settings> getSettings() async {
    final response = await _dioClient.get('/users/settings');
    if (response.data['success'] == true) {
      return Settings.fromJson(response.data['data']);
    }
    throw Exception(response.data['message'] ?? 'Failed to get settings');
  }

  @override
  Future<Settings> updateSettings(Settings settings) async {
    final response = await _dioClient.put(
      '/users/settings',
      data: settings.toJson(),
    );
    if (response.data['success'] == true) {
      return Settings.fromJson(response.data['data']);
    }
    throw Exception(response.data['message'] ?? 'Failed to update settings');
  }

  @override
  Future<bool> changePassword(String currentPassword, String newPassword) async {
    // Auth Service route
    final response = await _dioClient.post(
      '/auth/change-password',
      data: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      },
    );
    if (response.data['success'] == true) {
      return true;
    }
    throw Exception(response.data['message'] ?? 'Failed to change password');
  }
}
