import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/design/tokens.dart';
import '../../../../core/design/widgets/feedback.dart';
import '../../../../core/localization/l10n.dart';
import '../../scan/data/scan_outbox.dart';
import '../../scan/presentation/check_in_result.dart';
import '../../scan/presentation/desk_app_bar.dart';
import '../data/today_check_ins.dart';

/// Today's check-ins at the desk's branch, newest first: who came in at
/// what time, and who was turned away and why. Scans still waiting for the
/// internet come first, and those sent late are marked.
class TodayPage extends ConsumerWidget {
  const TodayPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final state = ref.watch(todayProvider);
    final controller = ref.read(todayProvider.notifier);
    final outbox = ref.watch(scanOutboxProvider);
    return Scaffold(
      appBar: const DeskAppBar(),
      body: RefreshIndicator(
        onRefresh: controller.refresh,
        child: NotificationListener<ScrollEndNotification>(
          onNotification: (notification) {
            if (notification.metrics.extentAfter < 200) controller.loadMore();
            return false;
          },
          child: ListView(
            padding: const EdgeInsets.all(20),
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              if (outbox.dropped > 0)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, color: CheckInResultView.turnedAwayColor),
                      const SizedBox(width: 10),
                      Expanded(child: Text(l10n.deskDroppedNotice(outbox.dropped), style: textTheme.bodyMedium)),
                      IconButton(
                        tooltip: l10n.deskDismiss,
                        icon: const Icon(Icons.close_rounded),
                        onPressed: ref.read(scanOutboxProvider.notifier).dismissDropped,
                      ),
                    ],
                  ),
                ),
              if (outbox.pending.isNotEmpty) ...[
                Row(
                  children: [
                    Expanded(child: Text(l10n.deskWaitingTitle, style: textTheme.titleLarge)),
                    if (outbox.isSending)
                      const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2.4))
                    else
                      TextButton.icon(
                        onPressed: ref.read(scanOutboxProvider.notifier).flush,
                        icon: const Icon(Icons.cloud_upload_rounded),
                        label: Text(l10n.deskSendNow),
                        style: TextButton.styleFrom(foregroundColor: SavedOfflineView.color),
                      ),
                  ],
                ),
                Text(l10n.deskWaitingBody, style: textTheme.bodySmall),
                for (final scan in outbox.pending)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.cloud_off_rounded, color: SavedOfflineView.color),
                    title: Text(l10n.deskWaitingRow(DateFormat.Hm().format(scan.scannedAt.toLocal()))),
                  ),
                const SizedBox(height: 20),
              ],
              Text(l10n.deskTodayTitle, style: textTheme.titleLarge),
              const SizedBox(height: 12),
              if (state.checkIns.isEmpty && !state.isLoading && state.failure == null)
                Text(l10n.deskTodayEmpty, style: textTheme.bodyMedium),
              for (final checkIn in state.checkIns)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    checkIn.letIn ? Icons.check_circle_rounded : Icons.block_rounded,
                    color: checkIn.letIn ? CheckInResultView.letInColor : CheckInResultView.turnedAwayColor,
                  ),
                  title: Text(checkIn.memberName ?? l10n.deskUnknownMember),
                  subtitle: switch ((checkIn.letIn, checkIn.scannedOffline)) {
                    (true, false) => null,
                    (true, true) => Text(l10n.deskOfflineChip),
                    (false, false) => Text(deskReason(l10n, checkIn.reasonCode)),
                    (false, true) => Text('${deskReason(l10n, checkIn.reasonCode)} · ${l10n.deskOfflineChip}'),
                  },
                  trailing: Text(DateFormat.Hm().format(checkIn.checkedInAt.toLocal()), style: textTheme.bodySmall),
                ),
              if (state.failure case final failure?) LoadFailedCard(failure: failure, onRetry: controller.refresh),
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
