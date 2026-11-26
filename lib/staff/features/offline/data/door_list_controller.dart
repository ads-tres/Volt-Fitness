import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/time/clock.dart' show clockProvider;
import '../../../core/desk_session.dart';
import '../domain/door_list.dart';
import 'door_list_repository.dart';

final class DoorListState {
  const DoorListState({this.list, this.problem, this.isRefreshing = false});

  /// The latest trusted list, downloaded or kept on the phone.
  final DoorList? list;

  /// Why there is none, when the gym platform refused or isn't set up.
  final DoorListProblem? problem;
  final bool isRefreshing;

  /// A list still good now, to scan offline with.
  DoorList? usableAt(DateTime now) => list != null && list!.isValidAt(now) ? list : null;
}

/// Keeps the desk's door list fresh for its branch: read from the phone at
/// start, downloaded when the desk opens a branch and whenever [refresh] is
/// called (on a timer, and after check-ins at the desk). A failed download
/// keeps the last good list.
final class DoorListController extends Notifier<DoorListState> {
  @override
  DoorListState build() {
    final branch = ref.watch(deskSessionProvider.select((session) => session is DeskSignedIn ? session.branch?.id : null));
    if (branch == null) return const DoorListState();
    unawaited(Future.microtask(_start));
    return const DoorListState(isRefreshing: true);
  }

  DoorListRepository get _repository => ref.read(doorListRepositoryProvider);

  int? get _branchId => switch (ref.read(deskSessionProvider)) {
    DeskSignedIn(branch: final branch?) => branch.id,
    _ => null,
  };

  Future<void> _start() async {
    final stored = await _repository.stored();
    if (!ref.mounted) return;
    state = DoorListState(list: stored, isRefreshing: true);
    await refresh();
  }

  Future<void> refresh() async {
    final branchId = _branchId;
    if (branchId == null) return;
    state = DoorListState(list: state.list, problem: state.problem, isRefreshing: true);
    try {
      final list = await _repository.download(branchId: branchId);
      if (ref.mounted) state = DoorListState(list: list);
    } on DoorListRefused catch (refused) {
      if (ref.mounted) state = DoorListState(list: state.list, problem: refused.problem);
    } on Failure {
      if (ref.mounted) state = DoorListState(list: state.list, problem: state.problem);
    }
  }

  /// The list to scan offline with right now, or null.
  DoorList? usable() => state.usableAt(ref.read(clockProvider)().toUtc());
}

final doorListProvider = NotifierProvider<DoorListController, DoorListState>(DoorListController.new);
