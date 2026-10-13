import 'package:flutter_test/flutter_test.dart';
import 'package:gym_mobile/core/utils/ethiopian_phone.dart';

void main() {
  test('the ways people type a number all normalize to E.164', () {
    for (final input in ['0911234567', '0911 23 45 67', '911234567', '+251911234567', '251 911 234 567']) {
      expect(EthiopianPhone.normalize(input), '+251911234567', reason: input);
    }
    expect(EthiopianPhone.normalize('0712345678'), '+251712345678', reason: 'Safaricom');
  });

  test('landlines, short numbers and other countries are rejected', () {
    for (final input in ['0111234567', '091123456', '+254712345678', '']) {
      expect(EthiopianPhone.normalize(input), isNull, reason: input);
    }
  });

  test('numbers display in groups', () {
    expect(EthiopianPhone.format('+251911234567'), '+251\u00A091\u00A0123\u00A04567');
  });
}
