import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:gym_mobile/l10n/app_localizations_am.dart';
import 'package:gym_mobile/staff/app/staff_app.dart';
import 'package:gym_mobile/staff/app/staff_router.dart';
import 'package:gym_mobile/staff/fake_front_desk.dart';
import 'package:material_ui/material_ui.dart';

import '../support/desk_driver.dart';
import '../support/layout_errors.dart';
import '../support/test_doubles.dart';

/// Walks every screen and sheet of the front desk app in Amharic on a
/// 360 × 780 phone, at normal and at large text, and fails on any text that
/// overflows. A new screen joins the tour here.
void main() {
  final am = AppLocalizationsAm();

  GoRouter router(WidgetTester tester) =>
      ProviderScope.containerOf(tester.element(find.byType(StaffApp))).read(staffRouterProvider);

  Future<void> signIn(WidgetTester tester, {String phone = '0911 00 00 01'}) async {
    await tester.enterText(find.byType(TextField).first, phone);
    await tester.enterText(find.byKey(const Key('password')), 'password');
    await tester.tap(find.text(am.deskSignIn));
    await tester.pumpAndSettle();
  }

  Future<void> scrollToEnd(WidgetTester tester, {Finder? within}) async {
    final scrollable = within == null
        ? find.byType(Scrollable)
        : find.descendant(of: within, matching: find.byType(Scrollable));
    if (scrollable.evaluate().isNotEmpty) {
      await tester.drag(scrollable.first, const Offset(0, -3000), warnIfMissed: false);
      await tester.pumpAndSettle();
    }
  }

  Future<void> visit(WidgetTester tester, LayoutErrors errors, String route) async {
    errors.screen = route;
    router(tester).go(route);
    await tester.pumpAndSettle();
    await scrollToEnd(tester);
  }

  /// Closes the sheet or dialog on top, as the phone's back button does.
  Future<void> closeTop(WidgetTester tester) async {
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
  }

  /// Opens a sheet or dialog with [button], looks at all of it, and closes it.
  Future<void> peek(WidgetTester tester, LayoutErrors errors, String name, Finder button) async {
    errors.screen = name;
    await tester.ensureVisible(button);
    await tester.pumpAndSettle();
    await tester.tap(button);
    await tester.pumpAndSettle();
    await scrollToEnd(tester, within: find.byType(BottomSheet));
    await closeTop(tester);
  }

  Future<void> search(WidgetTester tester, String text) async {
    router(tester).go(StaffRoutes.desk);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, text);
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
  }

  Future<void> scanAndLook(WidgetTester tester, LayoutErrors errors, FakeCamera camera, String name, String code) async {
    errors.screen = name;
    router(tester).go(StaffRoutes.scan);
    await tester.pumpAndSettle();
    camera.show(code);
    await tester.pumpAndSettle();
    final result = find.byKey(const Key('check-in-result'));
    if (result.evaluate().isNotEmpty) {
      await tester.tap(result);
      await tester.pumpAndSettle();
    }
  }

  for (final textScale in [1.0, 1.3]) {
    testWidgets('signing in and choosing a gym and branch fit in Amharic at ${textScale}x text', (tester) async {
      final errors = LayoutErrors()..screen = 'sign in';
      await startDesk(tester, language: 'am', textScale: textScale);
      await tester.enterText(find.byType(TextField).first, '0911 00 00 02');
      await tester.enterText(find.byKey(const Key('password')), 'wrong');
      await tester.tap(find.text(am.deskSignIn));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('password')), 'password');
      errors.screen = 'choose gym';
      await tester.tap(find.text(am.deskSignIn));
      await tester.pumpAndSettle();
      errors.screen = 'choose branch';
      await tester.tap(find.text('Demo Gym'));
      await tester.pumpAndSettle();
      errors.expectNoOverflow();
    });

    testWidgets('scanning, Today, Numbers, the inbox and settings fit in Amharic at ${textScale}x text', (tester) async {
      final errors = LayoutErrors();
      final camera = FakeCamera();
      final fake = FakeFrontDesk(latency: Duration.zero, now: () => testNow);
      await startDesk(tester, camera: camera, backend: fake, language: 'am', textScale: textScale);
      await signIn(tester);
      await tester.tap(find.text('Main Branch'));
      await tester.pumpAndSettle();

      await scanAndLook(tester, errors, camera, 'let in', 'GQ1:01K7Z3M6Q8V2N4R5T9W1X0Y2AB:59275728:4F1A2B3C4D5E6F70');
      await scanAndLook(tester, errors, camera, 'owes', 'GQ1:OWES000000000000000000000:1:00');
      await scanAndLook(tester, errors, camera, 'ended plan', 'GQ1:EXPIRED00000000000000000:1:00');
      fake.noInternet = true;
      await scanAndLook(tester, errors, camera, 'offline', FakeFrontDesk.doorCode(2, testNow));
      fake.noInternet = false;
      for (final route in [StaffRoutes.today, StaffRoutes.numbers, StaffRoutes.inbox, StaffRoutes.notificationSettings]) {
        await visit(tester, errors, route);
      }
      errors.screen = 'paused banner';
      fake.paused = true;
      await visit(tester, errors, StaffRoutes.today);
      await tester.fling(find.byType(Scrollable).first, const Offset(0, 400), 1000);
      await tester.pumpAndSettle();
      fake.paused = false;
      errors.expectNoOverflow();
    });

    testWidgets('search, the member page and every member sheet fit in Amharic at ${textScale}x text', (tester) async {
      final errors = LayoutErrors();
      await startDesk(tester, language: 'am', textScale: textScale);
      await signIn(tester);
      await tester.tap(find.text('Main Branch'));
      await tester.pumpAndSettle();

      errors.screen = 'desk search';
      await search(tester, 'a');
      await search(tester, 'zzz');
      await peek(tester, errors, 'add member', find.byKey(const Key('add-member')));
      await search(tester, 'abe');
      await peek(tester, errors, 'take payment', find.byKey(const Key('take-payment-1')));
      await peek(tester, errors, 'sell a plan', find.byKey(const Key('sell-plan-1')));
      await peek(tester, errors, 'membership', find.byKey(const Key('membership-1')));
      await peek(tester, errors, 'photo', find.byKey(const Key('member-photo-1')));

      errors.screen = 'freeze';
      await tester.ensureVisible(find.byKey(const Key('membership-1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('membership-1')));
      await tester.pumpAndSettle();
      await peek(tester, errors, 'freeze form', find.byKey(const Key('freeze-101')));
      await closeTop(tester);
      errors.screen = 'cancel dialog';
      await tester.ensureVisible(find.byKey(const Key('membership-1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('membership-1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('cancel-101')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('confirm-cancel')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(am.deskKeepMembership));
      await tester.pumpAndSettle();
      await closeTop(tester);

      for (final id in [1, 2, 3]) {
        await visit(tester, errors, StaffRoutes.member(id));
      }
      await visit(tester, errors, StaffRoutes.member(1));
      await peek(tester, errors, 'edit', find.byKey(const Key('edit-member')));
      errors.expectNoOverflow();
    });
  }
}
