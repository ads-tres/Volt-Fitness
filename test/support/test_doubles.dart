import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:gym_mobile/core/auth/token_store.dart';
import 'package:gym_mobile/core/config/env.dart';
import 'package:gym_mobile/core/device/app_info.dart';
import 'package:gym_mobile/core/network/api_client.dart';
import 'package:gym_mobile/core/storage/preferences_store.dart';
import 'package:gym_mobile/core/storage/secure_store.dart';

final class InMemorySecureStore implements SecureStore {
  final values = <String, String>{};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;

  @override
  Future<void> delete(String key) async => values.remove(key);
}

final class InMemoryPreferencesStore implements PreferencesStore {
  final values = <String, String>{};

  @override
  String? getString(String key) => values[key];

  @override
  Future<void> setString(String key, String value) async => values[key] = value;

  @override
  Future<void> remove(String key) async => values.remove(key);
}

const testEnv = Env(environment: AppEnvironment.dev, apiBaseUrl: 'https://api.test/api/v1');

const testAppInfo = AppInfo(
  version: '1.0.0',
  buildNumber: '7',
  platform: 'android',
  installationId: 'installation-1',
);

/// The overrides bootstrap() makes, with in-memory storage. A non-null
/// [token] starts the app signed in.
Future<List<Override>> testOverrides({
  String? token,
  InMemorySecureStore? secureStore,
  PreferencesStore? preferences,
}) async {
  secureStore ??= InMemorySecureStore();
  if (token != null) secureStore.values['auth.token'] = token;
  final tokenStore = TokenStore(secureStore);
  await tokenStore.load();
  return [
    envProvider.overrideWithValue(testEnv),
    preferencesStoreProvider.overrideWithValue(preferences ?? InMemoryPreferencesStore()),
    tokenStoreProvider.overrideWithValue(tokenStore),
    appInfoProvider.overrideWithValue(testAppInfo),
  ];
}

/// Stands in for the network: records each request and answers it with
/// [respond], which may also throw like a real socket would.
final class StubAdapter implements HttpClientAdapter {
  StubAdapter(this.respond);

  final FutureOr<ResponseBody> Function(RequestOptions request) respond;
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return await respond(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody jsonResponse(int status, Object? body, {Map<String, List<String>> headers = const {}}) =>
    ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
        ...headers,
      },
    );

/// A container wired like the app, with the network replaced by [adapter].
Future<ProviderContainer> containerWithAdapter(StubAdapter adapter, {String? token}) async {
  final container = ProviderContainer.test(overrides: await testOverrides(token: token));
  container.read(dioProvider).httpClientAdapter = adapter;
  return container;
}
