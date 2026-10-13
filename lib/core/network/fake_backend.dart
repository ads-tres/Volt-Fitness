import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

import 'api_headers.dart';

/// Answers API calls inside the app until the Laravel API runs, using the
/// JSON shapes from the backend contract doc. Dev builds only; prod never
/// uses it (see `Env.usesFakeBackend`).
///
/// Sign-in: any Ethiopian mobile number, code [validCode]. [expiredCode]
/// gives `OTP_EXPIRED`; five wrong codes give `OTP_TOO_MANY_ATTEMPTS`.
/// [twoGymsPhone] belongs to two gyms, [noGymPhone] to none, any other
/// number to one.
final class FakeBackend implements HttpClientAdapter {
  FakeBackend({this.latency = const Duration(milliseconds: 600)});

  static const validCode = '123456';
  static const expiredCode = '000000';
  static const twoGymsPhone = '+251911111111';
  static const noGymPhone = '+251900000000';

  static const _tokenPrefix = 'fake-token:';
  static const _maxWrongCodes = 5;

  final Duration latency;
  final _wrongCodes = <String, int>{};

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    await Future<void>.delayed(latency);
    final body = switch (options.data) {
      final Map<String, dynamic> map => map,
      _ => const <String, dynamic>{},
    };
    final requestId = options.headers[ApiHeaders.requestId];
    return switch ((options.method, options.path)) {
      ('GET', '/app-config') => _json(200, {
        'data': {
          'min_supported_build': 1,
          'latest_build': 1,
          'update_url': 'https://play.google.com/store/apps/details?id=com.volt.member',
          'maintenance': {'active': false, 'message': null},
        },
      }),
      ('POST', '/auth/otp/request') => _requestCode(body, requestId),
      ('POST', '/auth/otp/verify') => _verifyCode(body, requestId),
      ('GET', '/me') => _withSession(options, requestId, (phone) => _json(200, {'data': _profile(phone)})),
      ('POST', '/auth/logout') => _withSession(options, requestId, (_) => ResponseBody.fromString('', 204)),
      _ => _error(404, 'NOT_FOUND', 'Not found.', requestId),
    };
  }

  ResponseBody _requestCode(Map<String, dynamic> body, Object? requestId) {
    final phone = body['phone'];
    if (phone is! String || !RegExp(r'^\+251[79]\d{8}$').hasMatch(phone)) {
      return _error(422, 'VALIDATION_FAILED', 'The phone field must be a valid phone number.', requestId, errors: {
        'phone': ['The phone field must be a valid phone number.'],
      });
    }
    return _json(200, {
      'data': {'expires_in': 300, 'resend_in': 60},
    });
  }

  ResponseBody _verifyCode(Map<String, dynamic> body, Object? requestId) {
    final phone = body['phone'];
    final code = body['code'];
    if (phone is! String || code is! String) {
      return _error(422, 'VALIDATION_FAILED', 'The phone and code fields are required.', requestId);
    }
    final wrongCodes = _wrongCodes[phone] ?? 0;
    if (wrongCodes >= _maxWrongCodes) {
      return _error(429, 'OTP_TOO_MANY_ATTEMPTS', 'Too many attempts.', requestId, retryAfterSeconds: 60);
    }
    if (code == expiredCode) {
      return _error(422, 'OTP_EXPIRED', 'This code has expired.', requestId);
    }
    if (code != validCode) {
      _wrongCodes[phone] = wrongCodes + 1;
      return _error(422, 'OTP_INVALID', 'The code you entered is incorrect.', requestId, errors: {
        'code': ['The code you entered is incorrect.'],
      });
    }
    _wrongCodes.remove(phone);
    return _json(200, {
      'data': {'token': '$_tokenPrefix$phone', ..._profile(phone)},
    });
  }

  ResponseBody _withSession(RequestOptions options, Object? requestId, ResponseBody Function(String phone) respond) {
    final authorization = options.headers[ApiHeaders.authorization];
    final token = authorization is String && authorization.startsWith('Bearer ') ? authorization.substring(7) : null;
    if (token == null || !token.startsWith(_tokenPrefix)) {
      return _error(401, 'UNAUTHENTICATED', 'Unauthenticated.', requestId);
    }
    return respond(token.substring(_tokenPrefix.length));
  }

  Map<String, Object?> _profile(String phone) => {
    'user': {'id': '01K7Z5B2W8R3M5N7Q9S1T3V5X0', 'name': 'Abebe Kebede', 'phone': phone},
    'organizations': [
      if (phone != noGymPhone) _boleIronGym,
      if (phone == twoGymsPhone) _kazanchisFitClub,
    ],
  };

  static const _boleIronGym = {
    'id': '01K7Z6A1B2C3D4E5F6G7H8J9KM',
    'name': 'Bole Iron Gym',
    'role': 'member',
    'branding': {
      'logo_url': null,
      'primary_color': '#0E7C66',
      'accent_color': '#F5A524',
      'contact_phone': '+251 11 000 0001',
    },
    'features': ['classes'],
  };

  static const _kazanchisFitClub = {
    'id': '01K7Z6N2P3Q4R5S6T7V8W9X0YZ',
    'name': 'Kazanchis Fit Club',
    'role': 'member',
    'branding': {
      'logo_url': null,
      'primary_color': '#4F46E5',
      'accent_color': null,
      'contact_phone': '+251 11 000 0002',
    },
    'features': <String>[],
  };

  ResponseBody _json(int status, Object? body, {Map<String, List<String>> headers = const {}}) =>
      ResponseBody.fromString(
        jsonEncode(body),
        status,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
          ...headers,
        },
      );

  ResponseBody _error(
    int status,
    String code,
    String message,
    Object? requestId, {
    Map<String, List<String>>? errors,
    int? retryAfterSeconds,
  }) => _json(
    status,
    {'message': message, 'code': code, 'errors': ?errors, 'request_id': requestId},
    headers: {
      if (retryAfterSeconds != null) 'retry-after': ['$retryAfterSeconds'],
    },
  );

  @override
  void close({bool force = false}) {}
}
