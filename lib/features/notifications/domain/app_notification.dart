/// What the member can turn pushes on or off for. The inbox keeps every
/// notification either way.
enum NotificationTopic { membership, payments, visits, announcements }

/// The topic a notification type belongs to, by its prefix, so new types
/// such as `membership_resumed` land in the right place. Null for types the
/// app doesn't know.
NotificationTopic? topicOf(String type) => switch (type) {
  'announcement' => NotificationTopic.announcements,
  _ when type.startsWith('membership_') => NotificationTopic.membership,
  _ when type.startsWith('invoice_') || type.startsWith('payment_') => NotificationTopic.payments,
  _ when type.startsWith('visit_') => NotificationTopic.visits,
  _ => null,
};

/// One entry in the member's inbox (`GET /notifications`). The API writes
/// the title and body in the member's language.
final class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.createdAt,
    this.readAt,
    this.data = const {},
  });

  final String id;

  /// Such as `invoice_due`. Unknown types still show; they just don't
  /// open anything.
  final String type;
  final String title;
  final String body;
  final DateTime createdAt;
  final DateTime? readAt;

  /// IDs of what it is about, such as `invoice_id`.
  final Map<String, String> data;

  bool get isRead => readAt != null;

  NotificationTopic? get topic => topicOf(type);

  AppNotification markedRead(DateTime at) => AppNotification(
    id: id,
    type: type,
    title: title,
    body: body,
    createdAt: createdAt,
    readAt: readAt ?? at,
    data: data,
  );
}

/// Which topics the member gets pushes for, at the selected gym.
final class NotificationPreferences {
  const NotificationPreferences(this._enabled);

  final Map<NotificationTopic, bool> _enabled;

  /// Topics the API didn't mention count as on.
  bool operator [](NotificationTopic topic) => _enabled[topic] ?? true;

  NotificationPreferences withTopic(NotificationTopic topic, bool enabled) =>
      NotificationPreferences({..._enabled, topic: enabled});
}
