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
/// is refused like a wrong code, as the API does; five wrong codes give 429.
/// Gyms are known by their slug, in the path (`/me/gyms/{slug}/…`).
/// [twoGymsPhone] belongs to two gyms, [noGymPhone] to none, any other
/// number to one. The membership depends on the number too: see
/// [endingSoonPhone], [expiredPhone], [frozenPhone] and [noPlanPhone]; any
/// other number has a monthly plan with 18 days left. Payments made through
/// the fake checkout succeed, except for [paymentFailsPhone]. Each number
/// starts with a few notifications that fit its membership, and
/// `POST /dev/fake-push` makes a new one for the in-app fake push.
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
  static const paymentFailsPhone = '+251966666666';

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

  /// `phone|gym` to what was bought there in this session.
  final _heldPlans = <String, _HeldPlan>{};

  /// `phone|gym` to what is owed on the membership there, in minor units.
  /// [endingSoonPhone] owes for its renewal until it pays.
  final _owed = <String, int>{'$endingSoonPhone|bole-iron-gym': 150000};

  /// `phone|gym` to the receipts there, newest first.
  final _receipts = <String, List<Map<String, Object?>>>{};

  /// Payment links by id.
  final _links = <int, _Link>{};

  /// `phone|gym` to the member's notifications there, newest first.
  final _notifications = <String, List<Map<String, Object?>>>{};
  final _notificationPreferences = <String, Map<String, bool>>{};
  var _testPushes = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    await Future<void>.delayed(latency);
    final request = _Request(options);
    return switch ((options.method, request.path)) {
      ('GET', '/app-config') => _json(200, {
        'data': {
          'min_supported_build': 1,
          'latest_build': 1,
          'update_url': 'https://play.google.com/store/apps/details?id=com.volt.member',
          'maintenance': {'active': false, 'message': null},
        },
      }),
      ('POST', '/auth/sms-codes') => _requestCode(request),
      ('POST', '/auth/sms-tokens') => _verifyCode(request),
      ('GET', '/me') => _signedIn(request, (phone) => _json(200, {
        'data': {'user': _user(phone), 'staff': <Object?>[]},
      })),
      ('GET', '/me/gyms') => _signedIn(request, (phone) => _json(200, {'data': _gyms(phone)})),
      ('DELETE', '/auth/tokens/current') => _signedIn(request, (phone) {
        _revokeDevice(phone, request.deviceId, 'signed_out');
        return _noContent();
      }),
      ('GET', '/dashboard') => _inGym(request, _dashboard),
      ('GET', '/check-ins') => _inGym(request, (phone, gym) => _attendance(request, phone, gym)),
      ('POST', '/access-credential') => _inGym(request, (phone, gym) => _issueCredential(request, phone, gym)),
      ('GET', '/access-credential') => _inGym(request, (phone, gym) => _currentCredential(request, phone, gym)),
      ('GET', '/devices') => _signedIn(request, (phone) => _listDevices(request, phone)),
      ('GET', '/plans') => _inGym(request, (phone, gym) => _json(200, {'data': _plans(phone, gym)})),
      ('POST', final path) when _purchase.hasMatch(path) => _inGym(
        request,
        (phone, gym) => _buyPlan(request, phone, gym, _purchase.firstMatch(path)!.group(1)!),
      ),
      ('POST', final path) when _payMembership.hasMatch(path) => _inGym(
        request,
        (phone, gym) => _payWhatIsOwed(request, phone, gym, _payMembership.firstMatch(path)!.group(1)!),
      ),
      ('GET', final path) when _paymentLink.hasMatch(path) => _inGym(
        request,
        (phone, gym) => _linkAsItStands(request, phone, gym, _paymentLink.firstMatch(path)!.group(1)!),
      ),
      ('POST', final path) when _checkLink.hasMatch(path) => _inGym(
        request,
        (phone, gym) => _checkWithChapa(request, phone, gym, _checkLink.firstMatch(path)!.group(1)!),
      ),
      ('GET', '/payments') => _inGym(request, (phone, gym) => _json(200, {
        'data': _receiptsFor(phone, gym),
        'links': {'next': null, 'prev': null},
        'meta': {'current_page': 1, 'last_page': 1, 'per_page': 25, 'total': _receiptsFor(phone, gym).length},
      })),
      ('GET', final path) when _receipt.hasMatch(path) => _inGym(request, (phone, gym) {
        final id = int.parse(_receipt.firstMatch(path)!.group(1)!);
        final receipt = _receiptsFor(phone, gym).where((receipt) => receipt['id'] == id).firstOrNull;
        return receipt == null ? _error(404, 'NOT_FOUND', 'Not found.', request) : _json(200, {'data': receipt});
      }),
      ('POST', final path) when path.startsWith('/dev/fake-chapa/') => _signedIn(
        request,
        (phone) => _fakeCheckout(request, phone, path.substring('/dev/fake-chapa/'.length)),
      ),
      ('GET', '/notifications') => _inGym(request, (phone, gym) => _listNotifications(request, phone, gym)),
      ('POST', '/notifications/read-all') => _inGym(request, (phone, gym) {
        for (final notification in _notificationsFor(phone, gym)) {
          notification['read_at'] ??= _now().toUtc().toIso8601String();
        }
        return _noContent();
      }),
      ('POST', final path) when path.startsWith('/notifications/') && path.endsWith('/read') => _inGym(
        request,
        (phone, gym) => _markRead(request, phone, gym, path.split('/')[2]),
      ),
      ('GET', '/notification-preferences') => _inGym(
        request,
        (phone, gym) => _json(200, {'data': _preferencesFor(phone, gym)}),
      ),
      ('PATCH', '/notification-preferences') => _inGym(
        request,
        (phone, gym) => _updatePreferences(request, phone, gym),
      ),
      ('PUT', '/me/push-token') => _signedIn(request, (phone) => _savePushToken(request, phone)),
      ('POST', '/dev/fake-push') => _inGym(request, _fakePush),
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
    return _json(202, {'message': 'If this number is registered at a gym, a code is on its way by SMS.'});
  }

  ResponseBody _verifyCode(_Request request) {
    final phone = request.body['phone'];
    final code = request.body['code'];
    if (phone is! String || code is! String) {
      return _error(422, 'VALIDATION_FAILED', 'The phone and code fields are required.', request);
    }
    final wrongCodes = _wrongCodes[phone] ?? 0;
    if (wrongCodes >= _maxWrongCodes) {
      return _error(429, 'TOO_MANY_ATTEMPTS', 'Too Many Attempts.', request, retryAfterSeconds: 60);
    }
    if (code != validCode) {
      _wrongCodes[phone] = wrongCodes + 1;
      return _error(422, 'VALIDATION_FAILED', 'The code is wrong or has expired.', request, errors: {
        'code': ['The code is wrong or has expired.'],
      });
    }
    _wrongCodes.remove(phone);
    _registerDevice(phone, {'device_id': request.deviceId, 'device_name': request.body['device_name']});
    return _json(201, {
      'data': {'token': '$_tokenPrefix$phone', 'user': _user(phone)},
    });
  }

  Map<String, Object?> _user(String phone) => {'id': 7, 'name': 'Abebe Kebede', 'email': null, 'phone': phone};

  /// What `GET /me/gyms` lists: every gym where the number is a member.
  List<Map<String, Object?>> _gyms(String phone) => [
    for (final gym in _memberGyms(phone))
      {
        'slug': gym['id'],
        'name': gym['name'],
        'member': {'id': 7, 'full_name': 'Abebe Kebede', 'home_branch': null},
        'membership': null,
        'balance_due': _money(0),
      },
  ];

  List<Map<String, Object?>> _memberGyms(String phone) => [
    if (phone != noGymPhone) _boleIronGym,
    if (phone == twoGymsPhone) _kazanchisFitClub,
  ];

  // Membership and visits

  ResponseBody _dashboard(String phone, String gym) => _json(200, {
    'data': {
      'membership': switch (_membership(phone, gym)) {
        final membership? => {
          ...membership,
          'frozen_until': switch (_held(phone, gym)?.frozenToday) {
            final freeze? => _iso(_today.add(Duration(days: freeze.end))),
            null => null,
          },
        },
        null => null,
      },
      'next_membership': null,
      'recent_check_ins': _visits(phone, gym).take(5).toList(),
      'balance_due': _money(_owed[_key(phone, gym)] ?? 0),
      'open_payment_link': null,
      'unread_notifications': 0,
    },
  });

  /// The check-ins, newest first, 25 a page like Laravel's paginator.
  ResponseBody _attendance(_Request request, String phone, String gym) {
    const perPage = 25;
    final all = _visits(phone, gym);
    final page = max(1, int.tryParse(request.query['page'] ?? '') ?? 1);
    final from = min((page - 1) * perPage, all.length);
    final to = min(from + perPage, all.length);
    final lastPage = max(1, (all.length / perPage).ceil());
    return _json(200, {
      'data': all.sublist(from, to),
      'links': {'next': page < lastPage ? '?page=${page + 1}' : null, 'prev': page > 1 ? '?page=${page - 1}' : null},
      'meta': {'current_page': page, 'last_page': lastPage, 'per_page': perPage, 'total': all.length},
    });
  }

  /// The membership as the API sends it, with what is still owed on it.
  Map<String, Object?>? _membership(String phone, String gym) {
    final held = _held(phone, gym);
    if (held == null) return null;
    String day(int offset) => _iso(_today.add(Duration(days: offset)));
    final owed = _owed[_key(phone, gym)] ?? 0;
    final price = _plans(phone, gym).firstWhere((plan) => plan['name'] == held.name)['price']! as Map<String, Object?>;
    final priceMinor = price['amount_minor']! as int;
    return {
      'id': _membershipId(gym),
      'plan': {'id': _planId(held.name), 'name': held.name},
      'status': held.status == 'active' && held.frozenToday != null ? 'frozen' : held.status,
      'starts_on': day(held.start),
      'ends_on': day(held.end),
      'price': price,
      'amount_paid': _money(max(0, priceMinor - owed)),
      'balance_due': _money(owed),
      'valid_at_all_branches': false,
      'branches': _branchesOf(gym),
      'visits_remaining': null,
      'freeze_days_allowed': held.freezeDaysAllowed,
      'freeze_days_used': held.freezeDaysUsed,
      'freeze_days_left': max(0, held.freezeDaysAllowed - held.freezeDaysUsed),
      'freezes': [
        for (final freeze in held.freezes)
          {'id': freeze.id, 'starts_on': day(freeze.start), 'ends_on': day(freeze.end), 'days': freeze.days},
      ],
      'sold_in_app': false,
      'cancelled_at': null,
      'open_payment_link': null,
    };
  }

  static int _membershipId(String gym) => gym == _kazanchisFitClub['id'] ? 202 : 101;

  List<Map<String, Object?>> _branchesOf(String gym) =>
      gym == _kazanchisFitClub['id'] ? [_kazanchisBranch] : [_boleBranch, _megenagnaBranch];

  static String _key(String phone, String gym) => '$phone|$gym';

  /// The member's plan at [gym], in days from today: what they bought here
  /// in this session, or what their number starts with.
  _HeldPlan? _held(String phone, String gym) {
    if (_heldPlans['$phone|$gym'] case final bought?) return bought;
    if (gym == _kazanchisFitClub['id']) return const _HeldPlan('Quarterly', -26, 64);
    return switch (phone) {
      endingSoonPhone => const _HeldPlan('Monthly', -27, 3),
      expiredPhone => const _HeldPlan('Monthly', -36, -6, status: 'expired'),
      frozenPhone => const _HeldPlan('Monthly', -10, 30, freezeDaysAllowed: 10, freezes: [_Freeze(31, 0, 7)]),
      noPlanPhone => null,
      _ => const _HeldPlan('Monthly', -12, 18),
    };
  }

  /// A few weeks of morning visits, newest first, with one late-night scan
  /// the gym turned away.
  List<Map<String, Object?>> _visits(String phone, String gym) {
    if (phone == noPlanPhone) return const [];
    final branches = _branchesOf(gym);
    final today = _today;
    final visits = <Map<String, Object?>>[];
    for (var i = 0, daysAgo = 0; i < 26; i++, daysAgo += (i % 3 == 0) ? 2 : 1) {
      if (phone == frozenPhone && daysAgo < 3) continue;
      final lateNight = i == 3;
      final at = DateTime(today.year, today.month, today.day - daysAgo, lateNight ? 22 : 6, lateNight ? 40 : (5 + i * 7) % 60);
      final expired = phone == expiredPhone && daysAgo < 6;
      visits.add({
        'id': 900 + i,
        'decision': lateNight || expired ? 'deny' : 'allow',
        'reason_code': expired ? 'MEMBERSHIP_EXPIRED' : (lateNight ? 'OUTSIDE_HOURS' : null),
        'method': 'qr',
        'checked_in_at': at.toUtc().toIso8601String(),
        'branch': branches[i % branches.length],
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
        'algorithm': 'GQ1',
        'status': 'active',
        'revoked_reason': null,
        'issued_at': _now().toUtc().toIso8601String(),
        // Base64 of the 32 bytes, as the API sends it.
        'secret': base64.encode([
          for (var i = 0; i < credential.secret.length; i += 2) int.parse(credential.secret.substring(i, i + 2), radix: 16),
        ]),
      },
    });
  }

  ResponseBody _currentCredential(_Request request, String phone, String gym) {
    final credential = _credentials['$phone|$gym|${request.deviceId}'];
    if (credential == null) return _error(404, 'NOT_FOUND', 'Not found.', request);
    return _json(200, {
      'data': {
        'credential_id': credential.id,
        'algorithm': 'GQ1',
        'status': credential.status,
        'revoked_reason': credential.reason,
        'issued_at': _now().toUtc().toIso8601String(),
      },
    });
  }

  // Billing and Chapa

  static final _purchase = RegExp(r'^/plans/(\d+)/purchase$');
  static final _payMembership = RegExp(r'^/memberships/(\d+)/payment-link$');
  static final _paymentLink = RegExp(r'^/payment-links/(\d+)$');
  static final _checkLink = RegExp(r'^/payment-links/(\d+)/check$');
  static final _receipt = RegExp(r'^/payments/(\d+)$');

  /// The plans on sale, cheapest first, with the dates each would run if
  /// bought now: from the day after the member's plan ends, or today.
  List<Map<String, Object?>> _plans(String phone, String gym) {
    final held = _held(phone, gym);
    final startsIn = held != null && held.status != 'expired' && held.end >= 0 ? held.end + 1 : 0;
    Map<String, Object?> plan(String name, int days, int priceMinor) => {
      'id': _planId(name),
      'name': name,
      'description': null,
      'price': _money(priceMinor),
      'duration': {'count': days, 'unit': 'day'},
      'freeze_days_allowed': 7,
      'valid_at_all_branches': true,
      'starts_on': _iso(_today.add(Duration(days: startsIn))),
      'ends_on': _iso(_today.add(Duration(days: startsIn + days - 1))),
    };
    return gym == _kazanchisFitClub['id']
        ? [plan('Monthly', 30, 180000), plan('Quarterly', 90, 500000)]
        : [plan('Monthly', 30, 150000), plan('Quarterly', 90, 400000), plan('Annual', 365, 1400000)];
  }

  /// Money as the API sends it.
  static Map<String, Object?> _money(int amountMinor) => {
    'amount_minor': amountMinor,
    'currency': 'ETB',
    'formatted': _birr(amountMinor),
  };

  /// Like the receipts: "4,000.00 ETB".
  static String _birr(int amountMinor) {
    final whole = '${amountMinor ~/ 100}'.replaceAllMapped(RegExp(r'\B(?=(\d{3})+$)'), (_) => ',');
    return '$whole.${(amountMinor % 100).toString().padLeft(2, '0')} ETB';
  }

  static int _planId(String name) => switch (name) {
    'Monthly' => 11,
    'Quarterly' => 12,
    _ => 13,
  };

  /// Receipts, newest first: every member but [noPlanPhone] paid for their
  /// plan when it started.
  List<Map<String, Object?>> _receiptsFor(String phone, String gym) => _receipts.putIfAbsent(_key(phone, gym), () {
    if (phone == noPlanPhone) return [];
    final paidDaysAgo = phone == expiredPhone ? 36 : 12;
    return [_receiptFor(gym, 'R-2026-0142', 'Monthly', 150000, _today.subtract(Duration(days: paidDaysAgo)))];
  });

  var _receiptCount = 0;

  Map<String, Object?> _receiptFor(String gym, String number, String planName, int amountMinor, DateTime paidOn) => {
    'id': 500 + _receiptCount++,
    'receipt_number': number,
    'type': 'payment',
    'amount': _money(amountMinor),
    'method': 'chapa',
    'reference': 'CH${_ulid().substring(16)}',
    'paid_on': _iso(paidOn),
    'branch': _branchesOf(gym).first,
    'membership': {
      'id': _membershipId(gym),
      'plan': {'id': _planId(planName), 'name': planName},
    },
    'voided': false,
  };

  bool _isOpen(_Link link, String phone, String gym) =>
      link.phone == phone && link.gym == gym && link.state != 'cancelled' && !link.settled;

  /// One purchase at a time: choosing another plan cancels the unpaid one.
  ResponseBody _buyPlan(_Request request, String phone, String gym, String planId) {
    final plan = _plans(phone, gym).where((plan) => '${plan['id']}' == planId).firstOrNull;
    if (plan == null) return _error(404, 'NOT_FOUND', 'Not found.', request);
    for (final link in _links.values.where((link) => _isOpen(link, phone, gym) && link.plan != null).toList()) {
      if (link.plan!['id'] == plan['id']) return _json(200, {'data': link.toJson()});
      link.state = 'cancelled';
    }
    final price = plan['price']! as Map<String, Object?>;
    final link = _Link(
      id: 700 + _links.length,
      phone: phone,
      gym: gym,
      amountMinor: price['amount_minor']! as int,
      plan: plan,
      createdAt: _now(),
    );
    _links[link.id] = link;
    return _json(201, {'data': link.toJson()});
  }

  /// The open link for what is owed on the membership, made if there is none.
  ResponseBody _payWhatIsOwed(_Request request, String phone, String gym, String membershipId) {
    if ('${_membershipId(gym)}' != membershipId || _held(phone, gym) == null) {
      return _error(404, 'NOT_FOUND', 'Not found.', request);
    }
    final owed = _owed[_key(phone, gym)] ?? 0;
    if (owed <= 0) {
      return _error(422, 'VALIDATION_FAILED', 'Nothing is due on this membership.', request, errors: {
        'membership': ['Nothing is due on this membership.'],
      });
    }
    final open = _links.values.where((link) => _isOpen(link, phone, gym) && link.plan == null).firstOrNull;
    if (open != null) return _json(200, {'data': open.toJson()});
    final link = _Link(
      id: 700 + _links.length,
      phone: phone,
      gym: gym,
      amountMinor: owed,
      membershipId: _membershipId(gym),
      createdAt: _now(),
    );
    _links[link.id] = link;
    return _json(201, {'data': link.toJson()});
  }

  ResponseBody _linkAsItStands(_Request request, String phone, String gym, String id) {
    final link = _links[int.parse(id)];
    if (link == null || link.phone != phone || link.gym != gym) return _error(404, 'NOT_FOUND', 'Not found.', request);
    return _json(200, {'data': link.toJson()});
  }

  /// Like asking Chapa: a payment made on the fake checkout is still being
  /// confirmed on the first check, and settles on the next. A declined
  /// payment stays pending, as Chapa never reports it as paid.
  ResponseBody _checkWithChapa(_Request request, String phone, String gym, String id) {
    final link = _links[int.parse(id)];
    if (link == null || link.phone != phone || link.gym != gym) return _error(404, 'NOT_FOUND', 'Not found.', request);
    if (link.state == 'paid_on_chapa') {
      link.state = 'confirming';
    } else if (link.state == 'confirming') {
      _settle(link);
      _notify(
        phone,
        gym,
        'payment_succeeded',
        'Payment received',
        '${_birr(link.amountMinor)} received. Thank you!',
        data: {'payment_id': '${link.payment!['id']}', 'membership_id': '${_membershipId(gym)}'},
      );
    }
    return _json(200, {'data': link.toJson()});
  }

  /// Stands in for the member paying on Chapa's page. Only the in-app fake
  /// checkout calls it. [paymentFailsPhone]'s payments are declined.
  ResponseBody _fakeCheckout(_Request request, String phone, String path) {
    final parts = path.split('/');
    final link = _links[int.tryParse(parts.first) ?? -1];
    if (link == null || link.phone != phone) return _error(404, 'NOT_FOUND', 'Not found.', request);
    if (parts.last == 'pay' && link.state == 'pending' && phone != paymentFailsPhone) link.state = 'paid_on_chapa';
    return _noContent();
  }

  /// What the API does once Chapa confirms the payment: record the receipt,
  /// and either settle what was owed or start the plan bought.
  void _settle(_Link link) {
    final receipts = _receiptsFor(link.phone, link.gym);
    final held = _held(link.phone, link.gym);
    final planName = (link.plan?['name'] as String?) ?? held?.name ?? 'Monthly';
    final receipt = _receiptFor(link.gym, 'R-${_now().year}-${2000 + receipts.length}', planName, link.amountMinor, _now());
    receipts.insert(0, receipt);
    link
      ..state = 'paid'
      ..settled = true
      ..settledAt = _now()
      ..payment = {'id': receipt['id'], 'receipt_number': receipt['receipt_number'], 'paid_on': receipt['paid_on']};
    if (link.plan case final plan?) {
      final days = (plan['duration']! as Map<String, Object?>)['count']! as int;
      final continues = held != null && held.status != 'expired' && held.end >= 0;
      _heldPlans[_key(link.phone, link.gym)] =
          _HeldPlan(planName, continues ? held.start : 0, (continues ? held.end : -1) + days, freezes: continues ? held.freezes : const []);
      link.membershipId = _membershipId(link.gym);
    } else {
      _owed[_key(link.phone, link.gym)] = 0;
    }
  }

  // Notifications

  List<Map<String, Object?>> _notificationsFor(String phone, String gym) =>
      _notifications.putIfAbsent('$phone|$gym', () {
        DateTime at(int daysAgo, int hour, int minute) =>
            DateTime(_today.year, _today.month, _today.day - daysAgo, hour, minute);
        final kazanchis = gym == _kazanchisFitClub['id'];
        final notifications = [
          if (kazanchis)
            _notification(
              'announcement',
              'Spin classes start Monday',
              'Spin classes run at 6:30 and 18:00 on weekdays. Book a bike at the front desk.',
              at(2, 10, 0),
            )
          else
            _notification(
              'announcement',
              'Holiday hours on Saturday',
              'For Meskel, both branches open from 8:00 to 14:00. Happy holiday!',
              at(1, 18, 30),
            ),
          if (phone == endingSoonPhone) ...[
            _notification(
              'membership_expiring',
              'Your plan ends in 3 days',
              'Renew your Monthly plan to keep checking in.',
              at(0, 8, 0),
            ),
            _notification(
              'payment_due',
              'Payment due',
              '1,500.00 ETB is due on your Monthly plan.',
              at(1, 9, 15),
            ),
          ],
          if (phone == expiredPhone)
            _notification(
              'membership_expired',
              'Your plan has ended',
              'Renew to check in again. Your visit history stays.',
              at(6, 0, 5),
            ),
          if (phone == frozenPhone)
            _notification(
              'membership_frozen',
              'Your plan is on hold',
              "Your days are kept until it resumes. We'll see you soon.",
              at(3, 11, 0),
              read: true,
            ),
          if (phone != noPlanPhone && !kazanchis) ...[
            _notification(
              'visit_denied',
              'Check-in turned away',
              "Megenagna, 22:40: outside your plan's hours.",
              at(4, 22, 41),
              read: true,
            ),
            _notification(
              'payment_succeeded',
              'Payment received',
              '1,500.00 ETB for your Monthly plan. Thank you!',
              at(phone == expiredPhone ? 36 : 12, 7, 11),
              read: true,
              data: {'payment_id': '${_receiptsFor(phone, gym).last['id']}'},
            ),
          ],
        ];
        return notifications..sort((a, b) => (b['created_at']! as String).compareTo(a['created_at']! as String));
      });

  Map<String, Object?> _notification(
    String type,
    String title,
    String body,
    DateTime at, {
    Map<String, String> data = const {},
    bool read = false,
  }) => {
    'id': _ulid(),
    'type': type,
    'title': title,
    'body': body,
    'data': data,
    'created_at': at.toUtc().toIso8601String(),
    'read_at': read ? at.add(const Duration(hours: 1)).toUtc().toIso8601String() : null,
  };

  Map<String, Object?> _notify(
    String phone,
    String gym,
    String type,
    String title,
    String body, {
    Map<String, String> data = const {},
  }) {
    final notification = _notification(type, title, body, _now(), data: data);
    _notificationsFor(phone, gym).insert(0, notification);
    return notification;
  }

  /// The inbox, newest first, 25 a page, with the unread count across all.
  ResponseBody _listNotifications(_Request request, String phone, String gym) {
    const perPage = 25;
    final all = _notificationsFor(phone, gym);
    final page = max(1, int.tryParse(request.query['page'] ?? '') ?? 1);
    final from = min((page - 1) * perPage, all.length);
    final to = min(from + perPage, all.length);
    final lastPage = max(1, (all.length / perPage).ceil());
    return _json(200, {
      'data': all.sublist(from, to),
      'links': {'next': page < lastPage ? '?page=${page + 1}' : null, 'prev': page > 1 ? '?page=${page - 1}' : null},
      'meta': {
        'current_page': page,
        'last_page': lastPage,
        'per_page': perPage,
        'unread_count': all.where((notification) => notification['read_at'] == null).length,
      },
    });
  }

  ResponseBody _markRead(_Request request, String phone, String gym, String id) {
    final notification = _notificationsFor(phone, gym).where((notification) => notification['id'] == id).firstOrNull;
    if (notification == null) return _error(404, 'NOT_FOUND', 'No such notification.', request);
    notification['read_at'] ??= _now().toUtc().toIso8601String();
    return _noContent();
  }

  Map<String, bool> _preferencesFor(String phone, String gym) => _notificationPreferences.putIfAbsent(
    '$phone|$gym',
    () => {'membership': true, 'payments': true, 'visits': true, 'announcements': true},
  );

  ResponseBody _updatePreferences(_Request request, String phone, String gym) {
    final preferences = _preferencesFor(phone, gym);
    final changes = request.body;
    final valid =
        changes.isNotEmpty &&
        changes.entries.every((change) => preferences.containsKey(change.key) && change.value is bool);
    if (!valid) return _error(422, 'VALIDATION_FAILED', 'Send true or false for known topics.', request);
    for (final MapEntry(:key, :value) in changes.entries) {
      preferences[key] = value as bool;
    }
    return _json(200, {'data': preferences});
  }

  ResponseBody _savePushToken(_Request request, String phone) {
    final token = request.body['token'];
    if (token is! String || token.isEmpty) {
      return _error(422, 'VALIDATION_FAILED', 'The token field is required.', request);
    }
    final device = _devices[phone]?.where((device) => device.id == request.deviceId).firstOrNull;
    device
      ?..pushToken = token
      ..pushLocale = '${request.body['locale'] ?? 'en'}';
    return _noContent();
  }

  /// Makes a notification, as the API would before pushing it, and returns
  /// the FCM message for the in-app fake push. Cycles through gym news, a
  /// plan reminder and a receipt, to try each kind of tap.
  ResponseBody _fakePush(String phone, String gym) {
    final invoiceId = switch (_receiptsFor(phone, gym).firstOrNull?['id']) {
      final Object id => '$id',
      null => null,
    };
    final notification = switch (_testPushes++ % 3) {
      0 => _notify(
        phone,
        gym,
        'announcement',
        'Test: news from your gym',
        'This came from the fake backend. News opens in full in the inbox.',
      ),
      1 => _notify(phone, gym, 'membership_expiring', 'Test: your plan', 'Tap to open your membership.'),
      _ => _notify(
        phone,
        gym,
        'payment_succeeded',
        'Test: a receipt',
        'Tap to open your latest receipt.',
        data: {'payment_id': ?invoiceId},
      ),
    };
    return _json(200, {
      'data': {
        'title': notification['title'],
        'body': notification['body'],
        'data': {
          'type': notification['type'],
          'notification_id': notification['id'],
          'organization_id': gym,
          'gym': gym,
          ...notification['data']! as Map<String, String>,
        },
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

  /// Like the API: the gym in the path must be one of the member's, and any
  /// other answers 404.
  ResponseBody _inGym(_Request request, ResponseBody Function(String phone, String gym) respond) => _signedIn(
    request,
    (phone) {
      final gym = request.gym;
      final member = [for (final organization in _memberGyms(phone)) organization['id']];
      if (gym is! String || !member.contains(gym)) {
        return _error(404, 'NOT_FOUND', 'Not found.', request);
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

  static const _boleBranch = {'id': 1, 'code': 'BOLE', 'name': 'Bole', 'address': null};
  static const _megenagnaBranch = {'id': 2, 'code': 'MEG', 'name': 'Megenagna', 'address': null};
  static const _kazanchisBranch = {'id': 3, 'code': 'KAZ', 'name': 'Kazanchis', 'address': null};

  static const _boleIronGym = {
    'id': 'bole-iron-gym',
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
    'id': 'kazanchis-fit-club',
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
      gym = _gymPath.firstMatch(options.path)?.group(1),
      path = switch (_gymPath.firstMatch(options.path)) {
        final match? => match.group(2) ?? '/',
        null => options.path,
      },
      body = switch (options.data) {
        final Map<String, dynamic> map => map,
        _ => const <String, dynamic>{},
      },
      query = {for (final MapEntry(:key, :value) in options.queryParameters.entries) key: '$value'};

  /// `/me/gyms/{slug}/…`: the gym's slug, and the rest of the path.
  static final _gymPath = RegExp(r'^/me/gyms/([^/]+)(/.*)?$');

  final Map<String, dynamic> headers;
  final Map<String, dynamic> body;
  final Map<String, String> query;

  /// The gym's slug from the path, or null outside `/me/gyms/{slug}/…`.
  final String? gym;

  /// The path within the gym for gym paths, otherwise the whole path.
  final String path;

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
  String? pushToken;
  String? pushLocale;
}

final class _Credential {
  _Credential({required this.id, required this.secret});

  final String id;
  final String secret;
  String status = 'active';
  String? reason;
}

final class _HeldPlan {
  const _HeldPlan(
    this.name,
    this.start,
    this.end, {
    this.status = 'active',
    this.freezeDaysAllowed = 7,
    this.freezes = const [],
  });

  final String name;

  /// Days from today; negative is in the past.
  final int start;
  final int end;
  final String status;
  final int freezeDaysAllowed;
  final List<_Freeze> freezes;

  int get freezeDaysUsed => freezes.fold(0, (days, freeze) => days + freeze.days);

  /// The freeze covering today, which makes the membership frozen.
  _Freeze? get frozenToday => freezes.where((freeze) => freeze.start <= 0 && freeze.end >= 0).firstOrNull;
}

/// A freeze, in days from today like [_HeldPlan], both days included.
final class _Freeze {
  const _Freeze(this.id, this.start, this.end);

  final int id;
  final int start;
  final int end;

  int get days => end - start + 1;
}

final class _Link {
  _Link({
    required this.id,
    required this.phone,
    required this.gym,
    required this.amountMinor,
    required this.createdAt,
    this.plan,
    this.membershipId,
  });

  final int id;
  final String phone;
  final String gym;
  final int amountMinor;
  final DateTime createdAt;

  /// The plan being bought, or null when paying what a membership owes.
  final Map<String, Object?>? plan;
  int? membershipId;

  /// pending, paid_on_chapa, confirming, paid or cancelled.
  String state = 'pending';
  bool settled = false;
  DateTime? settledAt;
  Map<String, Object?>? payment;

  Map<String, Object?> toJson() => {
    'id': id,
    'status': switch (state) {
      'paid_on_chapa' || 'confirming' => 'pending',
      final other => other,
    },
    'amount': FakeBackend._money(amountMinor),
    'checkout_url': state == 'paid' || state == 'cancelled' ? null : 'https://checkout.chapa.co/checkout/payment/fake-$id',
    'return_url': state == 'paid' || state == 'cancelled' ? null : 'https://api.test/payments/returned',
    'membership_id': membershipId,
    'plan': plan == null ? null : {'id': plan!['id'], 'name': plan!['name']},
    'created_at': createdAt.toUtc().toIso8601String(),
    'settled_at': settledAt?.toUtc().toIso8601String(),
    'payment': payment,
  };
}
