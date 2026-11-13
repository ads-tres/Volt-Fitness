import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/localization/l10n.dart';
import '../../../core/desk_session.dart';
import 'desk_menu.dart';

/// The front desk's top bar: the app, where this desk is, and its menu.
class DeskAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const DeskAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) => AppBar(
    title: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(context.l10n.deskTitle),
        Text(deskPlace(ref.watch(deskSessionProvider)), style: Theme.of(context).textTheme.bodySmall),
      ],
    ),
    actions: const [DeskMenu()],
  );
}
