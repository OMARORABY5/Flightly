import 'package:flightly/features/auth/domain/models/user_model.dart';

abstract class AuthRepository {
  Future<UserModel> register({
    required String email,
    required String password,
    String? displayName,
  });

  Future<UserModel> login({
    required String email,
    required String password,
  });

  Future<void> logout();

  /// Returns the OTP string in development mode, or null in production.
  Future<String?> forgotPassword({required String email});

  Future<void> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  });

  Future<UserModel> verifyToken();
}
