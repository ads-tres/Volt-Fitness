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
/// One with `OFFLINE` in it fails as if the desk had no internet, until it
/// is sent again from the desk's queue (with `scanned_at`). A scan sent
/// late is recorded at the time it was scanned, flagged `scanned_offline`,
/// and refused when that was more than a day ago.
/// At the desk, Tigist is turned away and anyone else let in. Today's list
/// holds every check-in made here, newest first, after two from earlier.
///
/// The inbox starts with one unread message of each staff type at each gym;
/// choices start push on, SMS off, and are kept until the app restarts.
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
      ('PUT' || 'DELETE', '/me/push-token') => _signedIn(options, (_) => _empty()),
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
      ('GET', '/dashboard') => _dashboard(options, phone),
      ('GET', '/notifications') => _inbox(phone, gym),
      ('POST', '/notifications/read-all') => _readAll(phone, gym),
      ('POST', final path) when RegExp(r'^/notifications/[^/]+/read$').hasMatch(path) => _read(phone, gym, path.split('/')[2]),
      ('GET', '/notification-preferences') => _json(200, {'data': _choices(phone, gym)}),
      ('PATCH', '/notification-preferences') => _choose(options, phone, gym),
      _ => _json(404, {'message': 'Not found.'}),
    };
  }

  // Numbers

  /// The staff dashboard: check-ins counted from those made here, in the
  /// period and at the branch asked for; money and what is owed only for
  /// the owner, as the API leaves them out for roles that don't see money.
  ResponseBody _dashboard(RequestOptions options, String phone) {
    final query = options.queryParameters;
    final today = DateTime(_now().year, _now().month, _now().day);
    DateTime day(Object? iso, DateTime fallback) => DateTime.tryParse('${iso ?? ''}') ?? fallback;
    final from = day(query['from'], today);
    final to = day(query['to'], today);
    final branchId = int.tryParse('${query['branch_id'] ?? ''}');
    final inPeriod = [
      for (final checkIn in _history)
        if (branchId == null || (checkIn['branch']! as Map)['id'] == branchId)
          if (DateTime.parse(checkIn['checked_in_at']! as String).toLocal() case final at
              when !DateTime(at.year, at.month, at.day).isBefore(from) && !DateTime(at.year, at.month, at.day).isAfter(to))
            (checkIn, at),
    ];
    final denied = <String, int>{};
    final byHour = List<int>.filled(24, 0);
    var allowed = 0;
    for (final (checkIn, at) in inPeriod) {
      if (checkIn['decision'] == 'allow') {
        allowed++;
        byHour[at.hour]++;
      } else {
        denied.update(checkIn['reason_code']! as String, (count) => count + 1, ifAbsent: () => 1);
      }
    }
    final seesMoney = phone == staffPhone;
    String iso(DateTime day) => day.toIso8601String().substring(0, 10);
    return _json(200, {
      'data': {
        'period': {'from': iso(from), 'to': iso(to)},
        'money': seesMoney
            ? {
                'received': _money(450000),
                'refunded': _money(0),
                'net': _money(450000),
                'by_method': {'telebirr': _money(300000), 'cash': _money(150000)},
                'open_payment_links': {'count': 1, 'amount': _money(100000)},
                'refunds_needed': {'count': 1, 'amount': _money(150000)},
              }
            : null,
        'owed': seesMoney ? {'total': _money(100000), 'members': 1} : null,
        'check_ins': {'allowed': allowed, 'denied': denied.values.fold(0, (a, b) => a + b), 'denied_by_reason': denied},
        'members': {
          'active': 3,
          'new': 1,
          'memberships_sold': {'at_the_desk': 2, 'in_the_app': 1},
        },
        'expiring': [
          {
            'membership_id': 101,
            'member': _abebe,
            'plan': {'id': 2, 'name': 'Monthly'},
            'ends_on': iso(today.add(const Duration(days: 3))),
            if (seesMoney) 'balance_due': _money(100000),
          },
          {
            'membership_id': 103,
            'member': _hana,
            'plan': {'id': 4, 'name': '10 Visits'},
            'ends_on': iso(today.add(const Duration(days: 40))),
            'visits_remaining': 1,
            if (seesMoney) 'balance_due': _money(0),
          },
        ],
        'trends': {
          'check_ins_by_hour': [for (var hour = 0; hour < 24; hour++) {'hour': hour, 'allowed': byHour[hour]}],
        },
      },
    });
  }

  // Staff messages

  final _messages = <String, List<Map<String, Object?>>>{};
  final _preferences = <String, Map<String, Map<String, bool>>>{};

  List<Map<String, Object?>> _messagesAt(String phone, String gym) => _messages.putIfAbsent('$phone|$gym', () {
    Map<String, Object?> message(String id, String type, String title, String body, Map<String, Object?> data, int minutesAgo) => {
      'id': id,
      'type': type,
      'title': title,
      'body': body,
      'data': data,
      'read_at': null,
      'created_at': _now().subtract(Duration(minutes: minutesAgo)).toUtc().toIso8601String(),
    };
    return [
      message('9b1d4c6e-0000-4000-8000-000000000001', 'staff_online_payment', 'Online payment',
          'Abebe Kebede paid 1,500.00 ETB for Monthly with Chapa.', {'payment_id': 41, 'membership_id': 101}, 5),
      message('9b1d4c6e-0000-4000-8000-000000000002', 'staff_member_froze', 'Membership frozen in the app',
          'Hana Girma froze Monthly from Oct 16 to Oct 22.', {'membership_id': 103}, 40),
      message('9b1d4c6e-0000-4000-8000-000000000003', 'staff_refund_needed', 'A refund to make',
          'Chapa took 1,500.00 ETB from Tigist Haile that wasn\'t due. Refund it.', {'payment_link_id': 7, 'member_id': 2}, 90),
      message('9b1d4c6e-0000-4000-8000-000000000004', 'staff_members_to_call', 'Members to call today',
          '3 members have a plan ending soon or money owed.', <String, Object?>{}, 120),
    ];
  });

  ResponseBody _inbox(String phone, String gym) {
    final messages = _messagesAt(phone, gym);
    return _json(200, {
      'data': messages,
      'links': {'next': null},
      'meta': {'current_page': 1, 'unread_count': messages.where((message) => message['read_at'] == null).length},
    });
  }

  ResponseBody _read(String phone, String gym, String id) {
    final message = _messagesAt(phone, gym).where((message) => message['id'] == id).firstOrNull;
    if (message == null) return _json(404, {'message': 'Not found.'});
    message['read_at'] ??= _now().toUtc().toIso8601String();
    return _empty();
  }

  ResponseBody _readAll(String phone, String gym) {
    for (final message in _messagesAt(phone, gym)) {
      message['read_at'] ??= _now().toUtc().toIso8601String();
    }
    return _empty();
  }

  static const _topics = ['online_payments', 'refunds', 'app_freezes', 'members_to_call'];

  Map<String, Map<String, bool>> _choices(String phone, String gym) => _preferences.putIfAbsent(
    '$phone|$gym',
    () => {
      for (final topic in _topics) topic: {'push': true, 'sms': false},
    },
  );

  ResponseBody _choose(RequestOptions options, String phone, String gym) {
    final body = options.data is Map<String, dynamic> ? options.data as Map<String, dynamic> : const <String, dynamic>{};
    final choices = _choices(phone, gym);
    for (final MapEntry(key: topic, value: channels) in body.entries) {
      if (!_topics.contains(topic) || channels is! Map || channels.values.any((value) => value is! bool)) {
        return _json(422, {
          'message': 'Choose push or SMS, on or off, for a known topic.',
          'errors': {
            topic: ['Choose push or SMS, on or off, for a known topic.'],
          },
        });
      }
    }
    for (final MapEntry(key: topic, value: channels) in body.entries) {
      for (final MapEntry(key: channel, value: on) in (channels as Map).entries) {
        if (channel == 'push' || channel == 'sms') choices[topic]![channel as String] = on as bool;
      }
    }
    return _json(200, {'data': choices});
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
    if (payload.contains('OFFLINE') && body['scanned_at'] == null) {
      throw DioException.connectionError(requestOptions: options, reason: 'No internet at the desk (demo)');
    }
    final scannedAt = body['scanned_at'] is String ? DateTime.tryParse(body['scanned_at']! as String) : null;
    if (scannedAt != null && _now().difference(scannedAt) > const Duration(hours: 24)) {
      return _json(422, {
        'message': 'A scan can be sent up to 24 hours late.',
        'errors': {
          'scanned_at': ['A scan can be sent up to 24 hours late.'],
        },
      });
    }
    Map<String, Object?> checkIn(String? deny, {Map<String, Object?>? member, int owedMinor = 0, String? endsOn}) =>
        _checkIn(branch, deny: deny, member: member, owedMinor: owedMinor, endsOn: endsOn, scannedAt: scannedAt);
    if (!payload.startsWith('GQ1:')) return _record(checkIn('CREDENTIAL_INVALID'));
    if (!_scanned.add(payload)) return _record(checkIn('CODE_ALREADY_USED'));
    if (payload.contains('EXPIRED')) {
      return _record(checkIn('MEMBERSHIP_EXPIRED', member: _tigist, endsOn: '2026-10-08'));
    }
    if (payload.contains('OWES')) {
      return _record(checkIn(null, member: _abebe, owedMinor: 100000, endsOn: '2026-11-01'));
    }
    return _record(checkIn(null, member: _hana, endsOn: '2026-11-01'));
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
    // Newest first by when they happened: a scan sent late lands at its time.
    final all = [
      for (final checkIn in _history.reversed)
        if (branchId == null || (checkIn['branch']! as Map)['id'] == branchId) checkIn,
    ]..sort((a, b) => (b['checked_in_at']! as String).compareTo(a['checked_in_at']! as String));
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
    DateTime? scannedAt,
  }) => {
    'id': 800 + _checkIns++,
    'decision': deny == null ? 'allow' : 'deny',
    'reason_code': deny,
    'method': method,
    'checked_in_at': (scannedAt ?? _now().subtract(Duration(minutes: minutesAgo))).toUtc().toIso8601String(),
    'scanned_offline': scannedAt != null,
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
