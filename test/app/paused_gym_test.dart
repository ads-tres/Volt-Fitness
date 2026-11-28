import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../support/app_driver.dart';

void main() {
  testWidgets('a member of a paused gym is told to ask at the gym instead of an error', (tester) async {
    await startApp(tester);
    await signInWith(tester, phone: '0988888888');

    expect(find.byKey(const Key('gym-paused')), findsOneWidget);
    expect(find.text('This gym is paused for now. Ask at the gym.'), findsOneWidget);
    expect(find.text("You don't have access to this."), findsNothing);

    await tester.tap(find.byTooltip('Payments'));
    await tester.pumpAndSettle();
    expect(find.text('Bole Iron is paused for now. Ask at the gym.'), findsWidgets, reason: "other screens show the API's words");
  });

  testWidgets('a plan paid before the gym joined shows as "Paid before" on its receipt', (tester) async {
    await startApp(tester);
    await signInWith(tester, phone: '0933333333');

    await tester.tap(find.byTooltip('Payments'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Monthly plan'), 200, scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('Monthly plan'));
    await tester.pumpAndSettle();

    expect(find.text('Invoice R-2026-0142'), findsOneWidget);
    expect(find.text('Paid before'), findsOneWidget);
  });
}
