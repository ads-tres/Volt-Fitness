import 'package:flutter_test/flutter_test.dart';
import 'package:gym_mobile/features/access/presentation/qr_code_view.dart';

import '../support/app_driver.dart';

// The phone's clock in tests is Tuesday 14 October 2026; the fake backend
// builds each number's membership around it.
void main() {
  testWidgets('home shows the days left and the latest visits', (tester) async {
    await startApp(tester);
    await signInWith(tester, phone: '0912345678');

    expect(find.text('18 days'), findsOneWidget);
    expect(find.text('Ends Nov 1'), findsOneWidget);
    expect(find.text('Monthly'), findsOneWidget);
    expect(find.text('Renew'), findsNothing);
    expect(find.text('Recent visits'), findsOneWidget);
    expect(find.textContaining('Today · '), findsOneWidget);
  });

  testWidgets('a plan ending soon asks the member to renew', (tester) async {
    await startApp(tester);
    await signInWith(tester, phone: '0922222222');

    expect(find.text('3 days'), findsOneWidget);
    expect(find.text('Renew soon'), findsOneWidget);
    expect(find.text('Renew'), findsOneWidget);
  });

  testWidgets('an expired plan shows when it ended and offers renewal', (tester) async {
    await startApp(tester);
    await signInWith(tester, phone: '0933333333');
    expect(find.text('Expired'), findsOneWidget);
    expect(find.text('Ended Oct 8'), findsOneWidget);
    expect(find.text('Renew'), findsOneWidget);
  });

  testWidgets('a frozen plan shows until when', (tester) async {
    await startApp(tester);
    await signInWith(tester, phone: '0944444444');
    expect(find.text('Frozen'), findsOneWidget);
    expect(find.text('Until Oct 21'), findsOneWidget);
  });

  testWidgets('a member without a plan is told to ask the gym', (tester) async {
    await startApp(tester);
    await signInWith(tester, phone: '0955555555');
    expect(find.text('No plan'), findsOneWidget);
    expect(find.text('Ask your gym to start one'), findsOneWidget);

    await tester.tap(find.byTooltip('Membership'));
    await tester.pumpAndSettle();
    expect(find.text('No active plan'), findsOneWidget);
  });

  testWidgets('the membership tab shows the plan, its dates and branches', (tester) async {
    await startApp(tester);
    await signInWith(tester, phone: '0912345678');

    await tester.tap(find.byTooltip('Membership'));
    await tester.pumpAndSettle();

    expect(find.text('Monthly'), findsOneWidget);
    expect(find.text('Active'), findsOneWidget);
    expect(find.text('Oct 2, 2026'), findsOneWidget);
    expect(find.text('Nov 1, 2026'), findsOneWidget);
    expect(find.text('18 days left'), findsOneWidget);
    expect(find.text('Bole'), findsOneWidget);
    expect(find.text('Megenagna'), findsOneWidget);
  });

  testWidgets('the QR tab shows a rotating GQ1 code', (tester) async {
    await startApp(tester);
    await signInWith(tester, phone: '0912345678');

    await tester.tap(find.byTooltip('My QR'));
    await pumpFor(tester);

    final qr = tester.widget<QrCodeView>(find.byType(QrCodeView));
    expect(qr.data, matches(RegExp(r'^GQ1:[0-9A-Z]{26}:\d+:[0-9A-F]{16}$')));
    expect(find.textContaining('New code in'), findsOneWidget);
    expect(find.text('Works without internet'), findsOneWidget);
  });

  testWidgets('the visit history groups visits by day and explains a refusal', (tester) async {
    await startApp(tester);
    await signInWith(tester, phone: '0912345678');

    await tester.tap(find.text('See all'));
    await tester.pumpAndSettle();

    expect(find.text('Visits'), findsOneWidget);
    expect(find.text('Today'), findsOneWidget);
    expect(find.text('Yesterday'), findsOneWidget);
    await tester.scrollUntilVisible(find.text("Outside your plan's hours"), 200);
    expect(find.byTooltip('Not let in'), findsOneWidget);
  });

  testWidgets('choosing the Ethiopian calendar changes the dates', (tester) async {
    await startApp(tester);
    await signInWith(tester, phone: '0912345678');

    await tester.tap(find.byTooltip('Profile'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Calendar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ethiopian'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Home'));
    await tester.pumpAndSettle();

    expect(find.text('Ends Tikimt 22'), findsOneWidget);
  });

  testWidgets('another phone can be signed out from the device list', (tester) async {
    await startApp(tester);
    await signInWith(tester, phone: '0912345678');

    await tester.tap(find.byTooltip('Profile'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Signed-in devices'));
    await tester.pumpAndSettle();

    expect(find.text('samsung SM-J600G'), findsOneWidget);
    expect(find.text('This phone'), findsOneWidget);
    expect(find.text('TECNO Spark 10 Pro'), findsOneWidget);

    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();
    expect(find.text('Sign out TECNO Spark 10 Pro?'), findsOneWidget);
    await tester.tap(find.text('Sign out').last);
    await tester.pumpAndSettle();

    expect(find.text('TECNO Spark 10 Pro'), findsNothing);
    expect(find.text('samsung SM-J600G'), findsOneWidget);
  });
}
