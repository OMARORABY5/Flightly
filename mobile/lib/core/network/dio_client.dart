// dio_client.dart — FLIGHTLY HTTP Client
// Configured Dio instance with auth interceptors, error handling, and timeouts
// WHY: Centralizing HTTP setup ensures every request gets auth headers
//      and errors are consistently translated into Failure objects

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_constants.dart';
import '../errors/failures.dart';

final dioClientProvider = Provider<DioClient>((ref) => DioClient.instance());

class DioClient {
  static DioClient? _instance;
  late final Dio _dio;
  final FlutterSecureStorage _storage;

  DioClient._({required FlutterSecureStorage storage})
      : _storage = storage {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.baseUrl,
        connectTimeout: Duration(seconds: AppConstants.connectTimeoutSeconds),
        receiveTimeout: Duration(seconds: AppConstants.receiveTimeoutSeconds),
        sendTimeout: Duration(seconds: AppConstants.sendTimeoutSeconds),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Add interceptors in order: auth → logging → error
    _dio.interceptors.add(_AuthInterceptor(_storage));
    _dio.interceptors.add(_LoggingInterceptor());
  }

  /// Singleton factory — call DioClient.instance() to get the shared instance
  static DioClient instance({FlutterSecureStorage? storage}) {
    _instance ??= DioClient._(
      storage: storage ?? const FlutterSecureStorage(),
    );
    return _instance!;
  }

  /// GET request
  Future<Response> get(String path, {Map<String, dynamic>? queryParams}) async {
    return _execute(() => _dio.get(path, queryParameters: queryParams));
  }

  /// POST request
  Future<Response> post(String path, {dynamic data}) async {
    return _execute(() => _dio.post(path, data: data));
  }

  /// PUT request
  Future<Response> put(String path, {dynamic data}) async {
    return _execute(() => _dio.put(path, data: data));
  }

  /// DELETE request
  Future<Response> delete(String path, {Map<String, dynamic>? queryParams}) async {
    return _execute(() => _dio.delete(path, queryParameters: queryParams));
  }

  /// Execute a request and translate DioException → typed Failure
  Future<Response> _execute(Future<Response> Function() request) async {
    try {
      return await request();
    } on DioException catch (e) {
      throw _mapDioError(e);
    } catch (e) {
      throw UnknownFailure(message: e.toString());
    }
  }

  /// Map DioException types to our typed Failure hierarchy
  Failure _mapDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const TimeoutFailure();

      case DioExceptionType.connectionError:
        return const NetworkFailure();

      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        final message = _extractMessage(e.response);

        switch (statusCode) {
          case 400: return ServerFailure(message: message, statusCode: 400);
          case 401: return UnauthorizedFailure(message: message);
          case 403: return PermissionFailure(message: message);
          case 404: return NotFoundFailure(message: message);
          case 409: return ConflictFailure(message: message);
          case 429: return RateLimitFailure(message: message);
          default: return ServerFailure(message: message, statusCode: statusCode);
        }

      default:
        return const UnknownFailure();
    }
  }

  /// Extract error message from response body, with fallback
  String _extractMessage(Response? response) {
    try {
      final data = response?.data;
      if (data is Map<String, dynamic>) {
        return data['message'] as String? ?? 'An unexpected error occurred.';
      }
    } catch (_) {}
    return 'An unexpected error occurred.';
  }
}

// ─── Auth Interceptor ────────────────────────────────────────────────────────
// Attaches JWT token to every request that requires authentication
class _AuthInterceptor extends Interceptor {
  final FlutterSecureStorage _storage;

  _AuthInterceptor(this._storage);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Skip auth for public endpoints (auth routes + flight search = no token needed)
    final publicPaths = [
      '/auth/login',
      '/auth/register',
      '/auth/forgot-password',
      '/flights/',   // airport search is public
    ];
    final isPublic = publicPaths.any((path) => options.path.contains(path));

    // Read token from secure storage (works on Web via flutter_secure_storage_web)
    if (!isPublic) {
      final token = await _storage.read(key: AppConstants.jwtStorageKey);
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }

    handler.next(options);
  }
}

// ─── Logging Interceptor ─────────────────────────────────────────────────────
// Log requests/responses in development (no-op in production)
class _LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // Only log in debug mode — avoid sensitive data in production logs
    assert(() {
      print('[HTTP] ${options.method} ${options.path}');
      return true;
    }());
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    assert(() {
      print('[HTTP] ${response.statusCode} ${response.requestOptions.path}');
      return true;
    }());
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    assert(() {
      print('[HTTP] Error: ${err.type} — ${err.message}');
      return true;
    }());
    handler.next(err);
  }
}
