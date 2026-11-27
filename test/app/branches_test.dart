import 'package:flutter_test/flutter_test.dart';
import 'package:gym_mobile/app/routes.dart';
import 'package:gym_mobile/features/notifications/domain/app_notification.dart';
import 'package:gym_mobile/features/notifications/presentation/notification_routes.dart';

import '../support/app_driver.dart';

void main() {
  testWidgets('Profile shows the branches with their hours and whether each is open now', (tester) async {
    await startApp(tester);
    await signInWith(tester, phone: '0912345678');
    await tester.tap(find.byTooltip('Profile'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Branches and hours'));
    await tester.pumpAndSettle();

    expect(find.text('Bole'), findsOneWidget);
    expect(find.text('Open now · until 22:00'), findsOneWidget, reason: 'Tuesday 09:30');
    expect(find.text('Tue'), findsOneWidget);
    expect(find.text('08:00 – 14:00'), findsOneWidget, reason: 'Sunday');
    expect(find.text('Megenagna'), findsOneWidget);
    expect(find.text('Always open'), findsOneWidget);
    expect(find.text('Your plan'), findsNWidgets(2), reason: 'the plan is limited to both branches');

    expect(find.text('Closures and other hours'), findsOneWidget);
    expect(find.text('Oct 15, 2026 · Timket'), findsOneWidget);
    expect(find.text('Closed · Tir 11 · Every year'), findsOneWidget);
    expect(find.text('Oct 19, 2026 · Staff training'), findsOneWidget);
    expect(find.text('08:00–12:00'), findsOneWidget);
  });

  test('a branch closing, keeping other hours or reopening opens the branches and their hours', () {
    for (final type in ['branch_closed', 'branch_hours_changed', 'branch_reopened']) {
      expect(notificationRoute(type, {'branch_id': '1'}), AppRoutes.branches);
      expect(topicOf(type), NotificationTopic.announcements, reason: 'gym news, as the API files it');
    }
  });
}
