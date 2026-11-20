import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_mobile/staff/fake_front_desk.dart';
import 'package:material_ui/material_ui.dart';

import '../support/desk_driver.dart';
import '../support/test_doubles.dart';

/// The fake front desk, except that it refuses every change of choices.
final class RefusesChoices implements HttpClientAdapter {
  final _fake = FakeFrontDesk(latency: Duration.zero, now: () => testNow);

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    if (options.method == 'PATCH') {
      return jsonResponse(422, {
        'message': 'Choose push or SMS, on or off, for a known topic.',
        'errors': {
          'refunds': ['Choose push or SMS, on or off, for a known topic.'],
        },
      });
    }
    return _fake.fetch(options, requestStream, cancelFuture);
  }

  @override
  void close({bool force = false}) => _fake.close(force: force);
}

void main() {
  Future<void> openChoices(WidgetTester tester) async {
    await tester.tap(find.byTooltip('Menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Notifications'));
    await tester.pumpAndSettle();
  }

  bool isOn(WidgetTester tester, String key) => tester.widget<SwitchListTile>(find.byKey(Key(key))).value;

  testWidgets('staff turn on SMS for refunds, and it stays on', (tester) async {
    await startDesk(tester);
    await openScanner(tester);
    await openChoices(tester);

    expect(find.text('Refunds to make'), findsOneWidget);
    expect(isOn(tester, 'refunds.push'), isTrue);
    expect(isOn(tester, 'refunds.sms'), isFalse);

    await tester.tap(find.byKey(const Key('refunds.sms')));
    await tester.pumpAndSettle();
    expect(isOn(tester, 'refunds.sms'), isTrue);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await openChoices(tester);
    expect(isOn(tester, 'refunds.sms'), isTrue);
    expect(isOn(tester, 'online_payments.sms'), isFalse);
  });

  testWidgets('a refused change goes back and says why', (tester) async {
    await startDesk(tester, backend: RefusesChoices());
    await openScanner(tester);
    await openChoices(tester);

    await tester.tap(find.byKey(const Key('refunds.sms')));
    await tester.pumpAndSettle();

    expect(isOn(tester, 'refunds.sms'), isFalse);
    expect(find.text('Choose push or SMS, on or off, for a known topic.'), findsOneWidget);
  });
}
