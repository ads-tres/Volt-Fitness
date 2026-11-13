import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/localization/l10n.dart';
import '../../../core/desk_session.dart';
import '../../auth/data/desk_auth_repository.dart';

/// The branch this desk is at, and the menu to change it or sign out.
class DeskMenu extends ConsumerWidget {
  const DeskMenu({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return PopupMenuButton<String>(
      tooltip: l10n.deskMenu,
      onSelected: (choice) async {
        switch (choice) {
          case 'branch':
            await ref.read(deskSessionProvider.notifier).chooseAgain();
          case 'sign-out':
            // The token is revoked on the server when it can be; the desk
            // signs out either way.
            try {
              await ref.read(deskAuthRepositoryProvider).signOut();
            } on Failure {
              // Revoked at the next sign-in instead.
            }
            unawaited(ref.read(deskSessionProvider.notifier).signOut());
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(value: 'branch', child: Text(l10n.deskChangeBranch)),
        PopupMenuItem(value: 'sign-out', child: Text(l10n.signOut)),
      ],
    );
  }
}

/// "Bole Branch · Demo Gym", for the top bar.
String deskPlace(DeskSession session) => switch (session) {
  DeskSignedIn(gym: final gym?, branch: final branch?) => '${branch.name} · ${gym.name}',
  _ => '',
};
