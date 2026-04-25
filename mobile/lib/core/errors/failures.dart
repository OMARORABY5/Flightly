// failures.dart — FLIGHTLY Custom Error Types
// Typed failures for clean error handling across the app
// WHY: Typed errors allow UI to display appropriate messages without string matching

/// Base failure class — all errors extend this
abstract class Failure {
  final String message;
  final int? statusCode;

  const Failure({required this.message, this.statusCode});

  @override
  String toString() => 'Failure(message: $message, statusCode: $statusCode)';
}

// ─── Network Failures ────────────────────────────────────────────────────────

/// No internet connection
class NetworkFailure extends Failure {
  const NetworkFailure({super.message = 'No internet connection. Please check your network.'});
}

/// Request timed out
class TimeoutFailure extends Failure {
  const TimeoutFailure({super.message = 'Request timed out. Please try again.'});
}

/// Server returned an error response (4xx / 5xx)
class ServerFailure extends Failure {
  const ServerFailure({required super.message, super.statusCode});
}

// ─── Auth Failures ────────────────────────────────────────────────────────────

/// Invalid credentials (wrong email/password)
class AuthFailure extends Failure {
  const AuthFailure({super.message = 'Invalid email or password.'});
}

/// Account not found
class NotFoundFailure extends Failure {
  const NotFoundFailure({super.message = 'Account not found.'});
}

/// Email already registered
class ConflictFailure extends Failure {
  const ConflictFailure({super.message = 'This email is already registered.'});
}

/// Rate limit exceeded
class RateLimitFailure extends Failure {
  const RateLimitFailure({super.message = 'Too many attempts. Please wait 15 minutes.'});
}

/// Token expired / invalid
class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure({super.message = 'Your session has expired. Please log in again.'});
}

// ─── Data Failures ────────────────────────────────────────────────────────────

/// Data could not be parsed
class ParseFailure extends Failure {
  const ParseFailure({super.message = 'Failed to process server response.'});
}

/// Cache / local storage failure
class CacheFailure extends Failure {
  const CacheFailure({super.message = 'Failed to load saved data.'});
}

/// Feature not available (e.g., guest mode restriction)
class PermissionFailure extends Failure {
  const PermissionFailure({super.message = 'Please log in to use this feature.'});
}

/// Unknown / unexpected error
class UnknownFailure extends Failure {
  const UnknownFailure({super.message = 'Something went wrong. Please try again.'});
}
