import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_mobile/core/errors/failure.dart';
import 'package:gym_mobile/core/money/money.dart';
import 'package:gym_mobile/core/network/api_client.dart';
import 'package:gym_mobile/core/time/local_date.dart';
import 'package:gym_mobile/staff/core/desk_session.dart';
import 'package:gym_mobile/staff/fake_front_desk.dart';
import 'package:gym_mobile/staff/features/payments/data/desk_payments_repository.dart';
import 'package:gym_mobile/staff/features/plans/data/desk_plans_repository.dart';

import '../support/test_doubles.dart';

void main() {
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
    await session.signIn(
      token: adapter == null ? 'fake-desk-token:$phone' : '9|desk',
      name: 'Demo',
      gyms: [
        DeskGym(slug: 'demo-gym', name: 'Demo Gym', role: phone == FakeFrontDesk.staffPhone ? 'owner' : 'receptionist', worksAtAllBranches: true),
      ],
    );
    await session.selectBranch(const DeskBranch(id: 1, name: 'Main Branch'));
    return container;
  }

  Future<String?> refusal(Future<void> Function() call, String field) async {
    try {
      await call();
    } on ValidationFailure catch (failure) {
      return failure.fieldErrors[field]?.single;
    }
    return null;
  }

  test('reads the gym\'s plans, with the branches of those not good everywhere', () async {
    final adapter = StubAdapter(
      (_) => jsonResponse(200, {
        'data': [
          {
            'id': 4,
            'name': '10 visits',
            'price': money(120000),
            'duration': {'count': 2, 'unit': 'month'},
            'visit_limit': 10,
            'available_at_all_branches': false,
            'branches': [
              {'id': 1, 'name': 'Main Branch'},
            ],
          },
          {
            'id': 2,
            'name': 'Monthly',
            'price': money(150000),
            'duration': {'count': 1, 'unit': 'month'},
            'visit_limit': null,
            'available_at_all_branches': true,
          },
        ],
      }),
    );
    final plans = await (await desk(adapter: adapter)).read(deskPlansRepositoryProvider).plans();

    expect(adapter.requests.single.path, '/organizations/demo-gym/plans');
    expect(plans.first.visitLimit, 10);
    expect(plans.first.branchNames, ['Main Branch']);
    expect(plans.last.branchNames, isEmpty);
    expect(plans.last.price, const Money(150000, 'ETB'));
  });

  test('sends only what was chosen, and reads the sold membership', () async {
    final adapter = StubAdapter(
      (_) => jsonResponse(201, {
        'data': {
          'id': 9,
          'plan': {'id': 2, 'name': 'Monthly'},
          'starts_on': '2026-11-02',
          'ends_on': '2026-12-01',
          'price': money(135000),
          'balance_due': money(135000),
        },
      }),
    );
    final plans = (await desk(adapter: adapter)).read(deskPlansRepositoryProvider);

    final sold = await plans.sell(1, 2, promoCode: ' VOLT10 ', discount: '  ');
    await plans.sell(1, 2, startsOn: LocalDate(2026, 11, 2), discount: '10%', discountReason: ' Loyal member ');

    expect(adapter.requests.first.path, '/organizations/demo-gym/members/1/memberships');
    expect(adapter.requests.first.data, {'plan_id': 2, 'promo_code': 'VOLT10'});
    expect(adapter.requests.last.data, {
      'plan_id': 2,
      'starts_on': '2026-11-02',
      'discount': '10%',
      'discount_reason': 'Loyal member',
    });
    expect(sold.endsOn, LocalDate(2026, 12, 1));
    expect(sold.balanceDue, const Money(135000, 'ETB'));
  });

  test('the fake sells from the first free day, refuses a clash, and owes the price', () async {
    final container = await desk();
    final plans = container.read(deskPlansRepositoryProvider);

    final renewal = await plans.sell(1, 2);
    expect(renewal.startsOn, LocalDate(2026, 11, 2), reason: "the day after Abebe's plan ends");
    expect(renewal.endsOn, LocalDate(2026, 12, 1));

    expect(
      await refusal(() => plans.sell(1, 2, startsOn: LocalDate(2026, 11, 20)), 'starts_on'),
      'The member already has a membership from 2 November 2026 to 1 December 2026. '
      'The first free start date is 2 December 2026.',
    );

    final owing = await container.read(deskPaymentsRepositoryProvider).owing(1);
    expect([for (final each in owing) each.balanceDue.amountMinor], [150000, 100000]);
  });

  test('the fake takes VOLT10 off, and keeps past days and typed discounts for owners', () async {
    final owner = (await desk()).read(deskPlansRepositoryProvider);
    expect((await owner.sell(2, 2, promoCode: 'volt10')).price, const Money(135000, 'ETB'));
    expect(
      await refusal(() => owner.sell(3, 2, promoCode: 'NOPE', startsOn: LocalDate(2026, 12, 1)), 'promo_code'),
      "This promo code doesn't exist. Check how it is spelled.",
    );
    expect(
      (await owner.sell(3, 3, startsOn: LocalDate(2026, 12, 1), discount: '500', discountReason: 'Staff')).price,
      const Money(350000, 'ETB'),
    );

    final receptionist = (await desk(phone: FakeFrontDesk.twoGymsPhone)).read(deskPlansRepositoryProvider);
    expect(
      await refusal(() => receptionist.sell(2, 2, startsOn: LocalDate(2026, 10, 1)), 'starts_on'),
      'Only owners and managers can start a membership on a past date.',
    );
    expect(
      await refusal(() => receptionist.sell(2, 2, discount: '10%', discountReason: 'Friend'), 'discount'),
      'Only owners and managers can give a discount.',
    );
  });
}
