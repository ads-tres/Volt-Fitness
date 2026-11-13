import 'dart:convert';
import 'dart:io' show HttpDate;
import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../core/network/api_headers.dart';

/// Answers the front desk app's calls in dev builds, with the paths and JSON
/// of the gym platform's staff API, as the member app's fake does.
///
/// Sign in with [staffPhone] (Demo Gym, both branches) or [twoGymsPhone]
/// (Demo Gym's Main Branch, and Bole Fitness), password [password].
///
/// Any GQ1 code lets Hana Girma in; one with `EXPIRED` in it is Tigist
/// Haile's ended membership, and one with `OWES` lets Abebe Kebede in with
/// 1,000.00 ETB still to pay. A code scanned twice is `CODE_ALREADY_USED`.
final class FakeFrontDesk implements HttpClientAdapter {
  FakeFrontDesk({this.latency = const Duration(milliseconds: 400), DateTime Function()? now})
    : _now = now ?? DateTime.now;

  static const staffPhone = '+251911000001';
  static const twoGymsPhone = '+251911000002';
  static const password = 'password';

  static const _tokenPrefix = 'fake-desk-token:';

  final Duration latency;
  final DateTime Function() _now;
  final _scanned = <String>{};
  var _checkIns = 0;

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    await Future<void>.delayed(latency);
    final body = switch (options.data) {
      final Map<String, dynamic> map => map,
      _ => const <String, dynamic>{},
    };
    final gymPath = RegExp(r'^/organizations/([^/]+)(/.*)$').firstMatch(options.path);
    return switch ((options.method, options.path)) {
      ('POST', '/auth/tokens') => _signIn(body),
      ('GET', '/me') => _signedIn(options, (phone) => _json(200, {'data': _me(phone)})),
      ('DELETE', '/auth/tokens/current') => _signedIn(options, (_) => _empty()),
      _ when gymPath != null => _signedIn(options, (phone) => _inGym(options, phone, gymPath.group(1)!, gymPath.group(2)!)),
      _ => _json(404, {'message': 'Not found.'}),
    };
  }

  ResponseBody _signIn(Map<String, dynamic> body) {
    final phone = body['phone'];
    if ((phone != staffPhone && phone != twoGymsPhone) || body['password'] != password) {
      return _json(422, {
        'message': 'These credentials do not match our records.',
        'errors': {
          'phone': ['These credentials do not match our records.'],
        },
      });
    }
    return _json(201, {
      'data': {'token': '$_tokenPrefix$phone', 'user': _user(phone! as String)},
    });
  }

  Map<String, Object?> _user(String phone) => {
    'id': phone == staffPhone ? 1 : 2,
    'name': phone == staffPhone ? 'Demo Owner' : 'Demo Receptionist',
    'email': null,
    'phone': phone,
  };

  Map<String, Object?> _me(String phone) => {
    'user': _user(phone),
    'staff': [
      {
        'organization': {'slug': 'demo-gym', 'name': 'Demo Gym'},
        'role': phone == staffPhone ? 'owner' : 'receptionist',
        'works_at_all_branches': phone == staffPhone,
      },
      if (phone == twoGymsPhone)
        {
          'organization': {'slug': 'bole-fitness', 'name': 'Bole Fitness'},
          'role': 'receptionist',
          'works_at_all_branches': true,
        },
    ],
  };

  ResponseBody _inGym(RequestOptions options, String phone, String gym, String path) {
    final gyms = [for (final staff in _me(phone)['staff']! as List<Object?>) ((staff! as Map)['organization']! as Map)['slug']];
    if (!gyms.contains(gym)) return _json(404, {'message': 'Not found.'});
    return switch ((options.method, path)) {
      ('GET', '/branches') => _json(200, {'data': _branches(phone, gym)}),
      ('POST', '/check-ins/scan') => _scan(options, phone, gym),
      _ => _json(404, {'message': 'Not found.'}),
    };
  }

  List<Map<String, Object?>> _branches(String phone, String gym) => switch (gym) {
    'bole-fitness' => [_branch(3, 'BOLE', 'Bole Fitness')],
    _ when phone == twoGymsPhone => [_branch(1, 'MAIN', 'Main Branch')],
    _ => [_branch(2, 'BOLE', 'Bole Branch'), _branch(1, 'MAIN', 'Main Branch')],
  };

  ResponseBody _scan(RequestOptions options, String phone, String gym) {
    final body = options.data is Map<String, dynamic> ? options.data as Map<String, dynamic> : const <String, dynamic>{};
    final payload = '${body['payload'] ?? ''}';
    final branch = _branches(phone, gym).where((branch) => branch['id'] == body['branch_id']).firstOrNull;
    if (branch == null) {
      return _json(422, {
        'message': 'Choose a branch of this gym that you work at.',
        'errors': {
          'branch_id': ['Choose a branch of this gym that you work at.'],
        },
      });
    }
    if (!payload.startsWith('GQ1:')) return _json(200, {'data': _checkIn(branch, deny: 'CREDENTIAL_INVALID')});
    if (!_scanned.add(payload)) return _json(200, {'data': _checkIn(branch, deny: 'CODE_ALREADY_USED')});
    if (payload.contains('EXPIRED')) {
      return _json(200, {'data': _checkIn(branch, deny: 'MEMBERSHIP_EXPIRED', member: _tigist, owedMinor: 0, endsOn: '2026-10-08')});
    }
    if (payload.contains('OWES')) {
      return _json(200, {'data': _checkIn(branch, member: _abebe, owedMinor: 100000, endsOn: '2026-11-01')});
    }
    return _json(200, {'data': _checkIn(branch, member: _hana, owedMinor: 0, endsOn: '2026-11-01')});
  }

  static const _hana = {'id': 3, 'full_name': 'Hana Girma', 'phone': '+251933456789'};
  static const _tigist = {'id': 2, 'full_name': 'Tigist Haile', 'phone': '+251922345678'};
  static const _abebe = {'id': 1, 'full_name': 'Abebe Kebede', 'phone': '+251911234567'};

  Map<String, Object?> _checkIn(
    Map<String, Object?> branch, {
    String? deny,
    Map<String, Object?>? member,
    int? owedMinor,
    String? endsOn,
    String method = 'qr',
  }) => {
    'id': 800 + _checkIns++,
    'decision': deny == null ? 'allow' : 'deny',
    'reason_code': deny,
    'method': method,
    'checked_in_at': _now().toUtc().toIso8601String(),
    'branch': branch,
    'member': member,
    'membership': member == null
        ? null
        : {
            'id': 100 + (member['id']! as int),
            'plan': {'id': 2, 'name': 'Monthly'},
            'starts_on': '2026-10-02',
            'ends_on': endsOn,
            'balance_due': _money(owedMinor ?? 0),
          },
    'checked_in_by': {'id': 1, 'name': 'Demo Owner'},
  };

  static Map<String, Object?> _money(int minor) {
    final whole = '${minor ~/ 100}'.replaceAllMapped(RegExp(r'\B(?=(\d{3})+$)'), (_) => ',');
    return {'amount_minor': minor, 'currency': 'ETB', 'formatted': '$whole.${(minor % 100).toString().padLeft(2, '0')} ETB'};
  }

  static Map<String, Object?> _branch(int id, String code, String name) => {
    'id': id,
    'code': code,
    'name': name,
    'address': null,
  };

  ResponseBody _signedIn(RequestOptions options, ResponseBody Function(String phone) respond) {
    final authorization = options.headers[ApiHeaders.authorization];
    final token = authorization is String && authorization.startsWith('Bearer ') ? authorization.substring(7) : null;
    if (token == null || !token.startsWith(_tokenPrefix)) return _json(401, {'message': 'Unauthenticated.'});
    return respond(token.substring(_tokenPrefix.length));
  }

  ResponseBody _json(int status, Object? body) => ResponseBody.fromString(
    jsonEncode(body),
    status,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
      'date': [HttpDate.format(_now().toUtc())],
    },
  );

  ResponseBody _empty() => ResponseBody.fromString('', 204, headers: {
    'date': [HttpDate.format(_now().toUtc())],
  });

  @override
  void close({bool force = false}) {}
}
