import 'dart:io';

import 'package:dio/dio.dart';

import '../errors/failure.dart';
import 'api_headers.dart';

/// Turns a Dio error into a [Failure]. Error bodies follow the contract:
/// Laravel's `{message, errors}` plus `code` and `request_id`.
Failure mapDioException(DioException error) {
  final sentRequestId = switch (error.requestOptions.headers[ApiHeaders.requestId]) {
    final String id => id,
    _ => null,
  };
  return switch (error.type) {
    DioExceptionType.connectionTimeout ||
    DioExceptionType.sendTimeout ||
    DioExceptionType.receiveTimeout ||
    DioExceptionType.transformTimeout ||
    DioExceptionType.connectionError ||
    DioExceptionType.badCertificate => NetworkFailure(requestId: sentRequestId),
    DioExceptionType.cancel => CancelledFailure(requestId: sentRequestId),
    DioExceptionType.badResponse => _fromResponse(error.response, sentRequestId),
    DioExceptionType.unknown => switch (error.error) {
      SocketException() || HttpException() => NetworkFailure(requestId: sentRequestId),
      final cause => UnexpectedFailure(cause: cause, requestId: sentRequestId),
    },
  };
}

Failure _fromResponse(Response<dynamic>? response, String? sentRequestId) {
  if (response == null) return UnexpectedFailure(requestId: sentRequestId);

  // A proxy or a crash page can answer with HTML instead of JSON.
  final body = switch (response.data) {
    final Map<String, dynamic> json => json,
    _ => const <String, dynamic>{},
  };
  final code = _string(body['code']);
  final message = _string(body['message']);
  final requestId = _string(body['request_id']) ?? response.headers.value(ApiHeaders.requestId) ?? sentRequestId;
  final status = response.statusCode ?? 0;

  return switch (status) {
    401 => UnauthenticatedFailure(code: code, message: message, requestId: requestId),
    403 => ForbiddenFailure(code: code, message: message, requestId: requestId),
    404 => NotFoundFailure(code: code, message: message, requestId: requestId),
    409 => ConflictFailure(code: code, message: message, requestId: requestId),
    422 => ValidationFailure(
      fieldErrors: _fieldErrors(body['errors']),
      code: code,
      message: message,
      requestId: requestId,
    ),
    426 => UpdateRequiredFailure(code: code, message: message, requestId: requestId),
    429 => RateLimitedFailure(
      retryAfter: _retryAfter(response.headers.value('retry-after')),
      code: code,
      message: message,
      requestId: requestId,
    ),
    >= 500 => ServerFailure(statusCode: status, code: code, message: message, requestId: requestId),
    _ => UnexpectedFailure(statusCode: status, code: code, message: message, requestId: requestId),
  };
}

String? _string(Object? value) => value is String ? value : null;

Map<String, List<String>> _fieldErrors(Object? errors) {
  if (errors is! Map<String, dynamic>) return const {};
  return {
    for (final MapEntry(:key, :value) in errors.entries)
      if (value is List<dynamic>) key: [for (final message in value) if (message is String) message],
  };
}

/// Laravel's throttle middleware sends whole seconds.
Duration? _retryAfter(String? header) {
  final seconds = int.tryParse(header ?? '');
  return seconds == null ? null : Duration(seconds: seconds);
}
