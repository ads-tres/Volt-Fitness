import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_mobile/app/app.dart';
import 'package:gym_mobile/app/bootstrap.dart';
import 'package:material_ui/material_ui.dart';

import 'test_doubles.dart';

/// The app on a 360×780 phone, signed out, talking to the fake backend, or
/// to [backend] when a test needs answers the fake doesn't give.
Future<void> startApp(
  WidgetTester tester, {
  bool onboardingDone = true,
  bool pushAllowed = true,
  HttpClientAdapter? backend,
  List<Override> extraOverrides = const [],
  String? language,
  double textScale = 1,
}) async {
  tester.view.physicalSize = const Size(1080, 2340);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  if (textScale != 1) {
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  }
  await tester.pumpWidget(
    ProviderScope(
      retry: noAutomaticRetry,
      overrides: [
        ...await testOverrides(
          fakeBackend: true,
          fakeAdapter: backend,
          onboardingDone: onboardingDone,
          pushAllowed: pushAllowed,
          language: language,
        ),
        ...extraOverrides,
      ],
      child: const VoltApp(),
    ),
  );
  await tester.pumpAndSettle();
}

/// Signs in through the phone and code screens.
Future<void> signInWith(WidgetTester tester, {required String phone, String code = '123456'}) async {
  await tester.enterText(find.byType(TextField), phone);
  await tester.tap(find.text('Continue'));
  await tester.pumpAndSettle();
  expect(find.text('Enter the code'), findsOneWidget);
  await tester.enterText(find.byType(TextField), code);
  await tester.pumpAndSettle();
}

/// Lets a second of animations and loads pass. Use it where `pumpAndSettle`
/// never settles: the QR screen redraws every second.
Future<void> pumpFor(WidgetTester tester, [Duration duration = const Duration(seconds: 1)]) async {
  for (var elapsed = Duration.zero; elapsed < duration; elapsed += const Duration(milliseconds: 100)) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}
