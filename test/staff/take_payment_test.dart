import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../support/desk_driver.dart';

void main() {
  Future<void> findAbebe(WidgetTester tester) async {
    await openScanner(tester);
    await tester.tap(find.text('Desk'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'abe');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
  }

  Future<void> openPayment(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('take-payment-1')));
    await tester.pumpAndSettle();
  }

  Future<void> record(WidgetTester tester) async {
    await tester.ensureVisible(find.text('Record payment'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Record payment'));
    await tester.pumpAndSettle();
  }

  testWidgets('the desk takes what a member owes in cash, and the balance is gone', (tester) async {
    await startDesk(tester);
    await findAbebe(tester);
    expect(find.textContaining('Owes 1,000.00 ETB'), findsOneWidget);
    expect(find.byKey(const Key('take-payment-3')), findsNothing, reason: 'Hana owes nothing');

    await openPayment(tester);
    expect(find.text('Payment from Abebe Kebede'), findsOneWidget);
    expect(find.text('Up to 1,000.00 ETB is due'), findsOneWidget);
    expect(find.text('1,000.00 ETB by Cash from Abebe Kebede · paid in full'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('pay-amount')), '400');
    await tester.pump();
    expect(find.text('400.00 ETB by Cash from Abebe Kebede · 600.00 ETB left'), findsOneWidget);
    await record(tester);

    expect(find.text('Receipt R-000001 · 400.00 ETB'), findsOneWidget);
    expect(find.textContaining('Owes 600.00 ETB'), findsOneWidget);

    await openPayment(tester);
    await record(tester);
    expect(find.text('Receipt R-000002 · 600.00 ETB'), findsOneWidget);
    expect(find.textContaining('Owes'), findsNothing);
    expect(find.byKey(const Key('take-payment-1')), findsNothing);
  });

  testWidgets('a transfer needs its transaction number, and more than is due is refused', (tester) async {
    await startDesk(tester);
    await findAbebe(tester);
    await openPayment(tester);

    await tester.tap(find.text('telebirr'));
    await tester.pump();
    expect(find.byKey(const Key('pay-reference')), findsOneWidget);
    await record(tester);
    expect(find.text('Enter the transaction number from the payment confirmation.'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('pay-reference')), 'TB55');
    await tester.enterText(find.byKey(const Key('pay-amount')), '1500');
    await record(tester);
    expect(find.text('Only 1,000.00 ETB is still due on this membership.'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('pay-amount')), 'abc');
    await tester.pump();
    await tester.enterText(find.byKey(const Key('pay-amount')), '.');
    await record(tester);
    expect(find.text('Enter an amount like 500 or 500.50.'), findsOneWidget);
  });
}
