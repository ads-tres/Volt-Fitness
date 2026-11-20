import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_mobile/core/auth/profile.dart';
import 'package:gym_mobile/core/errors/failure.dart';
import 'package:gym_mobile/core/network/fake_backend.dart';
import 'package:gym_mobile/features/payments/data/billing_repository.dart';
import 'package:gym_mobile/features/payments/domain/billing.dart';

import '../../support/test_doubles.dart';

Map<String, Object?> money(int minor) => {'amount_minor': minor, 'currency': 'ETB', 'formatted': '…'};

void main() {
  test('buys a plan and pays what is owed through payment links in the gym\'s path', () async {
    final link = {
      'id': 31,
      'status': 'pending',
      'amount': money(250000),
      'checkout_url': 'https://checkout.chapa.co/checkout/payment/abc',
      'return_url': 'https://gym.test/payments/returned',
      'membership_id': null,
      'payment': null,
    };
    final adapter = StubAdapter((_) => jsonResponse(201, {'data': link}));
    final container = await containerWithAdapter(adapter, signedInAs: memberOf([boleGym]));
    final billing = container.read(billingRepositoryProvider);

    final bought = await billing.startPayment(planId: '2');
    await billing.startPayment(invoiceId: '7');
    await billing.check('31');

    expect(adapter.requests.map((request) => '${request.method} ${request.path}'), [
      'POST /me/gyms/bole-iron-gym/plans/2/purchase',
      'POST /me/gyms/bole-iron-gym/memberships/7/payment-link',
      'POST /me/gyms/bole-iron-gym/payment-links/31/check',
    ]);
    expect(bought.id, '31');
    expect(bought.status, PaymentStatus.pending);
    expect(bought.checkoutUrl, 'https://checkout.chapa.co/checkout/payment/abc');
    expect(bought.returnUrl, 'https://gym.test/payments/returned');
  });

  test('a paid link points at its receipt; one paid too late is a failure', () async {
    var status = 'paid';
    final adapter = StubAdapter(
      (_) => jsonResponse(200, {
        'data': {
          'id': 31,
          'status': status,
          'amount': money(250000),
          'checkout_url': null,
          'payment': {'id': 88, 'receipt_number': 'DG-000088', 'paid_on': '2026-10-14'},
        },
      }),
    );
    final container = await containerWithAdapter(adapter, signedInAs: memberOf([boleGym]));

    final paid = await container.read(billingRepositoryProvider).attempt('31');
    status = 'refund_needed';
    final tooLate = await container.read(billingRepositoryProvider).attempt('31');

    expect((paid.status, paid.invoiceId), (PaymentStatus.succeeded, '88'));
    expect(tooLate.status, PaymentStatus.failed);
  });

  test('reads plans with their length from the dates, and receipts as paid invoices', () async {
    final adapter = StubAdapter(
      (request) => switch (request.path) {
        '/me/gyms/bole-iron-gym/plans' => jsonResponse(200, {
          'data': [
            {
              'id': 2,
              'name': 'Monthly',
              'price': money(250000),
              'duration': {'count': 1, 'unit': 'month'},
              'starts_on': '2026-10-14',
              'ends_on': '2026-11-13',
            },
          ],
        }),
        _ => jsonResponse(200, {
          'data': [
            {
              'id': 88,
              'receipt_number': 'DG-000088',
              'type': 'payment',
              'amount': money(250000),
              'method': 'telebirr',
              'reference': 'FT2629',
              'paid_on': '2026-10-02',
              'membership': {
                'id': 7,
                'plan': {'id': 2, 'name': 'Monthly'},
              },
              'voided': true,
            },
          ],
        }),
      },
    );
    final container = await containerWithAdapter(adapter, signedInAs: memberOf([boleGym]));

    final plan = (await container.read(billingRepositoryProvider).plans()).single;
    final receipt = (await container.read(billingRepositoryProvider).invoices()).single;

    expect(plan.durationDays, 31);
    expect(adapter.requests.last.path, '/me/gyms/bole-iron-gym/payments');
    expect(receipt.number, 'DG-000088');
    expect(receipt.description, 'Monthly plan');
    expect(receipt.status, InvoiceStatus.voided);
    expect(receipt.receipt?.method, 'telebirr');
  });

  test('reads what the member pays: a group price, a code price, or the list price', () async {
    final adapter = StubAdapter(
      (_) => jsonResponse(200, {
        'data': [
          {
            'id': 2,
            'name': 'Monthly',
            'price': money(150000),
            'price_with_code': money(135000),
            'your_price': money(120000),
            'your_discount': {'source': 'discount_group', 'name': 'Student'},
            'starts_on': '2026-10-14',
            'ends_on': '2026-11-12',
          },
          {
            'id': 3,
            'name': 'Quarterly',
            'price': money(400000),
            'price_with_code': money(360000),
            'your_price': money(360000),
            'your_discount': {'source': 'promo_code', 'name': 'NEWYEAR'},
            'starts_on': '2026-10-14',
            'ends_on': '2027-01-11',
          },
          {
            'id': 4,
            'name': 'Annual',
            'price': money(1400000),
            'starts_on': '2026-10-14',
            'ends_on': '2027-10-13',
          },
        ],
      }),
    );
    final container = await containerWithAdapter(adapter, signedInAs: memberOf([boleGym]));

    final [monthly, quarterly, annual] = await container.read(billingRepositoryProvider).plans();

    expect((monthly.pays.amountMinor, monthly.discountName, monthly.discountFromCode), (120000, 'Student', false));
    expect(monthly.priceWithCode?.amountMinor, 135000);
    expect((quarterly.pays.amountMinor, quarterly.discountName, quarterly.discountFromCode), (360000, 'NEWYEAR', true));
    expect((annual.pays.amountMinor, annual.yourPrice, annual.discountName), (1400000, null, null));
  });

  test('asks for plans with the code, and buys with it', () async {
    final adapter = StubAdapter(
      (request) => request.method == 'GET'
          ? jsonResponse(200, {'data': <Object?>[]})
          : jsonResponse(201, {
              'data': {'id': 31, 'status': 'pending', 'amount': money(135000), 'checkout_url': 'https://checkout.chapa.co/x'},
            }),
    );
    final container = await containerWithAdapter(adapter, signedInAs: memberOf([boleGym]));
    final billing = container.read(billingRepositoryProvider);

    await billing.plans(promoCode: 'NEWYEAR');
    await billing.startPayment(planId: '2', promoCode: 'NEWYEAR');
    await billing.startPayment(planId: '3');

    expect(adapter.requests[0].queryParameters, {'promo_code': 'NEWYEAR'});
    expect(adapter.requests[1].data, {'promo_code': 'NEWYEAR'});
    expect(adapter.requests[2].data, isNull);
  });

  group('the fake backend\'s codes', () {
    Future<ProviderContainer> member(String phone) async => ProviderContainer.test(
      overrides: await testOverrides(
        fakeBackend: true,
        signedInAs: Profile(
          user: User(id: '01K7Z5B2W8R3M5N7Q9S1T3V5X0', name: 'Abebe Kebede', phone: phone),
          organizations: const [boleGym],
        ),
      ),
    );

    test('NEWYEAR lowers Monthly and Quarterly but not Annual; the better of code and group wins', () async {
      final container = await member('+251912345678');
      final codes = container.read(promoCodeProvider.notifier);
      await codes.apply('newyear');
      final plans = await container.read(plansProvider.future);

      expect(container.read(promoCodeProvider), 'NEWYEAR');
      expect([for (final plan in plans) (plan.name, plan.pays.amountMinor, plan.discountFromCode)], [
        ('Monthly', 135000, true),
        ('Quarterly', 360000, true),
        ('Annual', 1400000, false),
      ]);

      final student = await member(FakeBackend.studentPhone);
      await student.read(promoCodeProvider.notifier).apply('NEWYEAR');
      final monthly = (await student.read(plansProvider.future)).first;
      expect((monthly.pays.amountMinor, monthly.discountName), (120000, 'Student'), reason: '20% beats 10%');
    });

    test('a used or unknown code is refused with the API\'s reason and not applied', () async {
      final container = await member('+251912345678');

      await expectLater(
        container.read(promoCodeProvider.notifier).apply('USED'),
        throwsA(
          isA<ValidationFailure>().having(
            (failure) => failure.fieldErrors['promo_code'],
            'promo_code',
            ['You have already used this code.'],
          ),
        ),
      );
      expect(container.read(promoCodeProvider), isNull);
    });

    test('buying with the code charges its price', () async {
      final container = await member('+251912345678');
      final attempt = await container.read(billingRepositoryProvider).startPayment(planId: '11', promoCode: 'NEWYEAR');
      expect(attempt.amount.amountMinor, 135000);
    });
  });
}
