import 'package:flutter_test/flutter_test.dart';
import 'package:gym_mobile/core/access/gq1.dart';
import 'package:gym_mobile/staff/features/offline/domain/door_check.dart';
import 'package:gym_mobile/staff/features/offline/domain/door_list.dart';

void main() {
  const abebe = '01K7Z3M6Q8V2N4R5T9W1X0YAB1';
  const hana = '01K7Z3M6Q8V2N4R5T9W1X0YAB3';
  List<int> secret(String id) => List<int>.filled(32, id.codeUnitAt(25));

  // Tuesday 14 October 2026, 09:30 at the gym.
  final now = DateTime(2026, 10, 14, 9, 30);
  String code(String id, DateTime at, {int stepOffset = 0}) =>
      Gq1.payload(secret(id), id, Gq1.stepAt(at) + stepOffset);

  DoorList list({
    DoorDay abebeDay = const DoorDay(allowed: true, planName: 'Monthly'),
    DoorDay hanaDay = const DoorDay(allowed: true, planName: '10 Visits', branchIds: [1], visitsLeft: 1),
    Map<String, DoorHours?>? hours,
    int? abebeLastUsedStep,
  }) {
    final utcDay = Gq1.utcDayOf(Gq1.stepAt(now));
    DoorCredential credential(String id, int memberId, String name, DoorDay day, {int? lastUsedStep}) => DoorCredential(
      id: id,
      lastUsedStep: lastUsedStep,
      dayKeys: {for (final day in [utcDay, utcDay + 1]) day: Gq1.dayKey(secret(id), day)},
      memberId: memberId,
      memberName: name,
      days: {'2026-10-13': day, '2026-10-14': day, '2026-10-15': day},
    );
    return DoorList(
      gymSlug: 'demo-gym',
      generatedAt: now.toUtc(),
      validUntil: now.toUtc().add(const Duration(days: 1)),
      credentials: {
        abebe: credential(abebe, 1, 'Abebe Kebede', abebeDay, lastUsedStep: abebeLastUsedStep),
        hana: credential(hana, 3, 'Hana Girma', hanaDay),
      },
      hours: {
        1: hours ?? {'2026-10-13': (opensAt: 300, closesAt: 1380), '2026-10-14': (opensAt: 300, closesAt: 1380)},
        2: {'2026-10-14': null},
      },
    );
  }

  DoorDecision decide(DoorList list, String payload, {DateTime? at, int branchId = 1, DoorMemory? memory}) =>
      DoorCheck.decide(list: list, payload: payload, branchId: branchId, now: at ?? now, memory: memory ?? DoorMemory());

  test('a member\'s fresh code lets them in, by name, and is remembered', () {
    final memory = DoorMemory();
    final decision = decide(list(), code(abebe, now), memory: memory);

    expect((decision.letIn, decision.credential?.memberName, decision.day?.planName), (true, 'Abebe Kebede', 'Monthly'));
    expect(memory.lastUsedSteps[abebe], Gq1.stepAt(now));
    expect(memory.lastLetIn[1], now.toUtc());
  });

  test('1 and 3: not a GQ1 code, an unknown credential, or a forged code is invalid, with no member', () {
    expect(decide(list(), 'hello').reasonCode, 'CREDENTIAL_INVALID');
    expect(decide(list(), code('01K7Z3M6Q8V2N4R5T9W1X0YAB9', now)).reasonCode, 'CREDENTIAL_INVALID');
    final forged = '${code(abebe, now).substring(0, code(abebe, now).length - 4)}0000';
    final decision = decide(list(), forged);
    expect((decision.reasonCode, decision.credential), ('CREDENTIAL_INVALID', null));
  });

  test('2: a code more than a step from the scanner\'s clock has expired', () {
    expect(decide(list(), code(abebe, now, stepOffset: -1)).letIn, isTrue);
    final decision = decide(list(), code(abebe, now, stepOffset: -2));
    expect((decision.reasonCode, decision.credential?.memberName), ('CODE_EXPIRED', 'Abebe Kebede'));
  });

  test('4: a code no later than the last one used is already used', () {
    final memory = DoorMemory();
    decide(list(), code(abebe, now), memory: memory);
    expect(decide(list(), code(abebe, now), memory: memory).reasonCode, 'CODE_ALREADY_USED');
    expect(decide(list(abebeLastUsedStep: Gq1.stepAt(now)), code(abebe, now)).reasonCode, 'CODE_ALREADY_USED');
  });

  test('5: outside the branch\'s hours, counting hours past midnight', () {
    final early = list(hours: {'2026-10-14': (opensAt: 600, closesAt: 1320)});
    expect(decide(early, code(abebe, now)).reasonCode, 'OUTSIDE_HOURS', reason: 'opens at 10:00');
    expect(decide(list(), code(abebe, now), branchId: 2).reasonCode, 'OUTSIDE_HOURS', reason: 'closed that date');

    final lateNight = list(hours: {'2026-10-13': (opensAt: 1080, closesAt: 120), '2026-10-14': null});
    final halfPastOne = DateTime(2026, 10, 14, 1, 30);
    expect(decide(lateNight, code(abebe, halfPastOne), at: halfPastOne).letIn, isTrue, reason: 'Monday 18:00–02:00');
    final three = DateTime(2026, 10, 14, 3);
    expect(decide(lateNight, code(abebe, three), at: three).reasonCode, 'OUTSIDE_HOURS');
  });

  test('6: the membership\'s reason, another branch, or a pack used up', () {
    final ended = list(abebeDay: const DoorDay(allowed: false, reasonCode: 'MEMBERSHIP_EXPIRED'));
    expect(decide(ended, code(abebe, now)).reasonCode, 'MEMBERSHIP_EXPIRED');

    final elsewhere = list(hours: {'2026-10-14': (opensAt: 300, closesAt: 1380)});
    final atBole = DoorList(
      gymSlug: elsewhere.gymSlug,
      generatedAt: elsewhere.generatedAt,
      validUntil: elsewhere.validUntil,
      credentials: elsewhere.credentials,
      hours: {...elsewhere.hours, 2: {'2026-10-14': (opensAt: 300, closesAt: 1380)}},
    );
    expect(decide(atBole, code(hana, now), branchId: 2).reasonCode, 'BRANCH_NOT_ALLOWED');

    final usedUp = list(hanaDay: const DoorDay(allowed: true, branchIds: [1], visitsLeft: 0));
    expect(decide(usedUp, code(hana, now)).reasonCode, 'VISITS_USED_UP');
  });

  test('6 and 7: the last visit counts once a day, and nobody is let in twice in five minutes', () {
    final memory = DoorMemory();
    expect(decide(list(), code(hana, now), memory: memory).letIn, isTrue, reason: 'the last visit');

    final twoMinutesLater = now.add(const Duration(minutes: 2));
    expect(decide(list(), code(hana, twoMinutesLater), at: twoMinutesLater, memory: memory).reasonCode, 'ALREADY_CHECKED_IN');

    final anHourLater = now.add(const Duration(hours: 1));
    expect(decide(list(), code(hana, anHourLater), at: anHourLater, memory: memory).letIn, isTrue, reason: 'already came in today');

    final restored = DoorMemory.fromJson(memory.toJson());
    expect(restored.cameIn, memory.cameIn);
    expect(restored.lastLetIn, memory.lastLetIn);
  });
}
