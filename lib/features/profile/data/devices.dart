import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/json.dart';

/// A phone signed in to the member's account (`GET /devices`).
final class SignedInDevice {
  const SignedInDevice({
    required this.id,
    required this.name,
    required this.platform,
    required this.isCurrent,
    this.appVersion,
    this.lastSeenAt,
  });

  final String id;
  final String name;
  final String platform;
  final String? appVersion;
  final DateTime? lastSeenAt;

  /// The phone this app runs on.
  final bool isCurrent;
}

final devicesProvider = FutureProvider.autoDispose<List<SignedInDevice>>((ref) async {
  final response = await ref.watch(apiClientProvider).get('/devices');
  return readResponse(() {
    final json = response! as Map<String, dynamic>;
    return [
      for (final device in json.objects('data'))
        SignedInDevice(
          id: device.field<String>('id'),
          name: device.field<String>('device_name'),
          platform: device.optional<String>('platform') ?? '',
          appVersion: device.optional<String>('app_version'),
          lastSeenAt: switch (device.optional<String>('last_seen_at')) {
            final iso? => DateTime.parse(iso).toUtc(),
            null => null,
          },
          isCurrent: device.optional<bool>('is_current') ?? false,
        ),
    ];
  });
});

/// Signs another phone out: its token and QR credential stop working.
Future<void> removeDevice(WidgetRef ref, String id) async {
  await ref.read(apiClientProvider).delete('/devices/$id');
  ref.invalidate(devicesProvider);
}
