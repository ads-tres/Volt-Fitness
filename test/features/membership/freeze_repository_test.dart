import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_mobile/core/errors/failure.dart';
import 'package:gym_mobile/core/time/local_date.dart';
import 'package:gym_mobile/features/membership/data/freeze_repository.dart';
import 'package:gym_mobile/features/membership/domain/membership.dart';

import '../../support/test_doubles.dart';

Map<String, Object?> membership({required String endsOn, List<Map<String, Object?>> freezes = const []}) => {
  'id': 7,
  'plan': {'id': 2, 'name': 'Monthly'},
  'status': 'active',
  'starts_on': '2026-10-02',
  'ends_on': endsOn,
  'valid_at_all_branches': true,
  'freeze_days_allowed': 7,
  'freeze_days_left': 7 - freezes.fold(0, (days, freeze) => days + (freeze['days']! as int)),
  'freezes': freezes,
};

void main() {
  const today = LocalDate(2026, 10, 14);

  test('freezes and ends a freeze in the gym\'s path, and reads the membership back', () async {
    final adapter = StubAdapter(
      (request) => request.path.endsWith('/end')
          ? jsonResponse(200, {'data': membership(endsOn: '2026-11-01')})
          : jsonResponse(201, {
              'data': membership(
                endsOn: '2026-11-04',
                freezes: [
                  {'id': 31, 'starts_on': '2026-10-20', 'ends_on': '2026-10-22', 'days': 3},
                ],
              ),
            }),
    );
    final container = await containerWithAdapter(adapter, signedInAs: memberOf([boleGym]));
    final freezes = container.read(freezeRepositoryProvider);

    final frozen = await freezes.freeze(
      '7',
      startsOn: const LocalDate(2026, 10, 20),
      endsOn: const LocalDate(2026, 10, 22),
      reason: '  Travelling  ',
    );
    final back = await freezes.endFreeze('7', '31');
    await freezes.freeze('7', startsOn: today, endsOn: today, reason: ' ');

    expect(adapter.requests.map((request) => '${request.method} ${request.path}'), [
      'POST /me/gyms/bole-iron-gym/memberships/7/freezes',
      'POST /me/gyms/bole-iron-gym/memberships/7/freezes/31/end',
      'POST /me/gyms/bole-iron-gym/memberships/7/freezes',
    ]);
    expect(adapter.requests.first.data, {'starts_on': '2026-10-20', 'ends_on': '2026-10-22', 'reason': 'Travelling'});
    expect(adapter.requests.last.data, {'starts_on': '2026-10-14', 'ends_on': '2026-10-14'}, reason: 'a blank reason is left out');
    expect(frozen.endsOn, const LocalDate(2026, 11, 4));
    expect(frozen.freezeDaysLeft, 4);
    expect(frozen.freezes.single.id, '31');
    expect(back.endsOn, const LocalDate(2026, 11, 1));
  });

  test('a refusal is a validation failure naming its field', () async {
    final adapter = StubAdapter(
      (_) => jsonResponse(422, {
        'message': 'Only 2 freeze days are left on this membership.',
        'errors': {
          'ends_on': ['Only 2 freeze days are left on this membership.'],
        },
      }),
    );
    final container = await containerWithAdapter(adapter, signedInAs: memberOf([boleGym]));

    await expectLater(
      container.read(freezeRepositoryProvider).freeze('7', startsOn: today, endsOn: today.addDays(6)),
      throwsA(
        isA<ValidationFailure>().having(
          (failure) => failure.fieldErrors['ends_on'],
          'ends_on',
          ['Only 2 freeze days are left on this membership.'],
        ),
      ),
    );
  });

  group('the fake backend', () {
    Future<FreezeRepository> repository() async {
      final container = ProviderContainer.test(
        overrides: await testOverrides(signedInAs: memberOf([boleGym]), fakeBackend: true),
      );
      return container.read(freezeRepositoryProvider);
    }

    Future<String> refusal(Future<Membership> attempt) async {
      try {
        await attempt;
      } on ValidationFailure catch (failure) {
        return failure.fieldErrors.keys.single;
      }
      fail('The freeze was not refused');
    }

    test('freezes within the days left, moves the end date, and gives the days back when ended', () async {
      final freezes = await repository();

      final frozen = await freezes.freeze('101', startsOn: today.addDays(2), endsOn: today.addDays(4));
      expect(frozen.endsOn, today.addDays(21), reason: 'three days later than the 18 left');
      expect(frozen.freezeDaysLeft, 4);
      expect(frozen.currentOrNextFreeze(today)?.days, 3);

      final back = await freezes.endFreeze('101', frozen.freezes.single.id);
      expect(back.endsOn, today.addDays(18));
      expect(back.freezes, isEmpty, reason: 'a freeze that hadn\'t started is cancelled');
      expect(back.freezeDaysLeft, 7);
    });

    test('refuses a past start, more days than are left, and a freeze over another', () async {
      final freezes = await repository();

      expect(await refusal(freezes.freeze('101', startsOn: today.addDays(-1), endsOn: today)), 'starts_on');
      expect(await refusal(freezes.freeze('101', startsOn: today, endsOn: today.addDays(7))), 'ends_on');
      await freezes.freeze('101', startsOn: today, endsOn: today.addDays(1));
      expect(await refusal(freezes.freeze('101', startsOn: today.addDays(1), endsOn: today.addDays(2))), 'starts_on');
    });
  });
}
