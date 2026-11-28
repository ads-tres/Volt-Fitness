import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/json.dart';
import '../../../../core/time/local_date.dart';
import '../../../../core/utils/ethiopian_phone.dart';
import '../../../core/desk_session.dart';
import 'member_search.dart';

/// Someone joining at the desk, as typed.
final class NewMember {
  const NewMember({
    required this.fullName,
    required this.phone,
    this.gender,
    this.dateOfBirth,
    this.email = '',
    this.messageLanguage,
    this.emergencyContactName = '',
    this.emergencyContactPhone = '',
  });

  final String fullName;
  final String phone;

  /// `female` or `male`.
  final String? gender;
  final LocalDate? dateOfBirth;
  final String email;

  /// `en` or `am`: the language of their texts and pushes.
  final String? messageLanguage;
  final String emergencyContactName;
  final String emergencyContactPhone;

  /// As `POST members` takes it, at [homeBranchId]. An Ethiopian mobile is
  /// sent as E.164; anything else as typed, for the API to judge. With
  /// [everyField], as `PUT members/{id}` takes it: a field left empty is
  /// sent as null, which clears it.
  Map<String, Object?> toApi(int homeBranchId, {bool everyField = false}) {
    String? optional(String value) => value.trim().isEmpty ? null : value.trim();
    String phoneOf(String typed) => EthiopianPhone.normalize(typed) ?? typed.trim();
    final optionalFields = <String, Object?>{
      'gender': gender,
      'date_of_birth': dateOfBirth?.toIso(),
      'email': optional(email),
      'message_language': messageLanguage,
      'emergency_contact_name': optional(emergencyContactName),
      'emergency_contact_phone': optional(emergencyContactPhone) == null ? null : phoneOf(emergencyContactPhone),
    };
    return {
      'full_name': fullName.trim(),
      'phone': phoneOf(phone),
      'home_branch_id': homeBranchId,
      for (final MapEntry(:key, :value) in optionalFields.entries)
        if (everyField || value != null) key: value,
    };
  }
}

/// Adding a member at the desk (`POST /organizations/{gym}/members`), with
/// the desk's branch as their home branch. Throws a [Failure]; the API's
/// refusals are [ValidationFailure]s on the field they are about.
final class NewMemberRepository {
  const NewMemberRepository(this._api, this._session);

  final ApiClient _api;
  final DeskSession Function() _session;

  Future<DeskMember> add(NewMember member) async {
    final session = _session();
    final branchId = switch (session) {
      DeskSignedIn(branch: final branch?) => branch.id,
      _ => throw StateError('No branch is chosen'),
    };
    final response = await _api.post(deskPath(session, '/members'), body: member.toApi(branchId));
    return readResponse(
      () => deskMemberFromJson((response! as Map<String, dynamic>).field<Map<String, dynamic>>('data')),
    );
  }

  /// Changes the member's details to [member] (`PUT members/{id}`), with
  /// [homeBranchId] as their home branch.
  Future<void> update(int memberId, NewMember member, {required int homeBranchId}) =>
      _api.put(deskPath(_session(), '/members/$memberId'), body: member.toApi(homeBranchId, everyField: true));
}

final newMemberRepositoryProvider = Provider<NewMemberRepository>(
  (ref) => NewMemberRepository(ref.watch(apiClientProvider), () => ref.read(deskSessionProvider)),
);

/// What the signed-in staff member's role lets them do at the desk, as the
/// API's policies allow: owners, managers and receptionists add members,
/// sell plans and freeze memberships; only owners and managers cancel one.
/// Accountants do none of these, and trainers don't see payments.
typedef DeskRoles = ({
  bool mayAddMembers,
  bool maySell,
  bool mayFreeze,
  bool mayCancel,
  bool maySeePayments,
  bool maySeeRevenueInsights,
  bool maySeeInsights,
});

final deskRolesProvider = Provider<DeskRoles>((ref) {
  final role = switch (ref.watch(deskSessionProvider)) {
    DeskSignedIn(gym: final gym?) => gym.role,
    _ => null,
  };
  final front = const {'owner', 'manager', 'receptionist'}.contains(role);
  return (
    mayAddMembers: front,
    maySell: front,
    mayFreeze: front,
    mayCancel: role == 'owner' || role == 'manager',
    // Everyone but trainers sees what members paid.
    maySeePayments: role != null && role != 'trainer',
    // The gym's money month by month goes to the roles that see its money;
    // the other insights to owners and managers (the API's ADR 0040).
    maySeeRevenueInsights: const {'owner', 'manager', 'accountant'}.contains(role),
    maySeeInsights: role == 'owner' || role == 'manager',
  );
});
