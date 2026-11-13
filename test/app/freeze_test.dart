import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_mobile/core/network/fake_backend.dart';
import 'package:material_ui/material_ui.dart';

import '../support/app_driver.dart';
import '../support/test_doubles.dart';

/// Opens the membership tab and scrolls to [text].
Future<void> openMembership(WidgetTester tester, {required String phone, String? scrollTo}) async {
  await startApp(tester);
  await signInWith(tester, phone: phone);
  await tester.tap(find.byTooltip('Membership'));
  await tester.pumpAndSettle();
  if (scrollTo != null) await showInMiddle(tester, find.text(scrollTo));
}

/// Scrolls [finder] to the middle of the screen, clear of the navigation bar.
Future<void> showInMiddle(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(finder, 200);
  await Scrollable.ensureVisible(tester.element(finder), alignment: 0.5);
  await tester.pumpAndSettle();
}

/// The fake backend, except that freezing is always refused.
final class RefusesFreezes implements HttpClientAdapter {
  final _fake = FakeBackend(latency: Duration.zero, now: () => testNow);

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    if (options.method == 'POST' && options.path.endsWith('/freezes')) {
      return jsonResponse(422, {
        'message': 'This membership is already frozen from 2026-10-16 to 2026-10-18.',
        'errors': {
          'starts_on': ['This membership is already frozen from 2026-10-16 to 2026-10-18.'],
        },
      });
    }
    return _fake.fetch(options, requestStream, cancelFuture);
  }

  @override
  void close({bool force = false}) => _fake.close(force: force);
}

void main() {
  testWidgets('a member freezes for a week, the plan ends a week later, and "I\'m back" undoes it', (tester) async {
    await openMembership(tester, phone: '0912345678', scrollTo: 'Freeze my membership');
    expect(find.text('7 of 7 left'), findsOneWidget);

    await tester.tap(find.text('Freeze my membership'));
    await tester.pumpAndSettle();
    expect(find.text('Freeze your membership'), findsOneWidget);
    expect(find.text('Oct 14, 2026'), findsOneWidget, reason: 'from today');
    expect(find.text('Oct 20, 2026'), findsOneWidget, reason: 'for a week');
    expect(find.text('7 days · your plan will end on Nov 8, 2026'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Travelling');
    await tester.tap(find.text('Freeze'));
    await tester.pumpAndSettle();

    expect(find.text('Freeze your membership'), findsNothing);
    expect(find.text('Frozen from Oct 14, 2026 to Oct 20, 2026.'), findsOneWidget);
    expect(find.text('Nov 8, 2026'), findsOneWidget, reason: 'the new end date');
    expect(find.text('Frozen'), findsOneWidget, reason: 'the status');
    await showInMiddle(tester, find.text("I'm back"));
    expect(find.text('Frozen from Oct 14, 2026 to Oct 20, 2026'), findsOneWidget);
    expect(find.text('0 of 7 left'), findsOneWidget);
    expect(find.text('Freeze my membership'), findsNothing, reason: 'no freeze days left');

    await tester.tap(find.text("I'm back"));
    await tester.pumpAndSettle();
    expect(find.text('End your freeze today?'), findsOneWidget);
    await tester.tap(find.text("I'm back").last);
    await tester.pumpAndSettle();

    expect(find.text('Welcome back! Your freeze has ended.'), findsOneWidget);
    expect(find.text('Nov 1, 2026'), findsOneWidget, reason: 'the end date moved back');
    expect(find.text('7 of 7 left'), findsOneWidget);
  });

  testWidgets('a frozen member sees the freeze and its days, and may freeze again after it', (tester) async {
    await openMembership(tester, phone: '0944444444', scrollTo: 'Freeze my membership');

    expect(find.text('Frozen from Oct 14, 2026 to Oct 21, 2026'), findsOneWidget);
    expect(find.text('8 days'), findsOneWidget);
    expect(find.text('2 of 10 left'), findsOneWidget);
    expect(find.text("I'm back"), findsOneWidget);

    await tester.tap(find.text('Freeze my membership'));
    await tester.pumpAndSettle();
    expect(find.text('Oct 22, 2026'), findsOneWidget, reason: 'the day after the current freeze');
    expect(find.text('Oct 23, 2026'), findsOneWidget, reason: 'the two days left');
  });

  testWidgets('the API\'s refusal shows under the day it is about, and the sheet stays open', (tester) async {
    await startApp(tester, backend: RefusesFreezes());
    await signInWith(tester, phone: '0912345678');
    await tester.tap(find.byTooltip('Membership'));
    await tester.pumpAndSettle();
    await showInMiddle(tester, find.text('Freeze my membership'));

    await tester.tap(find.text('Freeze my membership'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Freeze'));
    await tester.pumpAndSettle();

    expect(find.text('Freeze your membership'), findsOneWidget);
    expect(find.text('This membership is already frozen from 2026-10-16 to 2026-10-18.'), findsOneWidget);
  });

  testWidgets('an expired plan offers no freeze', (tester) async {
    await openMembership(tester, phone: '0933333333', scrollTo: 'Renew plan');

    expect(find.text('Freeze my membership'), findsNothing);
  });
}
