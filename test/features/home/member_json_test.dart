import 'package:flutter_test/flutter_test.dart';
import 'package:gym_mobile/core/time/local_date.dart';
import 'package:gym_mobile/features/attendance/domain/visit.dart';
import 'package:gym_mobile/features/home/data/member_json.dart';
import 'package:gym_mobile/features/membership/domain/membership.dart';

void main() {
  Map<String, Object?> membership({required int balanceMinor, bool allBranches = true}) => {
    'id': 7,
    'plan': {'id': 2, 'name': 'Monthly'},
    'status': 'active',
    'starts_on': '2026-10-02',
    'ends_on': '2026-11-01',
    'balance_due': {'amount_minor': balanceMinor, 'currency': 'ETB', 'formatted': '…'},
    'valid_at_all_branches': allBranches,
    'branches': [
      {'id': 2, 'code': 'BOLE', 'name': 'Bole Branch', 'address': null},
    ],
    'visits_remaining': 4,
    'frozen_until': null,
  };

  test('reads the API\'s home screen: the membership, its balance and the latest check-ins', () {
    final dashboard = dashboardFromJson({
      'membership': membership(balanceMinor: 100000, allBranches: false),
      'next_membership': null,
      'recent_check_ins': [
        {
          'id': 5,
          'decision': 'deny',
          'reason_code': 'OUTSIDE_HOURS',
          'method': 'qr',
          'checked_in_at': '2026-10-14T06:05:00+03:00',
          'branch': {'id': 2, 'code': 'BOLE', 'name': 'Bole Branch', 'address': null},
        },
      ],
      'balance_due': {'amount_minor': 100000, 'currency': 'ETB', 'formatted': '…'},
    });

    expect(dashboard.membership?.planName, 'Monthly');
    expect(dashboard.membership?.visitsRemaining, 4);
    expect(dashboard.membership?.allowedBranches.single.name, 'Bole Branch');
    expect(dashboard.outstanding?.invoiceId, '7', reason: 'paid towards the membership');
    expect(dashboard.outstanding?.amount.amountMinor, 100000);
    expect(dashboard.recentVisits.single.result, VisitResult.denied);
    expect(dashboard.recentVisits.single.checkedInAt, DateTime.utc(2026, 10, 14, 3, 5));
  });

  test('nothing owed means no due card; all branches lists none; upcoming is pending', () {
    final dashboard = dashboardFromJson({'membership': membership(balanceMinor: 0), 'recent_check_ins': <Object?>[]});

    expect(dashboard.outstanding, isNull);
    expect(dashboard.membership?.allowedBranches, isEmpty);
    expect(membershipFromJson({...membership(balanceMinor: 0), 'status': 'upcoming'}).status, MembershipStatus.pending);
  });

  test('reads the freeze days and each freeze, and finds the one covering today or coming next', () {
    final frozen = membershipFromJson({
      ...membership(balanceMinor: 0),
      'freeze_days_allowed': 14,
      'freeze_days_left': 4,
      'freezes': [
        {'id': 3, 'starts_on': '2026-10-01', 'ends_on': '2026-10-03', 'days': 3},
        {'id': 9, 'starts_on': '2026-10-20', 'ends_on': '2026-10-26', 'days': 7},
      ],
    });

    expect(frozen.freezeDaysAllowed, 14);
    expect(frozen.freezeDaysLeft, 4);
    expect(frozen.canFreeze, isTrue);
    expect(frozen.freezes.map((freeze) => freeze.id), ['3', '9']);
    final next = frozen.currentOrNextFreeze(const LocalDate(2026, 10, 14));
    expect(next?.id, '9');
    expect(next?.days, 7);
    expect(next?.hasStarted(const LocalDate(2026, 10, 14)), isFalse);
    expect(frozen.currentOrNextFreeze(const LocalDate(2026, 10, 27)), isNull);
  });

  test('no freeze days left, an expired plan, or an older response without the fields can\'t freeze', () {
    expect(membershipFromJson({...membership(balanceMinor: 0), 'freeze_days_left': 0}).canFreeze, isFalse);
    expect(
      membershipFromJson({...membership(balanceMinor: 0), 'status': 'expired', 'freeze_days_left': 7}).canFreeze,
      isFalse,
    );
    final older = membershipFromJson(membership(balanceMinor: 0));
    expect(older.canFreeze, isFalse);
    expect(older.freezes, isEmpty);
  });
}
