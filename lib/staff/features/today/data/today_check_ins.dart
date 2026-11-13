import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/json.dart';
import '../../../../core/time/clock.dart';
import '../../../../core/time/local_date.dart';
import '../../../core/desk_session.dart';
import '../../scan/domain/desk_check_in.dart';

final class TodayState {
  const TodayState({this.checkIns = const [], this.nextPage, this.isLoading = false, this.failure});

  final List<DeskCheckIn> checkIns;
  final int? nextPage;
  final bool isLoading;
  final Failure? failure;
}

/// Today's check-ins at the desk's branch, newest first, 25 a page
/// (`GET /organizations/{gym}/check-ins?on=…&branch_id=…`). Today is the
/// phone's date, the gym's in Addis.
final class TodayController extends Notifier<TodayState> {
  @override
  TodayState build() {
    ref.watch(deskSessionProvider.select((session) => session is DeskSignedIn ? session.branch?.id : null));
    unawaited(Future.microtask(refresh));
    return const TodayState(isLoading: true);
  }

  Future<void> refresh() async {
    state = const TodayState(isLoading: true);
    await _load(page: 1, keep: const []);
  }

  Future<void> loadMore() async {
    final next = state.nextPage;
    if (next == null || state.isLoading) return;
    final keep = state.checkIns;
    state = TodayState(checkIns: keep, nextPage: next, isLoading: true);
    await _load(page: next, keep: keep);
  }

  Future<void> _load({required int page, required List<DeskCheckIn> keep}) async {
    final session = ref.read(deskSessionProvider);
    if (!ref.mounted || session is! DeskSignedIn || session.branch == null) return;
    try {
      final today = LocalDate.of(ref.read(clockProvider)());
      final response = await ref.read(apiClientProvider).get(
        deskPath(session, '/check-ins'),
        query: {'on': today.toIso(), 'branch_id': session.branch!.id, 'page': page},
      );
      final (checkIns, hasNext) = readResponse(() {
        final json = response! as Map<String, dynamic>;
        return (
          [for (final checkIn in json.objects('data')) deskCheckInFromJson(checkIn)],
          json.optional<Map<String, dynamic>>('links')?.optional<String>('next') != null,
        );
      });
      if (ref.mounted) state = TodayState(checkIns: [...keep, ...checkIns], nextPage: hasNext ? page + 1 : null);
    } on Failure catch (failure) {
      if (ref.mounted) state = TodayState(checkIns: keep, nextPage: page, failure: failure);
    }
  }
}

final todayProvider = NotifierProvider<TodayController, TodayState>(TodayController.new);
