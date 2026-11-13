import 'package:flutter_test/flutter_test.dart';
import 'package:gym_mobile/staff/features/desk/data/member_search.dart';
import 'package:material_ui/material_ui.dart';

import '../support/desk_driver.dart';

void main() {
  Future<void> openTab(WidgetTester tester, String tab) async {
    await tester.tap(find.text(tab));
    await tester.pumpAndSettle();
  }

  Future<void> searchFor(WidgetTester tester, String text) async {
    await tester.enterText(find.byType(TextField), text);
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
  }

  testWidgets('a member without their phone is found by name and checked in at the desk', (tester) async {
    await startDesk(tester);
    await openScanner(tester);
    await openTab(tester, 'Desk');

    await searchFor(tester, 'abe');
    expect(find.text('Abebe Kebede'), findsOneWidget);
    expect(find.textContaining('Owes 1,000.00 ETB'), findsOneWidget);

    await tester.tap(find.text('Check in'));
    await tester.pumpAndSettle();
    expect(find.text('Let in'), findsOneWidget);
    expect(find.text('Abebe Kebede'), findsWidgets);

    await tester.tap(find.byKey(const Key('check-in-result')));
    await tester.pumpAndSettle();
    expect(find.text('Let in'), findsNothing);
  });

  testWidgets('a member is found by phone, and the desk rules apply too', (tester) async {
    await startDesk(tester);
    await openScanner(tester);
    await openTab(tester, 'Desk');

    await searchFor(tester, '0922');
    expect(find.text('Tigist Haile'), findsOneWidget);
    await tester.tap(find.text('Check in'));
    await tester.pumpAndSettle();

    expect(find.text('Turned away'), findsOneWidget);
    expect(find.text('The membership has ended'), findsOneWidget);
    await tester.tap(find.byKey(const Key('check-in-result')));
    await tester.pumpAndSettle();
  });

  testWidgets('today lists the branch\'s check-ins, newest first, with why someone was turned away', (tester) async {
    final camera = FakeCamera();
    await startDesk(tester, camera: camera);
    await openScanner(tester);
    camera.show('GQ1:01K7Z3M6Q8V2N4R5T9W1X0Y2AB:59275728:4F1A2B3C4D5E6F70');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('check-in-result')));
    await tester.pumpAndSettle();

    await openTab(tester, 'Today');

    expect(find.text('Today at this branch'), findsOneWidget);
    final names = tester.widgetList<ListTile>(find.byType(ListTile)).map((tile) => (tile.title! as Text).data).toList();
    expect(names, ['Hana Girma', 'Hana Girma', 'Abebe Kebede']);
    expect(find.text('The branch is closed now'), findsOneWidget);
  });

  test('reads a member from the staff API', () {
    final member = deskMemberFromJson({
      'id': 3,
      'full_name': 'Hana Girma',
      'phone': '+251933456789',
      'membership': {
        'id': 7,
        'member_id': 3,
        'plan': {'id': 2, 'name': 'Monthly'},
        'status': 'active',
      },
      'balance_due': {'amount_minor': 0, 'currency': 'ETB', 'formatted': '0.00 ETB'},
    });

    expect((member.id, member.name, member.planName, member.status), (3, 'Hana Girma', 'Monthly', 'active'));
  });
}
