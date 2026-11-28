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

  Future<void> openEdit(WidgetTester tester, int memberId) async {
    await tester.tap(find.byKey(Key('open-member-$memberId')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('edit-member')));
    await tester.pumpAndSettle();
  }

  Future<void> save(WidgetTester tester) async {
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    final button = find.widgetWithText(FilledButton, 'Save changes');
    await tester.ensureVisible(button);
    await tester.pumpAndSettle();
    await tester.tap(button);
    await tester.pumpAndSettle();
  }

  testWidgets('the desk fixes a member\'s name and clears their email, and both show at once', (tester) async {
    await startDesk(tester);
    await openScanner(tester);
    await search(tester, 'abe');
    await openEdit(tester, 1);

    expect(find.text('Edit Abebe Kebede'), findsOneWidget);
    expect(find.descendant(of: find.byKey(const Key('new-member-email')), matching: find.text('abebe@example.com')), findsOneWidget);
    await tester.enterText(find.byKey(const Key('new-member-name')), 'Abebe K. Bekele');
    await tester.enterText(find.byKey(const Key('new-member-email')), '');
    expect(find.byKey(const Key('phone-change-note')), findsNothing, reason: 'the phone is unchanged');
    await save(tester);

    expect(find.text('Saved.'), findsOneWidget);
    expect(find.widgetWithText(AppBar, 'Abebe K. Bekele'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Messages in'), 200, scrollable: find.byType(Scrollable).first);
    expect(find.text('abebe@example.com'), findsNothing);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await search(tester, 'bekele');
    expect(find.text('Abebe K. Bekele'), findsOneWidget);
  });

  testWidgets('a new phone is flagged, and another member\'s is refused with Find them instead', (tester) async {
    await startDesk(tester);
    await openScanner(tester);
    await search(tester, 'hana');
    await openEdit(tester, 3);

    await tester.enterText(find.byKey(const Key('new-member-phone')), '0911 234 567');
    await tester.pump();
    expect(find.byKey(const Key('phone-change-note')), findsOneWidget);
    await save(tester);
    expect(find.text('The phone has already been taken.'), findsOneWidget);
    expect(find.text('Find them instead'), findsOneWidget);
  });

  testWidgets('an accountant can\'t edit members', (tester) async {
    await startDesk(tester);
    await signInAtDesk(tester, phone: '0911 00 00 03');
    await search(tester, 'hana');
    await tester.tap(find.byKey(const Key('open-member-3')));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Hana Girma'), findsOneWidget);
    expect(find.byKey(const Key('edit-member')), findsNothing);
  });
}
