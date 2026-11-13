import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_mobile/app/bootstrap.dart';
import 'package:gym_mobile/core/network/api_client.dart';
import 'package:gym_mobile/staff/app/staff_app.dart';
import 'package:gym_mobile/staff/core/desk_session.dart';
import 'package:gym_mobile/staff/fake_front_desk.dart';
import 'package:gym_mobile/staff/features/scan/presentation/code_camera.dart';
import 'package:material_ui/material_ui.dart';

import 'test_doubles.dart';

/// The front desk app on a 360×780 phone, signed out, talking to its fake.
Future<void> startDesk(WidgetTester tester, {CodeCamera? camera}) async {
  tester.view.physicalSize = const Size(1080, 2340);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final overrides = await testOverrides(
    fakeBackend: true,
    fakeAdapter: FakeFrontDesk(latency: Duration.zero, now: () => testNow),
  );
  await tester.pumpWidget(
    ProviderScope(
      retry: noAutomaticRetry,
      overrides: [
        ...overrides,
        codeCameraProvider.overrideWithValue(camera ?? FakeCamera()),
        onUnauthorizedProvider.overrideWith(
          (ref) =>
              () => unawaited(ref.read(deskSessionProvider.notifier).signOut()),
        ),
      ],
      child: const StaffApp(),
    ),
  );
  await tester.pumpAndSettle();
}

/// Signs in on the front desk's sign-in screen.
Future<void> signInAtDesk(WidgetTester tester, {String phone = '0911 00 00 01', String password = 'password'}) async {
  await tester.enterText(find.byType(TextField).first, phone);
  await tester.enterText(find.byKey(const Key('password')), password);
  await tester.tap(find.text('Sign in'));
  await tester.pumpAndSettle();
}

/// Stands in for the phone's camera: [show] holds a QR code up to it.
final class FakeCamera implements CodeCamera {
  void Function(String code)? _onCode;

  void show(String code) => _onCode?.call(code);

  @override
  Widget build(BuildContext context, void Function(String code) onCode) {
    _onCode = onCode;
    return const ColoredBox(color: Colors.black);
  }
}

/// Signs in as Demo Gym's owner and chooses Main Branch.
Future<void> openScanner(WidgetTester tester) async {
  await signInAtDesk(tester);
  await tester.tap(find.text('Main Branch'));
  await tester.pumpAndSettle();
}
