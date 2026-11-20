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

  Map<String, Object?> checkIn(int id) => {
    'id': id,
    'decision': 'allow',
    'reason_code': null,
    'method': 'qr',
    'checked_in_at': '2026-10-14T06:30:00Z',
  };

  Future<ProviderContainer> desk(StubAdapter adapter, {InMemoryPreferencesStore? preferences}) async {
    final container = ProviderContainer.test(overrides: await testOverrides(preferences: preferences));
    container.read(dioProvider).httpClientAdapter = adapter;
    final session = container.read(deskSessionProvider.notifier);
    await session.signIn(token: '9|desk', name: 'Selam', gyms: [demoGym]);
    await session.selectBranch(const DeskBranch(id: 1, name: 'Main Branch'));
    return container;
  }

  test('keeps scans on the phone and sends them oldest first, each with its key, time, gym and branch', () async {
    final preferences = InMemoryPreferencesStore();
    final adapter = StubAdapter((request) => jsonResponse(200, {'data': checkIn(1)}));
    final container = await desk(adapter, preferences: preferences);
    final outbox = container.read(scanOutboxProvider.notifier);

    final first = await outbox.add('GQ1:FIRST');
    await outbox.add('GQ1:SECOND');
    expect(preferences.values[ScanOutbox.storageKey], contains('GQ1:FIRST'));

    final restarted = await desk(adapter, preferences: preferences);
    expect(restarted.read(scanOutboxProvider).pending.map((scan) => scan.payload), ['GQ1:FIRST', 'GQ1:SECOND']);

    expect(await restarted.read(scanOutboxProvider.notifier).flush(), 2);
    final scans = adapter.requests.where((request) => request.path.endsWith('/check-ins/scan')).toList();
    expect(scans.map((request) => (request.data as Map)['payload']), ['GQ1:FIRST', 'GQ1:SECOND']);
    expect(scans.first.path, '/organizations/demo-gym/check-ins/scan');
    expect(scans.first.data, {
      'payload': 'GQ1:FIRST',
      'branch_id': 1,
      'scanned_at': testNow.toUtc().toIso8601String(),
    });
    expect(scans.first.headers['Idempotency-Key'], first.idempotencyKey);
    expect(restarted.read(scanOutboxProvider).pending, isEmpty);
    expect(preferences.values.containsKey(ScanOutbox.storageKey), isFalse);
  });

  test('stops at a network failure and keeps the rest; a refused scan is let go and counted', () async {
    var networkUp = false;
    final adapter = StubAdapter((request) {
      if (!request.path.endsWith('/check-ins/scan')) return jsonResponse(200, {'data': <Object?>[]});
      if (!networkUp) {
        throw DioException.connectionError(requestOptions: request, reason: 'offline', error: const SocketException('offline'));
      }
      return (request.data as Map)['payload'] == 'GQ1:OLD'
          ? jsonResponse(422, {
              'message': 'A scan can be sent up to 24 hours late.',
              'errors': {
                'scanned_at': ['A scan can be sent up to 24 hours late.'],
              },
            })
          : jsonResponse(200, {'data': checkIn(2)});
    });
    final container = await desk(adapter);
    final outbox = container.read(scanOutboxProvider.notifier);
    await outbox.add('GQ1:OLD');
    await outbox.add('GQ1:NEW');

    expect(await outbox.flush(), 0);
    expect(container.read(scanOutboxProvider).pending, hasLength(2), reason: 'nothing is lost while offline');

    networkUp = true;
    expect(await outbox.flush(), 1);
    expect(container.read(scanOutboxProvider).pending, isEmpty);
    expect(container.read(scanOutboxProvider).dropped, 1);
  });

  test('signing out empties the queue', () async {
    final preferences = InMemoryPreferencesStore();
    final container = await desk(StubAdapter((_) => jsonResponse(204, null)), preferences: preferences);
    await container.read(scanOutboxProvider.notifier).add('GQ1:WAITING');

    await container.read(deskSessionProvider.notifier).signOut();

    expect(container.read(scanOutboxProvider).pending, isEmpty);
    expect(preferences.values.containsKey(ScanOutbox.storageKey), isFalse);
  });
}
