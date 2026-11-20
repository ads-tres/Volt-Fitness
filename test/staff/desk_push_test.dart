import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_mobile/core/network/api_client.dart';
import 'package:gym_mobile/core/push/push_service.dart';
import 'package:gym_mobile/staff/app/staff_app.dart';
import 'package:gym_mobile/staff/core/desk_push.dart';
import 'package:gym_mobile/staff/core/desk_session.dart';
import 'package:gym_mobile/staff/features/auth/data/desk_auth_repository.dart';

import '../support/desk_driver.dart';
import '../support/test_doubles.dart';

/// Waits until [done], up to two seconds: the sync runs on its own time.
Future<void> until(bool Function() done) async {
  for (var waited = 0; !done() && waited < 2000; waited += 10) {
    await Future<void>.delayed(const Duration(milliseconds: 10), () {});
  }
}

/// Lets anything still in flight finish, to show nothing more is sent.
Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 200), () {});

/// What the API answers to PUT and DELETE: nothing.
ResponseBody noContent() => ResponseBody.fromString('', 204);

void main() {
  const demoGym = DeskGym(slug: 'demo-gym', name: 'Demo Gym', role: 'owner', worksAtAllBranches: true);

  test('sends the push token for staff pushes once signed in, and again only when it changes', () async {
    final adapter = StubAdapter((_) => noContent());
    final container = ProviderContainer.test(overrides: await testOverrides(fakeBackend: true));
    container.read(dioProvider).httpClientAdapter = adapter;
    final keepAlive = container.listen(deskPushTokenSyncProvider, (_, _) {});
    await settle();
    expect(adapter.requests, isEmpty, reason: 'signed out: nothing to send');

    await container.read(deskSessionProvider.notifier).signIn(token: '9|desk', name: 'Selam', gyms: [demoGym]);
    await until(() => adapter.requests.isNotEmpty);
    await settle();
    expect(adapter.requests.single.method, 'PUT');
    expect(adapter.requests.single.path, '/me/push-token');
    expect(adapter.requests.single.data, {'provider': 'fcm', 'token': 'fake-fcm-token-1', 'locale': 'en', 'app': 'staff'});

    container.invalidate(deskPushTokenSyncProvider);
    await settle();
    expect(adapter.requests, hasLength(1), reason: 'the same token is not sent twice');

    (container.read(pushServiceProvider) as FakePushService).rotateToken();
    await until(() => adapter.requests.length == 2);
    expect((adapter.requests.last.data as Map)['token'], 'fake-fcm-token-2');
    keepAlive.close();
  });

  test('signing out stops this phone\'s pushes before revoking the token', () async {
    final adapter = StubAdapter((_) => noContent());
    final container = await containerWithAdapter(adapter);

    await container.read(deskAuthRepositoryProvider).signOut();

    expect(adapter.requests.map((request) => '${request.method} ${request.path}'), [
      'DELETE /me/push-token',
      'DELETE /auth/tokens/current',
    ]);
  });

  group('at the desk', () {
    FakePushService pushOf(WidgetTester tester) =>
        ProviderScope.containerOf(tester.element(find.byType(StaffApp))).read(pushServiceProvider) as FakePushService;

    const frozen = PushMessage(
      title: 'Membership frozen in the app',
      body: 'Hana Girma froze Monthly from Oct 16 to Oct 22.',
      data: {'type': 'staff_member_froze', 'notification_id': '9b1d4c6e-0000-4000-8000-000000000002', 'gym': 'demo-gym'},
    );

    testWidgets('a push while the desk is open shows a banner that opens the message', (tester) async {
      await startDesk(tester);
      await openScanner(tester);

      pushOf(tester).deliver(frozen);
      await tester.pumpAndSettle();
      expect(find.text('Membership frozen in the app'), findsOneWidget);

      await tester.tap(find.text('View'));
      await tester.pumpAndSettle();
      expect(find.text('Hana Girma froze Monthly from Oct 16 to Oct 22.'), findsOneWidget);
    });

    testWidgets('a push tapped in the shade opens its message; one for another gym opens the inbox', (tester) async {
      await startDesk(tester);
      await openScanner(tester);

      pushOf(tester).deliver(frozen, tapped: true);
      await tester.pumpAndSettle();
      expect(find.text('Hana Girma froze Monthly from Oct 16 to Oct 22.'), findsOneWidget);
      await tester.tapAt(const Offset(180, 80));
      await tester.pumpAndSettle();

      pushOf(tester).deliver(
        const PushMessage(title: 'Online payment', data: {'type': 'staff_online_payment', 'notification_id': 'x', 'gym': 'bole-fitness'}),
        tapped: true,
      );
      await tester.pumpAndSettle();
      expect(find.text('Messages'), findsOneWidget);
    });
  });
}
