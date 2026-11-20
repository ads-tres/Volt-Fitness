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
}
