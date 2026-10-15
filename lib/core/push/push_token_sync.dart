import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/session_controller.dart';
import '../errors/failure.dart';
import '../localization/locale_controller.dart';
import '../network/api_client.dart';
import '../storage/preferences_store.dart';
import 'push_service.dart';

/// What was last sent, hashed: the token itself stays off the disk.
const _sentKey = '${userDataPrefix}push.sent';

/// Keeps the API's copy of this phone's push token current while a member
/// is signed in: at start, when the provider replaces the token, and when
/// the language changes, since the API writes pushes in the language the
/// phone last reported. Sent only when something changed.
final pushTokenSyncProvider = Provider.autoDispose<void>((ref) {
  final push = ref.watch(pushServiceProvider);
  if (!push.isAvailable) return;
  final languageCode = ref.watch(languageCodeProvider);

  Future<void> sync([String? changed]) async {
    final token = changed ?? await push.token();
    if (token == null || !ref.mounted) return;
    final preferences = ref.read(preferencesStoreProvider);
    final sent = sha256.convert(utf8.encode('${push.provider}|$token|$languageCode')).toString();
    if (preferences.getString(_sentKey) == sent) return;
    try {
      await ref
          .read(apiClientProvider)
          .put(
            '/devices/current/push-token',
            body: {'provider': push.provider, 'token': token, 'locale': languageCode},
          );
      await preferences.setString(_sentKey, sent);
    } on Failure {
      // Sent again at the next start or change.
    }
  }

  unawaited(sync());
  final subscription = push.tokenChanges.listen(sync);
  ref.onDispose(subscription.cancel);
});
