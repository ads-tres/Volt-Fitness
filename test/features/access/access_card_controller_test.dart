import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_mobile/app/bootstrap.dart';
import 'package:gym_mobile/core/auth/session_controller.dart';
import 'package:gym_mobile/core/network/api_client.dart';
import 'package:gym_mobile/features/access/data/access_card_controller.dart';
import 'package:gym_mobile/features/access/data/access_repository.dart';
import 'package:gym_mobile/features/access/domain/access_credential.dart';

import '../../support/test_doubles.dart';

final stored = AccessCredential(id: '01K7Z9STOREDCREDENTIAL0000', secret: List<int>.filled(32, 7));

Future<ProviderContainer> containerWith(StubAdapter adapter, InMemorySecureStore secureStore) async {
  final container = ProviderContainer.test(
    retry: noAutomaticRetry,
    overrides: await testOverrides(signedInAs: memberOf([boleGym]), secureStore: secureStore),
  );
  container.read(dioProvider).httpClientAdapter = adapter;
  return container;
}

void main() {
  test('the first visit creates a credential and keeps its secret', () async {
    final secureStore = InMemorySecureStore();
    final adapter = StubAdapter(
      (request) => jsonResponse(201, {
        'data': {'credential_id': '01K7Z9NEW00000000000000000', 'secret': '07' * 32, 'algorithm': 'GQ1'},
      }),
    );
    final container = await containerWith(adapter, secureStore);

    final card = await container.read(accessCardProvider.future);

    expect(card, isA<ActiveCard>().having((c) => c.credential.id, 'id', '01K7Z9NEW00000000000000000'));
    expect(adapter.requests.single.path, '/access/credentials');
    expect((await container.read(credentialStoreProvider).read(boleGym.id))?.id, '01K7Z9NEW00000000000000000');
  });

  test('a stored credential shows offline', () async {
    final secureStore = InMemorySecureStore();
    final adapter = StubAdapter((_) => throw const SocketException('offline'));
    final container = await containerWith(adapter, secureStore);
    await container.read(credentialStoreProvider).write(boleGym.id, stored);

    final card = await container.read(accessCardProvider.future);
    await pumpEventQueue();

    expect(card, isA<ActiveCard>().having((c) => c.credential.id, 'id', stored.id));
    expect(container.read(accessCardProvider).value, isA<ActiveCard>());
  });

  test('a credential taken over by another phone shows as replaced, and can be moved back', () async {
    final secureStore = InMemorySecureStore();
    var moved = false;
    final adapter = StubAdapter((request) {
      if (request.method == 'POST') {
        moved = true;
        return jsonResponse(201, {
          'data': {'credential_id': '01K7Z9BACK0000000000000000', 'secret': '09' * 32, 'algorithm': 'GQ1'},
        });
      }
      return jsonResponse(200, {
        'data': {'credential_id': stored.id, 'status': 'revoked', 'revoked_reason': 'replaced', 'algorithm': 'GQ1'},
      });
    });
    final container = await containerWith(adapter, secureStore);
    await container.read(credentialStoreProvider).write(boleGym.id, stored);

    await container.read(accessCardProvider.future);
    await pumpEventQueue();
    expect(container.read(accessCardProvider).value, isA<RevokedCard>().having((c) => c.reason, 'reason', 'replaced'));
    expect(await container.read(credentialStoreProvider).read(boleGym.id), isNull);

    await container.read(accessCardProvider.notifier).useThisPhone();
    expect(moved, isTrue);
    expect(container.read(accessCardProvider).value, isA<ActiveCard>());
  });

  test('signing out deletes the stored credentials', () async {
    final secureStore = InMemorySecureStore();
    final container = await containerWith(StubAdapter((_) => jsonResponse(204, null)), secureStore);
    await container.read(credentialStoreProvider).write(boleGym.id, stored);

    await container.read(sessionControllerProvider.notifier).signOut();

    expect(secureStore.values, isEmpty);
  });
}
