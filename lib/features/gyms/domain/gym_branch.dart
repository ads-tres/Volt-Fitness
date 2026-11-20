/// When a branch is open on one weekday: from [opensAt] to [closesAt],
/// minutes after midnight in the gym's time.
final class OpeningHours {
  const OpeningHours({required this.weekday, required this.opensAt, required this.closesAt});

  /// 1 is Monday, 7 is Sunday, as `DateTime.weekday`.
  final int weekday;
  final int opensAt;
  final int closesAt;
}

/// A branch of the gym with its week. As at the door (the API's ADR 0016):
/// a branch with no hours at all is always open, and a weekday without
/// hours is closed.
final class GymBranch {
  const GymBranch({required this.id, required this.name, this.address, this.hours = const []});

  final String id;
  final String name;
  final String? address;
  final List<OpeningHours> hours;

  bool get alwaysOpen => hours.isEmpty;

  OpeningHours? hoursOn(int weekday) => hours.where((day) => day.weekday == weekday).firstOrNull;

  /// Whether the door lets members in at [now], the gym's local time.
  bool isOpenAt(DateTime now) {
    if (alwaysOpen) return true;
    final today = hoursOn(now.weekday);
    final minute = now.hour * 60 + now.minute;
    return today != null && minute >= today.opensAt && minute < today.closesAt;
  }

  /// When an open branch closes, or null when it is always open.
  DateTime? closesAfter(DateTime now) {
    final today = hoursOn(now.weekday);
    if (alwaysOpen || today == null || !isOpenAt(now)) return null;
    return DateTime(now.year, now.month, now.day).add(Duration(minutes: today.closesAt));
  }

  /// When a closed branch next opens, within a week; null when it never
  /// does or is always open.
  DateTime? nextOpening(DateTime now) {
    if (alwaysOpen) return null;
    final midnight = DateTime(now.year, now.month, now.day);
    final minute = now.hour * 60 + now.minute;
    for (var days = 0; days <= 7; days++) {
      final day = DateTime(midnight.year, midnight.month, midnight.day + days);
      final hours = hoursOn(day.weekday);
      if (hours == null || (days == 0 && minute >= hours.opensAt)) continue;
      return day.add(Duration(minutes: hours.opensAt));
    }
    return null;
  }
}
