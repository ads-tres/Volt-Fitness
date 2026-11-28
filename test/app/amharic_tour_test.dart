import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:gym_mobile/app/app.dart';
import 'package:gym_mobile/app/router.dart';
import 'package:gym_mobile/l10n/app_localizations_am.dart';
import 'package:material_ui/material_ui.dart';

import '../support/app_driver.dart';
import '../support/layout_errors.dart';

/// Walks every screen of the member app in Amharic on a 360 × 780 phone,
/// at normal and at large text, and fails on any text that overflows. A new
/// screen joins the tour here.
void main() {
  final am = AppLocalizationsAm();

  GoRouter router(WidgetTester tester) =>
      ProviderScope.containerOf(tester.element(find.byType(VoltApp))).read(routerProvider);

  Future<void> signIn(WidgetTester tester, String phone) async {
    await tester.enterText(find.byType(TextField), phone);
    await tester.tap(find.text(am.continueButton));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '123456');
    await tester.pumpAndSettle();
  }

  /// Opens [route] and looks at every part of it by scrolling to the end.
  Future<void> visit(WidgetTester tester, LayoutErrors errors, String route, {bool ticking = false}) async {
    errors.screen = route;
    router(tester).go(route);
    if (ticking) {
      await pumpFor(tester);
    } else {
      await tester.pumpAndSettle();
    }
    final scrollable = find.byType(Scrollable);
    if (scrollable.evaluate().isNotEmpty) {
      await tester.drag(scrollable.first, const Offset(0, -3000), warnIfMissed: false);
      if (ticking) {
        await pumpFor(tester);
      } else {
        await tester.pumpAndSettle();
      }
    }
  }

  Future<void> openSheet(WidgetTester tester, LayoutErrors errors, String name, Finder button) async {
    errors.screen = name;
    await tester.ensureVisible(button);
    await tester.pumpAndSettle();
    await tester.tap(button);
    await tester.pumpAndSettle();
    final sheet = find.byType(BottomSheet);
    if (sheet.evaluate().isNotEmpty) {
      final scrollable = find.descendant(of: sheet, matching: find.byType(Scrollable));
      if (scrollable.evaluate().isNotEmpty) {
        await tester.drag(scrollable.first, const Offset(0, -2000), warnIfMissed: false);
        await tester.pumpAndSettle();
      }
    }
    await tester.tapAt(const Offset(180, 20));
    await tester.pumpAndSettle();
  }

  for (final textScale in [1.0, 1.3]) {
    testWidgets('the welcome and sign-in screens fit in Amharic at ${textScale}x text', (tester) async {
      final errors = LayoutErrors();
      await startApp(tester, onboardingDone: false, language: 'am', textScale: textScale);
      errors.screen = 'welcome';
      while (find.text(am.next).evaluate().isNotEmpty) {
        await tester.tap(find.text(am.next));
        await tester.pumpAndSettle();
      }
      errors.screen = 'login';
      await tester.tap(find.text(am.getStarted));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '0912345678');
      await tester.tap(find.text(am.continueButton));
      await tester.pumpAndSettle();
      errors.screen = 'verify';
      await tester.enterText(find.byType(TextField), '000000');
      await tester.pumpAndSettle();
      errors.expectNoOverflow();
    });

    for (final (who, phone) in [
      ('a member', '0912345678'),
      ('a member whose plan ends soon', '0922222222'),
      ('a member whose plan ended', '0933333333'),
      ('a frozen member', '0944444444'),
      ('a member without a plan', '0955555555'),
      ('a member of two gyms', '0911111111'),
    ]) {
      testWidgets('every screen fits in Amharic for $who at ${textScale}x text', (tester) async {
        final errors = LayoutErrors();
        await startApp(tester, language: 'am', textScale: textScale);
        await signIn(tester, phone);
        if (phone == '0911111111') {
          errors.screen = 'select gym';
          await tester.pumpAndSettle();
          router(tester).go(AppRoutes.selectGym);
          await tester.pumpAndSettle();
          await tester.tap(find.text('Bole Iron Gym'));
          await tester.pumpAndSettle();
        }
        for (final route in [
          AppRoutes.home,
          AppRoutes.visits,
          AppRoutes.notifications,
          AppRoutes.membership,
          AppRoutes.payments,
          AppRoutes.profile,
          AppRoutes.branches,
          AppRoutes.notificationSettings,
          AppRoutes.devices,
        ]) {
          await visit(tester, errors, route);
        }
        await visit(tester, errors, AppRoutes.qr, ticking: true);

        await visit(tester, errors, AppRoutes.membership);
        final freeze = find.text(am.freezeMembership);
        if (freeze.evaluate().isNotEmpty) await openSheet(tester, errors, 'freeze sheet', freeze);

        await visit(tester, errors, AppRoutes.payments);
        final receipt = find.textContaining('R-2026');
        if (receipt.evaluate().isNotEmpty) {
          errors.screen = 'receipt';
          await tester.tap(receipt.first);
          await tester.pumpAndSettle();
        }
        errors.expectNoOverflow();
      });
    }

    testWidgets('a paused gym fits in Amharic at ${textScale}x text', (tester) async {
      final errors = LayoutErrors();
      await startApp(tester, language: 'am', textScale: textScale);
      await signIn(tester, '0988888888');
      for (final route in [AppRoutes.home, AppRoutes.membership, AppRoutes.payments, AppRoutes.profile]) {
        await visit(tester, errors, route);
      }
      errors.expectNoOverflow();
    });
  }
}
