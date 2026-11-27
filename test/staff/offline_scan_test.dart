import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_mobile/staff/app/desk_shell.dart';
import 'package:gym_mobile/staff/app/staff_app.dart';
import 'package:gym_mobile/staff/fake_front_desk.dart';
import 'package:gym_mobile/staff/features/scan/data/scan_outbox.dart';
import 'package:material_ui/material_ui.dart';

import '../support/desk_driver.dart';
import '../support/test_doubles.dart';

void main() {
  ProviderContainer containerOf(WidgetTester tester) => ProviderScope.containerOf(tester.element(find.byType(StaffApp)));

  Future<void> dismiss(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('check-in-result')));
    await tester.pumpAndSettle();
  }

  testWidgets('without internet the door list decides: green for a member, red with the reason, sent once online', (tester) async {
    final camera = FakeCamera();
    final fake = FakeFrontDesk(latency: Duration.zero, now: () => testNow);
    await startDesk(tester, camera: camera, backend: fake);
    await openScanner(tester);
    fake.noInternet = true;

    camera.show(FakeFrontDesk.doorCode(1, testNow));
    await tester.pumpAndSettle();
    expect(find.text('Let in'), findsOneWidget);
    expect(find.text('Abebe Kebede'), findsOneWidget);
    expect(find.text('Decided offline'), findsOneWidget);
    await dismiss(tester);

    camera.show(FakeFrontDesk.doorCode(2, testNow));
    await tester.pumpAndSettle();
    expect(find.text('Turned away'), findsOneWidget);
    expect(find.text('The membership has ended'), findsOneWidget);
    await dismiss(tester);

    expect(find.text('2 waiting'), findsOneWidget);
    final waiting = containerOf(tester).read(scanOutboxProvider).pending;
    expect([for (final scan in waiting) (scan.letIn, scan.reasonCode)], [(true, null), (false, 'MEMBERSHIP_EXPIRED')]);

    fake.noInternet = false;
    await tester.pump(DeskShell.retryEvery);
    await tester.pumpAndSettle();
    expect(containerOf(tester).read(scanOutboxProvider).pending, isEmpty);
    expect(find.text('2 waiting'), findsNothing);
  });

  testWidgets('without internet and without a door list, the desk says it can\'t check', (tester) async {
    final camera = FakeCamera();
    final fake = FakeFrontDesk(latency: Duration.zero, now: () => testNow);
    await startDesk(tester, camera: camera, backend: fake);
    await signInAtDesk(tester);
    fake.noInternet = true;
    await tester.tap(find.text('Main Branch'));
    await tester.pumpAndSettle();

    camera.show(FakeFrontDesk.doorCode(1, testNow));
    await tester.pumpAndSettle();

    expect(find.text('Turned away'), findsOneWidget);
    expect(find.text('No internet, and no door list to check with'), findsOneWidget);
    expect(containerOf(tester).read(scanOutboxProvider).pending, isEmpty, reason: 'nothing was decided');
  });
}
