import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/json.dart';
import '../../../../core/utils/uuid.dart';
import '../../../core/desk_session.dart';
import '../domain/desk_check_in.dart';

/// Checking members in at the desk's gym and branch. Every call throws a
/// [Failure] when it fails.
final class CheckInRepository {
  const CheckInRepository(this._api, this._session);

  final ApiClient _api;
  final DeskSession Function() _session;

  int get _branchId => switch (_session()) {
    DeskSignedIn(branch: final branch?) => branch.id,
    _ => throw StateError('No branch is chosen'),
  };

  /// Sends a scanned code. The API answers 200 either way, with its
  /// decision. A new Idempotency-Key for each scan means a retry after a lost
  /// answer gets the first answer back, not `CODE_ALREADY_USED`.
  Future<DeskCheckIn> scan(String payload, {String? idempotencyKey}) async {
    final data = dataObject(
      await _api.post(
        deskPath(_session(), '/check-ins/scan'),
        body: {'payload': payload, 'branch_id': _branchId},
        idempotencyKey: idempotencyKey ?? uuidV4(),
      ),
    );
    return readResponse(() => deskCheckInFromJson(data));
  }

  /// Checks a member in without their phone, by the desk.
  Future<DeskCheckIn> atDesk(int memberId) async {
    final data = dataObject(
      await _api.post(deskPath(_session(), '/members/$memberId/check-ins'), body: {'branch_id': _branchId}),
    );
    return readResponse(() => deskCheckInFromJson(data));
  }
}

final checkInRepositoryProvider = Provider<CheckInRepository>(
  (ref) => CheckInRepository(ref.watch(apiClientProvider), () => ref.read(deskSessionProvider)),
);
