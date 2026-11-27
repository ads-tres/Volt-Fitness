import 'dart:convert';

import '../../../../core/network/json.dart';

/// What the membership allows a member on one of the gym's dates.
final class DoorDay {
  const DoorDay({required this.allowed, this.reasonCode, this.planName, this.branchIds, this.visitsLeft});

  final bool allowed;

  /// Why not: `MEMBERSHIP_NONE`, `MEMBERSHIP_EXPIRED` or `MEMBERSHIP_FROZEN`.
  final String? reasonCode;
  final String? planName;

  /// The branches it is valid at; null for every branch.
  final List<int>? branchIds;

  /// Visits left on a pack; null without a limit.
  final int? visitsLeft;
}

/// One active QR credential: the day keys to check its codes with, never
/// the secret, and what its member may do each date.
final class DoorCredential {
  const DoorCredential({
    required this.id,
    required this.lastUsedStep,
    required this.dayKeys,
    required this.memberId,
    required this.memberName,
    required this.days,
    this.photoUrl,
  });

  /// As in the code, upper case.
  final String id;
  final int? lastUsedStep;

  /// By UTC day number.
  final Map<int, List<int>> dayKeys;
  final int memberId;
  final String memberName;
  final String? photoUrl;

  /// By the gym's date, `YYYY-MM-DD`.
  final Map<String, DoorDay> days;
}

/// A branch's hours on a date, minutes after midnight; closing before
/// opening runs past midnight into the next date.
typedef DoorHours = ({int opensAt, int closesAt});

/// The signed list the desk downloads to let members in without internet
/// (the API's ADR 0038): the gym's active credentials with today's and
/// tomorrow's day keys, what each member may do on each date, and each
/// branch's hours by date.
final class DoorList {
  const DoorList({
    required this.gymSlug,
    required this.generatedAt,
    required this.validUntil,
    required this.credentials,
    required this.hours,
  });

  final String gymSlug;
  final DateTime generatedAt;
  final DateTime validUntil;

  /// By credential id, upper case.
  final Map<String, DoorCredential> credentials;

  /// Branch id to the gym's date to its hours, null when closed that date.
  final Map<int, Map<String, DoorHours?>> hours;

  bool isValidAt(DateTime now) => now.isBefore(validUntil);

  /// Reads the list's JSON text, as signed.
  static DoorList parse(String text) {
    final json = jsonDecode(text) as Map<String, dynamic>;
    int minutes(String time) {
      final [hours, minutes, ...] = time.split(':');
      return int.parse(hours) * 60 + int.parse(minutes);
    }

    return DoorList(
      gymSlug: json.field<Map<String, dynamic>>('gym').field<String>('slug'),
      generatedAt: DateTime.parse(json.field<String>('generated_at')).toUtc(),
      validUntil: DateTime.parse(json.field<String>('valid_until')).toUtc(),
      hours: {
        for (final branch in json.objects('branches'))
          branch.field<int>('id'): {
            for (final MapEntry(:key, :value) in (branch.optional<Map<String, dynamic>>('hours') ?? const {}).entries)
              key: value is Map<String, dynamic>
                  ? (opensAt: minutes(value.field<String>('opens_at')), closesAt: minutes(value.field<String>('closes_at')))
                  : null,
          },
      },
      credentials: {
        for (final credential in json.objects('credentials'))
          credential.field<String>('id').toUpperCase(): DoorCredential(
            id: credential.field<String>('id').toUpperCase(),
            lastUsedStep: credential.optional<int>('last_used_step'),
            dayKeys: {
              for (final MapEntry(:key, :value) in (credential.optional<Map<String, dynamic>>('day_keys') ?? const {}).entries)
                if (value is String) int.parse(key): base64.decode(value),
            },
            memberId: credential.field<Map<String, dynamic>>('member').field<int>('id'),
            memberName: credential.field<Map<String, dynamic>>('member').field<String>('full_name'),
            photoUrl: credential.field<Map<String, dynamic>>('member').optional<String>('photo_url'),
            days: {
              for (final MapEntry(:key, :value) in (credential.optional<Map<String, dynamic>>('days') ?? const {}).entries)
                if (value is Map<String, dynamic>)
                  key: DoorDay(
                    allowed: value.optional<bool>('allowed') ?? false,
                    reasonCode: value.optional<String>('reason_code'),
                    planName: value.optional<Map<String, dynamic>>('membership')?.optional<String>('plan'),
                    branchIds: switch (value.optional<List<dynamic>>('branch_ids')) {
                      final ids? => [for (final id in ids) if (id is int) id],
                      null => null,
                    },
                    visitsLeft: value.optional<int>('visits_left'),
                  ),
            },
          ),
      },
    );
  }
}
