import 'dart:developer' as developer;

/// Reports an error nothing else handled. It only logs for now; crash
/// reporting (Sentry) plugs in here once a project exists to send to.
///
/// Never pass tokens, OTP codes or QR payloads in [error]: whatever lands
/// here will end up in crash reports.
void reportError(Object error, StackTrace? stack) {
  developer.log('Unhandled error', name: 'error', error: error, stackTrace: stack);
}
