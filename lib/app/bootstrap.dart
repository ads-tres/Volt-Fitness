import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/auth/token_store.dart';
import '../core/config/env.dart';
import '../core/device/app_info.dart';
import '../core/observability/error_reporter.dart';
import '../core/storage/preferences_store.dart';
import '../core/storage/secure_store.dart';
import 'app.dart';

Duration? noAutomaticRetry(int retryCount, Object error) => null;

/// Loads what the first frame needs, then starts the app. The native splash
/// screen stays up meanwhile.
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    reportError(details.exception, details.stack);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    reportError(error, stack);
    return true;
  };
  LicenseRegistry.addLicense(() async* {
    for (final (font, file) in const [('Montserrat', 'OFL-Montserrat.txt'), ('Noto Sans Ethiopic', 'OFL-NotoSansEthiopic.txt')]) {
      yield LicenseEntryWithLineBreaks([font], await rootBundle.loadString('assets/fonts/$file'));
    }
  });

  final env = Env.fromFlavor(appFlavor);
  final preferences = SharedPreferencesStore(
    await SharedPreferencesWithCache.create(cacheOptions: const SharedPreferencesWithCacheOptions()),
  );
  final secureStore = FlutterSecureStore();
  final tokenStore = TokenStore(secureStore);
  await tokenStore.load();
  final appInfo = await AppInfo.load(preferences);

  runApp(
    ProviderScope(
      // Failed loads wait for the member to retry or pull to refresh,
      // instead of retrying on their own in the background.
      retry: noAutomaticRetry,
      overrides: [
        envProvider.overrideWithValue(env),
        preferencesStoreProvider.overrideWithValue(preferences),
        secureStoreProvider.overrideWithValue(secureStore),
        tokenStoreProvider.overrideWithValue(tokenStore),
        appInfoProvider.overrideWithValue(appInfo),
      ],
      child: const VoltApp(),
    ),
  );
}
