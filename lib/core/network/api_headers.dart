/// Headers agreed with the backend (see the API contract doc).
abstract final class ApiHeaders {
  static const authorization = 'Authorization';
  static const acceptLanguage = 'Accept-Language';
  static const organizationId = 'X-Organization-ID';
  static const deviceId = 'X-Device-ID';
  static const appVersion = 'X-App-Version';
  static const appBuild = 'X-App-Build';
  static const platform = 'X-Platform';
  static const requestId = 'X-Request-ID';
  static const idempotencyKey = 'Idempotency-Key';
}
