/// Base class for all API-related exceptions.
///
/// This provides a unified exception hierarchy for API operations,
/// making error handling consistent across all API helpers.
abstract class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  /// Human-readable error message.
  final String message;

  /// HTTP status code if applicable.
  final int? statusCode;

  @override
  String toString() => '$runtimeType: $message';
}

/// Exception thrown when network connectivity issues occur.
class NetworkException extends ApiException {
  const NetworkException([super.message = 'Network connection failed']);
}

/// Exception thrown when authentication fails or session expires.
class AuthenticationException extends ApiException {
  const AuthenticationException([
    super.message = 'Authentication failed',
  ]);
}

/// Exception thrown when the server returns an error response.
class ServerException extends ApiException {
  const ServerException(
    super.message, {
    super.statusCode,
    this.response,
  });

  /// Raw response data from the server.
  final dynamic response;
}

/// Exception thrown when retry limit is exceeded.
///
/// This is used when API operations fail repeatedly despite retry attempts.
class RetryLimitExceededException extends ApiException {
  const RetryLimitExceededException([
    super.message = 'Retry limit exceeded',
  ]);
}

/// Exception thrown when the user cancels an operation.
class OperationCancelledException extends ApiException {
  const OperationCancelledException([
    super.message = 'Operation cancelled by user',
  ]);
}

/// Exception thrown when user is not supported for the operation.
class UserNotSupportedException extends ApiException {
  const UserNotSupportedException([
    super.message = 'User not supported for this operation',
  ]) : super(statusCode: 403);
}
