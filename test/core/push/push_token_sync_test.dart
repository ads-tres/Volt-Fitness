import 'dart:ui' show Locale;

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_mobile/core/auth/session_controller.dart';
import 'package:gym_mobile/core/localization/locale_controller.dart';
import 'package:gym_mobile/core/network/api_client.dart';
import 'package:gym_mobile/core/push/push_service.dart';
import 'package:gym_mobile/core/push/push_token_sync.dart';

import '../../support/test_doubles.dart';

void main() {
  late StubAdapter adapter;
  late FakePushService push;
  late ProviderContainer container;

  setUp(() async {
    adapter = StubAdapter((request) => ResponseBody.fromString('', 204));
    final preferences = InMemoryPreferencesStore();
    push = FakePushService(preferences);
    container = ProviderContainer.test(
      overrides: [
        ...await testOverrides(signedInAs: memberOf([boleGym]), preferences: preferences),
        pushServiceProvider.overrideWithValue(push),
      ],
    );
    container.read(dioProvider).httpClientAdapter = adapter;
  });

  List<Object?> sent() => [
    for (final request in adapter.requests)
      if (request.path == '/devices/current/push-token') request.data,
  ];

  test('the push token goes to the API once, and again when it or the language changes', () async {
    final subscription = container.listen(pushTokenSyncProvider, (_, _) {});
    await pumpEventQueue();
    expect(sent(), [
      {'provider': 'fcm', 'token': 'fake-fcm-token-1', 'locale': 'en'},
    ]);

    // Nothing changed: nothing sent, even when the sync starts again.
    subscription.close();
    await pumpEventQueue();
    container.listen(pushTokenSyncProvider, (_, _) {});
    await pumpEventQueue();
    expect(sent(), hasLength(1));

    await container.read(localeControllerProvider.notifier).select(const Locale('am'));
    await pumpEventQueue();
    expect(sent().last, {'provider': 'fcm', 'token': 'fake-fcm-token-1', 'locale': 'am'});

    push.rotateToken();
    await pumpEventQueue();
    expect(sent().last, {'provider': 'fcm', 'token': 'fake-fcm-token-2', 'locale': 'am'});
    expect(sent(), hasLength(3));
  });

  test('a token the API never got is sent at the next start', () async {
    adapter = StubAdapter((request) => throw DioException.connectionError(requestOptions: request, reason: 'offline'));
    container.read(dioProvider).httpClientAdapter = adapter;
    final subscription = container.listen(pushTokenSyncProvider, (_, _) {});
    await pumpEventQueue();
    subscription.close();
    await pumpEventQueue();

    final online = StubAdapter((request) => ResponseBody.fromString('', 204));
    container.read(dioProvider).httpClientAdapter = online;
    container.listen(pushTokenSyncProvider, (_, _) {});
    await pumpEventQueue();
    expect(online.requests.where((request) => request.path == '/devices/current/push-token'), hasLength(1));
  });

  test('signing out stops pushes to this phone', () async {
    final before = await push.token();
    await container.read(sessionControllerProvider.notifier).signOut();
    expect(await push.token(), isNot(before));
  });
}
