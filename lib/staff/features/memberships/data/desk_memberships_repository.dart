import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/money/money.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/json.dart';
import '../../../../core/time/local_date.dart';
import '../../../core/desk_session.dart';

/// A pause on a membership.
final class DeskFreeze {
  const DeskFreeze({required this.id, required this.startsOn, required this.endsOn, required this.days, this.reason});

  final int id;
  final LocalDate startsOn;
  final LocalDate endsOn;
  final int days;
  final String? reason;

  bool hasStarted(LocalDate today) => startsOn.compareTo(today) <= 0;
}

/// A membership the desk can freeze or cancel: one that runs or is still to
/// come.
final class DeskMembership {
  const DeskMembership({
    required this.id,
    required this.planName,
    required this.status,
    required this.startsOn,
    required this.endsOn,
    required this.freezeDaysAllowed,
    required this.freezeDaysUsed,
    this.freezes = const [],
    this.balanceDue,
  });

  final int id;
  final String planName;

  /// `active`, `frozen` or `upcoming`.
  final String status;
  final LocalDate startsOn;
  final LocalDate endsOn;
  final int freezeDaysAllowed;
  final int freezeDaysUsed;
  final List<DeskFreeze> freezes;

  /// What is still owed on it, when the API sent it.
  final Money? balanceDue;

  int get freezeDaysLeft => freezeDaysAllowed - freezeDaysUsed < 0 ? 0 : freezeDaysAllowed - freezeDaysUsed;

  /// The freeze going on today, or else the next one.
  DeskFreeze? currentOrNextFreeze(LocalDate today) {
    final coming = [for (final freeze in freezes) if (freeze.endsOn.compareTo(today) >= 0) freeze]
      ..sort((a, b) => a.startsOn.compareTo(b.startsOn));
    return coming.firstOrNull;
  }
}

/// A membership from the staff API, or null when it has ended or was
/// cancelled, as the desk has nothing to do with those, unless [any].
DeskMembership? deskMembershipFromJson(Map<String, dynamic> json, {bool any = false}) {
  final status = json.field<String>('status');
  if (!any && !const {'active', 'frozen', 'upcoming'}.contains(status)) return null;
  return DeskMembership(
    id: json.field<int>('id'),
    planName: json.field<Map<String, dynamic>>('plan').field<String>('name'),
    status: status,
    startsOn: LocalDate.parse(json.field<String>('starts_on')),
    endsOn: LocalDate.parse(json.field<String>('ends_on')),
    freezeDaysAllowed: json.optional<int>('freeze_days_allowed') ?? 0,
    freezeDaysUsed: json.optional<int>('freeze_days_used') ?? 0,
    balanceDue: switch (json.optional<Map<String, dynamic>>('balance_due')) {
      final money? => Money.fromJson(money),
      null => null,
    },
    freezes: [
      for (final freeze in json.objects('freezes'))
        DeskFreeze(
          id: freeze.field<int>('id'),
          startsOn: LocalDate.parse(freeze.field<String>('starts_on')),
          endsOn: LocalDate.parse(freeze.field<String>('ends_on')),
          days: freeze.field<int>('days'),
          reason: freeze.optional<String>('reason'),
        ),
    ],
  );
}

/// Freezing, unfreezing and cancelling a member's membership at the desk
/// (`memberships/{id}/freezes`, `…/freezes/{freeze}/end` and
/// `…/cancellation`). Every call throws a [Failure]; the API's refusals are
/// [ValidationFailure]s on the field they are about.
final class DeskMembershipsRepository {
  const DeskMembershipsRepository(this._api, this._session);

  final ApiClient _api;
  final DeskSession Function() _session;

  String _path(String path) => deskPath(_session(), path);

  /// The member's memberships that run or are still to come, newest first.
  Future<List<DeskMembership>> memberships(int memberId) async {
    final response = await _api.get(_path('/members/$memberId/memberships'));
    return readResponse(
      () => [
        for (final membership in (response! as Map<String, dynamic>).objects('data')) ?deskMembershipFromJson(membership),
      ],
    );
  }

  /// Every one of the member's memberships, ended and cancelled too, newest
  /// first.
  Future<List<DeskMembership>> history(int memberId) async {
    final response = await _api.get(_path('/members/$memberId/memberships'));
    return readResponse(
      () => [
        for (final membership in (response! as Map<String, dynamic>).objects('data'))
          ?deskMembershipFromJson(membership, any: true),
      ],
    );
  }

  /// Freezes from [startsOn] (or today) through [endsOn]; the membership's
  /// end moves later by those days.
  Future<void> freeze(int membershipId, {LocalDate? startsOn, required LocalDate endsOn, required String reason}) =>
      _api.post(
        _path('/memberships/$membershipId/freezes'),
        body: {'starts_on': ?startsOn?.toIso(), 'ends_on': endsOn.toIso(), 'reason': reason.trim()},
      );

  /// Ends a freeze that started yesterday at the latest, or removes one
  /// still to come.
  Future<void> endFreeze(int membershipId, int freezeId) =>
      _api.post(_path('/memberships/$membershipId/freezes/$freezeId/end'));

  Future<void> cancel(int membershipId, {required String reason}) =>
      _api.post(_path('/memberships/$membershipId/cancellation'), body: {'reason': reason.trim()});
}

final deskMembershipsRepositoryProvider = Provider<DeskMembershipsRepository>(
  (ref) => DeskMembershipsRepository(ref.watch(apiClientProvider), () => ref.read(deskSessionProvider)),
);
