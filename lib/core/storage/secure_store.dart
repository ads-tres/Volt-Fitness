import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../observability/error_reporter.dart';

/// Storage for secrets only: the session token and, later, the QR secret.
/// Backed by the Android Keystore and the iOS Keychain.
abstract interface class SecureStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);

  /// Deletes every key starting with [prefix].
  Future<void> deletePrefixed(String prefix);
}

final class FlutterSecureStore implements SecureStore {
  FlutterSecureStore([this._storage = const FlutterSecureStorage()]);

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) async {
    try {
      return await _storage.read(key: key);
    } on PlatformException catch (error, stack) {
      // The Keystore key behind the value can be lost (an OS update, a
      // restored device), leaving the value unreadable. Drop it: the member
      // signs in again instead of the app failing at every start.
      reportError(error, stack);
      try {
        await _storage.delete(key: key);
      } on PlatformException {
        // Nothing more to do; the next write replaces it.
      }
      return null;
    }
  }

  @override
  Future<void> write(String key, String value) => _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);

  @override
  Future<void> deletePrefixed(String prefix) async {
    for (final key in (await _storage.readAll()).keys.where((key) => key.startsWith(prefix))) {
      await _storage.delete(key: key);
    }
  }
}

final secureStoreProvider = Provider<SecureStore>(
  (ref) => throw UnimplementedError('secureStoreProvider is overridden in bootstrap()'),
);
