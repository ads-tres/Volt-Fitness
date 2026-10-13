import 'dart:convert';

import '../observability/error_reporter.dart';
import '../storage/preferences_store.dart';
import 'profile.dart';
import 'profile_json.dart';

/// Keeps the last known profile and the chosen gym, so the app opens
/// straight into the right gym, even offline. `/me` refreshes it.
final class ProfileCache {
  ProfileCache(this._preferences);

  static const _profileKey = 'session.profile';
  static const _organizationKey = 'session.organization_id';

  final PreferencesStore _preferences;

  Profile? readProfile() {
    final stored = _preferences.getString(_profileKey);
    if (stored == null) return null;
    try {
      return profileFromJson(jsonDecode(stored) as Map<String, dynamic>);
    } on Object catch (error, stack) {
      // Written by an older app version with another shape: sign in again.
      reportError(error, stack);
      return null;
    }
  }

  String? readOrganizationId() => _preferences.getString(_organizationKey);

  Future<void> save(Profile profile, {required String? organizationId}) async {
    await _preferences.setString(_profileKey, jsonEncode(profileToJson(profile)));
    if (organizationId == null) {
      await _preferences.remove(_organizationKey);
    } else {
      await _preferences.setString(_organizationKey, organizationId);
    }
  }

  Future<void> clear() async {
    await _preferences.remove(_profileKey);
    await _preferences.remove(_organizationKey);
  }
}
