import 'dart:convert';
import 'dart:io' show HttpDate;
import 'dart:math';
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
/// number to one. The membership depends on the number too: see
/// [endingSoonPhone], [expiredPhone], [frozenPhone] and [noPlanPhone]; any
/// other number has a monthly plan with 18 days left.
final class FakeBackend implements HttpClientAdapter {
  FakeBackend({this.latency = const Duration(milliseconds: 600), DateTime Function()? now})
    : _now = now ?? DateTime.now;

  static const validCode = '123456';
  static const expiredCode = '000000';
  static const twoGymsPhone = '+251911111111';
  static const noGymPhone = '+251900000000';
  static const endingSoonPhone = '+251922222222';
  static const expiredPhone = '+251933333333';
  static const frozenPhone = '+251944444444';
  static const noPlanPhone = '+251955555555';

  static const _tokenPrefix = 'fake-token:';
  static const _maxWrongCodes = 5;

  final Duration latency;
  final DateTime Function() _now;
  final _random = Random();
  final _wrongCodes = <String, int>{};

  /// Phone number to its signed-in devices.
  final _devices = <String, List<_Device>>{};

  /// `phone|gym|device` to that device's QR credential.
  final _credentials = <String, _Credential>{};

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    await Future<void>.delayed(latency);
    final request = _Request(options);
    return switch ((options.method, options.path)) {
      ('GET', '/app-config') => _json(200, {
        'data': {
          'min_supported_build': 1,
          'latest_build': 1,
          'update_url': 'https://play.google.com/store/apps/details?id=com.volt.member',
          'maintenance': {'active': false, 'message': null},
        },
      }),
      ('POST', '/auth/otp/request') => _requestCode(request),
      ('POST', '/auth/otp/verify') => _verifyCode(request),
      ('GET', '/me') => _signedIn(request, (phone) => _json(200, {'data': _profile(phone)})),
      ('POST', '/auth/logout') => _signedIn(request, (phone) {
        _revokeDevice(phone, request.deviceId, 'signed_out');
        return _noContent();
      }),
      ('GET', '/me/dashboard') => _inGym(request, _dashboard),
      ('GET', '/attendance') => _inGym(request, (phone, gym) => _attendance(request, phone, gym)),
      ('POST', '/access/credentials') => _inGym(request, (phone, gym) => _issueCredential(request, phone, gym)),
      ('GET', '/access/credentials/current') => _inGym(request, (phone, gym) => _currentCredential(request, phone, gym)),
      ('GET', '/devices') => _signedIn(request, (phone) => _listDevices(request, phone)),
      ('DELETE', final path) when path.startsWith('/devices/') => _signedIn(
        request,
        (phone) => _removeDevice(request, phone, path.substring('/devices/'.length)),
      ),
      _ => _error(404, 'NOT_FOUND', 'Not found.', request),
    };
  }

  // Sign-in

  ResponseBody _requestCode(_Request request) {
    final phone = request.body['phone'];
    if (phone is! String || !RegExp(r'^\+251[79]\d{8}$').hasMatch(phone)) {
      return _error(422, 'VALIDATION_FAILED', 'The phone field must be a valid phone number.', request, errors: {
        'phone': ['The phone field must be a valid phone number.'],
      });
    }
    return _json(200, {
      'data': {'expires_in': 300, 'resend_in': 60},
    });
  }

  ResponseBody _verifyCode(_Request request) {
    final phone = request.body['phone'];
    final code = request.body['code'];
    if (phone is! String || code is! String) {
      return _error(422, 'VALIDATION_FAILED', 'The phone and code fields are required.', request);
    }
    final wrongCodes = _wrongCodes[phone] ?? 0;
    if (wrongCodes >= _maxWrongCodes) {
      return _error(429, 'OTP_TOO_MANY_ATTEMPTS', 'Too many attempts.', request, retryAfterSeconds: 60);
    }
    if (code == expiredCode) {
      return _error(422, 'OTP_EXPIRED', 'This code has expired.', request);
    }
    if (code != validCode) {
      _wrongCodes[phone] = wrongCodes + 1;
      return _error(422, 'OTP_INVALID', 'The code you entered is incorrect.', request, errors: {
        'code': ['The code you entered is incorrect.'],
      });
    }
    _wrongCodes.remove(phone);
    _registerDevice(phone, request.body['device']);
    return _json(200, {
      'data': {'token': '$_tokenPrefix$phone', ..._profile(phone)},
    });
  }

  Map<String, Object?> _profile(String phone) => {
    'user': {'id': '01K7Z5B2W8R3M5N7Q9S1T3V5X0', 'name': 'Abebe Kebede', 'phone': phone},
    'organizations': [
      if (phone != noGymPhone) _boleIronGym,
      if (phone == twoGymsPhone) _kazanchisFitClub,
    ],
  };

  // Membership and visits

  ResponseBody _dashboard(String phone, String gym) => _json(200, {
    'data': {
      'membership': _membership(phone, gym),
      'recent_attendance': _visits(phone, gym).take(5).toList(),
      'outstanding': null,
    },
  });

  ResponseBody _attendance(_Request request, String phone, String gym) {
    final all = _visits(phone, gym);
    final from = int.tryParse(request.query['cursor'] ?? '') ?? 0;
    final perPage = int.tryParse(request.query['per_page'] ?? '') ?? 20;
    final to = min(from + perPage, all.length);
    return _json(200, {
      'data': all.sublist(min(from, all.length), to),
      'links': {'next': null, 'prev': null},
      'meta': {'per_page': perPage, 'next_cursor': to < all.length ? '$to' : null, 'prev_cursor': null},
    });
  }

  Map<String, Object?>? _membership(String phone, String gym) {
    final today = _today;
    String day(int offset) => _iso(today.add(Duration(days: offset)));
    final branches = gym == _kazanchisFitClub['id'] ? [_kazanchisBranch] : [_boleBranch, _megenagnaBranch];

    Map<String, Object?> plan(String name, int startOffset, int endOffset, {String status = 'active'}) => {
      'id': '01K7Z7M${phone.substring(phone.length - 4)}${gym.substring(gym.length - 4)}'.padRight(26, '0'),
      'plan_name': name,
      'status': status,
      'starts_on': day(startOffset),
      'ends_on': day(endOffset),
      'grace_ends_on': null,
      'frozen_until': null,
      'allowed_branches': branches,
      'visits_remaining': null,
    };

    if (gym == _kazanchisFitClub['id']) return plan('Quarterly', -26, 64);
    return switch (phone) {
      endingSoonPhone => plan('Monthly', -27, 3),
      expiredPhone => plan('Monthly', -36, -6, status: 'expired'),
      frozenPhone => {...plan('Monthly', -10, 30, status: 'frozen'), 'frozen_until': day(7)},
      noPlanPhone => null,
      _ => plan('Monthly', -12, 18),
    };
  }

  /// A few weeks of morning visits, newest first, with one late-night scan
  /// the gym turned away.
  List<Map<String, Object?>> _visits(String phone, String gym) {
    if (phone == noPlanPhone) return const [];
    final branches = gym == _kazanchisFitClub['id'] ? [_kazanchisBranch] : [_boleBranch, _megenagnaBranch];
    final today = _today;
    final visits = <Map<String, Object?>>[];
    for (var i = 0, daysAgo = 0; i < 26; i++, daysAgo += (i % 3 == 0) ? 2 : 1) {
      if (phone == frozenPhone && daysAgo < 3) continue;
      final lateNight = i == 3;
      final at = DateTime(today.year, today.month, today.day - daysAgo, lateNight ? 22 : 6, lateNight ? 40 : (5 + i * 7) % 60);
      final expired = phone == expiredPhone && daysAgo < 6;
      visits.add({
        'id': '01K7Z8V${i.toString().padLeft(3, '0')}${gym.substring(gym.length - 4)}'.padRight(26, '0'),
        'checked_in_at': at.toUtc().toIso8601String(),
        'branch': branches[i % branches.length],
        'result': lateNight || expired ? 'denied' : 'allowed',
        'reason_code': expired ? 'MEMBERSHIP_EXPIRED' : (lateNight ? 'OUTSIDE_ALLOWED_HOURS' : null),
      });
    }
    return visits;
  }

  // QR credentials

  ResponseBody _issueCredential(_Request request, String phone, String gym) {
    // One active phone per member and gym: the newest one wins.
    for (final MapEntry(:key, :value) in _credentials.entries) {
      if (key.startsWith('$phone|$gym|') && value.status == 'active') {
        value
          ..status = 'revoked'
          ..reason = 'replaced';
      }
    }
    final credential = _Credential(id: _ulid(), secret: _hex(32));
    _credentials['$phone|$gym|${request.deviceId}'] = credential;
    return _json(201, {
      'data': {
        'credential_id': credential.id,
        'secret': credential.secret,
        'algorithm': 'GQ1',
        'issued_at': _now().toUtc().toIso8601String(),
      },
    });
  }

  ResponseBody _currentCredential(_Request request, String phone, String gym) {
    final credential = _credentials['$phone|$gym|${request.deviceId}'];
    if (credential == null) return _error(404, 'CREDENTIAL_NOT_FOUND', 'No credential for this device.', request);
    return _json(200, {
      'data': {
        'credential_id': credential.id,
        'status': credential.status,
        'revoked_reason': credential.reason,
        'algorithm': 'GQ1',
      },
    });
  }

  // Devices

  void _registerDevice(String phone, Object? device) {
    if (device is! Map<String, dynamic>) return;
    final devices = _devices.putIfAbsent(
      phone,
      () => [
        _Device(
          id: 'other-phone',
          name: 'TECNO Spark 10 Pro',
          platform: 'android',
          appVersion: '1.0.0',
          lastSeenAt: _now().subtract(const Duration(days: 3)),
        ),
      ],
    );
    final id = device['device_id'];
    if (id is! String) return;
    devices
      ..removeWhere((existing) => existing.id == id)
      ..insert(
        0,
        _Device(
          id: id,
          name: '${device['device_name'] ?? 'Phone'}',
          platform: '${device['platform'] ?? 'android'}',
          appVersion: '${device['app_version'] ?? ''}',
          lastSeenAt: _now(),
        ),
      );
  }

  ResponseBody _listDevices(_Request request, String phone) => _json(200, {
    'data': [
      for (final device in _devices[phone] ?? const <_Device>[])
        {
          'id': device.id,
          'device_name': device.name,
          'platform': device.platform,
          'app_version': device.appVersion,
          'last_seen_at': device.lastSeenAt.toUtc().toIso8601String(),
          'is_current': device.id == request.deviceId,
        },
    ],
  });

  ResponseBody _removeDevice(_Request request, String phone, String id) {
    final devices = _devices[phone];
    if (devices == null || !devices.any((device) => device.id == id)) {
      return _error(404, 'NOT_FOUND', 'No such device.', request);
    }
    devices.removeWhere((device) => device.id == id);
    _revokeDevice(phone, id, 'device_removed');
    return _noContent();
  }

  void _revokeDevice(String phone, String? deviceId, String reason) {
    for (final MapEntry(:key, :value) in _credentials.entries) {
      if (key.startsWith('$phone|') && key.endsWith('|$deviceId') && value.status == 'active') {
        value
          ..status = 'revoked'
          ..reason = reason;
      }
    }
  }

  // Plumbing

  ResponseBody _signedIn(_Request request, ResponseBody Function(String phone) respond) {
    final authorization = request.headers[ApiHeaders.authorization];
    final token = authorization is String && authorization.startsWith('Bearer ') ? authorization.substring(7) : null;
    if (token == null || !token.startsWith(_tokenPrefix)) {
      return _error(401, 'UNAUTHENTICATED', 'Unauthenticated.', request);
    }
    return respond(token.substring(_tokenPrefix.length));
  }

  /// Like the API: the selected gym is only context, checked against the
  /// member's own gyms.
  ResponseBody _inGym(_Request request, ResponseBody Function(String phone, String gym) respond) => _signedIn(
    request,
    (phone) {
      final gym = request.headers[ApiHeaders.organizationId];
      final member = [
        for (final organization in _profile(phone)['organizations']! as List<Object?>)
          (organization! as Map<String, Object?>)['id'],
      ];
      if (gym is! String || !member.contains(gym)) {
        return _error(403, 'ORGANIZATION_NOT_ALLOWED', 'Not a member of this organization.', request);
      }
      return respond(phone, gym);
    },
  );

  DateTime get _today {
    final now = _now();
    return DateTime(now.year, now.month, now.day);
  }

  static String _iso(DateTime day) =>
      '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';

  String _ulid() {
    const alphabet = '0123456789ABCDEFGHJKMNPQRSTVWXYZ';
    return '01K7Z9${[for (var i = 0; i < 20; i++) alphabet[_random.nextInt(alphabet.length)]].join()}';
  }

  String _hex(int bytes) => [for (var i = 0; i < bytes; i++) _random.nextInt(256).toRadixString(16).padLeft(2, '0')].join();

  ResponseBody _json(int status, Object? body, {Map<String, List<String>> headers = const {}}) =>
      ResponseBody.fromString(
        jsonEncode(body),
        status,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
          'date': [HttpDate.format(_now().toUtc())],
          ...headers,
        },
      );

  ResponseBody _noContent() => ResponseBody.fromString('', 204, headers: {
    'date': [HttpDate.format(_now().toUtc())],
  });

  ResponseBody _error(
    int status,
    String code,
    String message,
    _Request request, {
    Map<String, List<String>>? errors,
    int? retryAfterSeconds,
  }) => _json(
    status,
    {'message': message, 'code': code, 'errors': ?errors, 'request_id': request.headers[ApiHeaders.requestId]},
    headers: {
      if (retryAfterSeconds != null) 'retry-after': ['$retryAfterSeconds'],
    },
  );

  static const _boleBranch = {'id': '01K7Z6B0LE0000000000000001', 'name': 'Bole', 'photo_url': null};
  static const _megenagnaBranch = {'id': '01K7Z6B0LE0000000000000002', 'name': 'Megenagna', 'photo_url': null};
  static const _kazanchisBranch = {'id': '01K7Z6KAZ00000000000000001', 'name': 'Kazanchis', 'photo_url': null};

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

  @override
  void close({bool force = false}) {}
}

final class _Request {
  _Request(RequestOptions options)
    : headers = options.headers,
      body = switch (options.data) {
        final Map<String, dynamic> map => map,
        _ => const <String, dynamic>{},
      },
      query = {for (final MapEntry(:key, :value) in options.queryParameters.entries) key: '$value'};

  final Map<String, dynamic> headers;
  final Map<String, dynamic> body;
  final Map<String, String> query;

  String? get deviceId => switch (headers[ApiHeaders.deviceId]) {
    final String id => id,
    _ => null,
  };
}

final class _Device {
  _Device({required this.id, required this.name, required this.platform, required this.appVersion, required this.lastSeenAt});

  final String id;
  final String name;
  final String platform;
  final String appVersion;
  final DateTime lastSeenAt;
}

final class _Credential {
  _Credential({required this.id, required this.secret});

  final String id;
  final String secret;
  String status = 'active';
  String? reason;
}
