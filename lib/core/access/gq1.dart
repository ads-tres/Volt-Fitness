import 'dart:convert';

import 'package:crypto/crypto.dart';

/// The rotating QR code agreed with the backend, shared by the member app
/// (which makes it) and the desk (which checks it offline) (the "GQ1" section of the
/// contract doc): a new code every 30 seconds, made from the credential's
/// secret and the time, so a screenshot stops working within a minute.
abstract final class Gq1 {
  static const stepSeconds = 30;
  static const _stepsPerDay = 86400 ~/ stepSeconds;

  static int stepAt(DateTime time) => time.millisecondsSinceEpoch ~/ 1000 ~/ stepSeconds;

  /// Seconds until the code shown at [time] is replaced, 1 to 30.
  static int secondsLeft(DateTime time) => stepSeconds - (time.millisecondsSinceEpoch ~/ 1000) % stepSeconds;

  /// The 16-character code for [step]: HMAC-SHA256 of the credential and
  /// step, keyed by the day key, as uppercase hex of the first 8 bytes.
  static String code(List<int> secret, String credentialId, int step) =>
      codeWithDayKey(dayKey(secret, utcDayOf(step)), credentialId, step);

  /// The UTC day a step falls in, whose day key signs it.
  static int utcDayOf(int step) => step ~/ _stepsPerDay;

  /// The key for one UTC day: what the server gives a scanner instead of
  /// the secret, so it can check that day's codes offline.
  static List<int> dayKey(List<int> secret, int utcDay) =>
      Hmac(sha256, secret).convert(ascii.encode('GQ1-DAY|$utcDay')).bytes;

  /// The code for [step] from its day key.
  static String codeWithDayKey(List<int> dayKey, String credentialId, int step) {
    final mac = Hmac(sha256, dayKey).convert(ascii.encode('GQ1|${credentialId.toUpperCase()}|$step')).bytes;
    return [for (final byte in mac.take(8)) byte.toRadixString(16).padLeft(2, '0')].join().toUpperCase();
  }

  /// What the QR holds: `GQ1:<credential>:<step>:<code>`.
  static String payload(List<int> secret, String credentialId, int step) =>
      'GQ1:${credentialId.toUpperCase()}:$step:${code(secret, credentialId, step)}';
}
