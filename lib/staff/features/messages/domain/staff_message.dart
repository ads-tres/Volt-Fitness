/// A message to the staff member at this gym, from the inbox or a push:
/// an online payment, a refund to make, a member freezing or ending a
/// freeze in the app, or the morning's members to call. Its title and body
/// come written, in the staff member's language.
final class StaffMessage {
  const StaffMessage({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.createdAt,
    this.data = const {},
    this.readAt,
  });

  static const membersToCall = 'staff_members_to_call';

  final String id;
  final String type;
  final String title;
  final String body;

  /// The ids of what it is about, such as `payment_id`, kept for the screens
  /// the desk may gain.
  final Map<String, Object?> data;

  /// In UTC.
  final DateTime createdAt;
  final DateTime? readAt;

  bool get isRead => readAt != null;

  StaffMessage markedRead(DateTime at) =>
      StaffMessage(id: id, type: type, title: title, body: body, createdAt: createdAt, data: data, readAt: readAt ?? at);
}

/// What staff can be told about, each by push, SMS or both.
enum StaffTopic {
  onlinePayments('online_payments'),
  refunds('refunds'),
  appFreezes('app_freezes'),
  membersToCall('members_to_call');

  const StaffTopic(this.apiName);

  final String apiName;
}

/// How the staff member wants to hear about one topic.
typedef StaffChannels = ({bool push, bool sms});
