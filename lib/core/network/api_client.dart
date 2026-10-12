import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/session_controller.dart';
import '../auth/token_store.dart';
import '../config/env.dart';
import '../device/app_info.dart';
import '../errors/failure.dart';
import '../localization/locale_controller.dart';
import '../tenant/selected_organization.dart';
import 'api_headers.dart';
import 'error_mapper.dart';
import 'interceptors.dart';

/// The app's only way to call the API. Paths are relative to `/api/v1`.
/// Every method returns the decoded JSON body or throws a [Failure].
final class ApiClient {
  ApiClient(this._dio);

  final Dio _dio;

  Future<Object?> get(String path, {Map<String, Object?>? query}) =>
      _send(() => _dio.get<Object?>(path, queryParameters: query));

  /// Pass [idempotencyKey] when the call may be retried and must not take
  /// effect twice (payments, scans, offline sync).
  Future<Object?> post(String path, {Object? body, String? idempotencyKey}) => _send(
    () => _dio.post<Object?>(
      path,
      data: body,
      options: idempotencyKey == null ? null : Options(headers: {ApiHeaders.idempotencyKey: idempotencyKey}),
    ),
  );

  Future<Object?> put(String path, {Object? body}) => _send(() => _dio.put<Object?>(path, data: body));

  Future<Object?> patch(String path, {Object? body}) => _send(() => _dio.patch<Object?>(path, data: body));

  Future<Object?> delete(String path) => _send(() => _dio.delete<Object?>(path));

  Future<Object?> _send(Future<Response<Object?>> Function() request) async {
    try {
      return (await request()).data;
    } on DioException catch (error, stack) {
      Error.throwWithStackTrace(mapDioException(error), stack);
    }
  }
}

final dioProvider = Provider<Dio>((ref) {
  final env = ref.watch(envProvider);
  final dio = Dio(
    BaseOptions(
      baseUrl: env.apiBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      sendTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {Headers.acceptHeader: Headers.jsonContentType},
    ),
  );
  dio.interceptors.addAll([
    ContextHeadersInterceptor(
      appInfo: ref.watch(appInfoProvider),
      languageCode: () => ref.read(languageCodeProvider),
      organizationId: () => ref.read(selectedOrganizationProvider),
    ),
    AuthInterceptor(
      tokenStore: ref.watch(tokenStoreProvider),
      onUnauthorized: () => unawaited(ref.read(sessionControllerProvider.notifier).signOut()),
    ),
    if (env.logsNetwork) NetworkLogInterceptor(),
  ]);
  ref.onDispose(dio.close);
  return dio;
});

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient(ref.watch(dioProvider)));
