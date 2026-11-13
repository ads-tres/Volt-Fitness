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
    this.freezeDaysAllowed = 0,
    this.freezeDaysLeft = 0,
    this.freezes = const [],
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

  /// Days the plan lets the member freeze, and how many are still unused.
  final int freezeDaysAllowed;
  final int freezeDaysLeft;

  /// Every freeze on this membership, past and coming.
  final List<MembershipFreeze> freezes;

  /// Days from [today] to the last day, 0 on the last day itself.
  int daysLeft(LocalDate today) => max(0, today.daysUntil(endsOn));

  int get totalDays => max(1, startsOn.daysUntil(endsOn));

  /// How much of the plan is left, from 1 (just started) to 0.
  double shareLeft(LocalDate today) => (daysLeft(today) / totalDays).clamp(0, 1).toDouble();

  /// The member can freeze while the plan runs or before it starts, if any
  /// freeze days are left. The API checks the dates.
  bool get canFreeze =>
      freezeDaysLeft > 0 && (status == MembershipStatus.active || status == MembershipStatus.pending);

  /// The freeze covering [today], or else the next one to come.
  MembershipFreeze? currentOrNextFreeze(LocalDate today) {
    final coming = [for (final freeze in freezes) if (freeze.endsOn.compareTo(today) >= 0) freeze]
      ..sort((a, b) => a.startsOn.compareTo(b.startsOn));
    return coming.firstOrNull;
  }

  bool endsSoon(LocalDate today) => status == MembershipStatus.active && daysLeft(today) <= endsSoonDays;
}

/// A stretch of days the membership is paused, both days included. Its
/// days are added to the membership's end date.
final class MembershipFreeze {
  const MembershipFreeze({required this.id, required this.startsOn, required this.endsOn, required this.days});

  final String id;
  final LocalDate startsOn;
  final LocalDate endsOn;
  final int days;

  /// It started on or before [today], so ending it keeps the days used.
  bool hasStarted(LocalDate today) => startsOn.compareTo(today) <= 0;
}
