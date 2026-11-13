import 'package:flutter_test/flutter_test.dart';
import 'package:gym_mobile/core/network/api_client.dart';
import 'package:gym_mobile/features/attendance/data/visits_controller.dart';
import 'package:gym_mobile/features/attendance/domain/visit.dart';

import '../../support/test_doubles.dart';

void main() {
  test('reads the gym\'s check-ins a page at a time, knowing when the last page is reached', () async {
    Map<String, Object?> page(int number, {required bool more}) => {
      'data': [
        {
          'id': number,
          'decision': 'allow',
          'reason_code': null,
          'method': 'qr',
          'checked_in_at': '2026-10-14T06:05:00+03:00',
          'branch': {'id': 2, 'code': 'BOLE', 'name': 'Bole Branch', 'address': null},
        },
      ],
      'links': {'next': more ? 'https://api.test/api/v1/me/gyms/bole-iron-gym/check-ins?page=${number + 1}' : null},
      'meta': {'current_page': number, 'last_page': 2},
    };
    final adapter = StubAdapter(
      (request) => jsonResponse(200, request.queryParameters['page'] == '2' ? page(2, more: false) : page(1, more: true)),
    );
    final container = await containerWithAdapter(adapter, signedInAs: memberOf([boleGym]));
    final api = container.read(apiClientProvider);

    final first = await fetchVisits(api, gym: boleGym.id);
    final last = await fetchVisits(api, gym: boleGym.id, cursor: first.nextCursor);

    expect(adapter.requests.first.path, '/me/gyms/bole-iron-gym/check-ins');
    expect(first.nextCursor, '2');
    expect(first.visits.single.result, VisitResult.allowed);
    expect(last.nextCursor, isNull);
  });
}
