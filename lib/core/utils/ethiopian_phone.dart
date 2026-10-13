/// Ethiopian mobile numbers: nine digits after +251, starting with 9 (Ethio
/// Telecom) or 7 (Safaricom).
abstract final class EthiopianPhone {
  static final _mobile = RegExp(r'^[79]\d{8}$');

  /// `0911 23 45 67`, `911234567` or `+251 911 234 567` to `+251911234567`.
  /// Null when it isn't an Ethiopian mobile number.
  static String? normalize(String input) {
    final digits = input.replaceAll(RegExp(r'\D'), '');
    final local = switch (digits.length) {
      12 when digits.startsWith('251') => digits.substring(3),
      10 when digits.startsWith('0') => digits.substring(1),
      9 => digits,
      _ => null,
    };
    return local != null && _mobile.hasMatch(local) ? '+251$local' : null;
  }

  /// `+251911234567` to `+251 91 123 4567`, for display. The spaces are
  /// non-breaking, so a number never wraps across two lines.
  static String format(String e164) {
    if (e164.length != 13 || !e164.startsWith('+251')) return e164;
    return ['+251', e164.substring(4, 6), e164.substring(6, 9), e164.substring(9)].join('\u00A0');
  }
}
