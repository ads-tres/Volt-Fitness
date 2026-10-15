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
  final _invoices = <String, List<Map<String, Object?>>>{};
  final _attempts = <String, _Attempt>{};

  /// Idempotency key to the attempt it created.
  final _attemptKeys = <String, String>{};

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
      ('GET', '/plans') => _inGym(request, (phone, gym) => _json(200, {'data': _plans(gym)})),
      ('GET', '/invoices') => _inGym(request, (phone, gym) => _json(200, {
        'data': _invoicesFor(phone, gym),
        'links': {'next': null, 'prev': null},
        'meta': {'per_page': 30, 'next_cursor': null, 'prev_cursor': null},
      })),
      ('GET', final path) when path.startsWith('/invoices/') => _inGym(request, (phone, gym) {
        final id = path.substring('/invoices/'.length);
        final invoice = _invoicesFor(phone, gym).where((invoice) => invoice['id'] == id).firstOrNull;
        return invoice == null ? _error(404, 'NOT_FOUND', 'No such invoice.', request) : _json(200, {'data': invoice});
      }),
      ('POST', '/payment-attempts') => _inGym(request, (phone, gym) => _startPayment(request, phone, gym)),
      ('GET', final path) when path.startsWith('/payment-attempts/') => _inGym(
        request,
        (phone, gym) => _paymentStatus(request, path.substring('/payment-attempts/'.length)),
      ),
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
      ('GET', '/me/notification-preferences') => _inGym(
        request,
        (phone, gym) => _json(200, {'data': _preferencesFor(phone, gym)}),
      ),
      ('PATCH', '/me/notification-preferences') => _inGym(
        request,
        (phone, gym) => _updatePreferences(request, phone, gym),
      ),
      ('PUT', '/devices/current/push-token') => _signedIn(request, (phone) => _savePushToken(request, phone)),
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
      'outstanding': switch (_invoicesFor(phone, gym).where((invoice) => invoice['status'] == 'open').firstOrNull) {
        final open? => {
          'invoice_id': open['id'],
          'number': open['number'],
          'amount': open['total'],
          'due_on': open['due_on'],
        },
        null => null,
      },
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
    final held = _held(phone, gym);
    if (held == null) return null;
    String day(int offset) => _iso(_today.add(Duration(days: offset)));
    return {
      'id': '01K7Z7M${phone.substring(phone.length - 4)}${gym.substring(gym.length - 4)}'.padRight(26, '0'),
      'plan_name': held.name,
      'status': held.status,
      'starts_on': day(held.start),
      'ends_on': day(held.end),
      'grace_ends_on': null,
      'frozen_until': held.frozenUntil == null ? null : day(held.frozenUntil!),
      'allowed_branches': gym == _kazanchisFitClub['id'] ? [_kazanchisBranch] : [_boleBranch, _megenagnaBranch],
      'visits_remaining': null,
    };
  }

  /// The member's plan at [gym], in days from today: what they bought here
  /// in this session, or what their number starts with.
  _HeldPlan? _held(String phone, String gym) {
    if (_heldPlans['$phone|$gym'] case final bought?) return bought;
    if (gym == _kazanchisFitClub['id']) return const _HeldPlan('Quarterly', -26, 64);
    return switch (phone) {
      endingSoonPhone => const _HeldPlan('Monthly', -27, 3),
      expiredPhone => const _HeldPlan('Monthly', -36, -6, status: 'expired'),
      frozenPhone => const _HeldPlan('Monthly', -10, 30, status: 'frozen', frozenUntil: 7),
      noPlanPhone => null,
      _ => const _HeldPlan('Monthly', -12, 18),
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

  // Billing and Chapa

  List<Map<String, Object?>> _plans(String gym) => gym == _kazanchisFitClub['id']
      ? [_plan('Monthly', 30, 180000), _plan('Quarterly', 90, 500000)]
      : [_plan('Monthly', 30, 150000), _plan('Quarterly', 90, 400000), _plan('Annual', 365, 1400000)];

  Map<String, Object?> _plan(String name, int days, int priceMinor) => {
    'id': '01K7ZAP${name.toUpperCase()}'.padRight(26, '0'),
    'name': name,
    'duration_days': days,
    'price': {'amount_minor': priceMinor, 'currency': 'ETB'},
    'photo_url': null,
  };

  List<Map<String, Object?>> _invoicesFor(String phone, String gym) => _invoices.putIfAbsent('$phone|$gym', () {
    if (phone == noPlanPhone) return [];
    final paidDaysAgo = phone == expiredPhone ? 36 : 12;
    return [
      if (phone == endingSoonPhone) _invoice('INV-2026-0187', 'Monthly renewal', 150000, issuedDaysAgo: 1, dueInDays: 3),
      _invoice('INV-2026-0142', 'Monthly plan', 150000, issuedDaysAgo: paidDaysAgo)
        ..addAll(_paid(_today.subtract(Duration(days: paidDaysAgo)).add(const Duration(hours: 7, minutes: 10)))),
    ];
  });

  String _invoiceId(String number) => '01K7ZAI${number.replaceAll('-', '')}'.padRight(26, '0');

  /// Like the receipts: "4,000.00 ETB".
  static String _birr(int amountMinor) {
    final whole = '${amountMinor ~/ 100}'.replaceAllMapped(RegExp(r'\B(?=(\d{3})+$)'), (_) => ',');
    return '$whole.${(amountMinor % 100).toString().padLeft(2, '0')} ETB';
  }

  Map<String, Object?> _invoice(
    String number,
    String description,
    int amountMinor, {
    required int issuedDaysAgo,
    int? dueInDays,
  }) {
    final total = {'amount_minor': amountMinor, 'currency': 'ETB'};
    return {
      'id': _invoiceId(number),
      'number': number,
      'description': description,
      'total': total,
      'status': 'open',
      'issued_on': _iso(_today.subtract(Duration(days: issuedDaysAgo))),
      'due_on': dueInDays == null ? null : _iso(_today.add(Duration(days: dueInDays))),
      'lines': [
        {'description': description, 'amount': total},
      ],
      'receipt': null,
    };
  }

  Map<String, Object?> _paid(DateTime paidAt) => {
    'status': 'paid',
    'receipt': {
      'number': 'RCT-${paidAt.year}-${1000 + _random.nextInt(9000)}',
      'paid_at': paidAt.toUtc().toIso8601String(),
      'method': 'telebirr',
      'reference': 'CH${_ulid().substring(16)}',
      'url': null,
    },
  };

  ResponseBody _startPayment(_Request request, String phone, String gym) {
    final key = request.headers[ApiHeaders.idempotencyKey];
    if (key is String && _attemptKeys[key] != null) {
      return _json(201, {'data': _attempts[_attemptKeys[key]]!.toJson()});
    }

    final invoiceId = request.body['invoice_id'];
    final planId = request.body['plan_id'];
    final Map<String, Object?>? target = switch ((invoiceId, planId)) {
      (final String id, null) =>
        _invoicesFor(phone, gym).where((invoice) => invoice['id'] == id && invoice['status'] == 'open').firstOrNull,
      (null, final String id) => _plans(gym).where((plan) => plan['id'] == id).firstOrNull,
      _ => null,
    };
    if (target == null) return _error(422, 'VALIDATION_FAILED', 'Pay one open invoice or one plan.', request);

    final amount = (invoiceId is String ? target['total'] : target['price'])! as Map<String, Object?>;
    final attempt = _Attempt(
      id: _ulid(),
      phone: phone,
      gym: gym,
      amountMinor: amount['amount_minor']! as int,
      invoiceId: invoiceId is String ? invoiceId : null,
      plan: invoiceId is String ? null : target,
      expiresAt: _now().add(const Duration(minutes: 30)),
    );
    _attempts[attempt.id] = attempt;
    if (key is String) _attemptKeys[key] = attempt.id;
    return _json(201, {'data': attempt.toJson()});
  }

  ResponseBody _paymentStatus(_Request request, String id) {
    final attempt = _attempts[id];
    if (attempt == null) return _error(404, 'NOT_FOUND', 'No such payment.', request);
    // Like the real flow: a paid attempt shows as processing once, then
    // succeeds when the API has verified it with Chapa.
    if (attempt.state == 'paid') {
      attempt.state = 'verifying';
    } else if (attempt.state == 'verifying') {
      _settle(attempt);
      attempt.state = 'succeeded';
      _notify(
        attempt.phone,
        attempt.gym,
        'payment_succeeded',
        'Payment received',
        '${_birr(attempt.amountMinor)} received. Thank you!',
        data: {'invoice_id': ?attempt.invoiceId},
      );
    }
    return _json(200, {'data': attempt.toJson()});
  }

  /// Stands in for the member paying on Chapa's page and Chapa telling the
  /// API. Only the in-app fake checkout calls it.
  ResponseBody _fakeCheckout(_Request request, String phone, String path) {
    final parts = path.split('/');
    final attempt = _attempts[parts.first];
    if (attempt == null || attempt.phone != phone) return _error(404, 'NOT_FOUND', 'No such payment.', request);
    if (parts.last == 'pay' && attempt.state == 'pending') {
      if (phone == paymentFailsPhone) {
        attempt
          ..state = 'failed'
          ..failureReason = 'The telebirr account has too little balance.';
        _notify(
          phone,
          attempt.gym,
          'payment_failed',
          "Payment didn't go through",
          'The telebirr account has too little balance.',
          data: {'invoice_id': ?attempt.invoiceId},
        );
      } else {
        attempt.state = 'paid';
      }
    }
    return _noContent();
  }

  /// What the API does once Chapa's payment is verified: mark the invoice
  /// paid, or invoice the plan as paid, and extend the membership.
  void _settle(_Attempt attempt) {
    final invoices = _invoicesFor(attempt.phone, attempt.gym);
    final held = _held(attempt.phone, attempt.gym);
    final paidAt = _now();
    final String name;
    final int days;
    if (attempt.invoiceId case final invoiceId?) {
      invoices.firstWhere((invoice) => invoice['id'] == invoiceId).addAll(_paid(paidAt));
      name = held?.name ?? 'Monthly';
      days = 30;
    } else {
      final plan = attempt.plan!;
      name = plan['name']! as String;
      days = plan['duration_days']! as int;
      final invoice = _invoice('INV-${paidAt.year}-${2000 + invoices.length}', '$name plan', attempt.amountMinor, issuedDaysAgo: 0)
        ..addAll(_paid(paidAt));
      invoices.insert(0, invoice);
      attempt.invoiceId = invoice['id']! as String;
    }
    final continues = held != null && held.status != 'expired' && held.end >= 0;
    _heldPlans['${attempt.phone}|${attempt.gym}'] = _HeldPlan(
      name,
      continues ? held.start : 0,
      (continues ? held.end : -1) + days,
    );
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
              'invoice_issued',
              'New invoice INV-2026-0187',
              '1,500.00 ETB for your Monthly renewal, due in 3 days.',
              at(1, 9, 15),
              data: {'invoice_id': _invoiceId('INV-2026-0187')},
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
              data: {'invoice_id': _invoiceId('INV-2026-0142')},
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

  ResponseBody _listNotifications(_Request request, String phone, String gym) {
    final all = _notificationsFor(phone, gym);
    final from = int.tryParse(request.query['cursor'] ?? '') ?? 0;
    final perPage = int.tryParse(request.query['per_page'] ?? '') ?? 20;
    final to = min(from + perPage, all.length);
    return _json(200, {
      'data': all.sublist(min(from, all.length), to),
      'links': {'next': null, 'prev': null},
      'meta': {
        'per_page': perPage,
        'next_cursor': to < all.length ? '$to' : null,
        'prev_cursor': null,
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
  /// plan reminder and an invoice, to try each kind of tap.
  ResponseBody _fakePush(String phone, String gym) {
    final invoiceId = _invoicesFor(phone, gym).firstOrNull?['id'] as String?;
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
        'invoice_due',
        'Test: an invoice',
        'Tap to open your latest invoice.',
        data: {'invoice_id': ?invoiceId},
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
  const _HeldPlan(this.name, this.start, this.end, {this.status = 'active', this.frozenUntil});

  final String name;

  /// Days from today; negative is in the past.
  final int start;
  final int end;
  final String status;
  final int? frozenUntil;
}

final class _Attempt {
  _Attempt({
    required this.id,
    required this.phone,
    required this.gym,
    required this.amountMinor,
    required this.expiresAt,
    this.invoiceId,
    this.plan,
  });

  final String id;
  final String phone;
  final String gym;
  final int amountMinor;
  final DateTime expiresAt;
  final Map<String, Object?>? plan;

  /// The invoice paid; for a plan, the one created when the payment is
  /// verified.
  String? invoiceId;

  /// pending, paid, verifying, succeeded or failed.
  String state = 'pending';
  String? failureReason;

  Map<String, Object?> toJson() => {
    'id': id,
    'status': switch (state) {
      'paid' || 'verifying' => 'processing',
      final other => other,
    },
    'provider': 'chapa',
    'amount': {'amount_minor': amountMinor, 'currency': 'ETB'},
    'invoice_id': invoiceId,
    'checkout_url': 'https://checkout.chapa.co/checkout/payment/$id',
    'return_url': 'https://api.volt.example/api/v1/payments/return/$id',
    'expires_at': expiresAt.toUtc().toIso8601String(),
    'failure_reason': failureReason,
  };
}
