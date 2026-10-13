import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The backend a build talks to, picked by the build flavor
/// (`flutter run --flavor dev|staging|prod`).
enum AppEnvironment { dev, staging, prod }

final class Env {
  const Env({required this.environment, required this.apiBaseUrl, this.usesFakeBackend = false});

  /// A build without a flavor (tests, or iOS until it gets flavors) is dev,
  /// so nothing reaches production by accident. `--dart-define=API_BASE_URL=`
  /// points any build at another server, e.g. a laptop on the same Wi-Fi.
  ///
  /// Dev answers from the in-app fake backend until the API runs; pass
  /// `--dart-define=FAKE_BACKEND=false` to use the real one. Prod never fakes.
  factory Env.fromFlavor(String? flavor) {
    final environment = switch (flavor) {
      'prod' => AppEnvironment.prod,
      'staging' => AppEnvironment.staging,
      _ => AppEnvironment.dev,
    };
    const override = String.fromEnvironment('API_BASE_URL');
    const fake = String.fromEnvironment('FAKE_BACKEND');
    return Env(
      environment: environment,
      apiBaseUrl: override.isNotEmpty ? override : _defaultApiBaseUrl(environment),
      usesFakeBackend: switch (environment) {
        AppEnvironment.prod => false,
        AppEnvironment.dev => fake != 'false',
        AppEnvironment.staging => fake == 'true',
      },
    );
  }

  final AppEnvironment environment;
  final String apiBaseUrl;
  final bool usesFakeBackend;

  /// Request logs are for local debugging only; they never ship.
  bool get logsNetwork => environment == AppEnvironment.dev && kDebugMode;

  static String _defaultApiBaseUrl(AppEnvironment environment) => switch (environment) {
    // `php artisan serve` on the development machine, as the Android
    // emulator sees it.
    AppEnvironment.dev => 'http://10.0.2.2:8000/api/v1',
    // Placeholders until the backend is deployed.
    AppEnvironment.staging => 'https://staging-api.volt.example/api/v1',
    AppEnvironment.prod => 'https://api.volt.example/api/v1',
  };
}

final envProvider = Provider<Env>(
  (ref) => throw UnimplementedError('envProvider is overridden in bootstrap()'),
);
