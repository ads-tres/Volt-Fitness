import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_mobile/app/app.dart';
import 'package:material_ui/material_ui.dart';

import '../support/test_doubles.dart';

/// The app on a 360×780 phone, signed out, talking to the fake backend.
Future<void> startApp(WidgetTester tester, {bool onboardingDone = true}) async {
  tester.view.physicalSize = const Size(1080, 2340);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: await testOverrides(fakeBackend: true, onboardingDone: onboardingDone),
      child: const VoltApp(),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> signInWith(WidgetTester tester, {required String phone, String code = '123456'}) async {
  await tester.enterText(find.byType(TextField), phone);
  await tester.tap(find.text('Continue'));
  await tester.pumpAndSettle();
  expect(find.text('Enter the code'), findsOneWidget);
  await tester.enterText(find.byType(TextField), code);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('a first launch walks through the welcome pages to sign-in', (tester) async {
    await startApp(tester, onboardingDone: false);
    expect(find.text('Your gym,\nin your pocket'), findsOneWidget);

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Check in with\none scan'), findsOneWidget);

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Skip'), findsNothing);
    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();

    expect(find.text('Welcome to Volt'), findsOneWidget);
  });

  testWidgets('the welcome pages can be skipped', (tester) async {
    await startApp(tester, onboardingDone: false);

    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();

    expect(find.text('Welcome to Volt'), findsOneWidget);
  });

  testWidgets('a member of one gym goes from phone and code straight to their gym', (tester) async {
    await startApp(tester);
    expect(find.text('Welcome to Volt'), findsOneWidget);

    await signInWith(tester, phone: '0912 34 56 78');

    expect(find.text('Hello, Abebe'), findsOneWidget);
    expect(find.text('Bole Iron Gym'), findsWidgets);
    expect(find.text('Show my QR'), findsOneWidget);

    await tester.tap(find.text('Show my QR'));
    await tester.pumpAndSettle();
    expect(find.text('Your check-in QR code will show here.'), findsOneWidget);
  });

  testWidgets('a wrong number or code is explained, and the code can be retyped', (tester) async {
    await startApp(tester);

    await tester.enterText(find.byType(TextField), '0111234567');
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Enter an Ethiopian mobile number, like 0911 23 45 67.'), findsOneWidget);

    await signInWith(tester, phone: '0912345678', code: '111111');
    expect(find.text("That code isn't right. Check the SMS and try again."), findsOneWidget);

    await tester.enterText(find.byType(TextField), '123456');
    await tester.pumpAndSettle();
    expect(find.text('Hello, Abebe'), findsOneWidget);
  });

  testWidgets('a member of two gyms chooses one, and the app takes its name', (tester) async {
    await startApp(tester);

    await signInWith(tester, phone: '0911111111');
    expect(find.text('Choose your gym'), findsOneWidget);

    await tester.tap(find.text('Kazanchis Fit Club'));
    await tester.pumpAndSettle();

    expect(find.text('Hello, Abebe'), findsOneWidget);
    expect(find.text('Welcome back to Kazanchis Fit Club.'), findsOneWidget);
  });

  testWidgets('a number with no gym is told so and can try another', (tester) async {
    await startApp(tester);

    await signInWith(tester, phone: '0900000000');
    expect(find.text('No gym found'), findsOneWidget);

    await tester.tap(find.text('Use another number'));
    await tester.pumpAndSettle();
    expect(find.text('Welcome to Volt'), findsOneWidget);
  });

  testWidgets('Amharic can be chosen from any screen', (tester) async {
    await startApp(tester);
    await signInWith(tester, phone: '0912345678');

    await tester.tap(find.byTooltip('Language'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('አማርኛ').last);
    await tester.pumpAndSettle();

    expect(find.text('ሰላም፣ Abebe'), findsOneWidget);
    expect(find.byTooltip('መነሻ'), findsOneWidget);
  });

  testWidgets('signing out from the profile returns to the phone screen', (tester) async {
    await startApp(tester);
    await signInWith(tester, phone: '0912345678');

    await tester.tap(find.byTooltip('Profile'));
    await tester.pumpAndSettle();
    expect(find.text('+251\u00A091\u00A0234\u00A05678'), findsOneWidget);

    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();
    expect(find.text('Welcome to Volt'), findsOneWidget);
  });
}
