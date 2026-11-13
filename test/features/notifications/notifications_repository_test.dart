import 'package:flutter_test/flutter_test.dart';
import 'package:gym_mobile/features/notifications/data/notifications_repository.dart';
import 'package:gym_mobile/features/notifications/domain/app_notification.dart';
import 'package:gym_mobile/features/notifications/presentation/notification_routes.dart';

import '../../support/test_doubles.dart';

void main() {
  test('reads the gym\'s inbox a page at a time, with the unread count', () async {
    final adapter = StubAdapter(
      (_) => jsonResponse(200, {
        'data': [
          {
            'id': '9d2f1c3e-0000-4000-8000-000000000001',
            'type': 'payment_succeeded',
            'title': 'Payment received',
            'body': 'Your payment of 1,500.00 ETB for Monthly at Demo Gym was recorded.',
            'data': {'payment_id': '88', 'membership_id': '7'},
            'read_at': null,
            'created_at': '2026-10-14T09:00:00+03:00',
          },
        ],
        'links': {'next': 'https://api.test/api/v1/me/gyms/bole-iron-gym/notifications?page=2'},
        'meta': {'current_page': 1, 'last_page': 2, 'unread_count': 3},
      }),
    );
    final container = await containerWithAdapter(adapter, signedInAs: memberOf([boleGym]));
    final notifications = container.read(notificationsRepositoryProvider);

    final page = await notifications.page();
    await notifications.markRead(page.items.single.id);

    expect(adapter.requests.map((request) => '${request.method} ${request.path}'), [
      'GET /me/gyms/bole-iron-gym/notifications',
      'POST /me/gyms/bole-iron-gym/notifications/9d2f1c3e-0000-4000-8000-000000000001/read',
    ]);
    expect(page.unreadCount, 3);
    expect(page.nextCursor, '2');
    expect(notificationRoute(page.items.single.type, page.items.single.data), '/payments/invoices/88');
  });

  test('a visit pack running low is about the membership', () {
    expect(topicOf('visits_running_low'), NotificationTopic.membership);
    expect(notificationRoute('visits_running_low', const {'membership_id': '7'}), '/membership');
  });
}
