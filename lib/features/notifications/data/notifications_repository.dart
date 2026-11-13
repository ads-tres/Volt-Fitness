import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/json.dart';
import '../../../core/tenant/gym_path.dart';
import '../../../core/tenant/selected_organization.dart';
import '../domain/app_notification.dart';

final class NotificationPage {
  const NotificationPage({required this.items, required this.unreadCount, this.nextCursor});

  final List<AppNotification> items;

  /// At the selected gym, across all pages.
  final int unreadCount;
  final String? nextCursor;
}

/// The member's notifications and push settings at the selected gym
/// (`/me/gyms/{gym}/notifications` and `…/notification-preferences`).
final class NotificationsRepository {
  const NotificationsRepository(this._api, this._gym);

  final ApiClient _api;

  /// The selected gym's slug.
  final String? Function() _gym;

  String _path(String path) => gymPath(_gym(), path);

  /// A page of the inbox, 25 a page, newest first. The cursor is the next
  /// page's number.
  Future<NotificationPage> page({String? cursor}) async {
    final response = await _api.get(_path('/notifications'), query: {'page': ?cursor});
    return readResponse<NotificationPage>(() {
      final json = response! as Map<String, dynamic>;
      final meta = json.optional<Map<String, dynamic>>('meta');
      final hasNext = json.optional<Map<String, dynamic>>('links')?.optional<String>('next') != null;
      final current = meta?.optional<int>('current_page') ?? 1;
      return NotificationPage(
        items: [for (final item in json.objects('data')) notificationFromJson(item)],
        unreadCount: meta?.optional<int>('unread_count') ?? 0,
        nextCursor: hasNext ? '${current + 1}' : null,
      );
    });
  }

  Future<void> markRead(String id) => _api.post(_path('/notifications/$id/read'));

  Future<void> markAllRead() => _api.post(_path('/notifications/read-all'));

  Future<NotificationPreferences> preferences() async {
    final response = await _api.get(_path('/notification-preferences'));
    return readResponse<NotificationPreferences>(() => preferencesFromJson(dataObject(response)));
  }

  /// Changes only the topics given; returns them all.
  Future<NotificationPreferences> updatePreferences(Map<NotificationTopic, bool> changes) async {
    final response = await _api.patch(
      _path('/notification-preferences'),
      body: {for (final MapEntry(:key, :value) in changes.entries) key.name: value},
    );
    return readResponse<NotificationPreferences>(() => preferencesFromJson(dataObject(response)));
  }
}

final notificationsRepositoryProvider = Provider<NotificationsRepository>(
  (ref) => NotificationsRepository(ref.watch(apiClientProvider), () => ref.read(selectedOrganizationProvider)?.id),
);

AppNotification notificationFromJson(Map<String, dynamic> json) => AppNotification(
  id: json.field<String>('id'),
  type: json.field<String>('type'),
  title: json.field<String>('title'),
  body: json.optional<String>('body') ?? '',
  createdAt: DateTime.parse(json.field<String>('created_at')).toUtc(),
  readAt: switch (json.optional<String>('read_at')) {
    final iso? => DateTime.parse(iso).toUtc(),
    null => null,
  },
  data: {
    for (final MapEntry(:key, :value) in (json.optional<Map<String, dynamic>>('data') ?? const {}).entries)
      if (value is String) key: value,
  },
);

NotificationPreferences preferencesFromJson(Map<String, dynamic> json) =>
    NotificationPreferences({for (final topic in NotificationTopic.values) topic: ?json.optional<bool>(topic.name)});
