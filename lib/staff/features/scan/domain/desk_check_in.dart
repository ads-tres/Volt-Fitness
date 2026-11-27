import '../../../../core/money/money.dart';
import '../../../../core/network/json.dart';
import '../../../../core/time/local_date.dart';

/// A check-in at the desk, as the API decided it: let in or turned away,
/// with who it was and their membership, when the API knows them.
final class DeskCheckIn {
  const DeskCheckIn({
    required this.id,
    required this.letIn,
    required this.checkedInAt,
    this.reasonCode,
    this.memberId,
    this.memberName,
    this.memberPhone,
    this.planName,
    this.endsOn,
    this.balanceDue,
    this.branchName,
    this.memberPhotoUrl,
    this.offline = false,
    this.serverDisagrees = false,
    this.serverReasonCode,
  });

  final int id;
  final bool letIn;

  /// Why the member was turned away, such as `CODE_EXPIRED`.
  final String? reasonCode;

  /// In UTC; shown in the phone's timezone.
  final DateTime checkedInAt;
  final int? memberId;
  final String? memberName;
  final String? memberPhone;

  /// The member's photo, for the desk to see it's them; a link that works
  /// for 10 minutes.
  final String? memberPhotoUrl;
  final String? planName;
  final LocalDate? endsOn;

  /// What the member still owes. It never stops entry; the desk asks for it.
  final Money? balanceDue;
  final String? branchName;

  /// Decided at the door from the door list, without internet.
  final bool offline;

  /// The server, deciding again for that moment, would have answered
  /// [serverReasonCode] (or let them in); staff review it in the panel.
  final bool serverDisagrees;
  final String? serverReasonCode;

  bool get owes => (balanceDue?.amountMinor ?? 0) > 0;
}

/// A check-in from the staff API (`check-ins/scan`, `members/{id}/check-ins`
/// and `GET check-ins`).
DeskCheckIn deskCheckInFromJson(Map<String, dynamic> json) {
  final member = json.optional<Map<String, dynamic>>('member');
  final membership = json.optional<Map<String, dynamic>>('membership');
  return DeskCheckIn(
    id: json.field<int>('id'),
    letIn: json.optional<String>('decision') == 'allow',
    reasonCode: json.optional<String>('reason_code'),
    checkedInAt: DateTime.parse(json.field<String>('checked_in_at')).toUtc(),
    offline: json.optional<bool>('offline') ?? false,
    serverDisagrees: json.optional<bool>('server_disagrees') ?? false,
    serverReasonCode: json.optional<String>('server_reason_code'),
    memberId: member?.optional<int>('id'),
    memberName: member?.optional<String>('full_name'),
    memberPhone: member?.optional<String>('phone'),
    memberPhotoUrl: member?.optional<String>('photo_url'),
    planName: membership?.optional<Map<String, dynamic>>('plan')?.optional<String>('name'),
    endsOn: switch (membership?.optional<String>('ends_on')) {
      final iso? => LocalDate.parse(iso),
      null => null,
    },
    balanceDue: switch (membership?.optional<Map<String, dynamic>>('balance_due')) {
      final money? => Money.fromJson(money),
      null => null,
    },
    branchName: json.optional<Map<String, dynamic>>('branch')?.optional<String>('name'),
  );
}
