import '../../../../core/access/gq1.dart';
import 'door_list.dart';

/// What the door decided offline, and about whom when the code was real.
final class DoorDecision {
  const DoorDecision({required this.letIn, this.reasonCode, this.credential, this.day});

  final bool letIn;

  /// Why not, as the API's reason codes.
  final String? reasonCode;

  /// The member's credential, when the code was theirs; none for an
  /// unknown or forged code, as the server shows no member then.
  final DoorCredential? credential;

  /// What their membership allowed that date.
  final DoorDay? day;
}

/// What the desk remembers between offline scans, so codes, visits and the
/// 5-minute rule hold until the scans reach the server: the highest step
/// seen per credential, who came in on which date, and when each member was
/// last let in.
final class DoorMemory {
  DoorMemory({Map<String, int>? lastUsedSteps, Map<String, int>? cameIn, Map<int, DateTime>? lastLetIn})
    : lastUsedSteps = lastUsedSteps ?? {},
      cameIn = cameIn ?? {},
      lastLetIn = lastLetIn ?? {};

  /// Credential id to the highest step scanned here.
  final Map<String, int> lastUsedSteps;

  /// `memberId|date` to the visits counted here that date (one, or none).
  final Map<String, int> cameIn;

  /// Member id to when they were last let in, in UTC.
  final Map<int, DateTime> lastLetIn;

  Map<String, Object?> toJson() => {
    'last_used_steps': lastUsedSteps,
    'came_in': cameIn,
    'last_let_in': {for (final MapEntry(:key, :value) in lastLetIn.entries) '$key': value.toUtc().toIso8601String()},
  };

  static DoorMemory fromJson(Map<String, dynamic> json) => DoorMemory(
    lastUsedSteps: {
      for (final MapEntry(:key, :value) in ((json['last_used_steps'] as Map<String, dynamic>?) ?? const {}).entries)
        if (value is int) key: value,
    },
    cameIn: {
      for (final MapEntry(:key, :value) in ((json['came_in'] as Map<String, dynamic>?) ?? const {}).entries)
        if (value is int) key: value,
    },
    lastLetIn: {
      for (final MapEntry(:key, :value) in ((json['last_let_in'] as Map<String, dynamic>?) ?? const {}).entries)
        if (value is String) int.parse(key): DateTime.parse(value).toUtc(),
    },
  );
}

/// Decides a scan offline exactly as the contract's seven steps, in order
/// (the API's ADR 0038), from the door list and what this desk remembers.
/// [now] is the scanner's clock in the gym's time (the phone's, in Addis).
/// An allowed scan, and any real code, updates [memory].
abstract final class DoorCheck {
  static final _form = RegExp(r'^GQ1:([0-9A-Za-z]{26}):(\d+):([0-9A-Fa-f]{16})$');

  /// The 5-minute rule: a member let in moments ago isn't let in again.
  static const alreadyInFor = Duration(minutes: 5);

  static DoorDecision decide({
    required DoorList list,
    required String payload,
    required int branchId,
    required DateTime now,
    required DoorMemory memory,
  }) {
    // 1. The code's form, and a credential of this gym.
    final match = _form.firstMatch(payload.trim());
    final credential = match == null ? null : list.credentials[match.group(1)!.toUpperCase()];
    if (match == null || credential == null) return const DoorDecision(letIn: false, reasonCode: 'CREDENTIAL_INVALID');
    final step = int.parse(match.group(2)!);
    final date = _isoDate(now);
    final day = credential.days[date];
    DoorDecision deny(String reason, {bool withMember = true}) =>
        DoorDecision(letIn: false, reasonCode: reason, credential: withMember ? credential : null, day: day);

    // 2. Within one step of the scanner's clock.
    if ((step - Gq1.stepAt(now)).abs() > 1) return deny('CODE_EXPIRED');

    // 3. Signed with that UTC day's key.
    final dayKey = credential.dayKeys[Gq1.utcDayOf(step)];
    if (dayKey == null || Gq1.codeWithDayKey(dayKey, credential.id, step) != match.group(3)!.toUpperCase()) {
      return deny('CREDENTIAL_INVALID', withMember: false);
    }

    // 4. Later than any step already used, which it then becomes.
    final lastUsed = [?credential.lastUsedStep, ?memory.lastUsedSteps[credential.id]].fold<int?>(
      null,
      (highest, each) => highest == null || each > highest ? each : highest,
    );
    if (lastUsed != null && step <= lastUsed) return deny('CODE_ALREADY_USED');
    memory.lastUsedSteps[credential.id] = step;

    // 5. The branch open now, counting the previous date's hours past midnight.
    if (!_isOpen(list.hours[branchId], now)) return deny('OUTSIDE_HOURS');

    // 6. What the membership allows that date, at this branch, with visits.
    if (day == null) return deny('MEMBERSHIP_NONE');
    if (!day.allowed) return deny(day.reasonCode ?? 'MEMBERSHIP_NONE');
    if (day.branchIds case final ids? when !ids.contains(branchId)) return deny('BRANCH_NOT_ALLOWED');
    final visitKey = '${credential.memberId}|$date';
    final cameInToday = memory.cameIn.containsKey(visitKey);
    if (day.visitsLeft case final left? when !cameInToday && left <= 0) return deny('VISITS_USED_UP');

    // 7. Not let in within the last five minutes.
    final last = memory.lastLetIn[credential.memberId];
    if (last != null && now.toUtc().difference(last) < alreadyInFor) return deny('ALREADY_CHECKED_IN');

    memory.cameIn[visitKey] = 1;
    memory.lastLetIn[credential.memberId] = now.toUtc();
    return DoorDecision(letIn: true, credential: credential, day: day);
  }

  static bool _isOpen(Map<String, DoorHours?>? hours, DateTime now) {
    if (hours == null) return false;
    final minute = now.hour * 60 + now.minute;
    final today = hours[_isoDate(now)];
    if (today != null) {
      final overnight = today.closesAt <= today.opensAt;
      if (minute >= today.opensAt && (overnight || minute < today.closesAt)) return true;
    }
    final yesterday = hours[_isoDate(DateTime(now.year, now.month, now.day - 1))];
    return yesterday != null && yesterday.closesAt <= yesterday.opensAt && minute < yesterday.closesAt;
  }

  static String _isoDate(DateTime day) =>
      '${day.year.toString().padLeft(4, '0')}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
}
