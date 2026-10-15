import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../network/json.dart';

/// An amount as the API sends it: whole minor units (santim for ETB) and an
/// ISO currency. Never a floating-point number, so totals never drift.
@immutable
final class Money {
  const Money(this.amountMinor, this.currency);

  factory Money.fromJson(Map<String, dynamic> json) =>
      Money(json.field<int>('amount_minor'), json.field<String>('currency'));

  final int amountMinor;
  final String currency;

  /// "1,500.00 ETB", or "1,500.00 ብር" in Amharic.
  String format(String languageCode) {
    final minor = amountMinor.abs();
    final whole = NumberFormat.decimalPattern(languageCode).format(minor ~/ 100);
    final cents = (minor % 100).toString().padLeft(2, '0');
    final unit = currency == 'ETB' && languageCode == 'am' ? 'ብር' : currency;
    return '${amountMinor < 0 ? '-' : ''}$whole.$cents $unit';
  }

  @override
  bool operator ==(Object other) => other is Money && other.amountMinor == amountMinor && other.currency == currency;

  @override
  int get hashCode => Object.hash(amountMinor, currency);

  @override
  String toString() => format('en');
}
