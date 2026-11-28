import 'package:flutter_test/flutter_test.dart';
import 'package:gym_mobile/staff/features/memberships/presentation/freeze_membership_sheet.dart';
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
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<void> closeSheet(WidgetTester tester) async {
    await tester.tapAt(const Offset(180, 20));
    await tester.pumpAndSettle();
  }

  Future<void> checkIn(WidgetTester tester, String name) async {
    final row = find.ancestor(of: find.text(name), matching: find.byType(ListTile));
    await tester.tap(find.descendant(of: row, matching: find.text('Check in')));
    await tester.pumpAndSettle();
  }

  Future<void> dismissResult(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('check-in-result')));
    await tester.pumpAndSettle();
  }

  testWidgets('the desk freezes a membership, the member is turned away, and the freeze is ended from the result', (
    tester,
  ) async {
    await startDesk(tester);
    await openScanner(tester);
    await search(tester, 'abe');

    await tester.tap(find.byKey(const Key('membership-1')));
    await tester.pumpAndSettle();
    expect(find.text("Abebe Kebede's membership"), findsOneWidget);
    expect(find.text('Freeze days: 0 of 7 used'), findsOneWidget);

    await tester.tap(find.byKey(const Key('freeze-101')));
    await tester.pumpAndSettle();
    expect(find.textContaining('7 days · the plan will now end on'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('freeze-reason')), 'Travelling');
    await tapVisible(tester, find.descendant(of: find.byType(FreezeMembershipSheet), matching: find.text('Freeze')));
    expect(find.text('The membership is frozen.'), findsOneWidget);
    expect(find.text('Freeze days: 7 of 7 used'), findsOneWidget);
    expect(find.textContaining('Frozen '), findsOneWidget);
    await closeSheet(tester);

    await checkIn(tester, 'Abebe Kebede');
    expect(find.text('Turned away'), findsOneWidget);
    await tester.tap(find.byKey(const Key('result-end-freeze')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('check-in-result')), findsNothing);
    await tester.tap(find.text('End freeze'));
    await tester.pumpAndSettle();
    expect(find.text('End the freeze today?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'End freeze'));
    await tester.pumpAndSettle();
    expect(find.text('Freeze days: 0 of 7 used'), findsOneWidget);
    await closeSheet(tester);

    await checkIn(tester, 'Abebe Kebede');
    expect(find.text('Let in'), findsOneWidget);
    await dismissResult(tester);
  });

  testWidgets('a receptionist can\'t freeze past the plan\'s freeze days, nor cancel', (tester) async {
    await startDesk(tester);
    await signInAtDesk(tester, phone: '0911 00 00 02');
    await tester.tap(find.text('Demo Gym'));
    await tester.pumpAndSettle();
    await search(tester, 'hana');

    await tester.tap(find.byKey(const Key('membership-3')));
    await tester.pumpAndSettle();
    expect(find.text('Freeze days: 3 of 7 used'), findsOneWidget);
    expect(find.byKey(const Key('cancel-103')), findsNothing);

    await tester.tap(find.byKey(const Key('freeze-103')));
    await tester.pumpAndSettle();
    expect(find.text('4 freeze days left on this plan.'), findsOneWidget);
    await tester.tap(find.byKey(const Key('freeze-last-day')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('28'));
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.text('Only 4 freeze days are left.'), findsOneWidget);
    final freeze = tester.widget<FilledButton>(
      find.descendant(of: find.byType(FreezeMembershipSheet), matching: find.byType(FilledButton)),
    );
    expect(freeze.onPressed, isNull);
  });

  testWidgets('the owner removes a coming freeze, and cancels a membership with a reason', (tester) async {
    await startDesk(tester);
    await openScanner(tester);
    await search(tester, 'hana');

    await tester.tap(find.byKey(const Key('membership-3')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('end-freeze-301')));
    await tester.pumpAndSettle();
    expect(find.text('Remove this freeze?'), findsOneWidget);
    expect(find.text('The plan ends 3 days sooner.'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Remove freeze'));
    await tester.pumpAndSettle();
    expect(find.text('The freeze is removed.'), findsOneWidget);
    expect(find.text('Freeze days: 0 of 7 used'), findsOneWidget);

    await tester.tap(find.byKey(const Key('cancel-103')));
    await tester.pumpAndSettle();
    expect(find.text('Cancel Monthly?'), findsOneWidget);
    await tester.tap(find.byKey(const Key('confirm-cancel')));
    await tester.pumpAndSettle();
    expect(find.text('The reason field is required.'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('cancel-reason')), 'Moved to another city');
    await tester.tap(find.byKey(const Key('confirm-cancel')));
    await tester.pumpAndSettle();
    expect(find.text('The membership is cancelled.'), findsOneWidget);
    expect(find.text('No membership running or to come. Sell them a plan.'), findsOneWidget);
    await closeSheet(tester);

    await checkIn(tester, 'Hana Girma');
    expect(find.text('Turned away'), findsOneWidget);
    await dismissResult(tester);
  });

  testWidgets('an accountant sees no Membership action', (tester) async {
    await startDesk(tester);
    await signInAtDesk(tester, phone: '0911 00 00 03');
    await search(tester, 'hana');
    expect(find.text('Hana Girma'), findsOneWidget);
    expect(find.byKey(const Key('membership-3')), findsNothing);
  });
}
