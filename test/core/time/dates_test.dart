import 'package:flutter_test/flutter_test.dart';
import 'package:gym_mobile/core/time/date_text.dart';
import 'package:gym_mobile/core/time/ethiopian_date.dart';
import 'package:gym_mobile/core/time/local_date.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(initializeDateFormatting);

  group('Ethiopian calendar', () {
    EthiopianDate ethiopian(int year, int month, int day) => EthiopianDate.fromGregorian(LocalDate(year, month, day));

    test('new year falls on 11 September, or 12 before a Gregorian leap year', () {
      expect(ethiopian(2026, 9, 11), const EthiopianDate(2019, 1, 1));
      expect(ethiopian(2026, 9, 10), const EthiopianDate(2018, 13, 5), reason: 'Pagume has 5 days');
      expect(ethiopian(2027, 9, 11), const EthiopianDate(2019, 13, 6), reason: '2019 is a leap year');
      expect(ethiopian(2027, 9, 12), const EthiopianDate(2020, 1, 1));
    });

    test('holidays land where Ethiopians expect them', () {
      expect(ethiopian(2026, 1, 7), const EthiopianDate(2018, 4, 29), reason: 'Genna, Tahsas 29');
      expect(ethiopian(2024, 1, 7), const EthiopianDate(2016, 4, 28), reason: 'Genna after a leap year');
      expect(ethiopian(2026, 1, 19), const EthiopianDate(2018, 5, 11), reason: 'Timket, Tir 11');
    });
  });

  group('Dates read in the chosen calendar', () {
    const day = LocalDate(2026, 11, 13);

    test('Gregorian, Ethiopian or both', () {
      expect(const DateText(languageCode: 'en', calendar: CalendarSystem.gregorian).date(day), 'Nov 13, 2026');
      expect(const DateText(languageCode: 'en', calendar: CalendarSystem.ethiopian).date(day), 'Hidar 4, 2019');
      expect(const DateText(languageCode: 'am', calendar: CalendarSystem.ethiopian).date(day), 'ኅዳር 4, 2019');
      expect(
        const DateText(languageCode: 'en', calendar: CalendarSystem.both).date(day),
        'Nov 13, 2026 · Hidar 4, 2019',
      );
    });

    test('business dates do not shift with timezones', () {
      expect(LocalDate.parse('2026-11-13'), day);
      expect(const LocalDate(2026, 10, 14).daysUntil(day), 30);
      expect(day.addDays(-30), const LocalDate(2026, 10, 14));
      expect(() => LocalDate.parse('13/11/2026'), throwsFormatException);
    });
  });
}
