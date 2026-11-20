import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_mobile/core/network/api_client.dart';
import 'package:gym_mobile/core/time/local_date.dart';
import 'package:gym_mobile/staff/core/desk_session.dart';
import 'package:gym_mobile/staff/fake_front_desk.dart';
import 'package:gym_mobile/staff/features/numbers/data/numbers_repository.dart';
import 'package:gym_mobile/staff/features/numbers/domain/desk_numbers.dart';

import '../support/test_doubles.dart';

void main() {
  const demoGym = DeskGym(slug: 'demo-gym', name: 'Demo Gym', role: 'owner', worksAtAllBranches: true);
  const main = DeskBranch(id: 1, name: 'Main Branch');
  Map<String, Object?> money(int minor) => {'amount_minor': minor, 'currency': 'ETB', 'formatted': '…'};

  Future<ProviderContainer> desk({StubAdapter? adapter, String phone = FakeFrontDesk.staffPhone}) async {
    final container = ProviderContainer.test(
      overrides: await testOverrides(
        fakeBackend: adapter == null,
        fakeAdapter: FakeFrontDesk(latency: Duration.zero, now: () => testNow),
      ),
    );
    if (adapter != null) container.read(dioProvider).httpClientAdapter = adapter;
    final session = container.read(deskSessionProvider.notifier);
    await session.signIn(token: adapter == null ? 'fake-desk-token:$phone' : '9|desk', name: 'Demo', gyms: [demoGym]);
    await session.selectBranch(main);
    return container;
  }

  test('asks for the period at the desk\'s branch, or every branch, and reads the dashboard', () async {
    final adapter = StubAdapter(
      (_) => jsonResponse(200, {
        'data': {
          'period': {'from': '2026-10-08', 'to': '2026-10-14'},
          'money': {
            'received': money(450000),
            'refunded': money(50000),
            'net': money(400000),
            'by_method': {'telebirr': money(300000), 'cash': money(150000)},
            'open_payment_links': {'count': 2, 'amount': money(200000)},
            'refunds_needed': {'count': 1, 'amount': money(150000)},
          },
          'owed': {'total': money(100000), 'members': 1},
          'check_ins': {
            'allowed': 40,
            'denied': 5,
            'denied_by_reason': {'OUTSIDE_HOURS': 1, 'MEMBERSHIP_EXPIRED': 4},
          },
          'members': {
            'active': 120,
            'new': 6,
            'memberships_sold': {'at_the_desk': 9, 'in_the_app': 3},
          },
          'expiring': [
            {
              'membership_id': 7,
              'member': {'id': 3, 'full_name': 'Hana Girma', 'phone': '+251933456789'},
              'plan': {'id': 4, 'name': '10 Visits'},
              'ends_on': '2026-11-20',
              'visits_remaining': 1,
              'balance_due': money(0),
            },
          ],
          'trends': {
            'check_ins_by_hour': [
              {'hour': 6, 'allowed': 12},
              {'hour': 18, 'allowed': 20},
            ],
          },
        },
      }),
    );
    final container = await desk(adapter: adapter);

    final week = await container.read(numbersProvider((period: NumbersPeriod.week, allBranches: false)).future);
    await container.read(numbersProvider((period: NumbersPeriod.today, allBranches: true)).future);

    final dashboards = adapter.requests.where((request) => request.path.endsWith('/dashboard')).toList();
    expect(dashboards.first.path, '/organizations/demo-gym/dashboard');
    expect(dashboards.first.queryParameters, {'from': '2026-10-08', 'to': '2026-10-14', 'branch_id': 1});
    expect(dashboards.last.queryParameters, {'from': '2026-10-14', 'to': '2026-10-14'});

    expect((week.from, week.letIn, week.turnedAway), (const LocalDate(2026, 10, 8), 40, 5));
    expect(week.turnedAwayByReason, [('MEMBERSHIP_EXPIRED', 4), ('OUTSIDE_HOURS', 1)]);
    expect((week.activeMembers, week.newMembers, week.soldAtTheDesk, week.soldInTheApp), (120, 6, 9, 3));
    expect((week.checkInsByHour[6], week.checkInsByHour[18], week.checkInsByHour[12]), (12, 20, 0));
    expect(week.money?.net.amountMinor, 400000);
    expect(week.money?.byMethod['telebirr']?.amountMinor, 300000);
    expect((week.money?.openLinks, week.money?.refundsNeededAmount.amountMinor), (2, 150000));
    expect((week.owed?.total.amountMinor, week.owed?.members), (100000, 1));
    expect((week.toCall.single.name, week.toCall.single.visitsLeft), ('Hana Girma', 1));
  });

  test('the fake counts the desk\'s check-ins, and leaves money out for a receptionist', () async {
    final owner = await desk();
    final today = await owner.read(numbersProvider((period: NumbersPeriod.today, allBranches: false)).future);
    expect((today.letIn, today.turnedAway), (1, 1), reason: 'the two seeded check-ins at Main Branch');
    expect(today.turnedAwayByReason, [('OUTSIDE_HOURS', 1)]);
    expect(today.money, isNotNull);
    expect(today.toCall.first.balanceDue?.amountMinor, 100000);

    final receptionist = await desk(phone: FakeFrontDesk.twoGymsPhone);
    final theirs = await receptionist.read(numbersProvider((period: NumbersPeriod.today, allBranches: false)).future);
    expect(theirs.money, isNull);
    expect(theirs.owed, isNull);
    expect(theirs.toCall.first.balanceDue, isNull);
  });
}
