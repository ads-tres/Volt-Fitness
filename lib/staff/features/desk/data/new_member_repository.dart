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

  /// As `POST members` takes it, at the desk's branch. An Ethiopian mobile is
  /// sent as E.164; anything else as typed, for the API to judge.
  Map<String, Object?> toApi(int homeBranchId) {
    String? optional(String value) => value.trim().isEmpty ? null : value.trim();
    String phoneOf(String typed) => EthiopianPhone.normalize(typed) ?? typed.trim();
    return {
      'full_name': fullName.trim(),
      'phone': phoneOf(phone),
      'home_branch_id': homeBranchId,
      'gender': ?gender,
      'date_of_birth': ?dateOfBirth?.toIso(),
      'email': ?optional(email),
      'message_language': ?messageLanguage,
      'emergency_contact_name': ?optional(emergencyContactName),
      'emergency_contact_phone': ?(optional(emergencyContactPhone) == null ? null : phoneOf(emergencyContactPhone)),
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
}

final newMemberRepositoryProvider = Provider<NewMemberRepository>(
  (ref) => NewMemberRepository(ref.watch(apiClientProvider), () => ref.read(deskSessionProvider)),
);

/// Owners, managers and receptionists add members; accountants don't.
final mayAddMembersProvider = Provider<bool>(
  (ref) => switch (ref.watch(deskSessionProvider)) {
    DeskSignedIn(gym: final gym?) => const {'owner', 'manager', 'receptionist'}.contains(gym.role),
    _ => false,
  },
);
