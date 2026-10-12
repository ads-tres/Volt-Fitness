import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Non-secret settings that must be readable synchronously, such as the
/// chosen language. Secrets belong in secure storage instead.
abstract interface class PreferencesStore {
  String? getString(String key);
  Future<void> setString(String key, String value);
  Future<void> remove(String key);
}

final class SharedPreferencesStore implements PreferencesStore {
  SharedPreferencesStore(this._preferences);

  final SharedPreferencesWithCache _preferences;

  @override
  String? getString(String key) => _preferences.getString(key);

  @override
  Future<void> setString(String key, String value) => _preferences.setString(key, value);

  @override
  Future<void> remove(String key) => _preferences.remove(key);
}

final preferencesStoreProvider = Provider<PreferencesStore>(
  (ref) => throw UnimplementedError('preferencesStoreProvider is overridden in bootstrap()'),
);
