import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_mobile/core/errors/failure.dart';
import 'package:gym_mobile/core/network/api_client.dart';
import 'package:gym_mobile/core/time/local_date.dart';
import 'package:gym_mobile/staff/core/desk_session.dart';
import 'package:gym_mobile/staff/fake_front_desk.dart';
import 'package:gym_mobile/staff/features/memberships/data/desk_memberships_repository.dart';

import '../support/test_doubles.dart';

void main() {
  Future<DeskMembershipsRepository> desk({StubAdapter? adapter, String phone = FakeFrontDesk.staffPhone}) async {
    final container = ProviderContainer.test(
      overrides: await testOverrides(
        fakeBackend: adapter == null,
        fakeAdapter: FakeFrontDesk(latency: Duration.zero, now: () => testNow),
      ),
    );
    if (adapter != null) container.read(dioProvider).httpClientAdapter = adapter;
    final session = container.read(deskSessionProvider.notifier);
    await session.signIn(
      token: adapter == null ? 'fake-desk-token:$phone' : '9|desk',
      name: 'Demo',
      gyms: [const DeskGym(slug: 'demo-gym', name: 'Demo Gym', role: 'owner', worksAtAllBranches: true)],
    );
    await session.selectBranch(const DeskBranch(id: 1, name: 'Main Branch'));
    return container.read(deskMembershipsRepositoryProvider);
  }

  Future<String?> refusal(Future<void> Function() call, String field) async {
    try {
      await call();
    } on ValidationFailure catch (failure) {
      return failure.fieldErrors[field]?.single;
    }
    return null;
  }

  test('reads only memberships that run or are coming, with their freezes and freeze days', () async {
    final adapter = StubAdapter(
      (_) => jsonResponse(200, {
        'data': [
          {
            'id': 9,
            'plan': {'id': 2, 'name': 'Monthly'},
            'status': 'frozen',
            'starts_on': '2026-10-02',
            'ends_on': '2026-11-04',
            'freeze_days_allowed': 7,
            'freeze_days_used': 3,
            'freezes': [
              {'id': 30, 'starts_on': '2026-10-13', 'ends_on': '2026-10-15', 'days': 3, 'reason': 'Ill'},
            ],
          },
          {
            'id': 8,
            'plan': {'id': 2, 'name': 'Monthly'},
            'status': 'expired',
            'starts_on': '2026-09-01',
            'ends_on': '2026-09-30',
            'freezes': <Object?>[],
          },
        ],
      }),
    );
    final memberships = await (await desk(adapter: adapter)).memberships(3);

    expect(memberships, hasLength(1));
    expect(memberships.single.freezeDaysLeft, 4);
    expect(memberships.single.currentOrNextFreeze(LocalDate(2026, 10, 14))?.id, 30);
    expect(memberships.single.currentOrNextFreeze(LocalDate(2026, 10, 16)), isNull);
  });

  test('sends freezes, their ending and cancellations to the API\'s paths', () async {
    final adapter = StubAdapter((_) => jsonResponse(200, {'data': <String, Object?>{}}));
    final memberships = await desk(adapter: adapter);

    await memberships.freeze(9, endsOn: LocalDate(2026, 10, 20), reason: ' Travelling ');
    await memberships.freeze(9, startsOn: LocalDate(2026, 10, 15), endsOn: LocalDate(2026, 10, 20), reason: 'Ill');
    await memberships.endFreeze(9, 30);
    await memberships.cancel(9, reason: 'Moved away');

    expect([for (final request in adapter.requests) request.path], [
      '/organizations/demo-gym/memberships/9/freezes',
      '/organizations/demo-gym/memberships/9/freezes',
      '/organizations/demo-gym/memberships/9/freezes/30/end',
      '/organizations/demo-gym/memberships/9/cancellation',
    ]);
    expect(adapter.requests[0].data, {'ends_on': '2026-10-20', 'reason': 'Travelling'});
    expect(adapter.requests[1].data, {'starts_on': '2026-10-15', 'ends_on': '2026-10-20', 'reason': 'Ill'});
    expect(adapter.requests[3].data, {'reason': 'Moved away'});
  });

  test('the fake moves the end with a freeze, keeps receptionists to the freeze days, and refuses overlaps', () async {
    final owner = await desk();
    await owner.freeze(101, endsOn: LocalDate(2026, 10, 20), reason: 'Travelling');
    final abebe = (await owner.memberships(1)).single;
    expect(abebe.status, 'frozen');
    expect(abebe.endsOn, LocalDate(2026, 11, 8), reason: '7 days later');
    expect(
      await refusal(() => owner.freeze(101, startsOn: LocalDate(2026, 10, 18), endsOn: LocalDate(2026, 10, 19), reason: 'x'), 'starts_on'),
      'This membership is already frozen from 14 October 2026 to 20 October 2026.',
    );

    final receptionist = await desk(phone: FakeFrontDesk.twoGymsPhone);
    expect(
      await refusal(
        () => receptionist.freeze(103, startsOn: LocalDate(2026, 10, 24), endsOn: LocalDate(2026, 10, 28), reason: 'x'),
        'ends_on',
      ),
      'This membership can be frozen for 4 more days.',
      reason: "Hana's 3-day freeze is already counted",
    );
    expect(
      await refusal(() => receptionist.freeze(103, startsOn: LocalDate(2026, 10, 1), endsOn: LocalDate(2026, 10, 2), reason: 'x'), 'starts_on'),
      'Only owners and managers can start a freeze on a past date.',
    );
  });

  test('the fake removes a coming freeze, and cancels only for owners', () async {
    final owner = await desk();
    final hana = (await owner.memberships(3)).single;
    await owner.endFreeze(hana.id, hana.freezes.single.id);
    final unfrozen = (await owner.memberships(3)).single;
    expect(unfrozen.freezes, isEmpty);
    expect(unfrozen.endsOn, LocalDate(2026, 11, 1));

    final receptionist = await desk(phone: FakeFrontDesk.twoGymsPhone);
    await expectLater(receptionist.cancel(103, reason: 'x'), throwsA(isA<Failure>()));
    expect(await refusal(() => owner.cancel(103, reason: ' '), 'reason'), 'The reason field is required.');
    await owner.cancel(103, reason: 'Moved away');
    expect(await owner.memberships(3), isEmpty);
  });
}
