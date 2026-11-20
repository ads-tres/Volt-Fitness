import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/money/money.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/json.dart';
import '../../../../core/time/clock.dart' show clockProvider;
import '../../../../core/time/local_date.dart';
import '../../../core/desk_session.dart';
import '../domain/desk_numbers.dart';

/// The staff dashboard at the desk's gym (`GET /organizations/{gym}/
/// dashboard`). Throws a [Failure] when it fails.
final class NumbersRepository {
  const NumbersRepository(this._api, this._session);

  final ApiClient _api;
  final DeskSession Function() _session;

  /// From [from] to [to], both included, at [branchId] or at every branch
  /// the staff member works at.
  Future<DeskNumbers> load({required LocalDate from, required LocalDate to, int? branchId}) async {
    final data = dataObject(
      await _api.get(
        deskPath(_session(), '/dashboard'),
        query: {'from': from.toIso(), 'to': to.toIso(), 'branch_id': ?branchId},
      ),
    );
    return readResponse(() => deskNumbersFromJson(data));
  }
}

Money _money(Map<String, dynamic> json, String key) => Money.fromJson(json.field<Map<String, dynamic>>(key));

DeskNumbers deskNumbersFromJson(Map<String, dynamic> json) {
  final period = json.field<Map<String, dynamic>>('period');
  final checkIns = json.field<Map<String, dynamic>>('check_ins');
  final members = json.field<Map<String, dynamic>>('members');
  final sold = members.optional<Map<String, dynamic>>('memberships_sold') ?? const {};
  final byReason = [
    for (final MapEntry(:key, :value) in (checkIns.optional<Map<String, dynamic>>('denied_by_reason') ?? const {}).entries)
      if (value is int) (key, value),
  ]..sort((a, b) => b.$2.compareTo(a.$2));
  final byHour = List<int>.filled(24, 0);
  final trends = json.optional<Map<String, dynamic>>('trends') ?? const {};
  for (final hour in trends.objects('check_ins_by_hour')) {
    final at = hour.optional<int>('hour');
    if (at != null && at >= 0 && at < 24) byHour[at] = hour.optional<int>('allowed') ?? 0;
  }
  return DeskNumbers(
    from: LocalDate.parse(period.field<String>('from')),
    to: LocalDate.parse(period.field<String>('to')),
    letIn: checkIns.optional<int>('allowed') ?? 0,
    turnedAway: checkIns.optional<int>('denied') ?? 0,
    turnedAwayByReason: byReason,
    activeMembers: members.optional<int>('active') ?? 0,
    newMembers: members.optional<int>('new') ?? 0,
    soldAtTheDesk: sold.optional<int>('at_the_desk') ?? 0,
    soldInTheApp: sold.optional<int>('in_the_app') ?? 0,
    checkInsByHour: byHour,
    toCall: [
      for (final entry in json.objects('expiring'))
        MemberToCall(
          name: entry.field<Map<String, dynamic>>('member').field<String>('full_name'),
          phone: entry.field<Map<String, dynamic>>('member').optional<String>('phone') ?? '',
          planName: entry.optional<Map<String, dynamic>>('plan')?.optional<String>('name') ?? '',
          endsOn: LocalDate.parse(entry.field<String>('ends_on')),
          visitsLeft: entry.optional<int>('visits_remaining'),
          balanceDue: switch (entry.optional<Map<String, dynamic>>('balance_due')) {
            final money? => Money.fromJson(money),
            null => null,
          },
        ),
    ],
    money: switch (json.optional<Map<String, dynamic>>('money')) {
      final money? => DeskMoney(
        received: _money(money, 'received'),
        refunded: _money(money, 'refunded'),
        net: _money(money, 'net'),
        byMethod: {
          for (final MapEntry(:key, :value) in (money.optional<Map<String, dynamic>>('by_method') ?? const {}).entries)
            if (value is Map<String, dynamic>) key: Money.fromJson(value),
        },
        openLinks: money.optional<Map<String, dynamic>>('open_payment_links')?.optional<int>('count') ?? 0,
        openLinksAmount: _money(money.field<Map<String, dynamic>>('open_payment_links'), 'amount'),
        refundsNeeded: money.optional<Map<String, dynamic>>('refunds_needed')?.optional<int>('count') ?? 0,
        refundsNeededAmount: _money(money.field<Map<String, dynamic>>('refunds_needed'), 'amount'),
      ),
      null => null,
    },
    owed: switch (json.optional<Map<String, dynamic>>('owed')) {
      final owed? => DeskOwed(total: _money(owed, 'total'), members: owed.optional<int>('members') ?? 0),
      null => null,
    },
  );
}

final numbersRepositoryProvider = Provider<NumbersRepository>(
  (ref) => NumbersRepository(ref.watch(apiClientProvider), () => ref.read(deskSessionProvider)),
);

/// The period and whether to look at every branch, as chosen on the page.
typedef NumbersQuery = ({NumbersPeriod period, bool allBranches});

/// The figures for [NumbersQuery], ending today on the phone (the gym's day
/// in Addis), at the desk's branch unless every branch is asked for.
final numbersProvider = FutureProvider.autoDispose.family<DeskNumbers, NumbersQuery>((ref, query) {
  final session = ref.watch(deskSessionProvider);
  final today = LocalDate.of(ref.read(clockProvider)());
  final branchId = query.allBranches ? null : (session is DeskSignedIn ? session.branch?.id : null);
  return ref
      .watch(numbersRepositoryProvider)
      .load(from: today.addDays(1 - query.period.days), to: today, branchId: branchId);
});
