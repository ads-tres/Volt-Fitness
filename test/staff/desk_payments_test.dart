import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_mobile/core/errors/failure.dart';
import 'package:gym_mobile/core/money/money.dart';
import 'package:gym_mobile/core/network/api_client.dart';
import 'package:gym_mobile/core/time/local_date.dart';
import 'package:gym_mobile/staff/core/desk_session.dart';
import 'package:gym_mobile/staff/fake_front_desk.dart';
import 'package:gym_mobile/staff/features/payments/data/desk_payments_repository.dart';

import '../support/test_doubles.dart';

void main() {
  const main = DeskBranch(id: 1, name: 'Main Branch');
  Map<String, Object?> money(int minor) => {'amount_minor': minor, 'currency': 'ETB', 'formatted': '…'};

  Future<DeskPaymentsRepository> desk({
    StubAdapter? adapter,
    String phone = FakeFrontDesk.staffPhone,
    String gym = 'demo-gym',
  }) async {
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
      gyms: [DeskGym(slug: gym, name: gym, role: 'owner', worksAtAllBranches: true)],
    );
    await session.selectBranch(main);
    return container.read(deskPaymentsRepositoryProvider);
  }

  Future<String?> refusal(Future<void> Function() call, String field) async {
    try {
      await call();
    } on ValidationFailure catch (failure) {
      return failure.fieldErrors[field]?.single;
    }
    return null;
  }

  test('reads only the memberships with money due, with any open link', () async {
    final adapter = StubAdapter(
      (_) => jsonResponse(200, {
        'data': [
          {
            'id': 7,
            'plan': {'id': 2, 'name': 'Monthly'},
            'starts_on': '2026-10-02',
            'ends_on': '2026-11-01',
            'balance_due': money(50000),
            'cancellation': null,
            'open_payment_link': {'id': 40, 'amount': money(50000)},
          },
          {
            'id': 6,
            'plan': {'id': 2, 'name': 'Monthly'},
            'starts_on': '2026-09-02',
            'ends_on': '2026-10-01',
            'balance_due': money(0),
            'cancellation': null,
          },
          {
            'id': 5,
            'plan': {'id': 3, 'name': 'Yearly'},
            'starts_on': '2026-01-01',
            'ends_on': '2026-12-31',
            'balance_due': money(90000),
            'cancellation': {'cancelled_at': '2026-02-01T00:00:00Z', 'reason': null},
          },
        ],
      }),
    );
    final owing = await (await desk(adapter: adapter)).owing(3);

    expect(adapter.requests.single.path, '/organizations/demo-gym/members/3/memberships');
    expect(owing, hasLength(1));
    expect(owing.single.id, 7);
    expect(owing.single.planName, 'Monthly');
    expect(owing.single.balanceDue, const Money(50000, 'ETB'));
    expect(owing.single.openLinkId, 40);
  });

  test('sends a payment as the API reads it, at the desk\'s branch', () async {
    final adapter = StubAdapter(
      (_) => jsonResponse(201, {
        'data': {'id': 1, 'receipt_number': 'R-000042', 'amount': money(50050)},
      }),
    );
    final payments = await desk(adapter: adapter);

    final cash = await payments.record(7, amount: const Money(50050, 'ETB'), method: DeskPaymentMethod.cash, reference: 'x');
    await payments.record(
      7,
      amount: const Money(100000, 'ETB'),
      method: DeskPaymentMethod.telebirr,
      reference: ' TB123 ',
      paidOn: LocalDate(2026, 10, 13),
    );

    expect(cash.receiptNumber, 'R-000042');
    expect(adapter.requests.first.path, '/organizations/demo-gym/memberships/7/payments');
    expect(adapter.requests.first.data, {'amount': '500.50', 'method': 'cash', 'branch_id': 1});
    expect(adapter.requests.last.data, {
      'amount': '1000.00',
      'method': 'telebirr',
      'reference': 'TB123',
      'branch_id': 1,
      'paid_on': '2026-10-13',
    });
  });

  test('the fake takes what is due, refuses more, and wants a transaction number for transfers', () async {
    final payments = await desk();
    final abebe = (await payments.owing(1)).single;
    expect(abebe.balanceDue, const Money(100000, 'ETB'));

    expect(
      await refusal(() => payments.record(abebe.id, amount: const Money(40000, 'ETB'), method: DeskPaymentMethod.telebirr), 'reference'),
      'Enter the transaction number from the payment confirmation.',
    );
    expect(
      await refusal(() => payments.record(abebe.id, amount: const Money(100001, 'ETB'), method: DeskPaymentMethod.cash), 'amount'),
      'Only 1,000.00 ETB is still due on this membership.',
    );

    final receipt = await payments.record(abebe.id, amount: const Money(40000, 'ETB'), method: DeskPaymentMethod.cash);
    expect(receipt.receiptNumber, 'R-000001');
    expect((await payments.owing(1)).single.balanceDue, const Money(60000, 'ETB'));

    await payments.record(abebe.id, amount: const Money(60000, 'ETB'), method: DeskPaymentMethod.cbeBirr, reference: 'FT1');
    expect(await payments.owing(1), isEmpty);
  });

  test('the fake texts a pay link once every few minutes, and only where Chapa is connected', () async {
    final payments = await desk();
    await payments.textNewLink(101, amount: const Money(100000, 'ETB'));
    final linkId = (await payments.owing(1)).single.openLinkId!;

    expect(
      await refusal(() => payments.textNewLink(101, amount: const Money(100000, 'ETB')), 'membership'),
      'This membership already has an open payment link. Cancel it to create a new one.',
    );
    expect(
      await refusal(() => payments.textLink(linkId), 'payment_link'),
      'The link was texted to the member a moment ago. Wait a few minutes before sending it again.',
    );

    final bole = await desk(phone: FakeFrontDesk.twoGymsPhone, gym: 'bole-fitness');
    expect(
      await refusal(() => bole.textNewLink(101, amount: const Money(100000, 'ETB')), 'chapa_account'),
      "Connect the gym's Chapa account first.",
    );
  });
}
