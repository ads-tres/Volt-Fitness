import 'package:flutter_test/flutter_test.dart';
import 'package:gym_mobile/features/gyms/data/branches_repository.dart';
import 'package:gym_mobile/features/gyms/domain/gym_branch.dart';

void main() {
  // Monday to Saturday 06:00 to 22:00; closed on Sunday.
  final bole = gymBranchFromJson({
    'id': 1,
    'name': 'Bole',
    'opening_hours': [
      for (var weekday = 1; weekday <= 6; weekday++) {'weekday': weekday, 'opens_at': '06:00', 'closes_at': '22:00'},
    ],
  });

  test('reads a week of hours as minutes', () {
    expect(bole.hours, hasLength(6));
    expect((bole.hoursOn(2)?.opensAt, bole.hoursOn(2)?.closesAt), (360, 1320));
    expect(bole.hoursOn(7), isNull);
  });

  test('open from the opening minute until the closing one, as at the door', () {
    final tuesday = DateTime(2026, 10, 13);
    expect(bole.isOpenAt(tuesday.add(const Duration(hours: 5, minutes: 59))), isFalse);
    expect(bole.isOpenAt(tuesday.add(const Duration(hours: 6))), isTrue);
    expect(bole.closesAfter(tuesday.add(const Duration(hours: 9))), DateTime(2026, 10, 13, 22));
    expect(bole.isOpenAt(tuesday.add(const Duration(hours: 22))), isFalse);
  });

  test('a closed branch opens next later today, or on its next open weekday', () {
    expect(bole.nextOpening(DateTime(2026, 10, 13, 5)), DateTime(2026, 10, 13, 6));
    expect(bole.nextOpening(DateTime(2026, 10, 17, 23)), DateTime(2026, 10, 19, 6), reason: 'Saturday night: Monday');
    expect(bole.isOpenAt(DateTime(2026, 10, 18, 10)), isFalse, reason: 'no hours on Sunday: closed');
  });

  test('a branch with no hours at all is always open', () {
    const megenagna = GymBranch(id: '2', name: 'Megenagna');
    expect(megenagna.alwaysOpen, isTrue);
    expect(megenagna.isOpenAt(DateTime(2026, 10, 18, 3)), isTrue);
    expect(megenagna.nextOpening(DateTime(2026, 10, 18, 3)), isNull);
  });

  test('hours closing before they open run past midnight', () {
    // Friday 18:00 to 02:00.
    final late = gymBranchFromJson({
      'id': 3,
      'name': 'Kazanchis',
      'opening_hours': [
        {'weekday': 5, 'opens_at': '18:00', 'closes_at': '02:00'},
      ],
    });
    expect(late.hoursOn(5)?.pastMidnight, isTrue);
    expect(late.isOpenAt(DateTime(2026, 10, 16, 23)), isTrue, reason: 'Friday night');
    expect(late.closesAfter(DateTime(2026, 10, 16, 23)), DateTime(2026, 10, 17, 2));
    expect(late.isOpenAt(DateTime(2026, 10, 17, 1, 30)), isTrue, reason: 'early Saturday, on Friday\'s hours');
    expect(late.isOpenAt(DateTime(2026, 10, 17, 2)), isFalse);
  });

  test('a closure decides its dates: closed all day, or open other hours', () {
    final withClosures = gymBranchFromJson({
      'id': 1,
      'name': 'Bole',
      'opening_hours': [
        for (var weekday = 1; weekday <= 6; weekday++) {'weekday': weekday, 'opens_at': '06:00', 'closes_at': '22:00'},
      ],
      'closures': [
        {
          'id': 8,
          'starts_on': '2026-10-15',
          'ends_on': '2026-10-15',
          'reason': 'Short day',
          'opens_at': '08:00',
          'closes_at': '12:00',
          'repeats_yearly': false,
          'ethiopian_date': 'Tikimt 5',
        },
        {
          'id': 7,
          'starts_on': '2026-10-14',
          'ends_on': '2026-10-14',
          'reason': 'Holiday',
          'opens_at': null,
          'closes_at': null,
          'repeats_yearly': true,
          'ethiopian_date': 'Tikimt 4',
        },
      ],
    });

    expect(withClosures.closures.map((closure) => closure.id), ['7', '8'], reason: 'soonest first');
    expect(withClosures.closures.first.repeatsYearly, isTrue);
    expect(withClosures.isOpenAt(DateTime(2026, 10, 14, 10)), isFalse, reason: 'closed all day for the holiday');
    expect(withClosures.nextOpening(DateTime(2026, 10, 14, 10)), DateTime(2026, 10, 15, 8));
    expect(withClosures.isOpenAt(DateTime(2026, 10, 15, 13)), isFalse, reason: 'only 08:00 to 12:00 that day');
    expect(withClosures.closesAfter(DateTime(2026, 10, 15, 9)), DateTime(2026, 10, 15, 12));

    final alwaysOpen = gymBranchFromJson({
      'id': 2,
      'name': 'Megenagna',
      'closures': [
        {'id': 9, 'starts_on': '2026-10-14', 'ends_on': '2026-10-14', 'opens_at': null, 'closes_at': null},
      ],
    });
    expect(alwaysOpen.isOpenAt(DateTime(2026, 10, 14, 10)), isFalse, reason: 'a closure closes even an always-open branch');
  });
}
