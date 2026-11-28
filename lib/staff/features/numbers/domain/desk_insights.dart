import '../../../../core/money/money.dart';
import '../../../../core/network/json.dart';

/// Money taken in one month, net of refunds (the API's ADR 0040).
final class RevenueMonth {
  const RevenueMonth({required this.month, required this.net, this.byPlan = const {}, this.byMethod = const {}});

  /// The month's first day.
  final DateTime month;
  final Money net;
  final Map<String, Money> byPlan;

  /// By the API's method names: `cash`, `telebirr`, `brought_in`, …
  final Map<String, Money> byMethod;
}

/// Memberships that ended in one month, and whether their members came back.
final class RenewalMonth {
  const RenewalMonth({
    required this.month,
    required this.renewed,
    required this.lapsed,
    required this.waiting,
    this.rate,
    this.byPlan = const {},
  });

  final DateTime month;

  /// A new plan within 14 days of the end.
  final int renewed;
  final int lapsed;

  /// Ended under 14 days ago, so not decided yet.
  final int waiting;

  /// Renewed among those decided, 0 to 1; null when none is decided.
  final double? rate;

  /// Per plan: renewed, lapsed and waiting.
  final Map<String, ({int renewed, int lapsed, int waiting})> byPlan;

  int get ended => renewed + lapsed + waiting;
}

/// Check-ins that let members in, by weekday and hour.
final class BusyHours {
  const BusyHours({required this.grid, required this.total});

  /// Seven rows, Monday first, of 24 counts each.
  final List<List<int>> grid;
  final int total;

  /// The busiest weekday (1 is Monday) and hour, or null with no check-ins.
  ({int weekday, int hour, int count})? get busiest {
    ({int weekday, int hour, int count})? best;
    for (final (day, row) in grid.indexed) {
      for (final (hour, count) in row.indexed) {
        if (count > 0 && (best == null || count > best.count)) best = (weekday: day + 1, hour: hour, count: count);
      }
    }
    return best;
  }
}

/// Members at one month's end, and the visit packs that ended in it.
final class MembersMonth {
  const MembersMonth({
    required this.month,
    required this.active,
    required this.newMembers,
    required this.packsEnded,
    required this.visitsBought,
    required this.visitsUsed,
    required this.packsWithVisitsLeft,
  });

  final DateTime month;
  final int active;
  final int newMembers;
  final int packsEnded;
  final int visitsBought;
  final int visitsUsed;
  final int packsWithVisitsLeft;
}

DateTime _month(String yearMonth) => DateTime.parse('$yearMonth-01');

Map<String, Money> _moneyBy(Map<String, dynamic>? json) => {
  for (final MapEntry(:key, :value) in (json ?? const {}).entries)
    if (value is Map<String, dynamic>) key: Money.fromJson(value),
};

/// The API's `months` list; it replaces the count for these insights.
List<Map<String, dynamic>> _months(Map<String, dynamic> data) => data.objects('months');

List<RevenueMonth> revenueFromJson(Map<String, dynamic> data) => [
  for (final month in _months(data))
    RevenueMonth(
      month: _month(month.field<String>('month')),
      net: Money.fromJson(month.field<Map<String, dynamic>>('net')),
      byPlan: _moneyBy(month.optional<Map<String, dynamic>>('by_plan')),
      byMethod: _moneyBy(month.optional<Map<String, dynamic>>('by_method')),
    ),
];

List<RenewalMonth> renewalsFromJson(Map<String, dynamic> data) => [
  for (final month in _months(data))
    RenewalMonth(
      month: _month(month.field<String>('month')),
      renewed: month.optional<int>('renewed') ?? 0,
      lapsed: month.optional<int>('lapsed') ?? 0,
      waiting: month.optional<int>('waiting') ?? 0,
      rate: month.optional<num>('rate')?.toDouble(),
      byPlan: {
        for (final MapEntry(:key, :value) in (month.optional<Map<String, dynamic>>('by_plan') ?? const {}).entries)
          if (value is Map<String, dynamic>)
            key: (
              renewed: value.optional<int>('renewed') ?? 0,
              lapsed: value.optional<int>('lapsed') ?? 0,
              waiting: value.optional<int>('waiting') ?? 0,
            ),
      },
    ),
];

/// The grid comes keyed "1" (Monday) to "7"; a day left out had none.
BusyHours busyHoursFromJson(Map<String, dynamic> data) {
  final grid = data.optional<Map<String, dynamic>>('grid') ?? const {};
  return BusyHours(
    grid: [
      for (var weekday = 1; weekday <= 7; weekday++)
        switch (grid['$weekday']) {
          final List<dynamic> hours when hours.length == 24 => [for (final count in hours) count is int ? count : 0],
          _ => List<int>.filled(24, 0),
        },
    ],
    total: data.optional<int>('total') ?? 0,
  );
}

List<MembersMonth> membersFromJson(Map<String, dynamic> data) => [
  for (final month in _months(data))
    MembersMonth(
      month: _month(month.field<String>('month')),
      active: month.optional<int>('active') ?? 0,
      newMembers: month.optional<int>('new') ?? 0,
      packsEnded: month.optional<int>('packs_ended') ?? 0,
      visitsBought: month.optional<int>('visits_bought') ?? 0,
      visitsUsed: month.optional<int>('visits_used') ?? 0,
      packsWithVisitsLeft: month.optional<int>('packs_with_visits_left') ?? 0,
    ),
];
