import 'dart:io' show Platform;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../storage/preferences_store.dart';
import '../utils/uuid.dart';

/// Facts about this install that go out with every API request.
final class AppInfo {
  const AppInfo({
    required this.version,
    required this.buildNumber,
    required this.platform,
    required this.installationId,
  });

  static const _installationIdKey = 'device.installation_id';

  static Future<AppInfo> load(PreferencesStore preferences) async {
    final package = await PackageInfo.fromPlatform();
    var installationId = preferences.getString(_installationIdKey);
    if (installationId == null) {
      installationId = uuidV4();
      await preferences.setString(_installationIdKey, installationId);
    }
    return AppInfo(
      version: package.version,
      buildNumber: package.buildNumber,
      platform: Platform.operatingSystem,
      installationId: installationId,
    );
  }

  /// `1.0.0` from the pubspec, sent as `X-App-Version`.
  final String version;

  /// The build number from the pubspec, sent as `X-App-Build`.
  final String buildNumber;

  /// `android` or `ios`, sent as `X-Platform`.
  final String platform;

  /// Random per install, sent as `X-Device-ID`. A reinstall gets a new one;
  /// Android backup is off, so it is never copied to another phone.
  final String installationId;
}

final appInfoProvider = Provider<AppInfo>(
  (ref) => throw UnimplementedError('appInfoProvider is overridden in bootstrap()'),
);
