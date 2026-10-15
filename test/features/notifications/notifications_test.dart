import 'package:flutter_test/flutter_test.dart';
import 'package:gym_mobile/features/notifications/data/notifications_repository.dart';
import 'package:gym_mobile/features/notifications/domain/app_notification.dart';
import 'package:gym_mobile/features/notifications/presentation/notification_routes.dart';

void main() {
  test('a notification of a type the app does not know still reads, and opens nothing', () {
    final notification = notificationFromJson({
      'id': '01K7ZN0000000000000000000A',
      'type': 'class_reminder',
      'title': 'Spin at 18:00',
      'body': 'See you there.',
      'data': {'class_id': '01K7ZC', 'seats': 3},
      'created_at': '2026-10-14T05:00:00Z',
      'read_at': null,
    });
    expect(notification.topic, isNull);
    expect(notification.isRead, isFalse);
    // FCM data values are strings; anything else is dropped.
    expect(notification.data, {'class_id': '01K7ZC'});
    expect(notificationRoute(notification.type, notification.data), isNull);
  });

  test('each topic opens its screen, new types included', () {
    expect(notificationRoute('membership_expiring', {}), '/membership');
    expect(notificationRoute('membership_resumed', {}), '/membership');
    expect(notificationRoute('invoice_due', {'invoice_id': '01K7ZAI'}), '/payments/invoices/01K7ZAI');
    expect(notificationRoute('payment_failed', {}), '/payments');
    expect(notificationRoute('visit_denied', {}), '/home/visits');
    expect(notificationRoute('announcement', {}), isNull);
  });

  test('topics the API leaves out count as on', () {
    final preferences = preferencesFromJson({'announcements': false, 'visits': 'no'});
    expect(preferences[NotificationTopic.announcements], isFalse);
    expect(preferences[NotificationTopic.visits], isTrue);
    expect(preferences[NotificationTopic.membership], isTrue);
  });
}
