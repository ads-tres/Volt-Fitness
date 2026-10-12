import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'token_store.dart';

enum SessionStatus { signedOut, signedIn }

/// Whether this phone has a session. Phase 2 adds the signed-in user and
/// their gyms; the router only needs the status.
final class SessionController extends Notifier<SessionStatus> {
  @override
  SessionStatus build() =>
      ref.watch(tokenStoreProvider).token == null ? SessionStatus.signedOut : SessionStatus.signedIn;

  Future<void> signIn(String token) async {
    await ref.read(tokenStoreProvider).save(token);
    state = SessionStatus.signedIn;
  }

  /// Ends the session on this phone. Also runs when the API answers 401,
  /// meaning the token was revoked.
  Future<void> signOut() async {
    await ref.read(tokenStoreProvider).clear();
    state = SessionStatus.signedOut;
  }
}

final sessionControllerProvider = NotifierProvider<SessionController, SessionStatus>(
  SessionController.new,
);
