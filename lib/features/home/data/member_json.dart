import '../../../core/network/json.dart';
import '../../../core/time/local_date.dart';
import '../../attendance/domain/visit.dart';
import '../../membership/domain/membership.dart';
import '../../payments/data/billing_json.dart';
import '../domain/dashboard.dart';

/// Reads the member-core shapes from the API. Unknown enum values become
/// `unknown` rather than failing, so the API can add values safely.
///
/// What is owed comes from the membership's balance, or from the one that
/// follows it.
Dashboard dashboardFromJson(Map<String, dynamic> json) {
  final membership = json.optional<Map<String, dynamic>>('membership');
  return Dashboard(
    membership: membership == null ? null : membershipFromJson(membership),
    recentVisits: [for (final visit in json.objects('recent_check_ins')) visitFromJson(visit)],
    outstanding:
        outstandingFromMembership(membership) ?? outstandingFromMembership(json.optional<Map<String, dynamic>>('next_membership')),
  );
}

/// A membership as the API sends it. A membership valid at every branch
/// lists none: the app shows branches only when it is limited to some.
Membership membershipFromJson(Map<String, dynamic> json) => Membership(
  id: '${json.field<Object>('id')}',
  planName: json.field<Map<String, dynamic>>('plan').field<String>('name'),
  status: switch (json.optional<String>('status')) {
    'upcoming' => MembershipStatus.pending,
    final status => _enum(MembershipStatus.values, status, MembershipStatus.unknown),
  },
  startsOn: LocalDate.parse(json.field<String>('starts_on')),
  endsOn: LocalDate.parse(json.field<String>('ends_on')),
  frozenUntil: _date(json.optional<String>('frozen_until')),
  allowedBranches: json.optional<bool>('valid_at_all_branches') == false
      ? [for (final branch in json.objects('branches')) branchFromJson(branch)]
      : const [],
  visitsRemaining: json.optional<int>('visits_remaining'),
);

Branch branchFromJson(Map<String, dynamic> json) => Branch(
  id: '${json.field<Object>('id')}',
  name: json.field<String>('name'),
  photoUrl: json.optional<String>('photo_url'),
);

/// A check-in: `allow` let the member in, `deny` turned them away.
Visit visitFromJson(Map<String, dynamic> json) => Visit(
  id: '${json.field<Object>('id')}',
  checkedInAt: DateTime.parse(json.field<String>('checked_in_at')).toUtc(),
  branch: branchFromJson(json.field<Map<String, dynamic>>('branch')),
  result: switch (json.optional<String>('decision')) {
    'allow' => VisitResult.allowed,
    'deny' => VisitResult.denied,
    _ => VisitResult.unknown,
  },
  reasonCode: json.optional<String>('reason_code'),
);

LocalDate? _date(String? iso) => iso == null ? null : LocalDate.parse(iso);

T _enum<T extends Enum>(List<T> values, String? name, T unknown) =>
    values.where((value) => value.name == name).firstOrNull ?? unknown;
