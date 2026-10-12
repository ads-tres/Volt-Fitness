import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_mobile/app/app.dart';
import 'package:material_ui/material_ui.dart';

import '../support/test_doubles.dart';

void main() {
  testWidgets('signing in leads home and signing out leads back', (tester) async {
    await tester.pumpWidget(ProviderScope(overrides: await testOverrides(), child: const VoltApp()));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Sign in'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Home'), findsOneWidget);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Sign out'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Sign in'), findsOneWidget);
  });

  testWidgets('choosing Amharic translates the app and is remembered', (tester) async {
    final preferences = InMemoryPreferencesStore();
    await tester.pumpWidget(
      ProviderScope(
        overrides: await testOverrides(token: 'stored-token', preferences: preferences),
        child: const VoltApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Home'), findsOneWidget);

    await tester.tap(find.byTooltip('Language'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('አማርኛ').last);
    await tester.pumpAndSettle();

    expect(find.widgetWithText(AppBar, 'መነሻ'), findsOneWidget);
    expect(preferences.values['settings.language'], 'am');
  });
}
