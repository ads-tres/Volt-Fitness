import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_mobile/app/bootstrap.dart';
import 'package:gym_mobile/core/network/api_client.dart';
import 'package:gym_mobile/staff/app/staff_app.dart';
import 'package:gym_mobile/staff/core/desk_session.dart';
import 'package:gym_mobile/staff/fake_front_desk.dart';
import 'package:material_ui/material_ui.dart';

import 'test_doubles.dart';

/// The front desk app on a 360×780 phone, signed out, talking to its fake.
Future<void> startDesk(WidgetTester tester) async {
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
