import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_mobile/staff/fake_front_desk.dart';
import 'package:gym_mobile/staff/features/scan/domain/desk_check_in.dart';

import '../support/desk_driver.dart';
import '../support/test_doubles.dart';

/// The fake front desk, with one more of today's check-ins: let in offline,
/// where the server would have said the member was already in.
final class WithOneToReview implements HttpClientAdapter {
  final _fake = FakeFrontDesk(latency: Duration.zero, now: () => testNow);

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    final answer = await _fake.fetch(options, requestStream, cancelFuture);
    if (options.method != 'GET' || !options.path.endsWith('/check-ins')) return answer;
    final json = jsonDecode(await utf8.decodeStream(answer.stream)) as Map<String, dynamic>;
    (json['data'] as List).insert(0, {
      'id': 990,
      'decision': 'allow',
      'reason_code': null,
      'method': 'qr',
      'checked_in_at': testNow.toUtc().toIso8601String(),
      'offline': true,
      'server_disagrees': true,
      'server_reason_code': 'ALREADY_CHECKED_IN',
      'member': {'id': 1, 'full_name': 'Abebe Kebede', 'phone': '+251911234567'},
    });
    return jsonResponse(200, json);
  }

  @override
  void close({bool force = false}) => _fake.close(force: force);
}

void main() {
  test('reads whether a check-in was offline and whether the server disagrees', () {
    final checkIn = deskCheckInFromJson({
      'id': 5,
      'decision': 'allow',
      'checked_in_at': '2026-10-14T06:05:00Z',
      'offline': true,
      'server_disagrees': true,
      'server_reason_code': 'MEMBERSHIP_EXPIRED',
    });
    expect((checkIn.offline, checkIn.serverDisagrees, checkIn.serverReasonCode), (true, true, 'MEMBERSHIP_EXPIRED'));
    expect(deskCheckInFromJson({'id': 6, 'decision': 'allow', 'checked_in_at': '2026-10-14T06:05:00Z'}).offline, isFalse);
  });

  testWidgets('Today marks an offline check-in, and one the server disagrees with', (tester) async {
    await startDesk(tester, backend: WithOneToReview());
    await openScanner(tester);
    await tester.tap(find.text('Today'));
    await tester.pumpAndSettle();

    expect(
      find.text('Scanned offline · Server: Let in less than 5 minutes ago, review in the panel'),
      findsOneWidget,
    );
  });
}
