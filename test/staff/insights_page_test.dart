import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../support/desk_driver.dart';

void main() {
  Future<void> openNumbers(WidgetTester tester) async {
    await tester.tap(find.byTooltip('Menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Numbers'));
    await tester.pumpAndSettle();
  }

  Future<void> openInsights(WidgetTester tester) async {
    await openNumbers(tester);
    await tester.tap(find.byKey(const Key('month-by-month')));
    await tester.pumpAndSettle();
  }

  testWidgets('the owner sees money, renewals, busy hours and members month by month', (tester) async {
    await startDesk(tester);
    await openScanner(tester);
    await openInsights(tester);

    expect(find.widgetWithText(AppBar, 'Month by month'), findsOneWidget);
    expect(find.text('Taken in the last 12 months, net of refunds'), findsOneWidget);
    final twelveMonths = tester.widget<Text>(find.byKey(const Key('revenue-total'))).data;
    await tester.scrollUntilVisible(find.text('Paid before'), 200, scrollable: find.byType(Scrollable).last);

    await tester.tap(find.byKey(const Key('months-3')));
    await tester.pumpAndSettle();
    expect(find.text('Taken in the last 3 months, net of refunds'), findsOneWidget);
    expect(tester.widget<Text>(find.byKey(const Key('revenue-total'))).data, isNot(twelveMonths));

    await tester.tap(find.text('Renewals'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('renewal-rate')), findsOneWidget);
    expect(find.text('Renewed: a new plan within 14 days of the old one ending.'), findsOneWidget);

    await tester.tap(find.text('Busy hours'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Busiest: Mon 06:00'), findsOneWidget);

    await tester.tap(find.text('Members'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('active-members')), findsOneWidget);
    expect(find.text('Visit packs that ended'), findsOneWidget);
  });

  testWidgets('an accountant sees only money', (tester) async {
    await startDesk(tester);
    await signInAtDesk(tester, phone: '0911 00 00 03');
    await openInsights(tester);

    expect(find.byKey(const Key('revenue-total')), findsOneWidget);
    expect(find.byType(TabBar), findsNothing, reason: 'one insight needs no tabs');
    expect(find.text('Renewals'), findsNothing);
  });

  testWidgets('a receptionist sees no Month by month', (tester) async {
    await startDesk(tester);
    await signInAtDesk(tester, phone: '0911 00 00 02');
    await tester.tap(find.text('Demo Gym'));
    await tester.pumpAndSettle();
    await openNumbers(tester);

    expect(find.byKey(const Key('month-by-month')), findsNothing);
  });
}
