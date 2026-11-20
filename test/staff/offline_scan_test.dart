import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_mobile/staff/app/desk_shell.dart';
import 'package:gym_mobile/staff/app/staff_app.dart';
import 'package:gym_mobile/staff/features/scan/data/scan_outbox.dart';

import '../support/desk_driver.dart';

void main() {
  const offlineCode = 'GQ1:OFFLINE0000000000000000:1:00';

  ProviderContainer containerOf(WidgetTester tester) => ProviderScope.containerOf(tester.element(find.byType(StaffApp)));

  testWidgets('without internet the scan is kept, amber says so, and it is sent when the desk retries', (tester) async {
    final camera = FakeCamera();
    await startDesk(tester, camera: camera);
    await openScanner(tester);

    camera.show(offlineCode);
    await tester.pumpAndSettle();

    expect(find.text('Saved, will check when back online'), findsOneWidget);
    expect(find.text('Let in'), findsNothing);
    final waiting = containerOf(tester).read(scanOutboxProvider).pending;
    expect(waiting.single.payload, offlineCode);
    expect(waiting.single.branchId, 1);

    await tester.tap(find.byKey(const Key('saved-offline')));
    await tester.pumpAndSettle();
    expect(find.text('Saved, will check when back online'), findsNothing);

    await tester.pump(DeskShell.retryEvery);
    await tester.pumpAndSettle();
    expect(containerOf(tester).read(scanOutboxProvider).pending, isEmpty);
  });

  testWidgets('a scan that gets through sends what was waiting', (tester) async {
    final camera = FakeCamera();
    await startDesk(tester, camera: camera);
    await openScanner(tester);

    camera.show(offlineCode);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('saved-offline')));
    await tester.pumpAndSettle();
    expect(containerOf(tester).read(scanOutboxProvider).pending, hasLength(1));

    camera.show('GQ1:01K7Z3M6Q8V2N4R5T9W1X0Y2AB:59275728:4F1A2B3C4D5E6F70');
    await tester.pumpAndSettle();

    expect(find.text('Let in'), findsOneWidget);
    expect(containerOf(tester).read(scanOutboxProvider).pending, isEmpty);
    await tester.tap(find.byKey(const Key('check-in-result')));
    await tester.pumpAndSettle();
  });

  testWidgets('the top bar counts what waits; Today lists it, sends it, and marks it once sent', (tester) async {
    final camera = FakeCamera();
    await startDesk(tester, camera: camera);
    await openScanner(tester);
    camera.show(offlineCode);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('saved-offline')));
    await tester.pumpAndSettle();

    expect(find.text('1 waiting'), findsOneWidget);
    await tester.tap(find.byKey(const Key('waiting-scans')));
    await tester.pumpAndSettle();

    expect(find.text('Waiting to send'), findsOneWidget);
    expect(find.text('Scanned at 09:30'), findsOneWidget);
    expect(find.text('Scanned offline'), findsNothing);

    await tester.tap(find.text('Send now'));
    await tester.pumpAndSettle();

    expect(find.text('Waiting to send'), findsNothing);
    expect(find.text('1 waiting'), findsNothing);
    expect(find.text('Scanned offline'), findsOneWidget, reason: 'Hana, let in as of 09:30');
  });
}
