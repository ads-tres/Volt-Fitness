import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_mobile/staff/core/desk_session.dart';
import 'package:gym_mobile/staff/fake_front_desk.dart';
import 'package:gym_mobile/staff/features/offline/data/door_list_repository.dart';

import '../support/test_doubles.dart';

void main() {
  const demoGym = DeskGym(slug: 'demo-gym', name: 'Demo Gym', role: 'owner', worksAtAllBranches: true);

  Future<(ProviderContainer, InMemorySecureStore)> desk({
    HttpClientAdapter? adapter,
    DoorListKey? builtInKey,
  }) async {
    final secure = InMemorySecureStore();
    final fake = FakeFrontDesk(latency: Duration.zero, now: () => testNow);
    final container = ProviderContainer.test(
      overrides: [
        ...await testOverrides(fakeBackend: true, fakeAdapter: adapter ?? fake, secureStore: secure),
        doorListKeyProvider.overrideWithValue(builtInKey),
      ],
    );
    final session = container.read(deskSessionProvider.notifier);
    await session.signIn(token: 'fake-desk-token:${FakeFrontDesk.staffPhone}', name: 'Demo Owner', gyms: [demoGym]);
    await session.selectBranch(const DeskBranch(id: 1, name: 'Main Branch'));
    return (container, secure);
  }

  test('downloads the list, checks its signature with the fetched key, and keeps both', () async {
    final (container, secure) = await desk();
    final doorLists = container.read(doorListRepositoryProvider);

    final list = await doorLists.download(branchId: 1);

    expect(list.gymSlug, 'demo-gym');
    expect(list.credentials, hasLength(3));
    final hana = list.credentials[FakeFrontDesk.doorCredentials[3]]!;
    expect((hana.memberName, hana.dayKeys.length, hana.days.values.first.visitsLeft), ('Hana Girma', 2, 1));
    expect(hana.days.values.first.branchIds, [1]);
    expect(list.hours[1]!.values.first, (opensAt: 300, closesAt: 1380));
    expect(list.isValidAt(testNow.toUtc()), isTrue);
    expect(secure.values.keys, containsAll(['desk.door_list', 'desk.door_list_key']));
    expect((await doorLists.stored())?.credentials, hasLength(3), reason: 'checked again when read');
  });

  test('a list changed on the phone, or signed with another key than the built-in one, is refused', () async {
    final (container, secure) = await desk();
    await container.read(doorListRepositoryProvider).download(branchId: 1);

    final kept = jsonDecode(secure.values['desk.door_list']!) as Map<String, dynamic>;
    secure.values['desk.door_list'] = jsonEncode({...kept, 'list': (kept['list'] as String).replaceFirst('"allowed":false', '"allowed":true')});
    expect(await container.read(doorListRepositoryProvider).stored(), isNull);

    final (pinned, _) = await desk(builtInKey: (keyId: 'another-key', publicKey: base64.encode(List.filled(32, 9))));
    await expectLater(
      pinned.read(doorListRepositoryProvider).download(branchId: 1),
      throwsA(isA<DoorListRefused>().having((refused) => refused.problem, 'problem', DoorListProblem.badSignature)),
    );
  });

  test('a gym platform without a signing key answers 503: not set up', () async {
    final (container, _) = await desk(adapter: StubAdapter((_) => jsonResponse(503, {'message': 'No signing key.'})));

    await expectLater(
      container.read(doorListRepositoryProvider).download(branchId: 1),
      throwsA(isA<DoorListRefused>().having((refused) => refused.problem, 'problem', DoorListProblem.notSetUp)),
    );
  });

  test('signing out forgets the list', () async {
    final (container, secure) = await desk();
    await container.read(doorListRepositoryProvider).download(branchId: 1);

    await container.read(deskSessionProvider.notifier).signOut();

    expect(secure.values.keys.where((key) => key.startsWith('desk.')), isEmpty);
  });
}
