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

  /// The big figure above [label] in a card.
  Finder figure(String label) => find.ancestor(of: find.text(label), matching: find.byType(Column)).first;

  testWidgets('the owner sees check-ins, money and members; a scan at the desk counts', (tester) async {
    final camera = FakeCamera();
    await startDesk(tester, camera: camera);
    await openScanner(tester);
    camera.show('GQ1:01K7Z3M6Q8V2N4R5T9W1X0Y2AB:59275728:4F1A2B3C4D5E6F70');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('check-in-result')));
    await tester.pumpAndSettle();

    await openNumbers(tester);

    expect(find.text('Check-ins'), findsOneWidget);
    expect(find.descendant(of: figure('Let in'), matching: find.text('2')), findsOneWidget, reason: 'one seeded, one scanned');
    expect(find.text('The branch is closed now'), findsOneWidget);
    expect(find.text('Money'), findsOneWidget);
    expect(find.text('4,500.00 ETB'), findsWidgets);
    expect(find.text('1 refund to make'), findsOneWidget);
    expect(find.text('Owed'), findsOneWidget);

    await tester.tap(find.text('7 days'));
    await tester.pumpAndSettle();
    expect(find.text('Money'), findsOneWidget, reason: 'the week loads too');
  });

  testWidgets('a receptionist sees no money', (tester) async {
    await startDesk(tester);
    await signInAtDesk(tester, phone: '0911 00 00 02');
    await tester.tap(find.text('Demo Gym'));
    await tester.pumpAndSettle();

    await openNumbers(tester);

    expect(find.text('Check-ins'), findsOneWidget);
    expect(find.text('Members'), findsOneWidget);
    expect(find.text('Money'), findsNothing);
    expect(find.text('Owed'), findsNothing);
  });

  testWidgets('the members to call show their plan, end, visits and what they owe, with a call button', (tester) async {
    await startDesk(tester);
    await openScanner(tester);
    await openNumbers(tester);

    await tester.scrollUntilVisible(find.text('Members to call'), 200);
    await tester.pumpAndSettle();
    expect(find.text('Abebe Kebede'), findsOneWidget);
    expect(find.text('Monthly · ends Oct 17, 2026 · Owes 1,000.00 ETB'), findsOneWidget);
    expect(find.text('10 Visits · ends Nov 23, 2026 · 1 visit left'), findsOneWidget);
    expect(find.byTooltip('Call +251\u00A091\u00A0123\u00A04567'), findsOneWidget);
  });
}
