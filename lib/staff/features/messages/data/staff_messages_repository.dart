import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/json.dart';
import '../../../core/desk_session.dart';
import '../domain/staff_message.dart';

/// One page of the inbox, newest first, with how many are unread in all.
typedef StaffMessagePage = ({List<StaffMessage> messages, int unreadCount, int? nextPage});

/// The staff member's messages and their choices at the desk's gym
/// (`/organizations/{gym}/notifications…`). Every call throws a [Failure]
/// when it fails.
final class StaffMessagesRepository {
  const StaffMessagesRepository(this._api, this._session);

  final ApiClient _api;
  final DeskSession Function() _session;

  String _path(String path) => deskPath(_session(), path);

  Future<StaffMessagePage> page({int page = 1}) async {
    final response = await _api.get(_path('/notifications'), query: {'page': page});
    return readResponse(() {
      final json = response! as Map<String, dynamic>;
      final next = json.optional<Map<String, dynamic>>('links')?.optional<String>('next');
      return (
        messages: [for (final message in json.objects('data')) staffMessageFromJson(message)],
        unreadCount: json.optional<Map<String, dynamic>>('meta')?.optional<int>('unread_count') ?? 0,
        nextPage: next == null ? null : page + 1,
      );
    });
  }

  Future<void> markRead(String id) => _api.post(_path('/notifications/$id/read'));

  Future<void> markAllRead() => _api.post(_path('/notifications/read-all'));

  Future<Map<StaffTopic, StaffChannels>> preferences() async {
    final data = dataObject(await _api.get(_path('/notification-preferences')));
    return readResponse(() => staffPreferencesFromJson(data));
  }

  /// Changes one topic's channels; the API answers with them all.
  Future<Map<StaffTopic, StaffChannels>> updatePreferences(StaffTopic topic, {bool? push, bool? sms}) async {
    final data = dataObject(
      await _api.patch(
        _path('/notification-preferences'),
        body: {
          topic.apiName: {'push': ?push, 'sms': ?sms},
        },
      ),
    );
    return readResponse(() => staffPreferencesFromJson(data));
  }
}

StaffMessage staffMessageFromJson(Map<String, dynamic> json) => StaffMessage(
  id: '${json.field<Object>('id')}',
  type: json.optional<String>('type') ?? '',
  title: json.optional<String>('title') ?? '',
  body: json.optional<String>('body') ?? '',
  data: json.optional<Map<String, dynamic>>('data') ?? const {},
  createdAt: DateTime.parse(json.field<String>('created_at')).toUtc(),
  readAt: switch (json.optional<String>('read_at')) {
    final at? => DateTime.parse(at).toUtc(),
    null => null,
  },
);

/// Each topic the API knows; a topic it leaves out is push on, SMS off, its
/// default.
Map<StaffTopic, StaffChannels> staffPreferencesFromJson(Map<String, dynamic> json) => {
  for (final topic in StaffTopic.values)
    topic: (
      push: json.optional<Map<String, dynamic>>(topic.apiName)?.optional<bool>('push') ?? true,
      sms: json.optional<Map<String, dynamic>>(topic.apiName)?.optional<bool>('sms') ?? false,
    ),
};

final staffMessagesRepositoryProvider = Provider<StaffMessagesRepository>(
  (ref) => StaffMessagesRepository(ref.watch(apiClientProvider), () => ref.read(deskSessionProvider)),
);
