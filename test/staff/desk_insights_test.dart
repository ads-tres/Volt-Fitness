import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_mobile/core/errors/failure.dart';
import 'package:gym_mobile/core/money/money.dart';
import 'package:gym_mobile/core/network/api_client.dart';
import 'package:gym_mobile/staff/core/desk_session.dart';
import 'package:gym_mobile/staff/fake_front_desk.dart';
import 'package:gym_mobile/staff/features/numbers/data/insights_repository.dart';
import 'package:gym_mobile/staff/features/numbers/domain/desk_insights.dart';

import '../support/test_doubles.dart';

void main() {
  Map<String, Object?> money(int minor) => {'amount_minor': minor, 'currency': 'ETB', 'formatted': '…'};

  Future<InsightsRepository> desk({StubAdapter? adapter, String phone = FakeFrontDesk.staffPhone}) async {
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
    return container.read(insightsRepositoryProvider);
  }

  test('reads revenue and renewals by month, with an undecided month\'s rate as null', () {
    final revenue = revenueFromJson({
      'insight': 'revenue',
      'months': [
        {
          'month': '2026-09',
          'net': money(450000),
          'by_plan': {'Monthly': money(450000)},
          'by_method': {'cash': money(300000), 'brought_in': money(150000)},
        },
      ],
    });
    expect(revenue.single.month, DateTime(2026, 9));
    expect(revenue.single.net, const Money(450000, 'ETB'));
    expect(revenue.single.byMethod['brought_in'], const Money(150000, 'ETB'));

    final renewals = renewalsFromJson({
      'months': [
        {'month': '2026-09', 'renewed': 8, 'lapsed': 2, 'waiting': 0, 'rate': 0.8, 'by_plan': {'Monthly': {'renewed': 8, 'lapsed': 2, 'waiting': 0}}},
        {'month': '2026-10', 'renewed': 0, 'lapsed': 0, 'waiting': 5, 'rate': null},
      ],
    });
    expect(renewals.first.rate, 0.8);
    expect(renewals.first.ended, 10);
    expect(renewals.first.byPlan['Monthly']?.renewed, 8);
    expect(renewals.last.rate, isNull);
  });

  test('reads the busy-hours grid keyed by weekday, a missing day as empty, and finds the busiest hour', () {
    final busy = busyHoursFromJson({
      'months': 12,
      'grid': {
        '1': [for (var hour = 0; hour < 24; hour++) hour == 18 ? 40 : 1],
        '6': [for (var hour = 0; hour < 24; hour++) hour == 7 ? 55 : 0],
      },
      'total': 118,
    });
    expect(busy.grid, hasLength(7));
    expect(busy.grid[1], List<int>.filled(24, 0), reason: 'Tuesday had none');
    expect(busy.busiest, (weekday: 6, hour: 7, count: 55));
    expect(busy.total, 118);
  });

  test('asks for the months at the desk\'s branch, or at every branch', () async {
    final adapter = StubAdapter((_) => jsonResponse(200, {'data': {'insight': 'members', 'months': <Object?>[]}}));
    final insights = await desk(adapter: adapter);

    await insights.members((months: 6, allBranches: false));
    await insights.members((months: 3, allBranches: true));

    expect(adapter.requests.first.path, '/organizations/demo-gym/insights/members');
    expect(adapter.requests.first.queryParameters, {'months': 6, 'branch_id': 1});
    expect(adapter.requests.last.queryParameters, {'months': 3});
  });

  test('the fake gives each insight for the months asked, and only to the roles the API allows', () async {
    final owner = await desk();
    expect(await owner.revenue((months: 3, allBranches: true)), hasLength(3));
    expect(await owner.renewals((months: 6, allBranches: false)), hasLength(6));
    expect((await owner.busyHours((months: 12, allBranches: true))).busiest?.hour, 6);
    expect((await owner.members((months: 12, allBranches: true))).last.month, DateTime(2026, 10));

    final accountant = await desk(phone: FakeFrontDesk.accountantPhone);
    expect(await accountant.revenue((months: 12, allBranches: false)), hasLength(12));
    await expectLater(accountant.renewals((months: 12, allBranches: false)), throwsA(isA<ForbiddenFailure>()));

    final receptionist = await desk(phone: FakeFrontDesk.twoGymsPhone);
    await expectLater(receptionist.revenue((months: 12, allBranches: false)), throwsA(isA<ForbiddenFailure>()));
  });
}
