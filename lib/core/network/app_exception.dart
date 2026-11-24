/// Base exception class for errors originating in the data layer.
///
/// All data-layer exceptions extend this class so callers can catch a single
/// type and inspect [message] and the optional [statusCode].
class AppException implements Exception {
  /// Human-readable description of what went wrong.
  final String message;

  /// HTTP status code associated with the error, if available.
  final int? statusCode;

  /// Creates an [AppException] with an optional [statusCode].
  AppException(this.message, [this.statusCode]);

  @override
  String toString() => 'AppException: $message (statusCode: $statusCode)';
}

/// Thrown when a network request cannot be completed (DNS failure, timeout,
/// no internet, etc.).
class FetchDataException extends AppException {
  /// Creates a [FetchDataException] with an optional [statusCode].
  FetchDataException(String message, [int? statusCode])
      : super(message, statusCode);
}

/// Thrown when the server responds with a client error (400, 401, 403, 404).
///
/// Typically indicates invalid input, missing authentication, or a missing
/// resource.
class BadRequestException extends AppException {
  /// Creates a [BadRequestException] with an optional [statusCode].
  BadRequestException(String message, [int? statusCode])
      : super(message, statusCode);
}

/// Thrown when the server responds with a server error (5xx).
///
/// Indicates the backend is unavailable or encountered an unexpected failure.
class UnauthorisedException extends AppException {
  /// Creates an [UnauthorisedException] with an optional [statusCode].
  UnauthorisedException(String message, [int? statusCode])
      : super(message, statusCode);
}