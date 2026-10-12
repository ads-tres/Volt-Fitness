import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../storage/secure_store.dart';

/// Holds the Sanctum device token. It is loaded once at startup and kept in
/// memory, so the HTTP layer can read it without waiting on the Keystore.
final class TokenStore {
  TokenStore(this._secureStore);

  static const _key = 'auth.token';

  final SecureStore _secureStore;
  String? _token;

  String? get token => _token;

  Future<void> load() async {
    _token = await _secureStore.read(_key);
  }

  Future<void> save(String token) async {
    await _secureStore.write(_key, token);
    _token = token;
  }

  Future<void> clear() async {
    // Forget it in memory first, so no request goes out with it meanwhile.
    _token = null;
    await _secureStore.delete(_key);
  }
}

final tokenStoreProvider = Provider<TokenStore>(
  (ref) => throw UnimplementedError('tokenStoreProvider is overridden in bootstrap()'),
);
