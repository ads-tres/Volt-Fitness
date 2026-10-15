import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/failure.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/json.dart';
import '../../../core/tenant/selected_organization.dart';
import '../../home/data/member_json.dart';
import '../domain/visit.dart';

final class VisitsState {
  const VisitsState({this.visits = const [], this.nextCursor, this.isLoading = false, this.reachedEnd = false, this.failure});

  final List<Visit> visits;
  final String? nextCursor;
  final bool isLoading;
  final bool reachedEnd;
  final Failure? failure;
}

/// The member's visit history at the selected gym, newest first, loaded a
/// page at a time as the list scrolls (`GET /attendance`, cursor-paginated).
final class VisitsController extends Notifier<VisitsState> {
  static const pageSize = 20;

  @override
  VisitsState build() {
    ref.watch(selectedOrganizationProvider.select((organization) => organization?.id));
    unawaited(Future.microtask(loadMore));
    return const VisitsState(isLoading: true);
  }

  Future<void> loadMore() async {
    if (!ref.mounted || state.reachedEnd || (state.isLoading && state.visits.isNotEmpty)) return;
    final current = state;
    state = VisitsState(visits: current.visits, nextCursor: current.nextCursor, isLoading: true);
    try {
      final page = await fetchVisits(ref.read(apiClientProvider), cursor: current.nextCursor);
      if (!ref.mounted) return;
      state = VisitsState(
        visits: [...current.visits, ...page.visits],
        nextCursor: page.nextCursor,
        reachedEnd: page.nextCursor == null,
      );
    } on Failure catch (failure) {
      if (ref.mounted) state = VisitsState(visits: current.visits, nextCursor: current.nextCursor, failure: failure);
    }
  }

  Future<void> refresh() async {
    state = const VisitsState(isLoading: true);
    await loadMore();
  }
}

final visitsProvider = NotifierProvider<VisitsController, VisitsState>(VisitsController.new);

Future<VisitPage> fetchVisits(ApiClient api, {String? cursor}) async {
  final response = await api.get(
    '/attendance',
    query: {'per_page': VisitsController.pageSize, 'cursor': ?cursor},
  );
  return readResponse(() {
    final json = response! as Map<String, dynamic>;
    return VisitPage(
      visits: [for (final visit in json.objects('data')) visitFromJson(visit)],
      nextCursor: json.optional<Map<String, dynamic>>('meta')?.optional<String>('next_cursor'),
    );
  });
}
