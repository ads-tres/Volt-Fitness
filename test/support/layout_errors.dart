import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

/// Collects every layout overflow while a tour walks the screens, instead
/// of failing at the first, so one run lists everything to fix. Call
/// [expectNoOverflow] at the end; it names each screen that overflowed.
final class LayoutErrors {
  LayoutErrors() {
    final previous = FlutterError.onError;
    FlutterError.onError = (details) {
      final text = details.exceptionAsString();
      if (text.contains('overflowed')) {
        final where = details.informationCollector?.call().map((node) => node.toString()).firstWhere(
          (line) => line.contains('.dart:'),
          orElse: () => '',
        );
        found.add('$screen: ${text.split('\n').first} ${where ?? ''}');
      } else {
        previous?.call(details);
      }
    };
    addTearDown(() => FlutterError.onError = previous);
  }

  /// Where the tour is, for the report.
  String screen = '';
  final found = <String>[];

  void expectNoOverflow() => expect(found.toSet().toList(), isEmpty, reason: 'Text overflowed on these screens');
}
