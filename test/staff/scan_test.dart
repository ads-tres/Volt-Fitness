import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_mobile/staff/features/scan/domain/desk_check_in.dart';
import 'package:gym_mobile/staff/features/scan/presentation/scan_page.dart';

import '../support/desk_driver.dart';

void main() {
  const code = 'GQ1:01K7Z3M6Q8V2N4R5T9W1X0Y2AB:59275728:4F1A2B3C4D5E6F70';

  testWidgets('a member\'s code lets them in, and the scanner is back after a few seconds', (tester) async {
    final camera = FakeCamera();
    await startDesk(tester, camera: camera);
    await openScanner(tester);

    camera.show(code);
    await tester.pumpAndSettle();

    expect(find.text('Let in'), findsOneWidget);
    expect(find.text('Hana Girma'), findsOneWidget);
    expect(find.text('Monthly · until Nov 1, 2026'), findsOneWidget);

    await tester.pump(ScanPage.resultShownFor);
    await tester.pumpAndSettle();
    expect(find.text('Let in'), findsNothing);
    expect(find.text("Point the camera at the member's QR code"), findsOneWidget);
  });

  testWidgets('a turned-away member shows why, and what is owed shows either way', (tester) async {
    final camera = FakeCamera();
    await startDesk(tester, camera: camera);
    await openScanner(tester);

    camera.show('GQ1:EXPIRED00000000000000000:1:00');
    await tester.pumpAndSettle();
    expect(find.text('Turned away'), findsOneWidget);
    expect(find.text('The membership has ended'), findsOneWidget);
    expect(find.text('Tigist Haile'), findsOneWidget);

    await tester.tap(find.byKey(const Key('check-in-result')));
    await tester.pumpAndSettle();
    camera.show('GQ1:OWES000000000000000000000:1:00');
    await tester.pumpAndSettle();
    expect(find.text('Let in'), findsOneWidget);
    expect(find.text('Owes 1,000.00 ETB'), findsOneWidget);
    await tester.tap(find.byKey(const Key('check-in-result')));
    await tester.pumpAndSettle();
  });

  testWidgets('other QR codes are ignored, and a code still in view isn\'t sent twice', (tester) async {
    final camera = FakeCamera();
    await startDesk(tester, camera: camera);
    await openScanner(tester);

    camera.show('https://example.com');
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('check-in-result')), findsNothing);

    camera.show(code);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('check-in-result')));
    await tester.pumpAndSettle();
    camera.show(code);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('check-in-result')), findsNothing, reason: 'the same code, moments later');
  });

  test('reads a check-in from the staff API', () {
    final checkIn = deskCheckInFromJson({
      'id': 5,
      'decision': 'deny',
      'reason_code': 'VISITS_USED_UP',
      'method': 'qr',
      'checked_in_at': '2026-10-14T06:05:00+03:00',
      'branch': {'id': 1, 'code': 'MAIN', 'name': 'Main Branch', 'address': null},
      'member': {'id': 3, 'full_name': 'Hana Girma', 'phone': '+251933456789'},
      'membership': {
        'id': 7,
        'plan': {'id': 2, 'name': '10 Visits'},
        'starts_on': '2026-10-02',
        'ends_on': '2026-11-30',
        'balance_due': {'amount_minor': 50000, 'currency': 'ETB', 'formatted': '500.00 ETB'},
      },
      'checked_in_by': {'id': 1, 'name': 'Demo Owner'},
    });

    expect(checkIn.letIn, isFalse);
    expect(checkIn.reasonCode, 'VISITS_USED_UP');
    expect(checkIn.planName, '10 Visits');
    expect(checkIn.owes, isTrue);
    expect(checkIn.checkedInAt, DateTime.utc(2026, 10, 14, 3, 5));
  });
}
