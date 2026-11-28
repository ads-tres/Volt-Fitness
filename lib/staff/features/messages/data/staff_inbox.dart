import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/time/clock.dart' show clockProvider;
import '../../../core/desk_session.dart';
import '../../../core/gym_paused.dart';
import '../domain/staff_message.dart';
import 'staff_messages_repository.dart';

final class StaffInboxState {
  const StaffInboxState({
    this.messages = const [],
    this.unreadCount = 0,
    this.nextPage,
    this.isLoading = false,
    this.failure,
  });

  final List<StaffMessage> messages;
  final int unreadCount;
  final int? nextPage;
  final bool isLoading;
  final Failure? failure;

  StaffInboxState copyWith({List<StaffMessage>? messages, int? unreadCount, bool? isLoading, Failure? failure}) =>
      StaffInboxState(
        messages: messages ?? this.messages,
        unreadCount: unreadCount ?? this.unreadCount,
        nextPage: nextPage,
        isLoading: isLoading ?? false,
        failure: failure,
      );
}

/// The staff member's messages at the desk's gym, newest first, and how
/// many are unread for the bell. Loads with the desk, and again whenever
/// [refresh] is called: on opening the inbox, on a push, and on a timer.
final class StaffInbox extends Notifier<StaffInboxState> {
  @override
  StaffInboxState build() {
    final gym = ref.watch(deskSessionProvider.select((session) => session is DeskSignedIn ? session.gym?.slug : null));
    if (gym == null) return const StaffInboxState();
    unawaited(Future.microtask(refresh));
    return const StaffInboxState(isLoading: true);
  }

  StaffMessagesRepository get _repository => ref.read(staffMessagesRepositoryProvider);

  /// Bumped by every change made here; a load started before one is stale
  /// and its answer is dropped, so it can't undo a message just read.
  var _version = 0;

  bool get _atAGym => switch (ref.read(deskSessionProvider)) {
    DeskSignedIn(gym: _?) => true,
    _ => false,
  };

  /// Reloads the first page, keeping the list on screen meanwhile.
  Future<void> refresh() async {
    if (!_atAGym) return;
    final version = ++_version;
    try {
      final page = await _repository.page();
      if (!ref.mounted || version != _version) return;
      ref.read(deskGymPausedProvider.notifier).report(null);
      state = StaffInboxState(messages: page.messages, unreadCount: page.unreadCount, nextPage: page.nextPage);
    } on Failure catch (failure) {
      if (ref.mounted) ref.read(deskGymPausedProvider.notifier).report(failure);
      if (ref.mounted && version == _version) state = state.copyWith(failure: failure);
    }
  }

  Future<void> loadMore() async {
    final next = state.nextPage;
    if (next == null || state.isLoading || !_atAGym) return;
    final current = state;
    state = current.copyWith(isLoading: true);
    final version = ++_version;
    try {
      final page = await _repository.page(page: next);
      if (!ref.mounted || version != _version) return;
      state = StaffInboxState(
        messages: [...current.messages, ...page.messages],
        unreadCount: page.unreadCount,
        nextPage: page.nextPage,
      );
    } on Failure catch (failure) {
      if (ref.mounted && version == _version) state = current.copyWith(failure: failure);
    }
  }

  /// Marks it read here at once, then tells the API; a failure is left for
  /// the next refresh to correct.
  Future<void> markRead(String id) async {
    final message = state.messages.where((message) => message.id == id).firstOrNull;
    if (message == null || message.isRead) return;
    final now = ref.read(clockProvider)().toUtc();
    _version++;
    state = state.copyWith(
      messages: [for (final each in state.messages) each.id == id ? each.markedRead(now) : each],
      unreadCount: state.unreadCount > 0 ? state.unreadCount - 1 : 0,
    );
    try {
      await _repository.markRead(id);
    } on Failure {
      // The next refresh shows what the API has.
    }
  }

  Future<void> markAllRead() async {
    final now = ref.read(clockProvider)().toUtc();
    _version++;
    state = state.copyWith(messages: [for (final each in state.messages) each.markedRead(now)], unreadCount: 0);
    try {
      await _repository.markAllRead();
    } on Failure {
      // The next refresh shows what the API has.
    }
  }
}

final staffInboxProvider = NotifierProvider<StaffInbox, StaffInboxState>(StaffInbox.new);
