import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/localization/l10n.dart';
import '../../../app/staff_routes.dart';
import '../../../core/desk_session.dart';
import '../../messages/data/staff_inbox.dart';
import '../data/scan_outbox.dart';
import 'check_in_result.dart';
import 'desk_menu.dart';

/// The front desk's top bar: the app, where this desk is, how many scans
/// wait for the internet (tap for Today), the messages bell, and its menu.
class DeskAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const DeskAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final waiting = ref.watch(scanOutboxProvider.select((outbox) => outbox.pending.length));
    final unread = ref.watch(staffInboxProvider.select((inbox) => inbox.unreadCount));
    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.l10n.deskTitle),
          Text(deskPlace(ref.watch(deskSessionProvider)), style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
      actions: [
        if (waiting > 0)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: ActionChip(
              key: const Key('waiting-scans'),
              avatar: const Icon(Icons.cloud_off_rounded, size: 18, color: Colors.white),
              label: Text(context.l10n.deskWaitingBadge(waiting)),
              labelStyle: Theme.of(context).textTheme.labelMedium?.copyWith(color: Colors.white),
              backgroundColor: SavedOfflineView.color,
              side: BorderSide.none,
              onPressed: () => context.go(StaffRoutes.today),
            ),
          ),
        IconButton(
          key: const Key('messages'),
          tooltip: context.l10n.deskInboxTitle,
          onPressed: () => context.push(StaffRoutes.inbox),
          icon: Badge.count(
            count: unread,
            isLabelVisible: unread > 0,
            child: const Icon(Icons.notifications_none_rounded),
          ),
        ),
        const DeskMenu(),
      ],
    );
  }
}
