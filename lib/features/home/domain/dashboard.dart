import '../../attendance/domain/visit.dart';
import '../../membership/domain/membership.dart';
import '../../payments/domain/billing.dart';

/// Everything the home screen shows, from one call (`GET /me/dashboard`).
final class Dashboard {
  const Dashboard({this.membership, this.recentVisits = const [], this.outstanding});

  /// Null when the member has no plan at this gym.
  final Membership? membership;
  final List<Visit> recentVisits;

  /// The unpaid invoice to point at, if any.
  final OutstandingInvoice? outstanding;
}
