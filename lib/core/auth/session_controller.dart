import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../push/push_service.dart';
import '../storage/preferences_store.dart';
import '../storage/secure_store.dart';
import 'profile.dart';
import 'profile_cache.dart';
import 'session.dart';
import 'token_store.dart';

final profileCacheProvider = Provider<ProfileCache>((ref) => ProfileCache(ref.watch(preferencesStoreProvider)));

/// Keys of data that belongs to the signed-in member, in preferences and in
/// secure storage. Signing out deletes all of them, so features only need to
/// follow the naming: `user.dashboard`, `user.access_credentials`, ...
const userDataPrefix = 'user.';

/// Who is signed in on this phone, and in which gym. Restored at startup
/// from the stored token and the cached profile; both are needed.
final class SessionController extends Notifier<Session> {
  @override
  Session build() {
    final token = ref.watch(tokenStoreProvider).token;
    final cache = ref.watch(profileCacheProvider);
    final profile = cache.readProfile();
    if (token == null || profile == null) return const SignedOut();
    return SignedIn(profile: profile, organizationId: _validOrganization(profile, cache.readOrganizationId()));
  }

  Future<void> signIn({required String token, required Profile profile}) async {
    final organizationId = _validOrganization(profile, null);
    await ref.read(tokenStoreProvider).save(token);
    await ref.read(profileCacheProvider).save(profile, organizationId: organizationId);
    state = SignedIn(profile: profile, organizationId: organizationId);
  }

  /// Takes a fresh profile from `/me`, keeping the chosen gym if the member
  /// still belongs to it.
  Future<void> updateProfile(Profile profile) async {
    if (state case SignedIn(:final organizationId)) {
      final stillValid = _validOrganization(profile, organizationId);
      await ref.read(profileCacheProvider).save(profile, organizationId: stillValid);
      state = SignedIn(profile: profile, organizationId: stillValid);
    }
  }

  Future<void> selectOrganization(String organizationId) async {
    if (state case SignedIn(:final profile) when profile.organization(organizationId) != null) {
      await ref.read(profileCacheProvider).save(profile, organizationId: organizationId);
      state = SignedIn(profile: profile, organizationId: organizationId);
    }
  }

  /// Ends the session on this phone only. Also runs when the API answers
  /// 401, meaning the token was revoked. To end it on the server too, call
  /// the logout endpoint first.
  Future<void> signOut() async {
    // The member's pushes stop here even if the logout call never reached
    // the API. The next member gets a fresh token.
    await ref.read(pushServiceProvider).deleteToken();
    await ref.read(tokenStoreProvider).clear();
    await ref.read(profileCacheProvider).clear();
    await ref.read(preferencesStoreProvider).removePrefixed(userDataPrefix);
    await ref.read(secureStoreProvider).deletePrefixed(userDataPrefix);
    state = const SignedOut();
  }

  /// [preferred] if the member belongs to it; otherwise their only gym, if
  /// there is exactly one. Null means they still have to choose.
  static String? _validOrganization(Profile profile, String? preferred) {
    if (profile.organization(preferred) != null) return preferred;
    return profile.organizations.length == 1 ? profile.organizations.single.id : null;
  }
}

final sessionControllerProvider = NotifierProvider<SessionController, Session>(SessionController.new);
