import 'local_date.dart';

/// A day in the Ethiopian calendar: twelve months of 30 days, then Pagume
/// with 5 days, or 6 when the year divided by 4 leaves 3. The year starts on
/// 11 September (12 September before a Gregorian leap year).
final class EthiopianDate {
  const EthiopianDate(this.year, this.month, this.day);

  /// Converts through the Julian day number, counted from the Amete Mihret
  /// era used in Ethiopia today.
  factory EthiopianDate.fromGregorian(LocalDate date) {
    final days = _julianDayNumber(date) - _ameteMihretEpoch;
    final r = days % 1461;
    final n = r % 365 + 365 * (r ~/ 1460);
    return EthiopianDate(4 * (days ~/ 1461) + r ~/ 365 - r ~/ 1460, n ~/ 30 + 1, n % 30 + 1);
  }

  static const _ameteMihretEpoch = 1723856;

  final int year;

  /// 1 (Meskerem) to 13 (Pagume).
  final int month;
  final int day;

  static int _julianDayNumber(LocalDate date) {
    final a = (14 - date.month) ~/ 12;
    final y = date.year + 4800 - a;
    final m = date.month + 12 * a - 3;
    return date.day + (153 * m + 2) ~/ 5 + 365 * y + y ~/ 4 - y ~/ 100 + y ~/ 400 - 32045;
  }

  @override
  bool operator ==(Object other) =>
      other is EthiopianDate && other.year == year && other.month == month && other.day == day;

  @override
  int get hashCode => Object.hash(year, month, day);

  @override
  String toString() => '$day/$month/$year EC';
}
