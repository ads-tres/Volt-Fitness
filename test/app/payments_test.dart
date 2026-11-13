import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app_driver.dart';

/// Payments run against the fake backend's stand-in for Chapa: the fake
/// checkout reports the payment, and the result screen has the API check
/// with Chapa until it says the payment is in.
void main() {
  /// Plans scroll sideways; bring the card into view and open it.
  Future<void> openPlan(WidgetTester tester, String name) async {
    final plan = find.descendant(
      of: find.byKey(const Key('plans')),
      matching: find.text(name, skipOffstage: false),
      skipOffstage: false,
    );
    await tester.ensureVisible(plan);
    await tester.pumpAndSettle();
    await tester.tap(plan);
    await tester.pumpAndSettle();
  }

  Future<void> payInFakeCheckout(WidgetTester tester) async {
    await tester.pumpAndSettle();
    expect(find.text('Pay with Chapa'), findsOneWidget);
    await tester.tap(find.text('Pay with telebirr'));
    // Still confirming on the first check, paid on the next, 6 s later.
    await pumpFor(tester, const Duration(seconds: 7));
    await tester.pumpAndSettle();
  }

  testWidgets('an expired member renews with a new plan and home shows it', (tester) async {
    await startApp(tester);
    await signInWith(tester, phone: '0933333333');
    expect(find.text('Expired'), findsOneWidget);

    await tester.tap(find.text('Renew'));
    await tester.pumpAndSettle();
    expect(find.text('Renew or change your plan'), findsOneWidget);

    await openPlan(tester, 'Quarterly');
    await tester.tap(find.text('Pay 4,000.00 ETB'));
    await payInFakeCheckout(tester);

    expect(find.text('Payment received'), findsOneWidget);
    expect(find.text('4,000.00 ETB'), findsOneWidget);

    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(find.text('89 days'), findsOneWidget);
    expect(find.text('Quarterly'), findsOneWidget);
    expect(find.text('Renew'), findsNothing);
  });

  testWidgets('what is owed is paid from home and its receipt opens', (tester) async {
    await startApp(tester);
    await signInWith(tester, phone: '0922222222');
    expect(find.text('Payment due'), findsOneWidget);
    expect(find.text('1,500.00 ETB'), findsOneWidget);

    await tester.tap(find.text('Pay'));
    await payInFakeCheckout(tester);
    expect(find.text('Payment received'), findsOneWidget);

    await tester.tap(find.text('View receipt'));
    await tester.pumpAndSettle();
    expect(find.text('Invoice R-2026-2001'), findsOneWidget);
    expect(find.text('Paid'), findsWidgets);
    expect(find.text('Chapa'), findsOneWidget);

    await tester.tap(find.byTooltip('Home'));
    await tester.pumpAndSettle();
    expect(find.text('Payment due'), findsNothing);
  });

  testWidgets('a declined payment is never confirmed, and changes nothing', (tester) async {
    await startApp(tester);
    await signInWith(tester, phone: '0966666666');

    await tester.tap(find.byTooltip('Payments'));
    await tester.pumpAndSettle();
    await openPlan(tester, 'Monthly');
    await tester.tap(find.text('Pay 1,500.00 ETB'));
    await payInFakeCheckout(tester);
    // Chapa never reports a declined payment as paid: the checks run out.
    await pumpFor(tester, const Duration(seconds: 60));
    await tester.pumpAndSettle();

    expect(find.text('Still confirming'), findsOneWidget);
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(find.text('18 days'), findsOneWidget);
  });

  testWidgets('leaving the checkout reports the payment as not finished', (tester) async {
    await startApp(tester);
    await signInWith(tester, phone: '0912345678');

    await tester.tap(find.byTooltip('Payments'));
    await tester.pumpAndSettle();
    await openPlan(tester, 'Annual');
    await tester.tap(find.text('Pay 14,000.00 ETB'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Leave'));
    await tester.pumpAndSettle();
    expect(find.text('Leave the payment?'), findsOneWidget);
    await tester.tap(find.text('Leave').last);
    await tester.pumpAndSettle();

    expect(find.text('Payment not finished'), findsOneWidget);
    await tester.tap(find.text('Back to payments'));
    await tester.pumpAndSettle();
    expect(find.text('Renew or change your plan'), findsOneWidget);
  });

  testWidgets('the payment history opens a receipt', (tester) async {
    await startApp(tester);
    await signInWith(tester, phone: '0912345678');

    await tester.tap(find.byTooltip('Payments'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Monthly plan'), 200, scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('Monthly plan'));
    await tester.pumpAndSettle();

    expect(find.text('Invoice R-2026-0142'), findsOneWidget);
    expect(find.text('Receipt'), findsWidgets);
    expect(find.text('Chapa'), findsOneWidget);
  });
}
