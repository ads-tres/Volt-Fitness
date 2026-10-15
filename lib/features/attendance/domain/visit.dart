import '../../membership/domain/membership.dart';

enum VisitResult { allowed, denied, unknown }

/// One scan at the front desk.
final class Visit {
  const Visit({required this.id, required this.checkedInAt, required this.branch, required this.result, this.reasonCode});

  final String id;

  /// In UTC; shown in the phone's timezone.
  final DateTime checkedInAt;
  final Branch branch;
  final VisitResult result;

  /// Why a scan was denied, such as `OUTSIDE_ALLOWED_HOURS`.
  final String? reasonCode;
}

/// One page of the visit history, with the cursor for the next.
final class VisitPage {
  const VisitPage({required this.visits, this.nextCursor});

  final List<Visit> visits;
  final String? nextCursor;
}
