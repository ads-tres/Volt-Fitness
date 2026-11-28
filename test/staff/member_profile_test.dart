import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_mobile/core/money/money.dart';
import 'package:gym_mobile/core/network/api_client.dart';
import 'package:gym_mobile/core/time/local_date.dart';
import 'package:gym_mobile/staff/core/desk_session.dart';
import 'package:gym_mobile/staff/fake_front_desk.dart';
import 'package:gym_mobile/staff/features/member/data/member_profile_repository.dart';
import 'package:gym_mobile/staff/features/payments/data/desk_payments_repository.dart';

import '../support/test_doubles.dart';

void main() {
  Map<String, Object?> money(int minor) => {'amount_minor': minor, 'currency': 'ETB', 'formatted': '…'};

  Future<ProviderContainer> desk({StubAdapter? adapter}) async {
    final container = ProviderContainer.test(
      overrides: await testOverrides(
        fakeBackend: adapter == null,
        fakeAdapter: FakeFrontDesk(latency: Duration.zero, now: () => testNow),
      ),
    );
    if (adapter != null) container.read(dioProvider).httpClientAdapter = adapter;
    final session = container.read(deskSessionProvider.notifier);
    await session.signIn(
      token: adapter == null ? 'fake-desk-token:${FakeFrontDesk.staffPhone}' : '9|desk',
      name: 'Demo',
      gyms: [const DeskGym(slug: 'demo-gym', name: 'Demo Gym', role: 'owner', worksAtAllBranches: true)],
    );
    await session.selectBranch(const DeskBranch(id: 1, name: 'Main Branch'));
    return container;
  }

  test('reads a member with their details, and pages of their receipts by member', () async {
    final adapter = StubAdapter(
      (request) => request.path.endsWith('/payments')
          ? jsonResponse(200, {
              'data': [
                {
                  'id': 5,
                  'receipt_number': 'R-1',
                  'type': 'refund',
                  'amount': money(20000),
                  'method': 'brought_in',
                  'paid_on': '2026-09-09',
                  'membership': {
                    'id': 7,
                    'plan': {'id': 2, 'name': 'Monthly'},
                  },
                  'void': {'voided_at': '2026-09-10T00:00:00Z', 'reason': 'Typo'},
                },
              ],
              'links': {'next': '?page=2'},
            })
          : jsonResponse(200, {
              'data': {
                'id': 3,
                'full_name': 'Hana Girma',
                'phone': '+251933456789',
                'gender': 'female',
                'date_of_birth': '1999-01-31',
                'emergency_contact': {'name': 'Girma', 'phone': '+251911000000'},
                'message_language': 'am',
                'home_branch': {'id': 1, 'name': 'Main Branch'},
                'membership': {
                  'id': 7,
                  'plan': {'id': 2, 'name': 'Monthly'},
                  'status': 'frozen',
                  'starts_on': '2026-10-02',
                  'ends_on': '2026-11-04',
                },
                'balance_due': money(0),
                'discount_group': {'id': 1, 'name': 'Student'},
                'registered_at': '2026-09-01T07:00:00Z',
              },
            }),
    );
    final repository = (await desk(adapter: adapter)).read(memberProfileRepositoryProvider);

    final hana = await repository.member(3);
    expect(hana.status, 'frozen');
    expect(hana.endsOn, LocalDate(2026, 11, 4));
    expect(hana.emergencyContactPhone, '+251911000000');
    expect(hana.discountGroupName, 'Student');
    expect(hana.registeredOn, LocalDate(2026, 9, 1));

    final receipts = await repository.payments(3, page: 2);
    expect(adapter.requests.last.path, '/organizations/demo-gym/payments');
    expect(adapter.requests.last.queryParameters, {'member_id': 3, 'page': 2});
    expect(receipts.hasMore, isTrue);
    expect(receipts.items.single.isRefund, isTrue);
    expect(receipts.items.single.voided, isTrue);
    expect(receipts.items.single.planName, 'Monthly');
  });

  test('the fake lists a member\'s payments and visits, newest first, with those made at the desk', () async {
    final container = await desk();
    final repository = container.read(memberProfileRepositoryProvider);

    expect([for (final receipt in (await repository.payments(1)).items) receipt.receiptNumber], ['R-2026-0090']);
    expect((await repository.payments(2)).items.single.method, 'brought_in');

    await container.read(deskPaymentsRepositoryProvider).record(101, amount: const Money(30000, 'ETB'), method: DeskPaymentMethod.cash);
    expect([for (final receipt in (await repository.payments(1)).items) receipt.receiptNumber], ['R-000001', 'R-2026-0090']);
    expect((await repository.member(1)).balanceDue, const Money(70000, 'ETB'));

    final visits = await repository.visits(1);
    expect(visits.items, isNotEmpty);
    expect(visits.items.every((visit) => visit.memberName == 'Abebe Kebede'), isTrue);
  });
}
