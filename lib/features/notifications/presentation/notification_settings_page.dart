import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/config/env.dart';
import '../../../core/design/brand.dart';
import '../../../core/design/tokens.dart';
import '../../../core/design/widgets/controls.dart';
import '../../../core/design/widgets/feedback.dart';
import '../../../core/design/widgets/surfaces.dart';
import '../../../core/errors/failure.dart';
import '../../../core/errors/failure_messages.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/json.dart';
import '../../../core/push/push_service.dart';
import '../../../l10n/app_localizations.dart';
import '../data/inbox_controller.dart';
import '../domain/app_notification.dart';
import 'notification_routes.dart';
import 'push_permission_card.dart';

/// Which topics the member gets pushes for at the selected gym, and
/// whether the phone lets the app notify at all.
class NotificationSettingsPage extends ConsumerWidget {
  const NotificationSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final preferences = ref.watch(notificationPreferencesProvider);
    final push = ref.watch(pushServiceProvider);

    return SoftBackground(
      child: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            ScreenHeader(
              leading: HeaderButton(
                tooltip: l10n.back,
                onPressed: () => context.pop(),
                child: const Icon(Icons.arrow_back_rounded, color: AppColors.ink),
              ),
              title: l10n.notificationsTitle,
            ),
            const SizedBox(height: 24),
            if (!push.isAvailable)
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Text(
                  l10n.pushUnavailable,
                  style: textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
                ),
              ),
            const PushPermissionCard(padding: EdgeInsets.only(bottom: 20)),
            SectionHeader(l10n.notifyMeAbout),
            switch (preferences) {
              AsyncData(:final value) => AppCard(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  children: [
                    for (final (index, topic) in NotificationTopic.values.indexed) ...[
                      if (index > 0) const Divider(height: 1, indent: 66, color: AppColors.line),
                      _TopicSwitch(topic: topic, enabled: value[topic]),
                    ],
                  ],
                ),
              ),
              AsyncError(:final error) => LoadFailedCard(
                failure: error is Failure ? error : const UnexpectedFailure(),
                onRetry: () => ref.invalidate(notificationPreferencesProvider),
              ),
              _ => const Padding(
                padding: EdgeInsets.all(48),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2.4)),
              ),
            },
            const SizedBox(height: 14),
            Text(l10n.inboxKeepsAll, style: textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
            if (ref.watch(envProvider).usesFakeBackend) ...[const SizedBox(height: 28), const _FakePushButton()],
          ],
        ),
      ),
    );
  }
}

class _TopicSwitch extends ConsumerWidget {
  const _TopicSwitch({required this.topic, required this.enabled});

  final NotificationTopic topic;
  final bool enabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final brand = context.brand;
    final (title, hint) = _describe(l10n);
    // The whole row flips the switch, like the phone's own settings.
    return MergeSemantics(
      child: InkWell(
        onTap: () => _set(context, ref, !enabled),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 10, 10),
          child: Row(
            children: [
              _SettingIcon(topic: topic),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: textTheme.titleSmall),
                    Text(hint, style: textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
                  ],
                ),
              ),
              Switch(
                value: enabled,
                activeThumbColor: brand.onPrimary,
                activeTrackColor: brand.primary,
                onChanged: (value) => _set(context, ref, value),
              ),
            ],
          ),
        ),
      ),
    );
  }

  (String, String) _describe(AppLocalizations l10n) => switch (topic) {
    NotificationTopic.membership => (l10n.topicMembership, l10n.topicMembershipHint),
    NotificationTopic.payments => (l10n.topicPayments, l10n.topicPaymentsHint),
    NotificationTopic.visits => (l10n.topicVisits, l10n.topicVisitsHint),
    NotificationTopic.announcements => (l10n.topicAnnouncements, l10n.topicAnnouncementsHint),
  };

  Future<void> _set(BuildContext context, WidgetRef ref, bool value) async {
    try {
      await ref.read(notificationPreferencesProvider.notifier).set(topic, value);
    } on Failure catch (failure) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(failureMessage(context.l10n, failure))));
    }
  }
}

/// The topic's icon in a small cream square, like the profile's settings.
class _SettingIcon extends StatelessWidget {
  const _SettingIcon({required this.topic});

  final NotificationTopic topic;

  @override
  Widget build(BuildContext context) => Container(
    width: 36,
    height: 36,
    decoration: BoxDecoration(color: AppColors.canvas, borderRadius: BorderRadius.circular(11)),
    child: Icon(topicIcon(topic), size: 19, color: AppColors.ink),
  );
}

/// Dev builds only, in English: asks the fake backend for a notification
/// and delivers it a moment later, as FCM would.
class _FakePushButton extends ConsumerWidget {
  const _FakePushButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) => OutlinedButton.icon(
    onPressed: () async {
      // Read up front: the member may leave the page while it waits.
      final api = ref.read(apiClientProvider);
      final push = ref.read(pushServiceProvider);
      try {
        final response = dataObject(await api.post('/dev/fake-push'));
        final message = PushMessage(
          title: response.optional<String>('title'),
          body: response.optional<String>('body'),
          data: {
            for (final MapEntry(:key, :value) in response.field<Map<String, dynamic>>('data').entries) key: '$value',
          },
        );
        await Future<void>.delayed(const Duration(seconds: 2));
        if (push case final FakePushService fake) fake.deliver(message);
      } on Failure catch (failure) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(failureMessage(context.l10n, failure))));
      }
    },
    icon: const Icon(Icons.science_outlined),
    label: const Text('Send a test notification'),
  );
}
