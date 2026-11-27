import 'package:material_ui/material_ui.dart';

import '../../../../core/localization/l10n.dart';
import '../data/member_search.dart';

/// Says [member] was added; [onChanged] refreshes search after a change.
Future<void> welcomeNewMember(BuildContext context, DeskMember member, {required VoidCallback onChanged}) async {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(context.l10n.newMemberAdded(member.name))));
}
