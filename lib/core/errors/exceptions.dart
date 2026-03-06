/// Thrown by data layer for recoverable / well-typed errors.
sealed class AppException implements Exception {
  const AppException(this.message);
  final String message;

  /// Returns just the human-readable message, without the Dart class prefix.
  /// Use this in UI error strings instead of [toString].
  String get userMessage => message;

  /// Returns only the human-readable message - no class-name prefix.
  /// Use [runtimeType] explicitly if you need the class name in logs.
  @override
  String toString() => message;
}

final class NetworkException extends AppException {
  const NetworkException([super.message = 'Network error.']);
}

final class RequestTimeoutException extends AppException {
  const RequestTimeoutException([super.message = 'Request timed out.']);
}

final class UnauthorizedException extends AppException {
  const UnauthorizedException([
    super.message = 'Unauthorised - invalid or expired app password.',
  ]);
}

final class ForbiddenException extends AppException {
  const ForbiddenException([
    super.message = 'Forbidden - insufficient permissions.',
  ]);
}

final class NotFoundException extends AppException {
  const NotFoundException([super.message = 'Resource not found.']);
}

final class ServerException extends AppException {
  const ServerException([super.message = 'Server error.']);
  const ServerException.withCode(int code)
    : super('Server returned HTTP $code.');
}

final class CacheException extends AppException {
  const CacheException([super.message = 'Local storage error.']);
}

final class ParseException extends AppException {
  const ParseException([super.message = 'Failed to parse server response.']);
}

final class AuthFlowException extends AppException {
  const AuthFlowException([super.message = 'Authentication flow failed.']);
}

final class PollTimeoutException extends AppException {
  const PollTimeoutException() : super('Login polling timed out.');
}

final class ConflictException extends AppException {
  const ConflictException([super.message = 'Conflict detected.']);
}
