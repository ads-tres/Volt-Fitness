import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/failure.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/json.dart';
import '../../../core/tenant/gym_path.dart';
import '../../../core/tenant/selected_organization.dart';
import '../../../core/time/local_date.dart';
import '../../home/data/member_json.dart';
import '../domain/membership.dart';

/// Freezing the member's own membership at the selected gym. The API applies
/// the gym's rules (not in the past, inside the membership, within the
/// plan's freeze days) and answers with the membership as it now stands.
/// Every call throws a [Failure] when it fails; a refusal is a
/// [ValidationFailure] naming the field it is about.
final class FreezeRepository {
  FreezeRepository(this._api, this._gym);

  final ApiClient _api;

  /// The selected gym's slug.
  final String? Function() _gym;

  /// Freezes the membership from [startsOn] to [endsOn], both included. The
  /// membership's end date moves later by as many days.
  Future<Membership> freeze(String membershipId, {required LocalDate startsOn, required LocalDate endsOn, String? reason}) async {
    final data = dataObject(
      await _api.post(
        gymPath(_gym(), '/memberships/$membershipId/freezes'),
        body: {
          'starts_on': startsOn.toIso(),
          'ends_on': endsOn.toIso(),
          if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim(),
        },
      ),
    );
    return readResponse(() => membershipFromJson(data));
  }

  /// The member is back: ends the freeze today, or cancels it if it hasn't
  /// started. The unused days go back to the member.
  Future<Membership> endFreeze(String membershipId, String freezeId) async {
    final data = dataObject(await _api.post(gymPath(_gym(), '/memberships/$membershipId/freezes/$freezeId/end')));
    return readResponse(() => membershipFromJson(data));
  }
}

final freezeRepositoryProvider = Provider<FreezeRepository>(
  (ref) => FreezeRepository(ref.watch(apiClientProvider), () => ref.read(selectedOrganizationProvider)?.id),
);
