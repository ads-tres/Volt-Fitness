import 'package:flutter_test/flutter_test.dart';
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
    expect(bought.returnUrl, isNull);
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
}
