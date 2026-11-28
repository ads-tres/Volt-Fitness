import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Every message is written in English and Amharic under the same key, with
/// the same placeholders, as the gym platform keeps its own (its ADR 0034).
void main() {
  Map<String, dynamic> read(String language) =>
      jsonDecode(File('lib/l10n/app_$language.arb').readAsStringSync()) as Map<String, dynamic>;

  /// The placeholders a message uses: `{name}`, and the first word of an
  /// ICU part such as `{count, plural, …}`.
  Set<String> placeholders(String message) => {
    for (final match in RegExp(r'\{(\w+)(?:,|\})').allMatches(message)) match.group(1)!,
  };

  final english = read('en');
  final amharic = read('am');
  final keys = {for (final key in english.keys) if (!key.startsWith('@')) key};

  test('both languages have the same messages', () {
    final amharicKeys = {for (final key in amharic.keys) if (!key.startsWith('@')) key};
    expect(amharicKeys.difference(keys), isEmpty, reason: 'only in Amharic');
    expect(keys.difference(amharicKeys), isEmpty, reason: 'missing in Amharic');
  });

  test('each Amharic message uses the same placeholders as the English', () {
    final different = [
      for (final key in keys)
        if (amharic[key] is String && !_sameSet(placeholders(english[key] as String), placeholders(amharic[key] as String)))
          key,
    ];
    expect(different, isEmpty);
  });

  test('no Amharic message is left in English', () {
    // Names and brands read the same in both.
    const same = {'appTitle', 'languageEnglish', 'languageAmharic', 'appVersion', 'planDates'};
    final untranslated = [
      for (final key in keys)
        if (!same.contains(key) && amharic[key] == english[key] && RegExp('[A-Za-z]{3,}').hasMatch(english[key] as String)) key,
    ];
    expect(untranslated, isEmpty);
  });
}

bool _sameSet(Set<String> a, Set<String> b) => a.length == b.length && a.containsAll(b);
