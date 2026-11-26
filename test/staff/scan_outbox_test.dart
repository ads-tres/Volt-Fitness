import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_mobile/core/network/api_client.dart';
import 'package:gym_mobile/staff/core/desk_session.dart';
import 'package:gym_mobile/staff/features/scan/data/scan_outbox.dart';

import '../support/test_doubles.dart';

void main() {
  const demoGym = DeskGym(slug: 'demo-gym', name: 'Demo Gym', role: 'receptionist', worksAtAllBranches: false);

  Future<ProviderContainer> desk(StubAdapter adapter, {InMemoryPreferencesStore? preferences}) async {
    final container = ProviderContainer.test(overrides: await testOverrides(preferences: preferences));
    container.read(dioProvider).httpClientAdapter = adapter;
    final session = container.read(deskSessionProvider.notifier);
    await session.signIn(token: '9|desk', name: 'Selam', gyms: [demoGym]);
    await session.selectBranch(const DeskBranch(id: 1, name: 'Main Branch'));
    return container;
  }

  /// Answers each offline scan as [status], disagreeing for [disagreeWith].
  ResponseBody answer(RequestOptions request, String Function(Map<String, dynamic> scan) status, {String? disagreeWith}) =>
      jsonResponse(200, {
        'data': [
          for (final scan in ((request.data as Map)['scans'] as List).cast<Map<String, dynamic>>())
            {
              'id': scan['id'],
              'status': status(scan),
              'check_in_id': 900,
              'server_disagrees': scan['payload'] == disagreeWith,
              'server_reason_code': scan['payload'] == disagreeWith ? 'MEMBERSHIP_EXPIRED' : null,
              'message': status(scan) == 'refused' ? "The code doesn't match the time it was scanned." : null,
            },
        ],
      });

  test('keeps the door\'s decisions on the phone and sends them to check-ins/offline, each with its own id', () async {
    final preferences = InMemoryPreferencesStore();
    final adapter = StubAdapter(
      (request) => request.path.endsWith('/check-ins/offline')
          ? answer(request, (_) => 'recorded')
          : jsonResponse(200, {'data': <Object?>[]}),
    );
    final container = await desk(adapter, preferences: preferences);
    final outbox = container.read(scanOutboxProvider.notifier);

    final first = await outbox.add('GQ1:FIRST', letIn: true);
    await outbox.add('GQ1:SECOND', letIn: false, reasonCode: 'MEMBERSHIP_EXPIRED');
    expect(preferences.values[ScanOutbox.storageKey], contains('GQ1:FIRST'));

    final restarted = await desk(adapter, preferences: preferences);
    expect(restarted.read(scanOutboxProvider).pending, hasLength(2));
    expect(await restarted.read(scanOutboxProvider.notifier).flush(), 2);

    final sent = adapter.requests.singleWhere((request) => request.path.endsWith('/check-ins/offline'));
    expect(sent.path, '/organizations/demo-gym/check-ins/offline');
    expect((sent.data as Map)['scans'], [
      {'id': first.id, 'payload': 'GQ1:FIRST', 'branch_id': 1, 'scanned_at': testNow.toUtc().toIso8601String(), 'decision': 'allow'},
      {
        'id': isA<String>(),
        'payload': 'GQ1:SECOND',
        'branch_id': 1,
        'scanned_at': testNow.toUtc().toIso8601String(),
        'decision': 'deny',
        'reason_code': 'MEMBERSHIP_EXPIRED',
      },
    ]);
    expect(restarted.read(scanOutboxProvider).pending, isEmpty);
    expect(preferences.values.containsKey(ScanOutbox.storageKey), isFalse);
  });

  test('stops at a network failure and keeps everything; counts refused scans and those to review', () async {
    var networkUp = false;
    final adapter = StubAdapter((request) {
      if (!request.path.endsWith('/check-ins/offline')) return jsonResponse(200, {'data': <Object?>[]});
      if (!networkUp) {
        throw DioException.connectionError(requestOptions: request, reason: 'offline', error: const SocketException('offline'));
      }
      return answer(request, (scan) => scan['payload'] == 'GQ1:FORGED' ? 'refused' : 'recorded', disagreeWith: 'GQ1:TIGIST');
    });
    final container = await desk(adapter);
    final outbox = container.read(scanOutboxProvider.notifier);
    await outbox.add('GQ1:FORGED', letIn: true);
    await outbox.add('GQ1:TIGIST', letIn: true);
    await outbox.add('GQ1:ABEBE', letIn: true);

    expect(await outbox.flush(), 0);
    expect(container.read(scanOutboxProvider).pending, hasLength(3), reason: 'nothing is lost while offline');

    networkUp = true;
    expect(await outbox.flush(), 2);
    final state = container.read(scanOutboxProvider);
    expect(state.pending, isEmpty);
    expect((state.refused, state.toReview), (1, 1));

    outbox.dismissCounts();
    expect((container.read(scanOutboxProvider).refused, container.read(scanOutboxProvider).toReview), (0, 0));
  });

  test('sends 200 at a time, and keeps the scans the server didn\'t answer for', () async {
    final adapter = StubAdapter((request) {
      if (!request.path.endsWith('/check-ins/offline')) return jsonResponse(200, {'data': <Object?>[]});
      final scans = ((request.data as Map)['scans'] as List).cast<Map<String, dynamic>>();
      return jsonResponse(200, {
        'data': [
          for (final scan in scans.take(scans.length - 1))
            {'id': scan['id'], 'status': 'recorded', 'server_disagrees': false},
        ],
      });
    });
    final container = await desk(adapter);
    final outbox = container.read(scanOutboxProvider.notifier);
    for (var index = 0; index < 201; index++) {
      await outbox.add('GQ1:$index', letIn: true);
    }

    await outbox.flush();

    final batches = [
      for (final request in adapter.requests)
        if (request.path.endsWith('/check-ins/offline')) ((request.data as Map)['scans'] as List).length,
    ];
    expect(batches.first, 200);
    expect(container.read(scanOutboxProvider).pending, isNotEmpty, reason: 'unanswered scans stay to send again');
  });

  test('signing out empties the queue', () async {
    final preferences = InMemoryPreferencesStore();
    final container = await desk(StubAdapter((_) => ResponseBody.fromString('', 204)), preferences: preferences);
    await container.read(scanOutboxProvider.notifier).add('GQ1:WAITING', letIn: true);

    await container.read(deskSessionProvider.notifier).signOut();

    expect(container.read(scanOutboxProvider).pending, isEmpty);
    expect(preferences.values.containsKey(ScanOutbox.storageKey), isFalse);
  });
}
