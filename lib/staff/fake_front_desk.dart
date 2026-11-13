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
/// At the desk, Tigist is turned away and anyone else let in. Today's list
/// holds every check-in made here, newest first, after two from earlier.
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

  /// Every check-in made, oldest first, with its branch id.
  late final _history = <Map<String, Object?>>[
    _checkIn(_branch(1, 'MAIN', 'Main Branch'), member: _abebe, owedMinor: 0, endsOn: '2026-11-01', minutesAgo: 90),
    _checkIn(_branch(1, 'MAIN', 'Main Branch'), deny: 'OUTSIDE_HOURS', member: _hana, owedMinor: 0, endsOn: '2026-11-01', minutesAgo: 60),
  ];

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
      ('GET', '/members') => _json(200, {'data': _search('${options.queryParameters['search'] ?? ''}')}),
      ('POST', final path) when RegExp(r'^/members/\d+/check-ins$').hasMatch(path) => _atDesk(
        options,
        phone,
        gym,
        int.parse(path.split('/')[2]),
      ),
      ('GET', '/check-ins') => _today(options),
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
    if (!payload.startsWith('GQ1:')) return _record(_checkIn(branch, deny: 'CREDENTIAL_INVALID'));
    if (!_scanned.add(payload)) return _record(_checkIn(branch, deny: 'CODE_ALREADY_USED'));
    if (payload.contains('EXPIRED')) {
      return _record(_checkIn(branch, deny: 'MEMBERSHIP_EXPIRED', member: _tigist, owedMinor: 0, endsOn: '2026-10-08'));
    }
    if (payload.contains('OWES')) {
      return _record(_checkIn(branch, member: _abebe, owedMinor: 100000, endsOn: '2026-11-01'));
    }
    return _record(_checkIn(branch, member: _hana, owedMinor: 0, endsOn: '2026-11-01'));
  }

  ResponseBody _record(Map<String, Object?> checkIn) {
    _history.add(checkIn);
    return _json(200, {'data': checkIn});
  }

  /// Members whose name contains, or whose phone has the digits of, [typed].
  List<Map<String, Object?>> _search(String typed) {
    final text = typed.trim().toLowerCase();
    final digits = text.replaceAll(RegExp(r'\D'), '');
    return [
      for (final member in [_abebe, _tigist, _hana])
        if ((member['full_name']! as String).toLowerCase().contains(text) ||
            (digits.length >= 3 && (member['phone']! as String).replaceAll('+251', '0').contains(digits)))
          {
            ...member,
            'membership': {
              'id': 100 + (member['id']! as int),
              'plan': {'id': 2, 'name': 'Monthly'},
              'status': member == _tigist ? 'expired' : 'active',
              'starts_on': '2026-10-02',
              'ends_on': member == _tigist ? '2026-10-08' : '2026-11-01',
            },
            'balance_due': _money(member == _abebe ? 100000 : 0),
          },
    ];
  }

  ResponseBody _atDesk(RequestOptions options, String phone, String gym, int memberId) {
    final body = options.data is Map<String, dynamic> ? options.data as Map<String, dynamic> : const <String, dynamic>{};
    final branch = _branches(phone, gym).where((branch) => branch['id'] == body['branch_id']).firstOrNull;
    final member = [_abebe, _tigist, _hana].where((member) => member['id'] == memberId).firstOrNull;
    if (branch == null || member == null) return _json(404, {'message': 'Not found.'});
    if (member == _tigist) {
      return _record(_checkIn(branch, deny: 'MEMBERSHIP_EXPIRED', member: member, owedMinor: 0, endsOn: '2026-10-08', method: 'desk'));
    }
    return _record(
      _checkIn(branch, member: member, owedMinor: member == _abebe ? 100000 : 0, endsOn: '2026-11-01', method: 'desk'),
    );
  }

  /// Today's check-ins at a branch, newest first, 25 a page.
  ResponseBody _today(RequestOptions options) {
    final branchId = int.tryParse('${options.queryParameters['branch_id'] ?? ''}');
    final all = [
      for (final checkIn in _history.reversed)
        if (branchId == null || (checkIn['branch']! as Map)['id'] == branchId) checkIn,
    ];
    final page = int.tryParse('${options.queryParameters['page'] ?? ''}') ?? 1;
    final from = ((page - 1) * 25).clamp(0, all.length);
    final to = (from + 25).clamp(0, all.length);
    return _json(200, {
      'data': all.sublist(from, to),
      'links': {'next': to < all.length ? '?page=${page + 1}' : null},
      'meta': {'current_page': page},
    });
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
    int minutesAgo = 0,
  }) => {
    'id': 800 + _checkIns++,
    'decision': deny == null ? 'allow' : 'deny',
    'reason_code': deny,
    'method': method,
    'checked_in_at': _now().subtract(Duration(minutes: minutesAgo)).toUtc().toIso8601String(),
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
