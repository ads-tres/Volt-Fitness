import 'package:flutter_test/flutter_test.dart';
import 'package:gym_mobile/staff/fake_front_desk.dart';
import 'package:material_ui/material_ui.dart';

import '../support/desk_driver.dart';
import '../support/test_doubles.dart';

void main() {
  testWidgets('a paused gym shows a banner on every tab, says why a scan fails, and goes once it is back', (tester) async {
    final camera = FakeCamera();
    final fake = FakeFrontDesk(latency: Duration.zero, now: () => testNow);
    await startDesk(tester, camera: camera, backend: fake);
    await openScanner(tester);
    expect(find.byKey(const Key('gym-paused')), findsNothing);

    fake.paused = true;
    await tester.tap(find.text('Today'));
    await tester.pumpAndSettle();
    await tester.fling(find.byType(Scrollable).first, const Offset(0, 400), 1000);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('gym-paused')), findsOneWidget);
    expect(find.textContaining('This gym is paused. Contact the platform'), findsOneWidget);

    await tester.tap(find.text('Scan'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('gym-paused')), findsOneWidget, reason: 'on every tab');
    camera.show('GQ1:01K7Z3M6Q8V2N4R5T9W1X0Y2AB:59275728:4F1A2B3C4D5E6F70');
    await tester.pumpAndSettle();
    expect(find.text('This gym is paused by the platform. Contact the platform to switch it back on.'), findsOneWidget);

    fake.paused = false;
    await tester.tap(find.text('Today'));
    await tester.pumpAndSettle();
    await tester.fling(find.byType(Scrollable).first, const Offset(0, 400), 1000);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('gym-paused')), findsNothing);
  });

  testWidgets('the gym chooser marks a paused gym', (tester) async {
    final fake = FakeFrontDesk(latency: Duration.zero, now: () => testNow)..paused = true;
    await startDesk(tester, backend: fake);
    await signInAtDesk(tester, phone: '0911 00 00 02');

    final demo = find.ancestor(of: find.text('Demo Gym'), matching: find.byType(Row));
    expect(find.descendant(of: demo, matching: find.text('Paused')), findsOneWidget);
    final bole = find.ancestor(of: find.text('Bole Fitness'), matching: find.byType(Row));
    expect(find.descendant(of: bole, matching: find.text('Paused')), findsNothing);
  });
}
