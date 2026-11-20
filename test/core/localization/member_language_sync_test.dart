import 'dart:ui' show Locale;

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_mobile/core/localization/locale_controller.dart';
import 'package:gym_mobile/core/localization/member_language_sync.dart';
import 'package:gym_mobile/core/network/api_client.dart';

import '../../support/test_doubles.dart';

void main() {
  test('the member\'s language goes to the API after sign-in, and again only when it changes', () async {
    final adapter = StubAdapter((_) => ResponseBody.fromString('', 204));
    final container = ProviderContainer.test(overrides: await testOverrides(signedInAs: memberOf([boleGym])));
    container.read(dioProvider).httpClientAdapter = adapter;
    List<Object?> sent() => [
      for (final request in adapter.requests)
        if (request.path == '/me/language') request.data,
    ];

    final subscription = container.listen(memberLanguageSyncProvider, (_, _) {});
    await pumpEventQueue();
    expect(sent(), [
      {'language': 'en'},
    ]);

    subscription.close();
    await pumpEventQueue();
    container.listen(memberLanguageSyncProvider, (_, _) {});
    await pumpEventQueue();
    expect(sent(), hasLength(1), reason: 'nothing changed');

    await container.read(localeControllerProvider.notifier).select(const Locale('am'));
    await pumpEventQueue();
    expect(sent().last, {'language': 'am'});
    expect(sent(), hasLength(2));
  });

  test('a failure is sent again at the next start', () async {
    var fail = true;
    final adapter = StubAdapter(
      (_) => fail ? jsonResponse(503, {'message': 'Down'}) : ResponseBody.fromString('', 204),
    );
    final container = ProviderContainer.test(overrides: await testOverrides(signedInAs: memberOf([boleGym])));
    container.read(dioProvider).httpClientAdapter = adapter;

    final subscription = container.listen(memberLanguageSyncProvider, (_, _) {});
    await pumpEventQueue();
    subscription.close();
    await pumpEventQueue();

    fail = false;
    container.listen(memberLanguageSyncProvider, (_, _) {});
    await pumpEventQueue();
    expect(adapter.requests.where((request) => request.path == '/me/language'), hasLength(2));
  });
}
