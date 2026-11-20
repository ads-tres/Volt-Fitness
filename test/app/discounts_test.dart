import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app_driver.dart';

/// What a member pays: their discount group's price, or a promo code's,
/// against the fake backend (0977 77 77 77 is a Student; NEWYEAR takes 10%
/// off Monthly and Quarterly).
void main() {
  Finder inPlans(String text) => find.descendant(
    of: find.byKey(const Key('plans')),
    matching: find.text(text, skipOffstage: false),
    skipOffstage: false,
  );

  Future<void> openPayments(WidgetTester tester, {required String phone}) async {
    await startApp(tester);
    await signInWith(tester, phone: phone);
    await tester.tap(find.byTooltip('Payments'));
    await tester.pumpAndSettle();
  }

  Future<void> openPlan(WidgetTester tester, String name) async {
    await tester.ensureVisible(inPlans(name));
    await tester.pumpAndSettle();
    await tester.tap(inPlans(name));
    await tester.pumpAndSettle();
  }

  Future<void> applyCode(WidgetTester tester, String code) async {
    await tester.tap(find.text('Have a promo code?'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('promo-code')), code);
    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();
  }

  testWidgets('a Student sees their price beside the list price, and pays it', (tester) async {
    await openPayments(tester, phone: '0977777777');

    expect(inPlans('1,500.00 ETB'), findsOneWidget, reason: 'struck through');
    expect(inPlans('1,200.00 ETB'), findsOneWidget);
    expect(inPlans('Student'), findsNWidgets(3));

    await openPlan(tester, 'Monthly');
    expect(find.text('Pay 1,200.00 ETB'), findsOneWidget);
  });

  testWidgets('NEWYEAR lowers Monthly but not Annual, and buying Monthly charges the code\'s price', (tester) async {
    await openPayments(tester, phone: '0912345678');
    await applyCode(tester, 'newyear');

    expect(find.text('NEWYEAR applied'), findsOneWidget);
    expect(inPlans('1,350.00 ETB'), findsOneWidget);
    expect(inPlans('NEWYEAR'), findsNWidgets(2), reason: 'Monthly and Quarterly');
    expect(inPlans('14,000.00 ETB'), findsOneWidget, reason: 'Annual at its list price');

    await openPlan(tester, 'Monthly');
    await tester.tap(find.text('Pay 1,350.00 ETB'));
    await tester.pumpAndSettle();
    expect(find.text('Pay with Chapa'), findsOneWidget);
    expect(find.textContaining('1,350.00 ETB'), findsWidgets);
  });

  testWidgets('a used code shows why and isn\'t applied; removing a code brings the list prices back', (tester) async {
    await openPayments(tester, phone: '0912345678');
    await applyCode(tester, 'USED');

    expect(find.text('You have already used this code.'), findsOneWidget);
    expect(find.text('USED applied'), findsNothing);

    await tester.enterText(find.byKey(const Key('promo-code')), 'NEWYEAR');
    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();
    expect(inPlans('1,350.00 ETB'), findsOneWidget);

    await tester.tap(find.byTooltip('Remove the code'));
    await tester.pumpAndSettle();
    expect(inPlans('1,350.00 ETB'), findsNothing);
    expect(inPlans('1,500.00 ETB'), findsOneWidget);
    expect(find.text('Have a promo code?'), findsOneWidget);
  });
}
