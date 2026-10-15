import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' show Color;

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:gym_mobile/core/auth/profile.dart';
import 'package:gym_mobile/core/auth/profile_cache.dart';
import 'package:gym_mobile/core/auth/token_store.dart';
import 'package:gym_mobile/core/config/env.dart';
import 'package:gym_mobile/core/device/app_info.dart';
import 'package:gym_mobile/core/network/api_client.dart';
import 'package:gym_mobile/core/network/fake_backend.dart';
import 'package:gym_mobile/core/push/push_service.dart';
import 'package:gym_mobile/core/storage/preferences_store.dart';
import 'package:gym_mobile/core/storage/secure_store.dart';
import 'package:gym_mobile/core/tenant/organization.dart';
import 'package:gym_mobile/core/time/clock.dart';

final class InMemorySecureStore implements SecureStore {
  final values = <String, String>{};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;

  @override
  Future<void> delete(String key) async => values.remove(key);

  @override
  Future<void> deletePrefixed(String prefix) async => values.removeWhere((key, _) => key.startsWith(prefix));
}

final class InMemoryPreferencesStore implements PreferencesStore {
  final values = <String, String>{};

  @override
  String? getString(String key) => values[key];

  @override
  Future<void> setString(String key, String value) async => values[key] = value;

  @override
  Future<void> remove(String key) async => values.remove(key);

  @override
  Future<void> removePrefixed(String prefix) async => values.removeWhere((key, _) => key.startsWith(prefix));
}

/// The phone's clock in every test: Tuesday 14 October 2026, 09:30.
final testNow = DateTime(2026, 10, 14, 9, 30);

const testAppInfo = AppInfo(
  version: '1.0.0',
  buildNumber: '7',
  platform: 'android',
  installationId: 'installation-1',
  deviceName: 'samsung SM-J600G',
);

const boleGym = Organization(
  id: '01K7Z6A1B2C3D4E5F6G7H8J9KM',
  name: 'Bole Iron Gym',
  role: 'member',
  branding: Branding(primaryColor: Color(0xFF0E7C66), contactPhone: '+251 11 000 0001'),
);

const kazanchisGym = Organization(id: '01K7Z6N2P3Q4R5S6T7V8W9X0YZ', name: 'Kazanchis Fit Club', role: 'member');

Profile memberOf(List<Organization> organizations) => Profile(
  user: const User(id: '01K7Z5B2W8R3M5N7Q9S1T3V5X0', name: 'Abebe Kebede', phone: '+251911234567'),
  organizations: organizations,
);

/// The overrides bootstrap() makes, with in-memory storage. [signedInAs]
/// starts the app signed in, the way a restart after sign-in would; the
/// welcome pages count as seen unless [onboardingDone] is false, and the
/// phone allows notifications unless [pushAllowed] is false (never asked).
Future<List<Override>> testOverrides({
  Profile? signedInAs,
  String? organizationId,
  InMemorySecureStore? secureStore,
  InMemoryPreferencesStore? preferences,
  bool fakeBackend = false,
  bool onboardingDone = true,
  bool pushAllowed = true,
}) async {
  secureStore ??= InMemorySecureStore();
  preferences ??= InMemoryPreferencesStore();
  if (onboardingDone) preferences.values['onboarding.done'] = 'true';
  if (pushAllowed) preferences.values[FakePushService.permissionKey] = PushPermission.granted.name;
  if (signedInAs != null) {
    // The fake backend only accepts its own tokens.
    secureStore.values['auth.token'] = fakeBackend ? 'fake-token:${signedInAs.user.phone}' : 'token-1';
    await ProfileCache(preferences).save(
      signedInAs,
      organizationId: organizationId ?? (signedInAs.organizations.length == 1 ? signedInAs.organizations.single.id : null),
    );
  }
  final tokenStore = TokenStore(secureStore);
  await tokenStore.load();
  return [
    envProvider.overrideWithValue(
      const Env(environment: AppEnvironment.dev, apiBaseUrl: 'https://api.test/api/v1').withFakeBackend(fakeBackend),
    ),
    preferencesStoreProvider.overrideWithValue(preferences),
    secureStoreProvider.overrideWithValue(secureStore),
    tokenStoreProvider.overrideWithValue(tokenStore),
    appInfoProvider.overrideWithValue(testAppInfo),
    clockProvider.overrideWithValue(() => testNow),
    fakeBackendProvider.overrideWithValue(FakeBackend(latency: Duration.zero, now: () => testNow)),
  ];
}

extension on Env {
  Env withFakeBackend(bool fake) =>
      Env(environment: environment, apiBaseUrl: apiBaseUrl, usesFakeBackend: fake);
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
Future<ProviderContainer> containerWithAdapter(StubAdapter adapter, {Profile? signedInAs}) async {
  final container = ProviderContainer.test(overrides: await testOverrides(signedInAs: signedInAs));
  container.read(dioProvider).httpClientAdapter = adapter;
  return container;
}
