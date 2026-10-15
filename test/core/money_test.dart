import 'package:flutter_test/flutter_test.dart';
import 'package:gym_mobile/core/money/money.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(initializeDateFormatting);

  test('minor units format without ever becoming a float', () {
    expect(const Money(150050, 'ETB').format('en'), '1,500.50 ETB');
    expect(const Money(150050, 'ETB').format('am'), '1,500.50 ብር');
    expect(const Money(5, 'ETB').format('en'), '0.05 ETB');
    expect(const Money(140000000, 'ETB').format('en'), '1,400,000.00 ETB');
    expect(const Money(-2500, 'ETB').format('en'), '-25.00 ETB');
    expect(const Money(1999, 'USD').format('am'), '19.99 USD');
  });

  test('money reads the API shape', () {
    expect(Money.fromJson({'amount_minor': 150000, 'currency': 'ETB'}), const Money(150000, 'ETB'));
    expect(() => Money.fromJson({'amount': 1500.0, 'currency': 'ETB'}), throwsFormatException);
  });
}
