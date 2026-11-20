import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/session_controller.dart';
import '../errors/failure.dart';
import '../network/api_client.dart';
import '../storage/preferences_store.dart';
import 'locale_controller.dart';

/// The language last sent, so it is sent again only when it changes. A
/// member's key, so signing out forgets it.
const _sentKey = '${userDataPrefix}language.sent';

/// Tells the API the member's language (`PUT /me/language`), so texts from
/// every gym come in Amharic or English to match the app (the API's ADR
/// 0034). Watch it only while a member is signed in. Sent when the language
/// changes, or after sign-in; a failure is tried again at the next start.
final memberLanguageSyncProvider = Provider.autoDispose<void>((ref) {
  final language = ref.watch(languageCodeProvider) == 'am' ? 'am' : 'en';

  Future<void> sync() async {
    final preferences = ref.read(preferencesStoreProvider);
    if (preferences.getString(_sentKey) == language) return;
    // Noted before sending, so a second start meanwhile doesn't send it too.
    await preferences.setString(_sentKey, language);
    try {
      await ref.read(apiClientProvider).put('/me/language', body: {'language': language});
    } on Failure {
      if (preferences.getString(_sentKey) == language) await preferences.remove(_sentKey);
    }
  }

  unawaited(sync());
});
