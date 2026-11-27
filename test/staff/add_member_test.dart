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
    // A focused field scrolls itself back into view; let go of it first.
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  testWidgets('a walk-in is added from a phone nobody has, and is found in search', (tester) async {
    await startDesk(tester);
    await openScanner(tester);
    await search(tester, '0944 556 677');
    expect(find.text('No member of this gym matches.'), findsOneWidget);

    await tester.tap(find.text('Not a member yet? Add them.'));
    await tester.pumpAndSettle();
    expect(find.text('New member'), findsOneWidget);
    expect(find.text('Their home branch will be Main Branch. A plan and payment come next.'), findsOneWidget);
    expect(
      find.descendant(of: find.byKey(const Key('new-member-phone')), matching: find.text('0944 556 677')),
      findsOneWidget,
      reason: 'the typed phone is filled in',
    );

    await tester.enterText(find.byKey(const Key('new-member-name')), 'Selam Tesfaye');
    await tester.tap(find.text('Female'));
    await tapVisible(tester, find.widgetWithText(FilledButton, 'Add member'));

    expect(find.text('Selam Tesfaye is a member now.'), findsOneWidget);
    expect(find.widgetWithText(ListTile, 'Selam Tesfaye'), findsOneWidget);
  });

  testWidgets('a taken phone offers to find the member, and a contact needs both halves', (tester) async {
    await startDesk(tester);
    await openScanner(tester);
    await search(tester, 'Kebede');
    await tester.tap(find.byKey(const Key('add-member')));
    await tester.pumpAndSettle();
    expect(find.descendant(of: find.byKey(const Key('new-member-name')), matching: find.text('Kebede')), findsOneWidget, reason: 'a typed name goes in the name');

    await tester.enterText(find.byKey(const Key('new-member-phone')), '0911 234 567');
    await tester.enterText(find.byKey(const Key('new-member-contact-name')), 'Almaz');
    await tapVisible(tester, find.widgetWithText(FilledButton, 'Add member'));
    expect(find.text('The phone has already been taken.'), findsOneWidget);
    expect(
      find.text('The emergency contact phone field is required when emergency contact name is present.'),
      findsOneWidget,
    );

    await tapVisible(tester, find.text('Find them instead'));
    expect(find.text('New member'), findsNothing);
    expect(find.widgetWithText(ListTile, 'Abebe Kebede'), findsOneWidget);
  });

  testWidgets('an accountant can\'t add members', (tester) async {
    await startDesk(tester);
    await signInAtDesk(tester, phone: '0911 00 00 03');
    await search(tester, 'zzz');

    expect(find.text('No member of this gym matches.'), findsOneWidget);
    expect(find.byKey(const Key('add-member')), findsNothing);
    expect(find.text('Not a member yet? Add them.'), findsNothing);
  });
}
