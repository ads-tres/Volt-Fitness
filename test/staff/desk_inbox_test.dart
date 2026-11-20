import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../support/desk_driver.dart';

void main() {
  Finder badge(String count) => find.descendant(of: find.byKey(const Key('messages')), matching: find.text(count));

  testWidgets('the bell counts unread messages; opening one shows it and marks it read', (tester) async {
    await startDesk(tester);
    await openScanner(tester);
    expect(badge('4'), findsOneWidget);

    await tester.tap(find.byKey(const Key('messages')));
    await tester.pumpAndSettle();
    expect(find.text('Messages'), findsOneWidget);
    expect(find.text('Online payment'), findsOneWidget);
    expect(find.text('Members to call today'), findsOneWidget);

    await tester.tap(find.text('Online payment'));
    await tester.pumpAndSettle();
    expect(find.text('Abebe Kebede paid 1,500.00 ETB for Monthly with Chapa.'), findsNWidgets(2));
    expect(find.text('Open in the staff panel'), findsNothing);
    await tester.tapAt(const Offset(180, 80));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Members to call today'));
    await tester.pumpAndSettle();
    expect(find.text('Open in the staff panel'), findsOneWidget);
    await tester.tapAt(const Offset(180, 80));
    await tester.pumpAndSettle();

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(badge('2'), findsOneWidget);
  });

  testWidgets('mark all read clears the bell', (tester) async {
    await startDesk(tester);
    await openScanner(tester);

    await tester.tap(find.byKey(const Key('messages')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mark all read'));
    await tester.pumpAndSettle();
    expect(find.text('Mark all read'), findsNothing);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(badge('4'), findsNothing);
    expect(find.byIcon(Icons.notifications_none_rounded), findsOneWidget);
  });
}
