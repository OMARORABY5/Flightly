import 'package:dio/dio.dart';
import 'package:flightly/core/network/dio_client.dart';
import 'package:flightly/core/services/secure_storage_service.dart';
import 'package:flightly/features/auth/domain/models/user_model.dart';
import 'package:flightly/features/auth/domain/repositories/auth_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final dioClient = DioClient.instance();
  final secureStorage = ref.watch(secureStorageServiceProvider);
  return AuthRepositoryImpl(dioClient, secureStorage);
});

class AuthRepositoryImpl implements AuthRepository {
  final DioClient _dioClient;
  final SecureStorageService _secureStorage;

  AuthRepositoryImpl(this._dioClient, this._secureStorage);

  @override
  Future<UserModel> register({
    required String email,
    required String password,
    String? displayName,
  }) async {
    final response = await _dioClient.post(
      '/auth/register',
      data: {
        'email': email,
        'password': password,
        if (displayName != null) 'displayName': displayName,
      },
    );

    final data = response.data['data'];
    return UserModel.fromJson(data);
  }

  @override
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    final response = await _dioClient.post(
      '/auth/login',
      data: {
        'email': email,
        'password': password,
      },
    );

    final token = response.data['data']['token'];
    final userJson = response.data['data']['user'];
    
    await _secureStorage.saveToken(token);
    final user = UserModel.fromJson(userJson);
    await _secureStorage.saveUserId(user.id);

    return user;
  }

  @override
  Future<void> logout() async {
    try {
      await _dioClient.post('/auth/logout');
    } catch (_) {
      // Ignore network errors on logout, we still want to clear local storage
    } finally {
      await _secureStorage.deleteAll();
    }
  }

  @override
  Future<String?> forgotPassword({required String email}) async {
    final response = await _dioClient.post(
      '/auth/forgot-password',
      data: {'email': email},
    );
    if (response.data['success'] == true && response.data['data'] != null) {
      return response.data['data']['otp'] as String?;
    }
    return null;
  }

  @override
  Future<void> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    await _dioClient.post(
      '/auth/reset-password',
      data: {
        'email': email,
        'otp': otp,
        'newPassword': newPassword,
      },
    );
  }

  @override
  Future<UserModel> verifyToken() async {
    final response = await _dioClient.get('/auth/verify-token');
    final data = response.data['data'];
    return UserModel(
      id: data['userId'],
      email: data['email'],
      displayName: null, // Verify endpoint only returns ID and email
    );
  }
}
