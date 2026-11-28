import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/config/env.dart';
import '../../../../core/design/tokens.dart';
import '../../../../core/design/widgets/feedback.dart';
import '../../../../core/localization/l10n.dart';
import '../../../core/desk_session.dart';
import '../data/staff_inbox.dart';
import '../domain/staff_message.dart';

/// The staff member's messages at this gym, newest first; unread ones in
/// bold. Opening one shows it in full and marks it read.
class InboxPage extends ConsumerStatefulWidget {
  const InboxPage({super.key});

  @override
  ConsumerState<InboxPage> createState() => _InboxPageState();
}

class _InboxPageState extends ConsumerState<InboxPage> {
  @override
  void initState() {
    super.initState();
    unawaited(Future.microtask(ref.read(staffInboxProvider.notifier).refresh));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final state = ref.watch(staffInboxProvider);
    final inbox = ref.read(staffInboxProvider.notifier);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.deskInboxTitle),
        actions: [
          if (state.unreadCount > 0)
            // An icon, as in the member app: the words don't fit the top
            // bar in Amharic.
            IconButton(
              onPressed: inbox.markAllRead,
              tooltip: l10n.deskMarkAllRead,
              color: AppColors.ink,
              icon: const Icon(Icons.done_all_rounded),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: inbox.refresh,
        child: NotificationListener<ScrollEndNotification>(
          onNotification: (notification) {
            if (notification.metrics.extentAfter < 200) unawaited(inbox.loadMore());
            return false;
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              if (state.messages.isEmpty && !state.isLoading && state.failure == null)
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(l10n.deskInboxEmpty, textAlign: TextAlign.center, style: textTheme.bodyMedium),
                ),
              for (final message in state.messages)
                ListTile(
                  leading: Icon(
                    message.isRead ? Icons.mark_email_read_outlined : Icons.mark_email_unread_rounded,
                    color: message.isRead ? AppColors.textTertiary : AppColors.ink,
                  ),
                  title: Text(
                    message.title,
                    style: textTheme.titleSmall?.copyWith(fontWeight: message.isRead ? FontWeight.w400 : FontWeight.w700),
                  ),
                  subtitle: Text(message.body, maxLines: 2, overflow: TextOverflow.ellipsis),
                  trailing: Text(messageTime(message.createdAt), style: textTheme.bodySmall),
                  onTap: () => showStaffMessage(context, message),
                ),
              if (state.failure case final failure?) LoadFailedCard(failure: failure, onRetry: inbox.refresh),
              if (state.isLoading)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator(strokeWidth: 2.4, color: AppColors.ink)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The time today, or the date for older messages.
String messageTime(DateTime at) {
  final local = at.toLocal();
  final now = DateTime.now();
  final today = local.year == now.year && local.month == now.month && local.day == now.day;
  return today ? DateFormat.Hm().format(local) : DateFormat.MMMd().format(local);
}

/// Shows [message] in full and marks it read. Members to call live in the
/// staff panel, so that one links there.
Future<void> showStaffMessage(BuildContext context, StaffMessage message) {
  final container = ProviderScope.containerOf(context, listen: false);
  unawaited(container.read(staffInboxProvider.notifier).markRead(message.id));
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    backgroundColor: AppColors.surface,
    builder: (context) => _MessageSheet(message: message),
  );
}

class _MessageSheet extends ConsumerWidget {
  const _MessageSheet({required this.message});

  final StaffMessage message;

  /// The gym's staff panel: the site the API is on, at `/staff/{gym}`.
  Uri? _panel(WidgetRef ref) {
    final gym = switch (ref.read(deskSessionProvider)) {
      DeskSignedIn(gym: final gym?) => gym.slug,
      _ => null,
    };
    if (gym == null) return null;
    final api = Uri.parse(ref.read(envProvider).apiBaseUrl);
    return api.replace(path: '/staff/${Uri.encodeComponent(gym)}', query: null);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final panel = message.type == StaffMessage.membersToCall ? _panel(ref) : null;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(message.title, style: textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(
              DateFormat.yMMMd().add_Hm().format(message.createdAt.toLocal()),
              style: textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            Text(message.body, style: textTheme.bodyLarge),
            if (panel != null) ...[
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: () => unawaited(launchUrl(panel, mode: LaunchMode.externalApplication)),
                icon: const Icon(Icons.open_in_new_rounded),
                label: Text(l10n.deskOpenPanel),
                style: OutlinedButton.styleFrom(foregroundColor: AppColors.ink, minimumSize: const Size.fromHeight(48)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
