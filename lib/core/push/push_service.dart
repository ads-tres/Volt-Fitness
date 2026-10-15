import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/env.dart';
import '../storage/preferences_store.dart';

/// Whether the phone lets the app show notifications.
enum PushPermission {
  granted,
  denied,

  /// Never asked. Android 13+ and iOS ask once; older Android allows
  /// notifications without asking.
  notAsked,
}

/// A push from the API. It only says what happened and what it points at,
/// never personal details: the app fetches the rest.
final class PushMessage {
  const PushMessage({required this.data, this.title, this.body});

  /// FCM data values are always strings: `type`, `notification_id`,
  /// `organization_id` and IDs such as `invoice_id`.
  final Map<String, String> data;
  final String? title;
  final String? body;

  String get type => data['type'] ?? '';
  String? get notificationId => data['notification_id'];
  String? get organizationId => data['organization_id'];
}

/// The phone's push channel: Firebase Cloud Messaging once the Firebase
/// projects exist, and a fake in dev builds meanwhile.
abstract interface class PushService {
  /// False when this build can't receive pushes at all.
  bool get isAvailable;

  /// Sent to the API with the token.
  String get provider;

  Future<PushPermission> permission();

  /// Shows the system prompt where there is one.
  Future<PushPermission> requestPermission();

  /// The phone's settings for this app, to turn notifications back on.
  Future<void> openSettings();

  Future<String?> token();

  /// Fires when the provider replaces the token.
  Stream<String> get tokenChanges;

  /// Arrived while the app was open. The system shows nothing for these.
  Stream<PushMessage> get received;

  /// Tapped in the notification shade while the app was running.
  Stream<PushMessage> get opened;

  /// The notification whose tap started the app, the first time only.
  Future<PushMessage?> takeLaunchMessage();

  /// Stops pushes to this install. The next [token] is a new one. Never
  /// throws: signing out must not depend on it.
  Future<void> deleteToken();
}

/// A build without Firebase: nothing arrives, and the inbox still fills.
final class NoPushService implements PushService {
  const NoPushService();

  @override
  bool get isAvailable => false;

  @override
  String get provider => 'none';

  @override
  Future<PushPermission> permission() async => PushPermission.denied;

  @override
  Future<PushPermission> requestPermission() async => PushPermission.denied;

  @override
  Future<void> openSettings() async {}

  @override
  Future<String?> token() async => null;

  @override
  Stream<String> get tokenChanges => const Stream.empty();

  @override
  Stream<PushMessage> get received => const Stream.empty();

  @override
  Stream<PushMessage> get opened => const Stream.empty();

  @override
  Future<PushMessage?> takeLaunchMessage() async => null;

  @override
  Future<void> deleteToken() async {}
}

/// Stands in for FCM in dev builds. The fake backend's test push arrives
/// through [deliver], and the permission answer is remembered the way the
/// phone would remember it.
final class FakePushService implements PushService {
  FakePushService(this._preferences);

  static const permissionKey = 'dev.fake_push.permission';

  final PreferencesStore _preferences;
  final _tokenChanges = StreamController<String>.broadcast();
  final _received = StreamController<PushMessage>.broadcast();
  final _opened = StreamController<PushMessage>.broadcast();
  var _generation = 1;
  PushMessage? _launchMessage;

  /// A push arriving: in the foreground, or tapped in the shade.
  void deliver(PushMessage message, {bool tapped = false}) => (tapped ? _opened : _received).add(message);

  /// The next start opens with [message], as if its notification was tapped.
  void launchWith(PushMessage message) => _launchMessage = message;

  /// FCM replacing the token, as it does now and then.
  void rotateToken() {
    _generation++;
    _tokenChanges.add(_token);
  }

  String get _token => 'fake-fcm-token-$_generation';

  @override
  bool get isAvailable => true;

  @override
  String get provider => 'fcm';

  @override
  Future<PushPermission> permission() async =>
      PushPermission.values.where((value) => value.name == _preferences.getString(permissionKey)).firstOrNull ??
      PushPermission.notAsked;

  @override
  Future<PushPermission> requestPermission() async {
    await _preferences.setString(permissionKey, PushPermission.granted.name);
    return PushPermission.granted;
  }

  @override
  Future<void> openSettings() => requestPermission();

  @override
  Future<String?> token() async => _token;

  @override
  Stream<String> get tokenChanges => _tokenChanges.stream;

  @override
  Stream<PushMessage> get received => _received.stream;

  @override
  Stream<PushMessage> get opened => _opened.stream;

  @override
  Future<PushMessage?> takeLaunchMessage() async {
    final message = _launchMessage;
    _launchMessage = null;
    return message;
  }

  @override
  Future<void> deleteToken() async => _generation++;

  void dispose() {
    unawaited(_tokenChanges.close());
    unawaited(_received.close());
    unawaited(_opened.close());
  }
}

final pushServiceProvider = Provider<PushService>((ref) {
  // Real builds get FirebasePushService once the Firebase projects exist.
  if (!ref.watch(envProvider).usesFakeBackend) return const NoPushService();
  final push = FakePushService(ref.watch(preferencesStoreProvider));
  ref.onDispose(push.dispose);
  return push;
});

/// Whether the phone lets the app notify, checked again when the member
/// returns from the phone's settings.
final class PushPermissionController extends AsyncNotifier<PushPermission> {
  @override
  Future<PushPermission> build() => ref.watch(pushServiceProvider).permission();

  Future<void> request() async {
    final answer = await ref.read(pushServiceProvider).requestPermission();
    if (ref.mounted) state = AsyncData(answer);
  }

  Future<void> openSettings() async {
    await ref.read(pushServiceProvider).openSettings();
    ref.invalidateSelf();
  }
}

final pushPermissionProvider = AsyncNotifierProvider<PushPermissionController, PushPermission>(
  PushPermissionController.new,
);
