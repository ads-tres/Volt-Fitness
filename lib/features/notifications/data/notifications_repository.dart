import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/json.dart';
import '../domain/app_notification.dart';

final class NotificationPage {
  const NotificationPage({required this.items, required this.unreadCount, this.nextCursor});

  final List<AppNotification> items;

  /// At the selected gym, across all pages.
  final int unreadCount;
  final String? nextCursor;
}

/// The member's notifications and push settings at the selected gym.
final class NotificationsRepository {
  const NotificationsRepository(this._api);

  static const pageSize = 20;

  final ApiClient _api;

  Future<NotificationPage> page({String? cursor}) async {
    final response = await _api.get('/notifications', query: {'per_page': pageSize, 'cursor': ?cursor});
    return readResponse<NotificationPage>(() {
      final json = response! as Map<String, dynamic>;
      final meta = json.optional<Map<String, dynamic>>('meta');
      return NotificationPage(
        items: [for (final item in json.objects('data')) notificationFromJson(item)],
        unreadCount: meta?.optional<int>('unread_count') ?? 0,
        nextCursor: meta?.optional<String>('next_cursor'),
      );
    });
  }

  Future<void> markRead(String id) => _api.post('/notifications/$id/read');

  Future<void> markAllRead() => _api.post('/notifications/read-all');

  Future<NotificationPreferences> preferences() async {
    final response = await _api.get('/me/notification-preferences');
    return readResponse<NotificationPreferences>(() => preferencesFromJson(dataObject(response)));
  }

  /// Changes only the topics given; returns them all.
  Future<NotificationPreferences> updatePreferences(Map<NotificationTopic, bool> changes) async {
    final response = await _api.patch(
      '/me/notification-preferences',
      body: {for (final MapEntry(:key, :value) in changes.entries) key.name: value},
    );
    return readResponse<NotificationPreferences>(() => preferencesFromJson(dataObject(response)));
  }
}

final notificationsRepositoryProvider = Provider<NotificationsRepository>(
  (ref) => NotificationsRepository(ref.watch(apiClientProvider)),
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
