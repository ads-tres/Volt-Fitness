import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/failure.dart';
import '../../../core/tenant/selected_organization.dart';
import '../../../core/time/clock.dart';
import '../domain/app_notification.dart';
import 'notifications_repository.dart';

final class InboxState {
  const InboxState({
    this.items = const [],
    this.unreadCount = 0,
    this.nextCursor,
    this.isLoading = false,
    this.reachedEnd = false,
    this.failure,
  });

  final List<AppNotification> items;
  final int unreadCount;
  final String? nextCursor;
  final bool isLoading;
  final bool reachedEnd;
  final Failure? failure;

  InboxState _with({List<AppNotification>? items, int? unreadCount, bool? isLoading, Failure? failure}) => InboxState(
    items: items ?? this.items,
    unreadCount: unreadCount ?? this.unreadCount,
    nextCursor: nextCursor,
    isLoading: isLoading ?? false,
    reachedEnd: reachedEnd,
    failure: failure,
  );
}

/// The member's notifications at the selected gym, newest first, and how
/// many are unread for the bell. Loads with the home screen; older pages
/// load as the inbox scrolls.
final class InboxController extends Notifier<InboxState> {
  @override
  InboxState build() {
    ref.watch(selectedOrganizationProvider.select((organization) => organization?.id));
    unawaited(Future.microtask(loadMore));
    return const InboxState(isLoading: true);
  }

  NotificationsRepository get _repository => ref.read(notificationsRepositoryProvider);

  Future<void> loadMore() async {
    if (!ref.mounted || state.reachedEnd || (state.isLoading && state.items.isNotEmpty)) return;
    final current = state;
    state = current._with(isLoading: true);
    try {
      final page = await _repository.page(cursor: current.nextCursor);
      if (!ref.mounted) return;
      state = InboxState(
        items: [...current.items, ...page.items],
        unreadCount: page.unreadCount,
        nextCursor: page.nextCursor,
        reachedEnd: page.nextCursor == null,
      );
    } on Failure catch (failure) {
      if (ref.mounted) state = current._with(failure: failure);
    }
  }

  /// Reloads the first page, keeping the list on screen meanwhile.
  Future<void> refresh() async {
    try {
      final page = await _repository.page();
      if (!ref.mounted) return;
      state = InboxState(
        items: page.items,
        unreadCount: page.unreadCount,
        nextCursor: page.nextCursor,
        reachedEnd: page.nextCursor == null,
      );
    } on Failure catch (failure) {
      if (ref.mounted) state = state._with(failure: failure);
    }
  }

  /// Marks it read here at once, then on the server. If the server call
  /// fails, the next refresh shows the server's view; nothing to undo.
  Future<void> markRead(String id) async {
    final index = state.items.indexWhere((item) => item.id == id && !item.isRead);
    if (index != -1) {
      final now = ref.read(clockProvider)();
      state = state._with(
        items: [...state.items]..[index] = state.items[index].markedRead(now),
        unreadCount: state.unreadCount > 0 ? state.unreadCount - 1 : 0,
      );
    }
    try {
      await _repository.markRead(id);
    } on Failure {
      // See above.
    }
  }

  /// Throws the [Failure] after putting the list back as it was.
  Future<void> markAllRead() async {
    final before = state;
    final now = ref.read(clockProvider)();
    state = before._with(items: [for (final item in before.items) item.markedRead(now)], unreadCount: 0);
    try {
      await _repository.markAllRead();
    } on Failure {
      if (ref.mounted) state = before;
      rethrow;
    }
  }
}

final inboxProvider = NotifierProvider<InboxController, InboxState>(InboxController.new);

/// Push settings at the selected gym. A switch moves at once and moves back
/// if the API refuses the change.
final class NotificationPreferencesController extends AsyncNotifier<NotificationPreferences> {
  @override
  Future<NotificationPreferences> build() {
    ref.watch(selectedOrganizationProvider.select((organization) => organization?.id));
    return ref.read(notificationsRepositoryProvider).preferences();
  }

  /// Throws the [Failure] after moving the switch back.
  Future<void> set(NotificationTopic topic, bool enabled) async {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(current.withTopic(topic, enabled));
    try {
      final saved = await ref.read(notificationsRepositoryProvider).updatePreferences({topic: enabled});
      if (ref.mounted) state = AsyncData(saved);
    } on Failure {
      if (ref.mounted) state = AsyncData(current);
      rethrow;
    }
  }
}

final notificationPreferencesProvider =
    AsyncNotifierProvider.autoDispose<NotificationPreferencesController, NotificationPreferences>(
      NotificationPreferencesController.new,
    );
