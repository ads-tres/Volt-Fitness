/// Why a backend call failed, independent of Dio. Repositories throw these,
/// and the UI turns them into text with `failureMessage`.
sealed class Failure implements Exception {
  const Failure({this.code, this.message, this.requestId});

  /// The API's machine-readable code, such as `OTP_EXPIRED`.
  final String? code;

  /// The API's own message, already in the request's language.
  final String? message;

  /// The failed call's `X-Request-ID`, for finding it in the API logs.
  final String? requestId;

  // No message here: it can echo what the member typed.
  @override
  String toString() => '$runtimeType(code: $code, requestId: $requestId)';
}

/// No connection, a timeout, or a TLS failure.
final class NetworkFailure extends Failure {
  const NetworkFailure({super.requestId});
}

/// The caller cancelled the request; there is nothing to show.
final class CancelledFailure extends Failure {
  const CancelledFailure({super.requestId});
}

/// 401: the token is missing or was revoked. The session has already ended.
final class UnauthenticatedFailure extends Failure {
  const UnauthenticatedFailure({super.code, super.message, super.requestId});
}

/// 403
final class ForbiddenFailure extends Failure {
  const ForbiddenFailure({super.code, super.message, super.requestId});
}

/// 404
final class NotFoundFailure extends Failure {
  const NotFoundFailure({super.code, super.message, super.requestId});
}

/// 409: the request conflicts with the current state on the server.
final class ConflictFailure extends Failure {
  const ConflictFailure({super.code, super.message, super.requestId});
}

/// 422, with the API's messages per field.
final class ValidationFailure extends Failure {
  const ValidationFailure({this.fieldErrors = const {}, super.code, super.message, super.requestId});

  final Map<String, List<String>> fieldErrors;
}

/// 426: this build is older than the API supports.
final class UpdateRequiredFailure extends Failure {
  const UpdateRequiredFailure({super.code, super.message, super.requestId});
}

/// 429
final class RateLimitedFailure extends Failure {
  const RateLimitedFailure({this.retryAfter, super.code, super.message, super.requestId});

  final Duration? retryAfter;
}

/// 5xx
final class ServerFailure extends Failure {
  const ServerFailure({required this.statusCode, super.code, super.message, super.requestId});

  final int statusCode;
}

/// Anything else: an unexpected status, or a response the app can't read.
final class UnexpectedFailure extends Failure {
  const UnexpectedFailure({this.statusCode, this.cause, super.code, super.message, super.requestId});

  final int? statusCode;
  final Object? cause;
}
