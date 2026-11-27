import 'package:flutter_test/flutter_test.dart';
import 'package:gym_mobile/core/photos/photo_picker.dart';
import 'package:material_ui/material_ui.dart';

import '../support/desk_driver.dart';
import '../support/fake_photo_picker.dart';

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
    await tester.tap(find.text('Later'));
    await tester.pumpAndSettle();
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

  testWidgets('a walk-in joins in one go: photo, plan, payment, then let in', (tester) async {
    await startDesk(tester, extraOverrides: [photoPickerProvider.overrideWithValue(FakePicker())]);
    await openScanner(tester);
    await search(tester, '0944556677');
    await tester.tap(find.byKey(const Key('add-member')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('new-member-name')), 'Selam Tesfaye');
    await tapVisible(tester, find.widgetWithText(FilledButton, 'Add member'));

    await tester.tap(find.text('Take a photo'));
    await tester.pumpAndSettle();
    expect(find.text('Photo taken'), findsOneWidget);
    await tester.tap(find.descendant(of: find.byType(BottomSheet), matching: find.text('Sell a plan')));
    await tester.pumpAndSettle();
    expect(find.text('A plan for Selam Tesfaye'), findsOneWidget);
    await tapVisible(tester, find.text('Sell plan'));
    await tapVisible(tester, find.text('Record payment'));
    expect(find.text('Receipt R-000001 · 1,500.00 ETB'), findsOneWidget);

    final selam = find.ancestor(of: find.text('Selam Tesfaye'), matching: find.byType(ListTile));
    expect(find.descendant(of: selam, matching: find.byKey(const Key('member-photo'))), findsOneWidget);
    await tester.tap(find.descendant(of: selam, matching: find.text('Check in')));
    await tester.pumpAndSettle();
    expect(find.text('Let in'), findsOneWidget);
    await tester.tap(find.byKey(const Key('check-in-result')));
    await tester.pumpAndSettle();
  });

  testWidgets('a member added without a plan is turned away, with Renew', (tester) async {
    await startDesk(tester);
    await openScanner(tester);
    await search(tester, '0944556677');
    await tester.tap(find.byKey(const Key('add-member')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('new-member-name')), 'Selam Tesfaye');
    await tapVisible(tester, find.widgetWithText(FilledButton, 'Add member'));
    await tester.tap(find.text('Later'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Check in'));
    await tester.pumpAndSettle();
    expect(find.text('Turned away'), findsOneWidget);
    expect(find.byKey(const Key('result-renew')), findsOneWidget);
    await tester.tap(find.byKey(const Key('check-in-result')));
    await tester.pumpAndSettle();
  });
}
