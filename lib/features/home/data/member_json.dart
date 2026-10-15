import '../../../core/network/json.dart';
import '../../../core/time/local_date.dart';
import '../../attendance/domain/visit.dart';
import '../../membership/domain/membership.dart';
import '../domain/dashboard.dart';

/// Reads the member-core shapes from the API. Unknown enum values become
/// `unknown` rather than failing, so the API can add values safely.
Dashboard dashboardFromJson(Map<String, dynamic> json) => Dashboard(
  membership: switch (json.optional<Map<String, dynamic>>('membership')) {
    final membership? => membershipFromJson(membership),
    null => null,
  },
  recentVisits: [for (final visit in json.objects('recent_attendance')) visitFromJson(visit)],
);

Membership membershipFromJson(Map<String, dynamic> json) => Membership(
  id: json.field<String>('id'),
  planName: json.field<String>('plan_name'),
  status: _enum(MembershipStatus.values, json.optional<String>('status'), MembershipStatus.unknown),
  startsOn: LocalDate.parse(json.field<String>('starts_on')),
  endsOn: LocalDate.parse(json.field<String>('ends_on')),
  graceEndsOn: _date(json.optional<String>('grace_ends_on')),
  frozenUntil: _date(json.optional<String>('frozen_until')),
  allowedBranches: [for (final branch in json.objects('allowed_branches')) branchFromJson(branch)],
  visitsRemaining: json.optional<int>('visits_remaining'),
);

Branch branchFromJson(Map<String, dynamic> json) => Branch(
  id: json.field<String>('id'),
  name: json.field<String>('name'),
  photoUrl: json.optional<String>('photo_url'),
);

Visit visitFromJson(Map<String, dynamic> json) => Visit(
  id: json.field<String>('id'),
  checkedInAt: DateTime.parse(json.field<String>('checked_in_at')).toUtc(),
  branch: branchFromJson(json.field<Map<String, dynamic>>('branch')),
  result: _enum(VisitResult.values, json.optional<String>('result'), VisitResult.unknown),
  reasonCode: json.optional<String>('reason_code'),
);

LocalDate? _date(String? iso) => iso == null ? null : LocalDate.parse(iso);

T _enum<T extends Enum>(List<T> values, String? name, T unknown) =>
    values.where((value) => value.name == name).firstOrNull ?? unknown;
