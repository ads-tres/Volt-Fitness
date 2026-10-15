import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_mobile/app/app.dart';
import 'package:gym_mobile/core/push/push_service.dart';
import 'package:material_ui/material_ui.dart';

import '../support/app_driver.dart';
import '../support/test_doubles.dart';

/// The fake backend gives each number notifications that fit its plan; the
/// fake push service stands in for FCM.
void main() {
  FakePushService fakePush(WidgetTester tester) =>
      ProviderScope.containerOf(tester.element(find.byType(VoltApp))).read(pushServiceProvider) as FakePushService;

  Finder bellCount(String count) => find.descendant(of: find.byTooltip('Notifications'), matching: find.text(count));

  Future<void> openInbox(WidgetTester tester) async {
    await tester.tap(find.byTooltip('Notifications'));
    await tester.pumpAndSettle();
  }

  final endingSoonInvoiceId = '01K7ZAIINV20260187'.padRight(26, '0');

  testWidgets('the bell counts unread notifications, and one opens what it is about', (tester) async {
    await startApp(tester);
    await signInWith(tester, phone: '0922222222');
    expect(bellCount('3'), findsOneWidget);

    await openInbox(tester);
    expect(find.text('Your plan ends in 3 days'), findsOneWidget);
    expect(find.text('Holiday hours on Saturday'), findsOneWidget);

    await tester.tap(find.text('New invoice INV-2026-0187'));
    await tester.pumpAndSettle();
    expect(find.text('Invoice INV-2026-0187'), findsOneWidget);

    // The home tab kept its place: the inbox, one read now.
    await tester.tap(find.byTooltip('Home'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(bellCount('2'), findsOneWidget);
  });

  testWidgets('mark all as read clears the bell', (tester) async {
    await startApp(tester);
    await signInWith(tester, phone: '0922222222');
    await openInbox(tester);

    await tester.tap(find.byTooltip('Mark all as read'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Mark all as read'), findsNothing);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(bellCount('3'), findsNothing);
  });

  testWidgets('gym news opens in full', (tester) async {
    await startApp(tester);
    await signInWith(tester, phone: '0912345678');
    await openInbox(tester);

    await tester.tap(find.text('Holiday hours on Saturday'));
    await tester.pumpAndSettle();
    // In the list and in the sheet.
    expect(find.text('For Meskel, both branches open from 8:00 to 14:00. Happy holiday!'), findsNWidgets(2));

    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(find.text('Done'), findsNothing);
  });

  testWidgets('a tapped push opens its target in its own gym', (tester) async {
    await startApp(tester);
    await signInWith(tester, phone: '0911111111');
    await tester.tap(find.text('Bole Iron Gym'));
    await tester.pumpAndSettle();

    fakePush(tester).deliver(
      PushMessage(
        title: 'Your plan ends soon',
        data: {'type': 'membership_expiring', 'organization_id': kazanchisGym.id},
      ),
      tapped: true,
    );
    await tester.pumpAndSettle();

    expect(find.text('Quarterly'), findsOneWidget);
    expect(find.text('Kazanchis'), findsOneWidget);
  });

  testWidgets('a push while the app is open shows a banner that opens it', (tester) async {
    await startApp(tester);
    await signInWith(tester, phone: '0922222222');
    final push = fakePush(tester);
    final message = PushMessage(
      title: 'Payment due in 3 days',
      body: '1,500.00 ETB for INV-2026-0187.',
      data: {'type': 'invoice_due', 'organization_id': boleGym.id, 'invoice_id': endingSoonInvoiceId},
    );

    push.deliver(message);
    await tester.pumpAndSettle();
    expect(find.text('Payment due in 3 days'), findsOneWidget);
    // It goes away on its own.
    await tester.pump(const Duration(seconds: 7));
    expect(find.text('Payment due in 3 days'), findsNothing);

    push.deliver(message);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Payment due in 3 days'));
    await tester.pumpAndSettle();
    expect(find.text('Invoice INV-2026-0187'), findsOneWidget);
    expect(find.text('Payment due in 3 days'), findsNothing);
  });

  testWidgets('notification settings keep each switch', (tester) async {
    await startApp(tester);
    await signInWith(tester, phone: '0912345678');
    await tester.tap(find.byTooltip('Profile'));
    await tester.pumpAndSettle();

    Future<void> openSettings() async {
      await tester.tap(find.text('Notifications'));
      await tester.pumpAndSettle();
    }

    bool switchedOn(String topic) => tester
        .widget<Switch>(
          find.descendant(
            of: find.ancestor(of: find.text(topic), matching: find.byType(Row)).first,
            matching: find.byType(Switch),
          ),
        )
        .value;

    await openSettings();
    expect(switchedOn('News from your gym'), isTrue);
    await tester.tap(find.text('News from your gym'));
    await tester.pumpAndSettle();
    expect(switchedOn('News from your gym'), isFalse);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    await openSettings();
    expect(switchedOn('News from your gym'), isFalse);
    expect(switchedOn('My plan'), isTrue);
  });

  testWidgets('home offers to turn on notifications', (tester) async {
    await startApp(tester, pushAllowed: false);
    await signInWith(tester, phone: '0912345678');
    expect(find.text('Turn on notifications'), findsOneWidget);

    await tester.tap(find.text('Turn on'));
    await tester.pumpAndSettle();
    expect(find.text('Turn on notifications'), findsNothing);
  });

  testWidgets('"Not now" takes the offer off home, but the inbox still has it', (tester) async {
    await startApp(tester, pushAllowed: false);
    await signInWith(tester, phone: '0912345678');

    await tester.tap(find.text('Not now'));
    await tester.pumpAndSettle();
    expect(find.text('Turn on notifications'), findsNothing);

    await openInbox(tester);
    expect(find.text('Turn on notifications'), findsOneWidget);
    expect(find.text('Not now'), findsNothing);
  });
}
