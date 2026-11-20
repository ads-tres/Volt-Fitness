import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../support/app_driver.dart';

void main() {
  Future<void> openMembership(WidgetTester tester, String phone) async {
    await startApp(tester);
    await signInWith(tester, phone: phone);
    await tester.tap(find.byTooltip('Membership'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Your other plans'), 200, scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
  }

  testWidgets('the membership tab lists last month\'s plan, ended and paid', (tester) async {
    await openMembership(tester, '0912345678');

    await tester.scrollUntilVisible(find.text('Paid 1,500.00 ETB of 1,500.00 ETB'), 200, scrollable: find.byType(Scrollable).first);
    expect(find.text('Sep 2, 2026 – Oct 1, 2026'), findsOneWidget);
    expect(find.text('Expired'), findsOneWidget);
  });

  testWidgets('a plan coming after the current one shows too, with nothing paid yet', (tester) async {
    await openMembership(tester, '0922222222');

    await tester.scrollUntilVisible(find.text('Paid 0.00 ETB of 1,500.00 ETB'), 200, scrollable: find.byType(Scrollable).first);
    expect(find.text('Oct 18, 2026 – Nov 16, 2026'), findsOneWidget);
  });
}
