import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/design/brand.dart';
import '../../../core/design/tokens.dart';
import '../../../core/design/widgets/controls.dart';
import '../../../core/design/widgets/feedback.dart';
import '../../../core/design/widgets/surfaces.dart';
import '../../../core/errors/failure.dart';
import '../../../core/errors/failure_messages.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/time/clock.dart';
import '../../../core/time/date_text.dart';
import '../../../core/time/local_date.dart';
import '../../attendance/presentation/visit_card.dart';
import '../data/inbox_controller.dart';
import '../domain/app_notification.dart';
import 'notification_routes.dart';
import 'push_permission_card.dart';

/// Everything the gym and Volt told the member, newest first, grouped by
/// day. A tap opens what it is about; gym news opens in full.
class NotificationsPage extends ConsumerWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final state = ref.watch(inboxProvider);
    final dates = ref.watch(dateTextProvider);
    final today = ref.watch(todayProvider);
    final controller = ref.read(inboxProvider.notifier);

    // One row per day header or notification.
    final rows = <Object>[];
    LocalDate? previousDay;
    for (final notification in state.items) {
      final day = LocalDate.of(notification.createdAt.toLocal());
      if (day != previousDay) rows.add(day);
      rows.add(notification);
      previousDay = day;
    }

    return SoftBackground(
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: ScreenHeader(
                leading: HeaderButton(
                  tooltip: l10n.back,
                  onPressed: () => context.pop(),
                  child: const Icon(Icons.arrow_back_rounded, color: AppColors.ink),
                ),
                title: l10n.notificationsTitle,
                trailing: state.unreadCount > 0
                    ? HeaderButton(
                        tooltip: l10n.markAllRead,
                        onPressed: () => _markAllRead(context, ref),
                        child: const Icon(Icons.done_all_rounded, color: AppColors.ink),
                      )
                    : null,
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: controller.refresh,
                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                  itemCount: rows.length + 2,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return const PushPermissionCard(padding: EdgeInsets.only(bottom: 8));
                    }
                    if (index == rows.length + 1) return _Footer(state: state, onRetry: controller.loadMore);
                    if (index >= rows.length - 4 && !state.reachedEnd && !state.isLoading && state.failure == null) {
                      WidgetsBinding.instance.addPostFrameCallback((_) => controller.loadMore());
                    }
                    return switch (rows[index - 1]) {
                      final LocalDate day => Padding(
                        padding: EdgeInsets.only(top: index == 1 ? 4 : 18, bottom: 10),
                        child: Text(visitDayLabel(l10n, dates, day, today), style: textTheme.titleSmall),
                      ),
                      final AppNotification notification => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: NotificationTile(
                          notification: notification,
                          onTap: () => openNotification(context, ref, notification),
                        ),
                      ),
                      _ => const SizedBox.shrink(),
                    };
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _markAllRead(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(inboxProvider.notifier).markAllRead();
    } on Failure catch (failure) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(failureMessage(context.l10n, failure))));
    }
  }
}

/// Marks it read and opens what it is about, or shows it in full when it
/// points at nothing.
void openNotification(BuildContext context, WidgetRef ref, AppNotification notification) {
  unawaited(ref.read(inboxProvider.notifier).markRead(notification.id));
  switch (notificationRoute(notification.type, notification.data)) {
    case final route?:
      context.go(route);
    case null:
      unawaited(showNotificationSheet(context, notification));
  }
}

Future<void> showNotificationSheet(BuildContext context, AppNotification notification) => showModalBottomSheet<void>(
  context: context,
  showDragHandle: true,
  isScrollControlled: true,
  backgroundColor: AppColors.surface,
  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.card))),
  builder: (context) => _NotificationSheet(notification: notification),
);

class NotificationTile extends ConsumerWidget {
  const NotificationTile({super.key, required this.notification, required this.onTap});

  final AppNotification notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final brand = context.brand;
    final unread = !notification.isRead;
    return AppCard(
      padding: const EdgeInsets.all(14),
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TopicBadge(topic: notification.topic),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        notification.title,
                        style: textTheme.titleSmall?.copyWith(fontWeight: unread ? FontWeight.w700 : FontWeight.w500),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      ref.watch(dateTextProvider).time(notification.createdAt),
                      style: textTheme.bodySmall?.copyWith(color: AppColors.textTertiary),
                    ),
                  ],
                ),
                if (notification.body.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    notification.body,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodySmall?.copyWith(color: AppColors.textSecondary, height: 1.35),
                  ),
                ],
              ],
            ),
          ),
          if (unread)
            Semantics(
              label: context.l10n.unread,
              child: Container(
                width: 9,
                height: 9,
                margin: const EdgeInsets.only(left: 8, top: 6),
                decoration: BoxDecoration(color: brand.primary, shape: BoxShape.circle),
              ),
            ),
        ],
      ),
    );
  }
}

/// The topic's icon on a tint of the gym's colour.
class TopicBadge extends StatelessWidget {
  const TopicBadge({super.key, required this.topic, this.size = 42});

  final NotificationTopic? topic;
  final double size;

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: brand.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
      child: Icon(topicIcon(topic), color: brand.primary, size: size * 0.52),
    );
  }
}

class _NotificationSheet extends ConsumerWidget {
  const _NotificationSheet({required this.notification});

  final AppNotification notification;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final dates = ref.watch(dateTextProvider);
    final day = visitDayLabel(l10n, dates, LocalDate.of(notification.createdAt.toLocal()), ref.watch(todayProvider));
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                TopicBadge(topic: notification.topic, size: 36),
                const SizedBox(width: 12),
                Text(
                  '$day · ${dates.time(notification.createdAt)}',
                  style: textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(notification.title, style: textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(notification.body, style: textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary, height: 1.45)),
            const SizedBox(height: 24),
            PrimaryButton(label: l10n.done, onPressed: () => Navigator.of(context).pop()),
          ],
        ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.state, required this.onRetry});

  final InboxState state;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (state.failure case final failure? when state.items.isEmpty || !state.reachedEnd) {
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: LoadFailedCard(failure: failure, onRetry: onRetry),
      );
    }
    if (state.isLoading) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2.4)),
      );
    }
    if (state.items.isEmpty) {
      final l10n = context.l10n;
      return PhotoMessageCard(
        photo: 'assets/photos/onboarding_renew.jpg',
        title: l10n.noNotifications,
        body: l10n.noNotificationsBody,
      );
    }
    return const SizedBox.shrink();
  }
}
