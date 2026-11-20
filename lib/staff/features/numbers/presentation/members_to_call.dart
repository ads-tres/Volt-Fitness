import 'package:material_ui/material_ui.dart';

import '../domain/desk_numbers.dart';

/// The members to call. Filled in with the list next.
class MembersToCall extends StatelessWidget {
  const MembersToCall({super.key, required this.members});

  final List<MemberToCall> members;

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
