import 'dart:io' show Platform;

import 'package:device_info_plus/device_info_plus.dart';
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
    required this.deviceName,
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
      deviceName: await _deviceName(),
    );
  }

  /// The model, such as "samsung SM-J600G". Never the owner-given name,
  /// which is often a person's name.
  static Future<String> _deviceName() async {
    final info = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      final android = await info.androidInfo;
      return '${android.manufacturer} ${android.model}';
    }
    if (Platform.isIOS) return (await info.iosInfo).modelName;
    return Platform.operatingSystem;
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

  /// Shown in the member's list of signed-in devices.
  final String deviceName;
}

final appInfoProvider = Provider<AppInfo>(
  (ref) => throw UnimplementedError('appInfoProvider is overridden in bootstrap()'),
);
