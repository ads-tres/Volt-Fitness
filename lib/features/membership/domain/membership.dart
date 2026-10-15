import 'dart:math';

import '../../../core/time/local_date.dart';

/// From the API; the app shows it and never works it out itself.
enum MembershipStatus { active, frozen, expired, pending, cancelled, unknown }

final class Branch {
  const Branch({required this.id, required this.name, this.photoUrl});

  final String id;
  final String name;
  final String? photoUrl;
}

/// The member's current plan at the selected gym.
final class Membership {
  const Membership({
    required this.id,
    required this.planName,
    required this.status,
    required this.startsOn,
    required this.endsOn,
    this.graceEndsOn,
    this.frozenUntil,
    this.allowedBranches = const [],
    this.visitsRemaining,
  });

  /// Shown as "ends soon" from this many days before the end.
  static const endsSoonDays = 5;

  final String id;
  final String planName;
  final MembershipStatus status;
  final LocalDate startsOn;

  /// The last day the plan covers.
  final LocalDate endsOn;

  /// After expiry, the gym may still let the member in until this day.
  final LocalDate? graceEndsOn;
  final LocalDate? frozenUntil;
  final List<Branch> allowedBranches;

  /// For visit packs; null for plans with unlimited visits.
  final int? visitsRemaining;

  /// Days from [today] to the last day, 0 on the last day itself.
  int daysLeft(LocalDate today) => max(0, today.daysUntil(endsOn));

  int get totalDays => max(1, startsOn.daysUntil(endsOn));

  /// How much of the plan is left, from 1 (just started) to 0.
  double shareLeft(LocalDate today) => (daysLeft(today) / totalDays).clamp(0, 1).toDouble();

  bool endsSoon(LocalDate today) => status == MembershipStatus.active && daysLeft(today) <= endsSoonDays;
}
