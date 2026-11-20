import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_mobile/core/network/api_client.dart';
import 'package:gym_mobile/staff/core/desk_session.dart';
import 'package:gym_mobile/staff/fake_front_desk.dart';
import 'package:gym_mobile/staff/features/messages/data/staff_inbox.dart';
import 'package:gym_mobile/staff/features/messages/data/staff_messages_repository.dart';
import 'package:gym_mobile/staff/features/messages/domain/staff_message.dart';

import '../support/test_doubles.dart';

void main() {
  const demoGym = DeskGym(slug: 'demo-gym', name: 'Demo Gym', role: 'owner', worksAtAllBranches: true);

  Future<ProviderContainer> desk({StubAdapter? adapter}) async {
    final container = ProviderContainer.test(
      overrides: await testOverrides(
        fakeBackend: adapter == null,
        fakeAdapter: FakeFrontDesk(latency: Duration.zero, now: () => testNow),
      ),
    );
    if (adapter != null) container.read(dioProvider).httpClientAdapter = adapter;
    await container.read(deskSessionProvider.notifier).signIn(
      token: adapter == null ? 'fake-desk-token:${FakeFrontDesk.staffPhone}' : '9|desk',
      name: 'Demo Owner',
      gyms: [demoGym],
    );
    return container;
  }

  test('reads the inbox, marks read, and changes a choice in the gym\'s path', () async {
    final adapter = StubAdapter(
      (request) => switch ((request.method, request.path)) {
        ('GET', '/organizations/demo-gym/notifications') => jsonResponse(200, {
          'data': [
            {
              'id': '9b1d4c6e-0000-4000-8000-000000000001',
              'type': 'staff_online_payment',
              'title': 'Online payment',
              'body': 'Abebe Kebede paid 1,500.00 ETB.',
              'data': {'payment_id': 41, 'membership_id': 101},
              'read_at': null,
              'created_at': '2026-10-14T06:25:00+00:00',
            },
          ],
          'links': {'next': '?page=2'},
          'meta': {'current_page': 1, 'unread_count': 7},
        }),
        ('PATCH', _) => jsonResponse(200, {
          'data': {
            'online_payments': {'push': true, 'sms': false},
            'refunds': {'push': true, 'sms': true},
            'app_freezes': {'push': false, 'sms': false},
          },
        }),
        _ => jsonResponse(204, null),
      },
    );
    final container = await desk(adapter: adapter);
    final messages = container.read(staffMessagesRepositoryProvider);

    final page = await messages.page();
    await messages.markRead(page.messages.single.id);
    await messages.markAllRead();
    final choices = await messages.updatePreferences(StaffTopic.refunds, sms: true);

    expect(page.unreadCount, 7);
    expect(page.nextPage, 2);
    expect(page.messages.single.title, 'Online payment');
    expect(page.messages.single.data['payment_id'], 41);
    expect(page.messages.single.isRead, isFalse);
    final calls = adapter.requests.map((request) => '${request.method} ${request.path}').toList();
    expect(calls, containsAllInOrder([
      'GET /organizations/demo-gym/notifications',
      'POST /organizations/demo-gym/notifications/9b1d4c6e-0000-4000-8000-000000000001/read',
      'POST /organizations/demo-gym/notifications/read-all',
      'PATCH /organizations/demo-gym/notification-preferences',
    ]));
    expect(adapter.requests.last.data, {
      'refunds': {'sms': true},
    });
    expect(choices[StaffTopic.refunds], (push: true, sms: true));
    expect(choices[StaffTopic.appFreezes], (push: false, sms: false));
    expect(choices[StaffTopic.membersToCall], (push: true, sms: false), reason: 'left out: the default');
  });

  test('the inbox counts what is unread, and reading one or all brings it down', () async {
    final container = await desk();
    final inbox = container.read(staffInboxProvider.notifier);
    await Future<void>.delayed(const Duration(milliseconds: 20), () {}); // it loads as it starts

    expect(container.read(staffInboxProvider).messages, hasLength(4));
    expect(container.read(staffInboxProvider).unreadCount, 4);

    await inbox.markRead(container.read(staffInboxProvider).messages.first.id);
    expect(container.read(staffInboxProvider).unreadCount, 3);
    await inbox.refresh();
    expect(container.read(staffInboxProvider).unreadCount, 3, reason: 'the API kept it read');

    await inbox.markAllRead();
    await inbox.refresh();
    expect(container.read(staffInboxProvider).unreadCount, 0);
    expect(container.read(staffInboxProvider).messages.every((message) => message.isRead), isTrue);
  });
}
