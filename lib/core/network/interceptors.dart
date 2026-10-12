import 'dart:developer' as developer;

import 'package:dio/dio.dart';

import '../auth/token_store.dart';
import '../device/app_info.dart';
import '../utils/uuid.dart';
import 'api_headers.dart';

/// Adds the headers every request carries. Values that change while the
/// app runs (language, gym) are read per request.
final class ContextHeadersInterceptor extends Interceptor {
  ContextHeadersInterceptor({
    required this.appInfo,
    required this.languageCode,
    required this.organizationId,
  });

  final AppInfo appInfo;
  final String Function() languageCode;
  final String? Function() organizationId;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.headers.addAll({
      ApiHeaders.acceptLanguage: languageCode(),
      ApiHeaders.deviceId: appInfo.installationId,
      ApiHeaders.appVersion: appInfo.version,
      ApiHeaders.appBuild: appInfo.buildNumber,
      ApiHeaders.platform: appInfo.platform,
      ApiHeaders.requestId: uuidV4(),
    });
    final organizationId = this.organizationId();
    if (organizationId != null) {
      options.headers[ApiHeaders.organizationId] = organizationId;
    }
    handler.next(options);
  }
}

/// Sends the bearer token, and ends the session when the API rejects it.
final class AuthInterceptor extends Interceptor {
  AuthInterceptor({required this.tokenStore, required this.onUnauthorized});

  static const _sentTokenKey = 'auth.sentToken';

  final TokenStore tokenStore;
  final void Function() onUnauthorized;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = tokenStore.token;
    if (token != null) {
      options.headers[ApiHeaders.authorization] = 'Bearer $token';
      options.extra[_sentTokenKey] = token;
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // A 401 only ends the session if it rejected the token still in use. A
    // slow request sent before a new sign-in must not sign the member out.
    final sentToken = err.requestOptions.extra[_sentTokenKey];
    if (err.response?.statusCode == 401 && sentToken != null && sentToken == tokenStore.token) {
      onUnauthorized();
    }
    handler.next(err);
  }
}

/// Logs method, path, status and timing in debug builds. Never headers or
/// bodies: they carry tokens, OTP codes and QR secrets.
final class NetworkLogInterceptor extends Interceptor {
  static const _startedAtKey = 'log.startedAt';

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.extra[_startedAtKey] = DateTime.now();
    handler.next(options);
  }

  @override
  void onResponse(Response<dynamic> response, ResponseInterceptorHandler handler) {
    _log(response.requestOptions, '${response.statusCode}');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _log(err.requestOptions, '${err.response?.statusCode ?? err.type.name}');
    handler.next(err);
  }

  void _log(RequestOptions options, String outcome) {
    final startedAt = options.extra[_startedAtKey];
    final elapsed = startedAt is DateTime ? ' ${DateTime.now().difference(startedAt).inMilliseconds}ms' : '';
    final requestId = options.headers[ApiHeaders.requestId];
    developer.log('${options.method} ${options.uri.path} -> $outcome$elapsed [$requestId]', name: 'http');
  }
}
