import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flightly/core/services/secure_storage_service.dart';
import 'package:flightly/features/auth/domain/models/user_model.dart';
import 'package:flightly/features/auth/data/repositories/auth_repository_impl.dart';

abstract class AuthState {
  const AuthState();
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthAuthenticated extends AuthState {
  final UserModel user;
  const AuthAuthenticated(this.user);
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);
}

class AuthNotifier extends StateNotifier<AuthState> {
  final Ref _ref;

  AuthNotifier(this._ref) : super(const AuthInitial()) {
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    state = const AuthLoading();
    try {
      final storageService = _ref.read(secureStorageServiceProvider);
      final token = await storageService.getToken();

      if (token == null) {
        state = const AuthUnauthenticated();
        return;
      }

      final authRepository = _ref.read(authRepositoryProvider);
      final user = await authRepository.verifyToken();
      state = AuthAuthenticated(user);
    } catch (e) {
      // If verification fails (e.g. token expired, blacklisted, network issue),
      // we log them out.
      await _ref.read(secureStorageServiceProvider).deleteAll();
      state = const AuthUnauthenticated();
    }
  }

  Future<void> login(String email, String password) async {
    state = const AuthLoading();
    try {
      final authRepository = _ref.read(authRepositoryProvider);
      final user = await authRepository.login(email: email, password: password);
      state = AuthAuthenticated(user);
    } catch (e) {
      state = AuthError(e.toString());
      // Revert to unauthenticated after error to clear the error state on next interaction
      await Future.delayed(const Duration(milliseconds: 100));
      state = const AuthUnauthenticated();
      rethrow;
    }
  }

  Future<void> register({
    required String email,
    required String password,
    String? displayName,
  }) async {
    state = const AuthLoading();
    try {
      final authRepository = _ref.read(authRepositoryProvider);
      await authRepository.register(
        email: email,
        password: password,
        displayName: displayName,
      );
      state = const AuthUnauthenticated(); // Will log in manually after register
    } catch (e) {
      state = AuthError(e.toString());
      await Future.delayed(const Duration(milliseconds: 100));
      state = const AuthUnauthenticated();
      rethrow;
    }
  }

  Future<void> logout() async {
    state = const AuthLoading();
    try {
      final authRepository = _ref.read(authRepositoryProvider);
      await authRepository.logout();
    } catch (_) {
      // Ignore errors on logout
    } finally {
      state = const AuthUnauthenticated();
    }
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref);
});
