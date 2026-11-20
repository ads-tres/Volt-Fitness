import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/design/tokens.dart';
import '../../../../core/design/widgets/feedback.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/errors/failure_messages.dart';
import '../../../../core/localization/l10n.dart';
import '../../../../l10n/app_localizations.dart';
import '../data/staff_messages_repository.dart';
import '../domain/staff_message.dart';

String staffTopicName(AppLocalizations l10n, StaffTopic topic) => switch (topic) {
  StaffTopic.onlinePayments => l10n.deskTopicOnlinePayments,
  StaffTopic.refunds => l10n.deskTopicRefunds,
  StaffTopic.appFreezes => l10n.deskTopicAppFreezes,
  StaffTopic.membersToCall => l10n.deskTopicMembersToCall,
};

/// How the staff member hears about each topic at this gym: by push, SMS,
/// both or neither. A switch takes effect at once; if the API refuses, it
/// goes back and says why.
class DeskNotificationSettingsPage extends ConsumerStatefulWidget {
  const DeskNotificationSettingsPage({super.key});

  @override
  ConsumerState<DeskNotificationSettingsPage> createState() => _DeskNotificationSettingsPageState();
}

class _DeskNotificationSettingsPageState extends ConsumerState<DeskNotificationSettingsPage> {
  Map<StaffTopic, StaffChannels>? _choices;
  Failure? _failure;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    setState(() => _failure = null);
    try {
      final choices = await ref.read(staffMessagesRepositoryProvider).preferences();
      if (mounted) setState(() => _choices = choices);
    } on Failure catch (failure) {
      if (mounted) setState(() => _failure = failure);
    }
  }

  Future<void> _change(StaffTopic topic, {bool? push, bool? sms}) async {
    final before = _choices!;
    final current = before[topic]!;
    setState(() => _choices = {...before, topic: (push: push ?? current.push, sms: sms ?? current.sms)});
    try {
      final saved = await ref.read(staffMessagesRepositoryProvider).updatePreferences(topic, push: push, sms: sms);
      if (mounted) setState(() => _choices = saved);
    } on Failure catch (failure) {
      if (!mounted) return;
      setState(() => _choices = before);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(switch (failure) {
              ValidationFailure(message: final message?) => message,
              _ => failureMessage(context.l10n, failure),
            }),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final choices = _choices;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.deskNotificationSettings)),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          if (_failure case final failure? when choices == null)
            Padding(padding: const EdgeInsets.all(20), child: LoadFailedCard(failure: failure, onRetry: _load))
          else if (choices == null)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2.4, color: AppColors.ink)),
            )
          else ...[
            for (final topic in StaffTopic.values) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Text(staffTopicName(l10n, topic), style: textTheme.titleSmall),
              ),
              SwitchListTile(
                key: Key('${topic.apiName}.push'),
                title: Text(l10n.deskChannelPush),
                value: choices[topic]!.push,
                onChanged: (on) => unawaited(_change(topic, push: on)),
              ),
              SwitchListTile(
                key: Key('${topic.apiName}.sms'),
                title: Text(l10n.deskChannelSms),
                value: choices[topic]!.sms,
                onChanged: (on) => unawaited(_change(topic, sms: on)),
              ),
            ],
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(l10n.deskQuietHours, style: textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
            ),
          ],
        ],
      ),
    );
  }
}
