import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/design/tokens.dart';
import '../../../core/design/widgets/controls.dart';
import '../../../core/design/widgets/feedback.dart';
import '../../../core/design/widgets/surfaces.dart';
import '../../../core/errors/failure.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/localization/locale_controller.dart';
import '../../../core/time/clock.dart';
import '../../home/data/dashboard_repository.dart';
import '../../membership/domain/membership.dart' show Branch;
import '../data/branches_repository.dart';
import '../domain/gym_branch.dart';

/// The gym's branches with their week, and whether each is open now, so a
/// member doesn't come when the door would turn them away.
class BranchesPage extends ConsumerWidget {
  const BranchesPage({super.key});

  static const openColor = Color(0xFF12805C);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final branches = ref.watch(gymBranchesProvider);
    final yours = {
      for (final branch in ref.watch(dashboardProvider).value?.membership?.allowedBranches ?? const <Branch>[]) branch.id,
    };
    return SoftBackground(
      child: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () => ref.refresh(gymBranchesProvider.future),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              ScreenHeader(
                leading: HeaderButton(
                  tooltip: l10n.back,
                  onPressed: () => context.pop(),
                  child: const Icon(Icons.arrow_back_rounded, color: AppColors.ink),
                ),
                title: l10n.branchesTitle,
              ),
              const SizedBox(height: 24),
              switch (branches) {
                AsyncData(:final value) => Column(
                  children: [
                    for (final branch in value)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _BranchCard(branch: branch, onYourPlan: yours.contains(branch.id)),
                      ),
                  ],
                ),
                AsyncError(:final error) => LoadFailedCard(
                  failure: error is Failure ? error : const UnexpectedFailure(),
                  onRetry: () => ref.invalidate(gymBranchesProvider),
                ),
                _ => const Padding(
                  padding: EdgeInsets.all(48),
                  child: Center(child: CircularProgressIndicator(strokeWidth: 2.4)),
                ),
              },
            ],
          ),
        ),
      ),
    );
  }
}

class _BranchCard extends ConsumerWidget {
  const _BranchCard({required this.branch, required this.onYourPlan});

  final GymBranch branch;
  final bool onYourPlan;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final locale = ref.watch(languageCodeProvider);
    final now = ref.watch(clockProvider)();
    final time = DateFormat.Hm(locale);
    String day(DateTime date) => DateFormat.E(locale).format(date);

    final open = branch.isOpenAt(now);
    final status = switch ((branch.alwaysOpen, open)) {
      (true, _) => l10n.branchAlwaysOpen,
      (false, true) => l10n.branchOpenUntil(time.format(branch.closesAfter(now)!)),
      (false, false) => switch (branch.nextOpening(now)) {
        final next? when next.day == now.day => l10n.branchClosedOpensAt(time.format(next)),
        final next? => l10n.branchClosedOpensAt('${day(next)} ${time.format(next)}'),
        null => l10n.branchClosed,
      },
    };
    // A Monday, to name each weekday in the member's language.
    final monday = DateTime(now.year, now.month, now.day - (now.weekday - 1));

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(branch.name, style: textTheme.titleMedium)),
              if (onYourPlan)
                Text(l10n.branchOnYourPlan, style: textTheme.labelMedium?.copyWith(color: AppColors.textSecondary)),
            ],
          ),
          if (branch.address case final address?) Text(address, style: textTheme.bodySmall),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(
                Icons.circle,
                size: 10,
                color: open ? BranchesPage.openColor : AppColors.danger,
              ),
              const SizedBox(width: 6),
              Expanded(child: Text(status, style: textTheme.titleSmall)),
            ],
          ),
          if (!branch.alwaysOpen) ...[
            const Divider(height: 24, color: AppColors.line),
            for (var weekday = 1; weekday <= 7; weekday++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: DefaultTextStyle.merge(
                  style: (textTheme.bodyMedium ?? const TextStyle()).copyWith(
                    fontWeight: weekday == now.weekday ? FontWeight.w700 : FontWeight.w400,
                  ),
                  child: Row(
                    children: [
                      Expanded(child: Text(day(monday.add(Duration(days: weekday - 1))))),
                      Text(switch (branch.hoursOn(weekday)) {
                        final hours? =>
                          '${time.format(monday.add(Duration(minutes: hours.opensAt)))} – '
                              '${time.format(monday.add(Duration(minutes: hours.closesAt)))}',
                        null => l10n.branchClosed,
                      }),
                    ],
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
