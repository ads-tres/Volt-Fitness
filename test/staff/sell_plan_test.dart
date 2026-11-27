import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../support/desk_driver.dart';

void main() {
  Future<void> search(WidgetTester tester, String text) async {
    await tester.tap(find.text('Desk'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), text);
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
  }

  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  testWidgets('the desk renews a member whose plan ended, takes the payment, and checks them in', (tester) async {
    await startDesk(tester);
    await openScanner(tester);
    await search(tester, 'tig');

    await tester.tap(find.byKey(const Key('sell-plan-2')));
    await tester.pumpAndSettle();
    expect(find.text('A plan for Tigist Haile'), findsOneWidget);
    expect(find.text('Current plan'), findsOneWidget);
    expect(find.text('10 visits · 2 months · Main Branch'), findsOneWidget);
    expect(
      find.text('Monthly for Tigist Haile · 1,500.00 ETB, or less with their discount group or promo code'),
      findsOneWidget,
    );

    await tapVisible(tester, find.text('Sell plan'));
    expect(find.textContaining('Monthly sold to Tigist Haile'), findsOneWidget);
    expect(find.textContaining('· 1,500.00 ETB'), findsWidgets);
    expect(find.text('Payment from Tigist Haile'), findsOneWidget);
    expect(find.text('Up to 1,500.00 ETB is due'), findsOneWidget);
    await tapVisible(tester, find.text('Record payment'));
    expect(find.text('Receipt R-000001 · 1,500.00 ETB'), findsOneWidget);

    final tigist = find.ancestor(of: find.text('Tigist Haile'), matching: find.byType(ListTile));
    await tester.tap(find.descendant(of: tigist, matching: find.text('Check in')));
    await tester.pumpAndSettle();
    expect(find.text('Let in'), findsOneWidget);
    await tester.tap(find.byKey(const Key('check-in-result')));
    await tester.pumpAndSettle();
  });

  testWidgets('a promo code lowers what is due, and a clashing start day is refused', (tester) async {
    await startDesk(tester);
    await openScanner(tester);
    await search(tester, 'abe');

    await tester.tap(find.byKey(const Key('sell-plan-1')));
    await tester.pumpAndSettle();
    await tapVisible(tester, find.byKey(const Key('sell-starts')));
    await tester.tap(find.text('20'));
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tapVisible(tester, find.text('Sell plan'));
    expect(
      find.text(
        'The member already has a membership from 2 October 2026 to 1 November 2026. '
        'The first free start date is 2 November 2026.',
      ),
      findsOneWidget,
    );

    await tapVisible(tester, find.byTooltip('The first free day'));
    await tester.enterText(find.byKey(const Key('sell-promo-code')), 'NOPE');
    await tapVisible(tester, find.text('Sell plan'));
    expect(find.text("This promo code doesn't exist. Check how it is spelled."), findsOneWidget);

    await tester.enterText(find.byKey(const Key('sell-promo-code')), 'VOLT10');
    await tapVisible(tester, find.text('Sell plan'));
    expect(find.text('Payment from Abebe Kebede'), findsOneWidget);
    expect(find.text('Up to 1,350.00 ETB is due'), findsOneWidget, reason: 'the new plan, not the older debt');
  });

  testWidgets('owners can type a discount with its reason; receptionists can\'t', (tester) async {
    await startDesk(tester);
    await openScanner(tester);
    await search(tester, 'hana');
    await tester.tap(find.byKey(const Key('sell-plan-3')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('sell-discount-reason')), findsNothing);
    await tester.enterText(find.byKey(const Key('sell-discount')), '10%');
    await tester.pump();
    expect(find.byKey(const Key('sell-discount-reason')), findsOneWidget);
    await tapVisible(tester, find.text('Sell plan'));
    expect(find.text('The discount reason field is required when discount is present.'), findsOneWidget);
  });

  testWidgets('a receptionist sees no discount', (tester) async {
    await startDesk(tester);
    await signInAtDesk(tester, phone: '0911 00 00 02');
    await tester.tap(find.text('Demo Gym'));
    await tester.pumpAndSettle();
    await search(tester, 'hana');
    await tester.tap(find.byKey(const Key('sell-plan-3')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('sell-promo-code')), findsOneWidget);
    expect(find.byKey(const Key('sell-discount')), findsNothing);
  });
}
