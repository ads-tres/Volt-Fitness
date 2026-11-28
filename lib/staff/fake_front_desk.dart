import 'dart:convert';
import 'dart:io' show HttpDate;
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:dio/dio.dart';

import '../core/access/gq1.dart';
import '../core/network/api_headers.dart';

/// Answers the front desk app's calls in dev builds, with the paths and JSON
/// of the gym platform's staff API, as the member app's fake does.
///
/// Sign in with [staffPhone] (Demo Gym, both branches), [twoGymsPhone]
/// (Demo Gym's Main Branch, and Bole Fitness) or [accountantPhone] (Demo
/// Gym's Main Branch, who may not add members), password [password].
///
/// Any GQ1 code lets Hana Girma in; one with `EXPIRED` in it is Tigist
/// Haile's ended membership, and one with `OWES` lets Abebe Kebede in with
/// 1,000.00 ETB still to pay. A code scanned twice is `CODE_ALREADY_USED`.
/// While [noInternet] is on, every call fails as if the desk had no
/// internet, so the desk decides from its door list; offline scans sent
/// later are recorded at the time they were made, flagged for review when
/// the fake would have decided otherwise.
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
  static const accountantPhone = '+251911000003';
  static const password = 'password';

  static const _tokenPrefix = 'fake-desk-token:';

  final Duration latency;

  /// Dev builds' "No internet" switch in the desk menu, and tests'.
  bool noInternet = false;
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
    if (noInternet) throw DioException.connectionError(requestOptions: options, reason: 'No internet at the desk (demo)');
    final body = switch (options.data) {
      final Map<String, dynamic> map => map,
      _ => const <String, dynamic>{},
    };
    final gymPath = RegExp(r'^/organizations/([^/]+)(/.*)$').firstMatch(options.path);
    // A photo has to be read first, so its upload is answered here.
    final photoPath = gymPath == null ? null : RegExp(r'^/members/(\d+)/photo$').firstMatch(gymPath.group(2)!);
    if (photoPath != null && options.method == 'PUT') {
      final authorization = options.headers[ApiHeaders.authorization];
      if (authorization is! String || !authorization.startsWith('Bearer $_tokenPrefix')) {
        return _json(401, {'message': 'Unauthenticated.'});
      }
      return _savePhoto(options, int.parse(photoPath.group(1)!));
    }
    // Signing takes a moment, so the door list is answered here.
    if (gymPath != null && options.method == 'GET' && gymPath.group(2)!.startsWith('/door-list')) {
      final authorization = options.headers[ApiHeaders.authorization];
      final token = authorization is String && authorization.startsWith('Bearer ') ? authorization.substring(7) : null;
      if (token == null || !token.startsWith(_tokenPrefix)) return _json(401, {'message': 'Unauthenticated.'});
      return gymPath.group(2) == '/door-list/public-key'
          ? _publicKey()
          : _doorList(
              token.substring(_tokenPrefix.length),
              gymPath.group(1)!,
              int.tryParse('${options.queryParameters['branch_id'] ?? ''}'),
            );
    }
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
    if (!const [staffPhone, twoGymsPhone, accountantPhone].contains(phone) || body['password'] != password) {
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
    'id': switch (phone) {
      staffPhone => 1,
      twoGymsPhone => 2,
      _ => 3,
    },
    'name': switch (phone) {
      staffPhone => 'Demo Owner',
      twoGymsPhone => 'Demo Receptionist',
      _ => 'Demo Accountant',
    },
    'email': null,
    'phone': phone,
  };

  Map<String, Object?> _me(String phone) => {
    'user': _user(phone),
    'staff': [
      {
        'organization': {'slug': 'demo-gym', 'name': 'Demo Gym'},
        'role': switch (phone) {
          staffPhone => 'owner',
          twoGymsPhone => 'receptionist',
          _ => 'accountant',
        },
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
      ('GET', '/plans') => _planList(phone, gym),
      ('POST', '/members') => _addMember(options, phone, gym),
      ('POST', final path) when RegExp(r'^/memberships/\d+/freezes$').hasMatch(path) => _freeze(options, phone, int.parse(path.split('/')[2])),
      ('POST', final path) when RegExp(r'^/memberships/\d+/freezes/\d+/end$').hasMatch(path) => _endFreeze(
        phone,
        int.parse(path.split('/')[2]),
        int.parse(path.split('/')[4]),
      ),
      ('POST', final path) when RegExp(r'^/memberships/\d+/cancellation$').hasMatch(path) => _cancel(options, phone, int.parse(path.split('/')[2])),
      ('POST', final path) when RegExp(r'^/members/\d+/memberships$').hasMatch(path) => _sell(options, phone, int.parse(path.split('/')[2])),
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
      ('DELETE', final path) when RegExp(r'^/members/\d+/photo$').hasMatch(path) => () {
        _photos.remove(int.parse(path.split('/')[2]));
        return _empty();
      }(),
      ('POST', '/check-ins/offline') => _offline(options, phone, gym),
      ('GET', final path) when RegExp(r'^/members/\d+/memberships$').hasMatch(path) => _memberships(int.parse(path.split('/')[2])),
      ('POST', final path) when RegExp(r'^/memberships/\d+/payments$').hasMatch(path) => _pay(
        options,
        phone,
        gym,
        int.parse(path.split('/')[2]),
      ),
      ('POST', final path) when RegExp(r'^/memberships/\d+/payment-links$').hasMatch(path) => _openLink(
        options,
        phone,
        gym,
        int.parse(path.split('/')[2]),
      ),
      ('POST', final path) when RegExp(r'^/payment-links/\d+/sms$').hasMatch(path) => _textLink(int.parse(path.split('/')[2])),
      ('GET', '/notifications') => _inbox(phone, gym),
      ('POST', '/notifications/read-all') => _readAll(phone, gym),
      ('POST', final path) when RegExp(r'^/notifications/[^/]+/read$').hasMatch(path) => _read(phone, gym, path.split('/')[2]),
      ('GET', '/notification-preferences') => _json(200, {'data': _choices(phone, gym)}),
      ('PATCH', '/notification-preferences') => _choose(options, phone, gym),
      _ => _json(404, {'message': 'Not found.'}),
    };
  }

  // Photos

  /// Each member's photo, as a data link the desk can show offline.
  final _photos = <Object?, String>{};

  /// Keeps a photo taken at the desk, with the API's limits: an image, up
  /// to 5 MB.
  Future<ResponseBody> _savePhoto(RequestOptions options, int memberId) async {
    final form = options.data;
    final file = form is FormData ? form.files.where((entry) => entry.key == 'photo').firstOrNull?.value : null;
    if (file == null) {
      return _json(422, {
        'message': 'The photo field is required.',
        'errors': {
          'photo': ['The photo field is required.'],
        },
      });
    }
    // Dio has already read the original for the request.
    final bytes = <int>[for (final chunk in await file.clone().finalize().toList()) ...chunk];
    if (bytes.length > 5 * 1024 * 1024) {
      return _json(422, {
        'message': 'The photo may not be bigger than 5 MB.',
        'errors': {
          'photo': ['The photo may not be bigger than 5 MB.'],
        },
      });
    }
    _photos[memberId] = 'data:image/jpeg;base64,${base64.encode(bytes)}';
    return _empty();
  }

  // Payments

  /// Every membership, oldest first. Abebe's started this month and he
  /// owes 1,000 ETB of it; Tigist's ended last week; Hana's is current.
  final _sold = <_FakeMembership>[
    _FakeMembership(id: 101, memberId: 1, plan: _plans[0], startsOn: DateTime(2026, 10, 2), endsOn: DateTime(2026, 11, 1), priceMinor: 150000, owedMinor: 100000),
    _FakeMembership(id: 102, memberId: 2, plan: _plans[0], startsOn: DateTime(2026, 9, 9), endsOn: DateTime(2026, 10, 8), priceMinor: 150000),
    // Hana is away for three days next week, so her plan ends three days later.
    _FakeMembership(id: 103, memberId: 3, plan: _plans[0], startsOn: DateTime(2026, 10, 2), endsOn: DateTime(2026, 11, 4), priceMinor: 150000)
      ..freezes.add(_FakeFreeze(id: 301, startsOn: DateTime(2026, 10, 20), endsOn: DateTime(2026, 10, 22), reason: 'Travelling')),
  ];
  var _receipts = 0;

  /// Pay-online links not paid yet, by id: the membership's id and when the
  /// link was last texted.
  final _links = <int, ({int membershipId, int amountMinor, DateTime? textedAt})>{};

  DateTime get _todayDate => DateTime(_now().year, _now().month, _now().day);

  /// Everything [member] owes, across their memberships.
  int _owed(Map<String, Object?> member) =>
      _sold.where((each) => each.memberId == member['id']).fold(0, (sum, each) => sum + each.owedMinor);

  /// The member's membership today, or else their latest.
  _FakeMembership? _currentOf(Map<String, Object?> member) {
    final theirs = _sold.where((each) => each.memberId == member['id']).toList();
    return theirs.where((each) => each.covers(_todayDate)).firstOrNull ?? theirs.lastOrNull;
  }

  Map<String, Object?> _membershipJson(_FakeMembership membership, {bool withMoney = false}) {
    final link = _links.entries.where((entry) => entry.value.membershipId == membership.id).firstOrNull;
    return {
      'id': membership.id,
      'member_id': membership.memberId,
      'plan': {'id': membership.plan.id, 'name': membership.plan.name},
      'status': membership.statusOn(_todayDate),
      'starts_on': _iso(membership.startsOn),
      'ends_on': _iso(membership.endsOn),
      if (withMoney) ...{
        'list_price': _money(membership.plan.priceMinor),
        'price': _money(membership.priceMinor),
        'discount': membership.discountReason == null
            ? null
            : {'amount': _money(membership.plan.priceMinor - membership.priceMinor), 'reason': membership.discountReason},
        'balance_due': _money(membership.owedMinor),
        'freeze_days_allowed': membership.freezeDaysAllowed,
        'freeze_days_used': membership.freezeDaysUsed,
        'freezes': [
          for (final freeze in membership.freezes)
            {
              'id': freeze.id,
              'starts_on': _iso(freeze.startsOn),
              'ends_on': _iso(freeze.endsOn),
              'days': freeze.days,
              'reason': freeze.reason,
              'frozen_in_app': false,
            },
        ],
        'cancellation': membership.cancelReason == null ? null : {'cancelled_at': _now().toUtc().toIso8601String(), 'reason': membership.cancelReason},
        'open_payment_link': link == null
            ? null
            : {'id': link.key, 'amount': _money(link.value.amountMinor), 'checkout_url': 'https://checkout.chapa.co/demo'},
      },
    };
  }

  static String _iso(DateTime day) => day.toIso8601String().substring(0, 10);

  static const _months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];

  /// As the API writes dates in its messages: "2 November 2026".
  static String _longDate(DateTime day) => '${day.day} ${_months[day.month - 1]} ${day.year}';

  ResponseBody _memberships(int memberId) {
    if (!_members.any((member) => member['id'] == memberId)) return _json(404, {'message': 'Not found.'});
    return _json(200, {
      'data': [
        for (final membership in _sold.reversed)
          if (membership.memberId == memberId) _membershipJson(membership, withMoney: true),
      ],
    });
  }

  // Freezes and cancellations

  var _freezeIds = 400;

  /// Freezes a membership, with the API's rules: from today at the earliest
  /// and within the plan's freeze days unless an owner, one freeze at a time,
  /// while the membership runs. Its end moves later by the frozen days.
  ResponseBody _freeze(RequestOptions options, String phone, int membershipId) {
    if (phone == accountantPhone) return _json(403, {'message': 'This action is unauthorized.'});
    final membership = _sold.where((each) => each.id == membershipId).firstOrNull;
    if (membership == null) return _json(404, {'message': 'Not found.'});
    final body = options.data is Map<String, dynamic> ? options.data as Map<String, dynamic> : const <String, dynamic>{};
    final owner = phone == staffPhone;
    final reason = '${body['reason'] ?? ''}'.trim();
    if (body['ends_on'] is! String) return _refuse('ends_on', 'The ends on field is required.');
    if (reason.isEmpty) return _refuse('reason', 'The reason field is required.');
    final startsOn = body['starts_on'] is String ? DateTime.parse(body['starts_on']! as String) : _todayDate;
    final endsOn = DateTime.parse(body['ends_on']! as String);
    if (startsOn.isBefore(_todayDate) && !owner) {
      return _refuse('starts_on', 'Only owners and managers can start a freeze on a past date.');
    }
    if (membership.cancelReason != null) return _refuse('membership', 'This membership is cancelled.');
    if (membership.endsOn.isBefore(_todayDate)) return _refuse('membership', 'This membership has already ended.');
    if (endsOn.isBefore(startsOn)) return _refuse('ends_on', "The last day of the freeze can't be before its first day.");
    if (!membership.covers(startsOn)) {
      return _refuse(
        'starts_on',
        'A freeze must start while the membership runs, from ${_longDate(membership.startsOn)} to ${_longDate(membership.endsOn)}.',
      );
    }
    final clash = membership.freezes.where((each) => !startsOn.isAfter(each.endsOn) && !endsOn.isBefore(each.startsOn)).firstOrNull;
    if (clash != null) {
      return _refuse('starts_on', 'This membership is already frozen from ${_longDate(clash.startsOn)} to ${_longDate(clash.endsOn)}.');
    }
    final days = endsOn.difference(startsOn).inDays + 1;
    final left = membership.freezeDaysAllowed - membership.freezeDaysUsed;
    if (days > left && !owner) {
      return _refuse(
        'ends_on',
        left > 0 ? 'This membership can be frozen for $left more ${left == 1 ? 'day' : 'days'}.' : 'This membership has no freeze days left.',
      );
    }
    membership
      ..freezes.add(_FakeFreeze(id: _freezeIds++, startsOn: startsOn, endsOn: endsOn, reason: reason))
      ..endsOn = membership.endsOn.add(Duration(days: days));
    return _json(201, {'data': _membershipJson(membership, withMoney: true)});
  }

  /// Ends a freeze early: one that started stops yesterday, one still to come
  /// is removed, and the membership ends that many days sooner.
  ResponseBody _endFreeze(String phone, int membershipId, int freezeId) {
    if (phone == accountantPhone) return _json(403, {'message': 'This action is unauthorized.'});
    final membership = _sold.where((each) => each.id == membershipId).firstOrNull;
    final freeze = membership?.freezes.where((each) => each.id == freezeId).firstOrNull;
    if (membership == null || freeze == null) return _json(404, {'message': 'Not found.'});
    if (membership.cancelReason != null) return _refuse('membership', 'This membership is cancelled.');
    if (freeze.endsOn.isBefore(_todayDate)) return _refuse('freeze', 'This freeze has already ended.');
    final int daysBack;
    if (freeze.startsOn.isBefore(_todayDate)) {
      daysBack = freeze.endsOn.difference(_todayDate).inDays + 1;
      freeze.endsOn = _todayDate.subtract(const Duration(days: 1));
    } else {
      daysBack = freeze.days;
      membership.freezes.remove(freeze);
    }
    membership.endsOn = membership.endsOn.subtract(Duration(days: daysBack));
    return _json(200, {'data': _membershipJson(membership, withMoney: true)});
  }

  /// Cancels a membership that runs or is still to come; owners only here.
  ResponseBody _cancel(RequestOptions options, String phone, int membershipId) {
    if (phone != staffPhone) return _json(403, {'message': 'This action is unauthorized.'});
    final membership = _sold.where((each) => each.id == membershipId).firstOrNull;
    if (membership == null) return _json(404, {'message': 'Not found.'});
    final body = options.data is Map<String, dynamic> ? options.data as Map<String, dynamic> : const <String, dynamic>{};
    final reason = '${body['reason'] ?? ''}'.trim();
    if (reason.isEmpty) return _refuse('reason', 'The reason field is required.');
    if (membership.cancelReason != null) return _refuse('membership', 'This membership is already cancelled.');
    if (membership.endsOn.isBefore(_todayDate)) return _refuse('membership', 'This membership has already ended.');
    membership.cancelReason = reason;
    return _json(200, {'data': _membershipJson(membership, withMoney: true)});
  }

  // Plans

  static const _plans = [
    _FakePlan(id: 2, name: 'Monthly', priceMinor: 150000, months: 1),
    _FakePlan(id: 3, name: '3 months', priceMinor: 400000, months: 3),
    _FakePlan(id: 4, name: '10 visits', priceMinor: 120000, months: 2, visitLimit: 10, branchIds: [1]),
  ];

  ResponseBody _planList(String phone, String gym) => _json(200, {
    'data': [
      for (final plan in _plans)
        {
          'id': plan.id,
          'name': plan.name,
          'description': null,
          'price': _money(plan.priceMinor),
          'duration': {'count': plan.visitLimit == null ? plan.months : plan.months, 'unit': 'month'},
          'freeze_days_allowed': 7,
          'visit_limit': plan.visitLimit,
          'available_at_all_branches': plan.branchIds == null,
          'branches': [
            if (plan.branchIds case final ids?)
              for (final branch in _branches(phone, gym))
                if (ids.contains(branch['id'])) branch,
          ],
        },
    ],
  });

  /// Sells a plan, with the API's rules: the first free day unless one is
  /// given, past days and typed discounts only for owners, the promo code
  /// VOLT10 for 10% off.
  ResponseBody _sell(RequestOptions options, String phone, int memberId) {
    final body = options.data is Map<String, dynamic> ? options.data as Map<String, dynamic> : const <String, dynamic>{};
    final member = _members.where((member) => member['id'] == memberId).firstOrNull;
    if (member == null) return _json(404, {'message': 'Not found.'});
    final plan = _plans.where((plan) => plan.id == body['plan_id']).firstOrNull;
    if (plan == null) return _refuse('plan_id', 'Choose a plan of this gym that is still on sale.');
    final owner = phone == staffPhone;
    final theirs = _sold.where((each) => each.memberId == memberId && each.cancelReason == null).toList();
    final lastEnd = theirs.map((each) => each.endsOn).fold<DateTime?>(null, (latest, end) => latest == null || end.isAfter(latest) ? end : latest);
    final firstFree = lastEnd == null || lastEnd.isBefore(_todayDate) ? _todayDate : lastEnd.add(const Duration(days: 1));
    final startsOn = switch (body['starts_on']) {
      final String day => DateTime.parse(day),
      _ => firstFree,
    };
    if (startsOn.isBefore(_todayDate) && !owner) {
      return _refuse('starts_on', 'Only owners and managers can start a membership on a past date.');
    }
    final discount = '${body['discount'] ?? ''}'.trim();
    final promo = '${body['promo_code'] ?? ''}'.trim();
    if (discount.isNotEmpty && !owner) return _refuse('discount', 'Only owners and managers can give a discount.');
    if (discount.isNotEmpty && promo.isNotEmpty) return _refuse('promo_code', 'The promo code field prohibits discount from being present.');
    if (discount.isNotEmpty && '${body['discount_reason'] ?? ''}'.trim().isEmpty) {
      return _refuse('discount_reason', 'The discount reason field is required when discount is present.');
    }
    var price = plan.priceMinor;
    String? reason;
    if (discount.isNotEmpty) {
      final percent = RegExp(r'^(\d+)%$').firstMatch(discount);
      final off = percent == null ? _minorOf(discount) : plan.priceMinor * int.parse(percent.group(1)!) ~/ 100;
      if (off == null) {
        return _refuse('discount', 'Cannot read [$discount] as a discount. Expected an amount like 500 or a percentage like 10%.');
      }
      if (off <= 0) return _refuse('discount', 'A discount must be more than zero, not [$discount].');
      if (off > plan.priceMinor) return _refuse('discount', 'The discount is more than the price of ${_money(plan.priceMinor)['formatted']}.');
      price -= off;
      reason = '${body['discount_reason']}'.trim();
    } else if (promo.isNotEmpty) {
      if (promo.toUpperCase() != 'VOLT10') return _refuse('promo_code', "This promo code doesn't exist. Check how it is spelled.");
      price -= plan.priceMinor ~/ 10;
      reason = 'Promo code VOLT10';
    }
    final endsOn = DateTime(startsOn.year, startsOn.month + plan.months, startsOn.day).subtract(const Duration(days: 1));
    final clash = theirs.where((each) => !startsOn.isAfter(each.endsOn) && !endsOn.isBefore(each.startsOn)).firstOrNull;
    if (clash != null) {
      return _refuse(
        'starts_on',
        'The member already has a membership from ${_longDate(clash.startsOn)} to ${_longDate(clash.endsOn)}. '
            'The first free start date is ${_longDate(firstFree)}.',
      );
    }
    final membership = _FakeMembership(
      id: 200 + _sold.length,
      memberId: memberId,
      plan: plan,
      startsOn: startsOn,
      endsOn: endsOn,
      priceMinor: price,
      owedMinor: price,
      discountReason: reason,
    );
    _sold.add(membership);
    return _json(201, {'data': _membershipJson(membership, withMoney: true)});
  }

  /// "1,000.50" as santim, or null when it isn't an amount.
  static int? _minorOf(Object? amount) {
    final match = RegExp(r'^(\d+)(?:\.(\d{1,2}))?$').firstMatch('${amount ?? ''}'.replaceAll(',', ''));
    if (match == null) return null;
    return int.parse(match.group(1)!) * 100 + int.parse((match.group(2) ?? '0').padRight(2, '0'));
  }

  ResponseBody _refuse(String field, String message) => _json(422, {
    'message': message,
    'errors': {
      field: [message],
    },
  });

  /// Records cash or a transfer, with the API's rules.
  ResponseBody _pay(RequestOptions options, String phone, String gym, int membershipId) {
    final body = options.data is Map<String, dynamic> ? options.data as Map<String, dynamic> : const <String, dynamic>{};
    final membership = _sold.where((each) => each.id == membershipId).firstOrNull;
    if (membership == null) return _json(404, {'message': 'Not found.'});
    final amount = _minorOf(body['amount']);
    if (amount == null) return _refuse('amount', 'The amount must be an amount written as text, like "2,500" or "2500.50".');
    if (amount <= 0) return _refuse('amount', 'The amount must be more than zero.');
    final method = body['method'];
    if (!const ['cash', 'telebirr', 'cbe_birr', 'bank_transfer'].contains(method)) {
      return _refuse('method', 'The selected method is invalid.');
    }
    final reference = '${body['reference'] ?? ''}'.trim();
    if (method != 'cash' && reference.isEmpty) return _refuse('reference', 'Enter the transaction number from the payment confirmation.');
    if (method == 'cash' && reference.isNotEmpty) return _refuse('reference', 'A cash payment has no transaction number.');
    if (!_branches(phone, gym).any((branch) => branch['id'] == body['branch_id'])) {
      return _refuse('branch_id', 'Choose the branch where the money was taken.');
    }
    if (body['paid_on'] case final String paidOn) {
      final today = DateTime(_now().year, _now().month, _now().day);
      final day = DateTime.parse(paidOn);
      if (day.isAfter(today)) return _refuse('paid_on', "A payment can't be dated in the future.");
      if (day.isBefore(today) && phone != staffPhone) {
        return _refuse('paid_on', 'Only owners, managers and accountants can date a payment in the past.');
      }
    }
    final owed = membership.owedMinor;
    if (amount > owed) {
      return _refuse(
        'amount',
        owed > 0 ? 'Only ${_money(owed)['formatted']} is still due on this membership.' : 'Nothing is due on this membership.',
      );
    }
    membership.owedMinor = owed - amount;
    if (owed == amount) _links.removeWhere((_, link) => link.membershipId == membershipId);
    return _json(201, {
      'data': {
        'id': 900 + _receipts,
        'receipt_number': 'R-${(++_receipts).toString().padLeft(6, '0')}',
        'type': 'payment',
        'amount': _money(amount),
        'method': method,
        'reference': method == 'cash' ? null : reference,
        'paid_on': '${body['paid_on'] ?? _now().toIso8601String().substring(0, 10)}',
      },
    });
  }

  /// Opens a pay-online link; only Demo Gym has connected Chapa.
  ResponseBody _openLink(RequestOptions options, String phone, String gym, int membershipId) {
    final body = options.data is Map<String, dynamic> ? options.data as Map<String, dynamic> : const <String, dynamic>{};
    final membership = _sold.where((each) => each.id == membershipId).firstOrNull;
    if (membership == null) return _json(404, {'message': 'Not found.'});
    if (gym != 'demo-gym') return _refuse('chapa_account', "Connect the gym's Chapa account first.");
    if (_links.values.any((link) => link.membershipId == membershipId)) {
      return _refuse('membership', 'This membership already has an open payment link. Cancel it to create a new one.');
    }
    final owed = membership.owedMinor;
    final amount = body['amount'] == null ? owed : _minorOf(body['amount']);
    if (amount == null) return _refuse('amount', 'The amount must be an amount written as text, like "2,500" or "2500.50".');
    if (amount <= 0 || owed <= 0) return _refuse('amount', 'Nothing is due on this membership.');
    if (amount > owed) return _refuse('amount', 'Only ${_money(owed)['formatted']} is still due on this membership.');
    final id = 700 + _links.length;
    _links[id] = (membershipId: membershipId, amountMinor: amount, textedAt: null);
    return _json(201, {
      'data': {'id': id, 'status': 'pending', 'amount': _money(amount), 'checkout_url': 'https://checkout.chapa.co/demo'},
    });
  }

  /// Texts a link, at most once every 5 minutes.
  ResponseBody _textLink(int linkId) {
    final link = _links[linkId];
    if (link == null) return _refuse('payment_link', 'This payment link is no longer open.');
    final texted = link.textedAt;
    if (texted != null && _now().difference(texted) < const Duration(minutes: 5)) {
      return _refuse(
        'payment_link',
        'The link was texted to the member a moment ago. Wait a few minutes before sending it again.',
      );
    }
    _links[linkId] = (membershipId: link.membershipId, amountMinor: link.amountMinor, textedAt: _now());
    return _json(202, {
      'data': {'id': linkId, 'status': 'pending', 'amount': _money(link.amountMinor)},
    });
  }

  // Offline: the door list

  /// The seed of the fake's Ed25519 signing key; dev builds fetch its public
  /// key and keep it, as with a gym platform that has no key built in.
  static final _signingSeed = List<int>.generate(32, (index) => index + 1);

  /// Each member's QR credential: an id as in the code, and a secret only
  /// the fake and tests know. Hana's pack has one visit left, at Main.
  static const doorCredentials = {
    1: '01K7Z3M6Q8V2N4R5T9W1X0YAB1',
    2: '01K7Z3M6Q8V2N4R5T9W1X0YAB2',
    3: '01K7Z3M6Q8V2N4R5T9W1X0YAB3',
  };

  static List<int> doorSecret(int memberId) => List<int>.filled(32, memberId * 7);

  /// The code member [memberId] shows at [now], as the member app makes it.
  static String doorCode(int memberId, DateTime now) =>
      Gq1.payload(doorSecret(memberId), doorCredentials[memberId]!, Gq1.stepAt(now));

  final _offlineIds = <String>{};

  /// Records scans the desk decided offline, at the time they were made, as
  /// the door decided; refuses a code that doesn't match its time or isn't
  /// one of the fake's, one over 3 days old or in the future, or at a branch
  /// the staff member doesn't work at. Tigist's ended plan is where the fake
  /// would disagree with a door that let her in.
  ResponseBody _offline(RequestOptions options, String phone, String gym) {
    final body = options.data is Map<String, dynamic> ? options.data as Map<String, dynamic> : const <String, dynamic>{};
    final scans = [for (final scan in (body['scans'] as List<dynamic>? ?? const [])) if (scan is Map<String, dynamic>) scan];
    Map<String, Object?> answer(String id, String status, {int? checkInId, bool disagrees = false, String? reason, String? message}) => {
      'id': id,
      'status': status,
      'check_in_id': checkInId,
      'server_disagrees': disagrees,
      'server_reason_code': reason,
      'message': message,
    };
    return _json(200, {
      'data': [
        for (final scan in scans)
          () {
            final id = '${scan['id']}';
            if (!_offlineIds.add(id)) return answer(id, 'already_recorded');
            final at = DateTime.tryParse('${scan['scanned_at']}')?.toUtc();
            final branch = _branches(phone, gym).where((branch) => branch['id'] == scan['branch_id']).firstOrNull;
            final match = RegExp(r'^GQ1:([0-9A-Z]{26}):(\d+):([0-9A-F]{16})$').firstMatch('${scan['payload']}');
            final memberId = doorCredentials.entries.where((entry) => entry.value == match?.group(1)).firstOrNull?.key;
            if (branch == null) return answer(id, 'refused', message: "You don't work at this branch.");
            if (at == null || at.isAfter(_now().toUtc().add(const Duration(minutes: 2))) || _now().toUtc().difference(at) > const Duration(days: 3)) {
              return answer(id, 'refused', message: 'The scan is dated too far from now.');
            }
            if (match == null || memberId == null || (int.parse(match.group(2)!) - Gq1.stepAt(at)).abs() > 1 ||
                Gq1.code(doorSecret(memberId), match.group(1)!, int.parse(match.group(2)!)) != match.group(3)) {
              return answer(id, 'refused', message: "The code doesn't match the time it was scanned.");
            }
            final serverDeny = memberId == 2 ? 'MEMBERSHIP_EXPIRED' : null;
            final doorDeny = scan['decision'] == 'deny' ? '${scan['reason_code']}' : null;
            final disagrees = serverDeny != doorDeny;
            final member = {1: _abebe, 2: _tigist, 3: _hana}[memberId];
            final checkIn = _checkIn(
              branch,
              deny: doorDeny,
              member: member,
              owedMinor: 0,
              endsOn: '2026-11-01',
              scannedAt: at,
              serverDisagrees: disagrees,
              serverReasonCode: disagrees ? serverDeny : null,
            );
            _history.add(checkIn);
            return answer(id, 'recorded', checkInId: checkIn['id'] as int?, disagrees: disagrees, reason: disagrees ? serverDeny : null);
          }(),
      ],
    });
  }

  Future<SimpleKeyPair> _keyPair() => Ed25519().newKeyPairFromSeed(_signingSeed);

  Future<String> _keyId() async {
    final publicKey = await (await _keyPair()).extractPublicKey();
    return base64.encode(publicKey.bytes).substring(0, 16);
  }

  Future<ResponseBody> _publicKey() async {
    final publicKey = await (await _keyPair()).extractPublicKey();
    return _json(200, {
      'data': {'algorithm': 'Ed25519', 'public_key': base64.encode(publicKey.bytes), 'key_id': await _keyId()},
    });
  }

  /// Today's and tomorrow's list, signed: the three members' credentials
  /// with their day keys, Abebe's Monthly plan, Tigist's ended one and Hana's
  /// pack, and Main Branch open 05:00 to 23:00, Bole Branch 06:00 to 22:00.
  Future<ResponseBody> _doorList(String phone, String gym, int? branchId) async {
    final now = _now();
    String date(int days) => DateTime(now.year, now.month, now.day + days).toIso8601String().substring(0, 10);
    final dates = [date(0), date(1)];
    final firstUtcDay = now.toUtc().millisecondsSinceEpoch ~/ 86400000;
    final utcDays = [firstUtcDay, firstUtcDay + 1];
    final branches = [
      for (final branch in _branches(phone, gym))
        if (branchId == null || branch['id'] == branchId) branch,
    ];
    final members = {1: _abebe, 2: _tigist, 3: _hana};
    Map<String, Object?> day(int memberId) => switch (memberId) {
      1 => {'allowed': true, 'reason_code': null, 'membership': {'id': 101, 'plan': 'Monthly'}, 'branch_ids': null, 'visits_left': null},
      2 => {'allowed': false, 'reason_code': 'MEMBERSHIP_EXPIRED', 'membership': {'id': 102, 'plan': 'Monthly'}, 'branch_ids': null, 'visits_left': null},
      _ => {'allowed': true, 'reason_code': null, 'membership': {'id': 103, 'plan': '10 Visits'}, 'branch_ids': [1], 'visits_left': 1},
    };
    final list = jsonEncode({
      'gym': {'id': 1, 'slug': gym, 'name': gym == 'bole-fitness' ? 'Bole Fitness' : 'Demo Gym', 'timezone': 'Africa/Addis_Ababa'},
      'generated_at': now.toUtc().toIso8601String(),
      'valid_until': DateTime.fromMillisecondsSinceEpoch((firstUtcDay + 2) * 86400000, isUtc: true).toIso8601String(),
      'utc_days': utcDays,
      'dates': dates,
      'branches': [
        for (final branch in branches)
          {
            'id': branch['id'],
            'name': branch['name'],
            'hours': {
              for (final each in dates)
                each: branch['id'] == 1 ? {'opens_at': '05:00', 'closes_at': '23:00'} : {'opens_at': '06:00', 'closes_at': '22:00'},
            },
          },
      ],
      'credentials': [
        for (final MapEntry(key: memberId, value: id) in doorCredentials.entries)
          {
            'id': id,
            'last_used_step': null,
            'day_keys': {for (final utcDay in utcDays) '$utcDay': base64.encode(Gq1.dayKey(doorSecret(memberId), utcDay))},
            'member': {'id': memberId, 'full_name': members[memberId]!['full_name'], 'photo_url': _photos[memberId]},
            'days': {for (final each in dates) each: day(memberId)},
          },
      ],
    });
    final signature = await Ed25519().sign(utf8.encode(list), keyPair: await _keyPair());
    return _json(200, {
      'data': {'list': list, 'signature': base64.encode(signature.bytes), 'key_id': await _keyId()},
    });
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
    _ when phone != staffPhone => [_branch(1, 'MAIN', 'Main Branch')],
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
    Map<String, Object?> checkIn(String? deny, {Map<String, Object?>? member, int owedMinor = 0, String? endsOn}) =>
        _checkIn(branch, deny: deny, member: member, owedMinor: owedMinor, endsOn: endsOn);
    if (!payload.startsWith('GQ1:')) return _record(checkIn('CREDENTIAL_INVALID'));
    if (!_scanned.add(payload)) return _record(checkIn('CODE_ALREADY_USED'));
    if (payload.contains('EXPIRED')) {
      return _record(checkIn('MEMBERSHIP_EXPIRED', member: _tigist, endsOn: '2026-10-08'));
    }
    if (payload.contains('OWES')) {
      return _record(checkIn(null, member: _abebe, owedMinor: _owed(_abebe), endsOn: '2026-11-01'));
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
      for (final member in _members)
        if ((member['full_name']! as String).toLowerCase().contains(text) ||
            (digits.length >= 3 && (member['phone']! as String).replaceAll('+251', '0').contains(digits)))
          {
            ...member,
            'photo_url': _photos[member['id']],
            'membership': switch (_currentOf(member)) {
              final membership? => _membershipJson(membership),
              null => null,
            },
            'balance_due': _money(_owed(member)),
          },
    ];
  }

  ResponseBody _atDesk(RequestOptions options, String phone, String gym, int memberId) {
    final body = options.data is Map<String, dynamic> ? options.data as Map<String, dynamic> : const <String, dynamic>{};
    final branch = _branches(phone, gym).where((branch) => branch['id'] == body['branch_id']).firstOrNull;
    final member = _members.where((member) => member['id'] == memberId).firstOrNull;
    if (branch == null || member == null) return _json(404, {'message': 'Not found.'});
    final membership = _currentOf(member);
    final endsOn = membership == null ? null : _iso(membership.endsOn);
    if (membership == null || !membership.covers(_todayDate) || membership.statusOn(_todayDate) != 'active') {
      final reason = switch (membership?.statusOn(_todayDate)) {
        null => 'MEMBERSHIP_NONE',
        'frozen' => 'MEMBERSHIP_FROZEN',
        'cancelled' => 'MEMBERSHIP_NONE',
        _ => 'MEMBERSHIP_EXPIRED',
      };
      return _record(
        _checkIn(branch, deny: reason, member: member, owedMinor: _owed(member), endsOn: endsOn, method: 'desk'),
      );
    }
    return _record(_checkIn(branch, member: member, owedMinor: _owed(member), endsOn: endsOn, method: 'desk'));
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

  /// Everyone at the gym: the three demo members, then any added here.
  final _members = <Map<String, Object?>>[_abebe, _tigist, _hana];

  /// Adds a member at the desk's branch, with the API's rules: a name, a
  /// phone no other member of the gym has, both halves of an emergency
  /// contact, a birthday in the past. Accountants may not.
  ResponseBody _addMember(RequestOptions options, String phone, String gym) {
    if (phone == accountantPhone) return _json(403, {'message': 'This action is unauthorized.'});
    final body = options.data is Map<String, dynamic> ? options.data as Map<String, dynamic> : const <String, dynamic>{};
    String text(String field) => '${body[field] ?? ''}'.trim();
    bool isPhone(String value) => RegExp(r'^\+251[79]\d{8}$').hasMatch(value);
    const phoneFormat = 'must be a phone number like 0911 234 567, or an international number starting with +.';
    final errors = <String, List<String>>{};
    void refuse(String field, String message) => errors[field] = [message];
    if (text('full_name').isEmpty) refuse('full_name', 'The full name field is required.');
    if (text('phone').isEmpty) {
      refuse('phone', 'The phone field is required.');
    } else if (!isPhone(text('phone'))) {
      refuse('phone', 'The phone $phoneFormat');
    } else if (_members.any((member) => member['phone'] == text('phone'))) {
      refuse('phone', 'The phone has already been taken.');
    }
    if (text('email').isNotEmpty && !text('email').contains('@')) refuse('email', 'The email field must be a valid email address.');
    if (text('date_of_birth').isNotEmpty && !DateTime.parse(text('date_of_birth')).isBefore(_todayDate)) {
      refuse('date_of_birth', 'The date of birth field must be a date before today.');
    }
    if (text('emergency_contact_name').isNotEmpty && text('emergency_contact_phone').isEmpty) {
      refuse('emergency_contact_phone', 'The emergency contact phone field is required when emergency contact name is present.');
    }
    if (text('emergency_contact_phone').isNotEmpty) {
      if (!isPhone(text('emergency_contact_phone'))) refuse('emergency_contact_phone', 'The emergency contact phone $phoneFormat');
      if (text('emergency_contact_name').isEmpty) {
        refuse('emergency_contact_name', 'The emergency contact name field is required when emergency contact phone is present.');
      }
    }
    final branch = _branches(phone, gym).where((branch) => branch['id'] == body['home_branch_id']).firstOrNull;
    if (branch == null) refuse('home_branch_id', 'Choose a branch of this gym that you work at.');
    if (errors.isNotEmpty) return _json(422, {'message': errors.values.first.first, 'errors': errors});
    final member = <String, Object?>{'id': 10 + _members.length, 'full_name': text('full_name'), 'phone': text('phone')};
    _members.add(member);
    return _json(201, {
      'data': {
        ...member,
        'email': text('email').isEmpty ? null : text('email'),
        'gender': body['gender'],
        'date_of_birth': body['date_of_birth'],
        'emergency_contact': text('emergency_contact_name').isEmpty
            ? null
            : {'name': text('emergency_contact_name'), 'phone': text('emergency_contact_phone')},
        'message_language': body['message_language'] ?? 'en',
        'photo_url': null,
        'home_branch': branch,
        'membership': null,
        'balance_due': _money(0),
        'registered_at': _now().toUtc().toIso8601String(),
      },
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
    bool serverDisagrees = false,
    String? serverReasonCode,
  }) => {
    'id': 800 + _checkIns++,
    'decision': deny == null ? 'allow' : 'deny',
    'reason_code': deny,
    'method': method,
    'checked_in_at': (scannedAt ?? _now().subtract(Duration(minutes: minutesAgo))).toUtc().toIso8601String(),
    'offline': scannedAt != null,
    'server_disagrees': serverDisagrees,
    'server_reason_code': serverReasonCode,
    'branch': branch,
    'member': member == null ? null : {...member, 'photo_url': _photos[member['id']]},
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

/// A plan of the fake gym.
final class _FakePlan {
  const _FakePlan({required this.id, required this.name, required this.priceMinor, required this.months, this.visitLimit, this.branchIds});

  final int id;
  final String name;
  final int priceMinor;
  final int months;
  final int? visitLimit;
  final List<int>? branchIds;
}

/// A membership the fake sold, and what is still owed on it.
final class _FakeMembership {
  _FakeMembership({
    required this.id,
    required this.memberId,
    required this.plan,
    required this.startsOn,
    required this.endsOn,
    required this.priceMinor,
    this.owedMinor = 0,
    this.discountReason,
  });

  final int id;
  final int memberId;
  final _FakePlan plan;
  final DateTime startsOn;
  DateTime endsOn;
  final int priceMinor;
  final String? discountReason;
  int owedMinor;
  final freezes = <_FakeFreeze>[];
  final freezeDaysAllowed = 7;
  String? cancelReason;

  int get freezeDaysUsed => freezes.fold(0, (sum, freeze) => sum + freeze.days);

  bool covers(DateTime day) => !day.isBefore(startsOn) && !day.isAfter(endsOn);

  String statusOn(DateTime day) {
    if (cancelReason != null) return 'cancelled';
    if (day.isBefore(startsOn)) return 'upcoming';
    if (day.isAfter(endsOn)) return 'expired';
    return freezes.any((freeze) => !day.isBefore(freeze.startsOn) && !day.isAfter(freeze.endsOn)) ? 'frozen' : 'active';
  }
}

/// A freeze on a membership of the fake gym.
final class _FakeFreeze {
  _FakeFreeze({required this.id, required this.startsOn, required this.endsOn, required this.reason});

  final int id;
  final DateTime startsOn;
  DateTime endsOn;
  final String reason;

  int get days => endsOn.difference(startsOn).inDays + 1;
}
