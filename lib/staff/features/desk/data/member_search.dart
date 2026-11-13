import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/money/money.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/json.dart';
import '../../../core/desk_session.dart';

/// A member found at the desk, with their membership at a glance.
final class DeskMember {
  const DeskMember({required this.id, required this.name, required this.phone, this.planName, this.status, this.balanceDue});

  final int id;
  final String name;
  final String phone;
  final String? planName;

  /// `upcoming`, `active`, `frozen`, `expired` or `cancelled`.
  final String? status;
  final Money? balanceDue;
}

/// A member from the staff API (`GET /organizations/{gym}/members`).
DeskMember deskMemberFromJson(Map<String, dynamic> json) {
  final membership = json.optional<Map<String, dynamic>>('membership');
  return DeskMember(
    id: json.field<int>('id'),
    name: json.field<String>('full_name'),
    phone: json.field<String>('phone'),
    planName: membership?.optional<Map<String, dynamic>>('plan')?.optional<String>('name'),
    status: membership?.optional<String>('status'),
    balanceDue: switch (json.optional<Map<String, dynamic>>('balance_due')) {
      final money? => Money.fromJson(money),
      null => null,
    },
  );
}

/// The gym's members whose name contains, or whose phone has the digits
/// of, what was typed. Empty until something is typed.
final memberSearchProvider = FutureProvider.autoDispose.family<List<DeskMember>, String>((ref, typed) async {
  final search = typed.trim();
  if (search.length < 2) return const [];
  final response = await ref
      .watch(apiClientProvider)
      .get(deskPath(ref.read(deskSessionProvider), '/members'), query: {'search': search});
  return readResponse(
    () => [for (final member in (response! as Map<String, dynamic>).objects('data')) deskMemberFromJson(member)],
  );
});
