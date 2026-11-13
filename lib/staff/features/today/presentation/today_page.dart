import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/design/tokens.dart';
import '../../../../core/design/widgets/feedback.dart';
import '../../../../core/localization/l10n.dart';
import '../../scan/presentation/check_in_result.dart';
import '../../scan/presentation/desk_app_bar.dart';
import '../data/today_check_ins.dart';

/// Today's check-ins at the desk's branch, newest first: who came in at
/// what time, and who was turned away and why.
class TodayPage extends ConsumerWidget {
  const TodayPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final state = ref.watch(todayProvider);
    final controller = ref.read(todayProvider.notifier);
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
                  subtitle: checkIn.letIn ? null : Text(deskReason(l10n, checkIn.reasonCode)),
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
