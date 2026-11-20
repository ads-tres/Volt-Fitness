import 'package:flutter_test/flutter_test.dart';

import '../support/app_driver.dart';

void main() {
  testWidgets('Profile shows the branches with their hours and whether each is open now', (tester) async {
    await startApp(tester);
    await signInWith(tester, phone: '0912345678');
    await tester.tap(find.byTooltip('Profile'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Branches and hours'));
    await tester.pumpAndSettle();

    expect(find.text('Bole'), findsOneWidget);
    expect(find.text('Open now · until 22:00'), findsOneWidget, reason: 'Tuesday 09:30');
    expect(find.text('Tue'), findsOneWidget);
    expect(find.text('08:00 – 14:00'), findsOneWidget, reason: 'Sunday');
    expect(find.text('Megenagna'), findsOneWidget);
    expect(find.text('Always open'), findsOneWidget);
    expect(find.text('Your plan'), findsNWidgets(2), reason: 'the plan is limited to both branches');
  });
}
