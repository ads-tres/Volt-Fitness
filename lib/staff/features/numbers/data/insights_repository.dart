import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/json.dart';
import '../../../core/desk_session.dart';
import '../domain/desk_insights.dart';

/// The gym month by month (`GET /organizations/{gym}/insights/{insight}`,
/// the API's ADR 0040), for the last 3, 6 or 12 months, at the desk's
/// branch or at every branch the staff member works at. Throws a
/// [Failure]; a role that may not see an insight gets a [ForbiddenFailure].
final class InsightsRepository {
  const InsightsRepository(this._api, this._session);

  final ApiClient _api;
  final DeskSession Function() _session;

  Future<Map<String, dynamic>> _get(String insight, InsightsQuery query) async {
    final session = _session();
    final branchId = query.allBranches ? null : (session is DeskSignedIn ? session.branch?.id : null);
    return dataObject(
      await _api.get(deskPath(session, '/insights/$insight'), query: {'months': query.months, 'branch_id': ?branchId}),
    );
  }

  Future<List<RevenueMonth>> revenue(InsightsQuery query) async {
    final data = await _get('revenue', query);
    return readResponse(() => revenueFromJson(data));
  }

  Future<List<RenewalMonth>> renewals(InsightsQuery query) async {
    final data = await _get('renewals', query);
    return readResponse(() => renewalsFromJson(data));
  }

  Future<BusyHours> busyHours(InsightsQuery query) async {
    final data = await _get('busy-hours', query);
    return readResponse(() => busyHoursFromJson(data));
  }

  Future<List<MembersMonth>> members(InsightsQuery query) async {
    final data = await _get('members', query);
    return readResponse(() => membersFromJson(data));
  }
}

/// How many months back, 3, 6 or 12, and whether at every branch.
typedef InsightsQuery = ({int months, bool allBranches});

final insightsRepositoryProvider = Provider<InsightsRepository>(
  (ref) => InsightsRepository(ref.watch(apiClientProvider), () => ref.read(deskSessionProvider)),
);

final revenueInsightProvider = FutureProvider.autoDispose.family<List<RevenueMonth>, InsightsQuery>(
  (ref, query) => ref.watch(insightsRepositoryProvider).revenue(query),
);

final renewalsInsightProvider = FutureProvider.autoDispose.family<List<RenewalMonth>, InsightsQuery>(
  (ref, query) => ref.watch(insightsRepositoryProvider).renewals(query),
);

final busyHoursInsightProvider = FutureProvider.autoDispose.family<BusyHours, InsightsQuery>(
  (ref, query) => ref.watch(insightsRepositoryProvider).busyHours(query),
);

final membersInsightProvider = FutureProvider.autoDispose.family<List<MembersMonth>, InsightsQuery>(
  (ref, query) => ref.watch(insightsRepositoryProvider).members(query),
);
