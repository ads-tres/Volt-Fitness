import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/failure.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/json.dart';
import '../../../core/tenant/gym_path.dart';
import '../../../core/tenant/selected_organization.dart';
import '../../home/data/member_json.dart';
import '../domain/membership.dart';

/// Every membership the member has had or has coming at the selected gym,
/// newest first (`GET /me/gyms/{gym}/memberships`). Throws a [Failure] when
/// it fails.
final class MembershipsRepository {
  const MembershipsRepository(this._api, this._gym);

  final ApiClient _api;
  final String? Function() _gym;

  Future<List<Membership>> all() async {
    final response = await _api.get(gymPath(_gym(), '/memberships'));
    return readResponse(
      () => [for (final membership in (response! as Map<String, dynamic>).objects('data')) membershipFromJson(membership)],
    );
  }
}

final membershipsRepositoryProvider = Provider<MembershipsRepository>(
  (ref) => MembershipsRepository(ref.watch(apiClientProvider), () => ref.read(selectedOrganizationProvider)?.id),
);

final membershipsProvider = FutureProvider.autoDispose<List<Membership>>((ref) {
  ref.watch(selectedOrganizationProvider.select((organization) => organization?.id));
  return ref.watch(membershipsRepositoryProvider).all();
});
