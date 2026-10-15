import 'package:flutter/foundation.dart';

/// A calendar day with no time or timezone, such as a membership's last day.
/// The API sends these as `YYYY-MM-DD` in the gym's timezone, so they are
/// never converted between zones.
@immutable
final class LocalDate implements Comparable<LocalDate> {
  const LocalDate(this.year, this.month, this.day);

  /// The day [moment] falls on, in [moment]'s own timezone.
  factory LocalDate.of(DateTime moment) => LocalDate(moment.year, moment.month, moment.day);

  /// Reads `2026-11-13`. Throws a [FormatException] otherwise.
  factory LocalDate.parse(String iso) {
    final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(iso);
    if (match == null) throw FormatException('Not a YYYY-MM-DD date', iso);
    return LocalDate(int.parse(match[1]!), int.parse(match[2]!), int.parse(match[3]!));
  }

  final int year;
  final int month;
  final int day;

  DateTime get _utc => DateTime.utc(year, month, day);

  /// Whole days from this date to [other]; negative when [other] is earlier.
  int daysUntil(LocalDate other) => other._utc.difference(_utc).inDays;

  LocalDate addDays(int days) => LocalDate.of(_utc.add(Duration(days: days)));

  /// Midnight at the start of this day, for formatting with `intl`.
  DateTime toDateTime() => DateTime(year, month, day);

  String toIso() =>
      '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';

  @override
  int compareTo(LocalDate other) => _utc.compareTo(other._utc);

  @override
  bool operator ==(Object other) =>
      other is LocalDate && other.year == year && other.month == month && other.day == day;

  @override
  int get hashCode => Object.hash(year, month, day);

  @override
  String toString() => toIso();
}
