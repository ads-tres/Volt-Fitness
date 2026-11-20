import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/failure.dart';
import '../../core/localization/locale_controller.dart';
import '../../core/network/api_client.dart';
import '../../core/push/push_service.dart';
import '../../core/storage/preferences_store.dart';
import 'desk_session.dart';

/// What was last sent, hashed: the token itself stays off the disk. Under
/// the desk's prefix, so signing out forgets it and the next person's
/// sign-in sends the token again.
const _sentKey = '${DeskSessionController.prefix}push.sent';

/// Keeps the API's copy of this phone's push token current while staff are
/// signed in at the desk, marked `"app": "staff"` so it gets staff pushes
/// and never members' (the API's ADR 0035): at start, when the provider
/// replaces the token, and when the language changes. Sent only when
/// something changed. Builds without push (no Firebase yet) send nothing.
final deskPushTokenSyncProvider = Provider.autoDispose<void>((ref) {
  final push = ref.watch(pushServiceProvider);
  if (!push.isAvailable) return;
  final signedIn = ref.watch(deskSessionProvider.select((session) => session is DeskSignedIn));
  if (!signedIn) return;
  final languageCode = ref.watch(languageCodeProvider);

  Future<void> sync([String? changed]) async {
    final token = changed ?? await push.token();
    if (token == null || !ref.mounted) return;
    final preferences = ref.read(preferencesStoreProvider);
    final sent = sha256.convert(utf8.encode('staff|${push.provider}|$token|$languageCode')).toString();
    if (preferences.getString(_sentKey) == sent) return;
    // Noted before sending, so a second sync starting meanwhile (the desk
    // opening and signing in at once) doesn't send it again.
    await preferences.setString(_sentKey, sent);
    try {
      await ref
          .read(apiClientProvider)
          .put(
            '/me/push-token',
            body: {'provider': push.provider, 'token': token, 'locale': languageCode, 'app': 'staff'},
          );
    } on Failure {
      // Sent again at the next start or change.
      if (preferences.getString(_sentKey) == sent) await preferences.remove(_sentKey);
    }
  }

  unawaited(sync());
  final subscription = push.tokenChanges.listen(sync);
  ref.onDispose(subscription.cancel);
});
