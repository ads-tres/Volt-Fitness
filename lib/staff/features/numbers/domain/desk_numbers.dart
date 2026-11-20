import '../../../../core/money/money.dart';
import '../../../../core/time/local_date.dart';

/// The gym's figures for a period, from the staff dashboard. Money and
/// what is owed are null for roles that don't see money: the API leaves
/// them out, and the desk shows what it gets.
final class DeskNumbers {
  const DeskNumbers({
    required this.from,
    required this.to,
    required this.letIn,
    required this.turnedAway,
    required this.turnedAwayByReason,
    required this.activeMembers,
    required this.newMembers,
    required this.soldAtTheDesk,
    required this.soldInTheApp,
    required this.checkInsByHour,
    required this.toCall,
    this.money,
    this.owed,
  });

  final LocalDate from;
  final LocalDate to;
  final int letIn;
  final int turnedAway;

  /// Reason code to how many, most first.
  final List<(String, int)> turnedAwayByReason;
  final int activeMembers;
  final int newMembers;
  final int soldAtTheDesk;
  final int soldInTheApp;

  /// Let in during each of the gym's 24 hours, 0 to 23.
  final List<int> checkInsByHour;
  final List<MemberToCall> toCall;
  final DeskMoney? money;
  final DeskOwed? owed;
}

final class DeskMoney {
  const DeskMoney({
    required this.received,
    required this.refunded,
    required this.net,
    required this.byMethod,
    required this.openLinks,
    required this.openLinksAmount,
    required this.refundsNeeded,
    required this.refundsNeededAmount,
  });

  final Money received;
  final Money refunded;
  final Money net;

  /// Payment method, such as `telebirr`, to what came in that way.
  final Map<String, Money> byMethod;
  final int openLinks;
  final Money openLinksAmount;
  final int refundsNeeded;
  final Money refundsNeededAmount;
}

final class DeskOwed {
  const DeskOwed({required this.total, required this.members});

  final Money total;
  final int members;
}

/// A member whose plan ends soon or whose visit pack is nearly used.
final class MemberToCall {
  const MemberToCall({
    required this.name,
    required this.phone,
    required this.planName,
    required this.endsOn,
    this.visitsLeft,
    this.balanceDue,
  });

  final String name;

  /// E.164, for dialing.
  final String phone;
  final String planName;
  final LocalDate endsOn;
  final int? visitsLeft;

  /// What they owe; null when the staff member doesn't see money.
  final Money? balanceDue;
}

/// How far back the desk looks: today, or the last 7 or 30 days.
enum NumbersPeriod {
  today(1),
  week(7),
  month(30);

  const NumbersPeriod(this.days);

  final int days;
}
