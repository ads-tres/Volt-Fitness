import '../../../core/time/local_date.dart';

/// When a branch is open on one weekday: from [opensAt] to [closesAt],
/// minutes after midnight in the gym's time. Closing at or before opening
/// runs past midnight: Friday 18:00–02:00 is open until 02:00 on Saturday.
final class OpeningHours {
  const OpeningHours({required this.weekday, required this.opensAt, required this.closesAt});

  /// 1 is Monday, 7 is Sunday, as `DateTime.weekday`.
  final int weekday;
  final int opensAt;
  final int closesAt;

  bool get pastMidnight => closesAt <= opensAt;
}

/// Days a branch is closed, or keeps other hours, such as a holiday (the
/// API's ADR 0037 and 0039). Without [opensAt] and [closesAt] it is closed
/// all day; with them it is open only then, whatever its week says.
final class BranchClosure {
  const BranchClosure({
    required this.id,
    required this.startsOn,
    required this.endsOn,
    this.reason,
    this.opensAt,
    this.closesAt,
    this.repeatsYearly = false,
    this.ethiopianDate,
  });

  final String id;
  final LocalDate startsOn;

  /// Included.
  final LocalDate endsOn;
  final String? reason;
  final int? opensAt;
  final int? closesAt;

  /// It comes back every year on the same Ethiopian date.
  final bool repeatsYearly;

  /// The Ethiopian day and month it starts on, such as "Tir 11".
  final String? ethiopianDate;

  bool get closedAllDay => opensAt == null || closesAt == null;

  bool covers(LocalDate date) => startsOn.compareTo(date) <= 0 && endsOn.compareTo(date) >= 0;
}

/// When a branch opens on one date, minutes after midnight; closing at or
/// before opening runs past midnight into the next date.
typedef DayWindow = ({int opensAt, int closesAt});

/// A branch of the gym with its week and closures. As at the door (the
/// API's ADR 0016 and 0037): a closure decides its dates; otherwise a branch
/// with no hours at all is always open, and a weekday without hours is
/// closed.
final class GymBranch {
  const GymBranch({required this.id, required this.name, this.address, this.hours = const [], this.closures = const []});

  final String id;
  final String name;
  final String? address;
  final List<OpeningHours> hours;

  /// From today to 60 days ahead, soonest first.
  final List<BranchClosure> closures;

  static const _wholeDay = (opensAt: 0, closesAt: 24 * 60);

  bool get alwaysOpen => hours.isEmpty;

  OpeningHours? hoursOn(int weekday) => hours.where((day) => day.weekday == weekday).firstOrNull;

  BranchClosure? closureOn(LocalDate date) => closures.where((closure) => closure.covers(date)).firstOrNull;

  /// The branch's hours on [date], or null when it is closed all day.
  DayWindow? windowOn(LocalDate date) {
    if (closureOn(date) case final closure?) {
      return closure.closedAllDay ? null : (opensAt: closure.opensAt!, closesAt: closure.closesAt!);
    }
    if (alwaysOpen) return _wholeDay;
    final day = hoursOn(date.toDateTime().weekday);
    return day == null ? null : (opensAt: day.opensAt, closesAt: day.closesAt);
  }

  /// Whether the door lets members in at [now], the gym's local time,
  /// counting the previous date's hours past midnight.
  bool isOpenAt(DateTime now) => closesAfter(now) != null;

  /// When an open branch closes; null when it is closed now.
  DateTime? closesAfter(DateTime now) {
    final today = LocalDate.of(now);
    final minute = now.hour * 60 + now.minute;
    final midnight = DateTime(now.year, now.month, now.day);
    if (windowOn(today) case final window? when minute >= window.opensAt && (_pastMidnight(window) || minute < window.closesAt)) {
      return midnight.add(Duration(minutes: _pastMidnight(window) ? 24 * 60 + window.closesAt : window.closesAt));
    }
    if (windowOn(today.addDays(-1)) case final window? when _pastMidnight(window) && minute < window.closesAt) {
      return midnight.add(Duration(minutes: window.closesAt));
    }
    return null;
  }

  /// When a closed branch next opens, within a week; null when it is open
  /// now or doesn't open within the week.
  DateTime? nextOpening(DateTime now) {
    if (isOpenAt(now)) return null;
    final today = LocalDate.of(now);
    final minute = now.hour * 60 + now.minute;
    for (var days = 0; days <= 7; days++) {
      final date = today.addDays(days);
      final window = windowOn(date);
      if (window == null || (days == 0 && minute >= window.opensAt)) continue;
      return date.toDateTime().add(Duration(minutes: window.opensAt));
    }
    return null;
  }

  static bool _pastMidnight(DayWindow window) => window.closesAt <= window.opensAt;
}
