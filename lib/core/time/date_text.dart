import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../localization/locale_controller.dart';
import '../storage/preferences_store.dart';
import 'ethiopian_date.dart';
import 'local_date.dart';

enum CalendarSystem { gregorian, ethiopian, both }

/// The calendar the member chose, or null to follow the language: Ethiopian
/// with Amharic, Gregorian with English. Language and calendar stay separate
/// settings, so English with Ethiopian dates is possible.
final class CalendarController extends Notifier<CalendarSystem?> {
  static const _key = 'settings.calendar';

  @override
  CalendarSystem? build() {
    final stored = ref.watch(preferencesStoreProvider).getString(_key);
    return CalendarSystem.values.where((calendar) => calendar.name == stored).firstOrNull;
  }

  Future<void> select(CalendarSystem? calendar) async {
    final preferences = ref.read(preferencesStoreProvider);
    if (calendar == null) {
      await preferences.remove(_key);
    } else {
      await preferences.setString(_key, calendar.name);
    }
    state = calendar;
  }
}

final calendarControllerProvider = NotifierProvider<CalendarController, CalendarSystem?>(CalendarController.new);

final calendarProvider = Provider<CalendarSystem>(
  (ref) =>
      ref.watch(calendarControllerProvider) ??
      (ref.watch(languageCodeProvider) == 'am' ? CalendarSystem.ethiopian : CalendarSystem.gregorian),
);

/// Dates and times as the member wants to read them. Server times are UTC
/// and shown in the phone's timezone; business dates are shown as sent.
final class DateText {
  const DateText({required this.languageCode, required this.calendar});

  final String languageCode;
  final CalendarSystem calendar;

  /// "Nov 13, 2026", "Hidar 4, 2019", or both.
  String date(LocalDate date) => _pick(
    DateFormat.yMMMd(languageCode).format(date.toDateTime()),
    () {
      final ethiopian = EthiopianDate.fromGregorian(date);
      return '${_ethiopianMonth(ethiopian.month)} ${ethiopian.day}, ${ethiopian.year}';
    },
  );

  /// "Nov 13" or "Hidar 4", for places where the year is obvious.
  String dayMonth(LocalDate date) => _pick(
    DateFormat.MMMd(languageCode).format(date.toDateTime()),
    () {
      final ethiopian = EthiopianDate.fromGregorian(date);
      return '${_ethiopianMonth(ethiopian.month)} ${ethiopian.day}';
    },
  );

  /// "Mon, Oct 12": the weekday is the same in both calendars.
  String weekdayDate(LocalDate date) =>
      '${DateFormat.E(languageCode).format(date.toDateTime())}, ${dayMonth(date)}';

  /// "6:42 AM", in the phone's timezone.
  String time(DateTime moment) => DateFormat.jm(languageCode).format(moment.toLocal());

  String _pick(String gregorian, String Function() ethiopian) => switch (calendar) {
    CalendarSystem.gregorian => gregorian,
    CalendarSystem.ethiopian => ethiopian(),
    CalendarSystem.both => '$gregorian · ${ethiopian()}',
  };

  String _ethiopianMonth(int month) =>
      (languageCode == 'am' ? _amharicMonths : _transliteratedMonths)[month - 1];

  static const _amharicMonths = [
    'መስከረም', 'ጥቅምት', 'ኅዳር', 'ታኅሣሥ', 'ጥር', 'የካቲት', 'መጋቢት', //
    'ሚያዝያ', 'ግንቦት', 'ሰኔ', 'ሐምሌ', 'ነሐሴ', 'ጳጉሜ',
  ];

  static const _transliteratedMonths = [
    'Meskerem', 'Tikimt', 'Hidar', 'Tahsas', 'Tir', 'Yekatit', 'Megabit', //
    'Miazia', 'Genbot', 'Sene', 'Hamle', 'Nehase', 'Pagume',
  ];
}

final dateTextProvider = Provider<DateText>(
  (ref) => DateText(languageCode: ref.watch(languageCodeProvider), calendar: ref.watch(calendarProvider)),
);
