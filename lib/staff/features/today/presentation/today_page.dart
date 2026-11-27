import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/design/tokens.dart';
import '../../../../core/design/widgets/member_photo.dart';
import '../../../../core/design/widgets/feedback.dart';
import '../../../../core/localization/l10n.dart';
import '../../scan/data/scan_outbox.dart';
import '../../scan/domain/desk_check_in.dart';
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
              if (outbox.refused > 0 || outbox.toReview > 0)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, color: CheckInResultView.turnedAwayColor),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          [
                            if (outbox.refused > 0) l10n.deskOfflineRefused(outbox.refused),
                            if (outbox.toReview > 0) l10n.deskOfflineToReview(outbox.toReview),
                          ].join(' '),
                          style: textTheme.bodyMedium,
                        ),
                      ),
                      IconButton(
                        tooltip: l10n.deskDismiss,
                        icon: const Icon(Icons.close_rounded),
                        onPressed: ref.read(scanOutboxProvider.notifier).dismissCounts,
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
                        style: TextButton.styleFrom(foregroundColor: offlineColor),
                      ),
                  ],
                ),
                Text(l10n.deskWaitingBody, style: textTheme.bodySmall),
                for (final scan in outbox.pending)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.cloud_off_rounded, color: offlineColor),
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
                  leading: _RowLeading(checkIn: checkIn),
                  title: Text(checkIn.memberName ?? l10n.deskUnknownMember),
                  subtitle: switch ([
                    if (!checkIn.letIn) deskReason(l10n, checkIn.reasonCode),
                    if (checkIn.offline) l10n.deskOfflineChip,
                    if (checkIn.serverDisagrees)
                      l10n.deskServerDisagrees(
                        checkIn.serverReasonCode == null ? l10n.deskLetIn : deskReason(l10n, checkIn.serverReasonCode),
                      ),
                  ]) {
                    [] => null,
                    final parts => Text(parts.join(' · ')),
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

/// The member's photo with the door's answer in its corner, or just the
/// answer when there is no photo.
class _RowLeading extends StatelessWidget {
  const _RowLeading({required this.checkIn});

  final DeskCheckIn checkIn;

  @override
  Widget build(BuildContext context) {
    final icon = Icon(
      checkIn.letIn ? Icons.check_circle_rounded : Icons.block_rounded,
      color: checkIn.letIn ? CheckInResultView.letInColor : CheckInResultView.turnedAwayColor,
      size: checkIn.memberPhotoUrl == null ? null : 16,
    );
    final photo = checkIn.memberPhotoUrl;
    if (photo == null) return icon;
    return SizedBox(
      width: 40,
      height: 40,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          MemberPhoto(url: photo, size: 40, fallback: InitialsCircle(name: checkIn.memberName ?? '', size: 40)),
          Positioned(
            right: -4,
            bottom: -4,
            child: DecoratedBox(
              decoration: const BoxDecoration(color: AppColors.surface, shape: BoxShape.circle),
              child: Padding(padding: const EdgeInsets.all(1), child: icon),
            ),
          ),
        ],
      ),
    );
  }
}
