import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/routes.dart';
import '../../../core/design/tokens.dart';
import '../../../core/design/widgets/surfaces.dart';
import '../../../core/localization/l10n.dart';
import '../data/inbox_controller.dart';

/// The home header's way into the inbox, with the unread count.
class NotificationBell extends ConsumerWidget {
  const NotificationBell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(inboxProvider.select((state) => state.unreadCount));
    return HeaderButton(
      tooltip: context.l10n.notificationsTitle,
      onPressed: () => context.go(AppRoutes.notifications),
      child: Badge(
        isLabelVisible: unread > 0,
        backgroundColor: AppColors.danger,
        label: Text(unread > 9 ? '9+' : '$unread'),
        child: const Icon(Icons.notifications_none_rounded, color: AppColors.ink),
      ),
    );
  }
}
