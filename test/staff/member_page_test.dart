import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../support/desk_driver.dart';

void main() {
  Future<void> openAbebe(WidgetTester tester) async {
    await openScanner(tester);
    await tester.tap(find.text('Desk'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'abe');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('open-member-1')));
    await tester.pumpAndSettle();
  }

  Future<void> scrollTo(WidgetTester tester, Finder finder) async {
    await tester.scrollUntilVisible(finder, 200, scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
  }

  testWidgets('a member\'s page shows who they are, their plan, payments, visits and details', (tester) async {
    await startDesk(tester);
    await openAbebe(tester);

    expect(find.widgetWithText(AppBar, 'Abebe Kebede'), findsOneWidget);
    expect(find.text('Active · Monthly'), findsOneWidget);
    expect(find.text('Student'), findsOneWidget);
    expect(tester.widget<Text>(find.byKey(const Key('member-owes'))).data, 'Owes 1,000.00 ETB');

    await scrollTo(tester, find.byKey(const Key('receipt-R-2026-0090')));
    expect(find.textContaining('Cash'), findsWidgets);
    await scrollTo(tester, find.text('Visits'));
    await scrollTo(tester, find.text('Almaz Kebede · +251 91 199 8877'));
    expect(find.text('abebe@example.com'), findsOneWidget);
  });

  testWidgets('a payment and a check-in made from the page show on it at once', (tester) async {
    await startDesk(tester);
    await openAbebe(tester);

    await tester.tap(find.byKey(const Key('member-page-pay')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('pay-amount')), '250');
    await tester.ensureVisible(find.text('Record payment'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Record payment'));
    await tester.pumpAndSettle();
    expect(tester.widget<Text>(find.byKey(const Key('member-owes'))).data, 'Owes 750.00 ETB');
    await scrollTo(tester, find.byKey(const Key('receipt-R-000001')));

    await tester.drag(find.byType(Scrollable).first, const Offset(0, 2000));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('member-page-check-in')));
    await tester.pumpAndSettle();
    expect(find.text('Let in'), findsOneWidget);
    await tester.tap(find.byKey(const Key('check-in-result')));
    await tester.pumpAndSettle();

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.textContaining('Owes 750.00 ETB'), findsOneWidget, reason: 'search shows the new balance');
  });

  testWidgets('a scan result opens the member\'s page', (tester) async {
    final camera = FakeCamera();
    await startDesk(tester, camera: camera);
    await openScanner(tester);
    camera.show('GQ1:OWES000000000000000000000:1:00');
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('result-open-member')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('check-in-result')), findsNothing);
    expect(find.widgetWithText(AppBar, 'Abebe Kebede'), findsOneWidget);
  });
}
