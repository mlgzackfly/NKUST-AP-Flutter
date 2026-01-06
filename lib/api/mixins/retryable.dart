import 'package:nkust_ap/api/api_exceptions.dart';

// Re-export RetryLimitExceededException for backward compatibility
export 'package:nkust_ap/api/api_exceptions.dart'
    show RetryLimitExceededException;

/// Mixin providing retry logic for API operations.
///
/// This mixin provides a standardized way to handle retry logic when
/// API calls fail due to authentication issues or transient errors.
///
/// Usage:
/// ```dart
/// class MyHelper with Retryable {
///   @override
///   int get retryLimit => 3;
///
///   Future<Data> fetchData() async {
///     return executeWithRetry(
///       operation: () => _doFetchData(),
///       onRetry: () => _reLogin(),
///     );
///   }
/// }
/// ```
mixin Retryable {
  int _retryCount = 0;

  /// Maximum number of retry attempts allowed.
  int get retryLimit => 3;

  /// Current retry count.
  int get retryCount => _retryCount;

  /// Whether retries are still available.
  bool get canRetry => _retryCount < retryLimit;

  /// Increments the retry counter.
  void incrementRetryCount() => _retryCount++;

  /// Resets the retry counter to zero.
  void resetRetryCount() => _retryCount = 0;

  /// Checks if retry limit is exceeded and throws if so.
  ///
  /// Throws [RetryLimitExceededException] if retry limit is exceeded.
  void checkRetryLimit() {
    if (!canRetry) {
      throw const RetryLimitExceededException(
        'Exceeded retry limit',
      );
    }
  }

  /// Executes an operation with automatic retry on failure.
  ///
  /// [operation] is the async operation to execute.
  /// [onRetry] is called before each retry attempt (e.g., re-login).
  /// [shouldRetry] determines if the error should trigger a retry.
  /// [maxRetries] overrides the default [retryLimit] for this call.
  ///
  /// Returns the result of [operation] on success.
  /// Throws [RetryLimitExceededException] if all retries are exhausted.
  Future<T> executeWithRetry<T>({
    required Future<T> Function() operation,
    required Future<void> Function() onRetry,
    bool Function(Object error)? shouldRetry,
    int? maxRetries,
  }) async {
    final int limit = maxRetries ?? retryLimit;
    int attempts = 0;

    while (true) {
      try {
        final T result = await operation();
        resetRetryCount();
        return result;
      } catch (e) {
        attempts++;

        // Check if we should retry this error
        final bool doRetry = shouldRetry?.call(e) ?? true;

        if (!doRetry || attempts >= limit) {
          resetRetryCount();
          rethrow;
        }

        // Perform retry action (e.g., re-login)
        await onRetry();
      }
    }
  }
}
