import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/design/brand.dart';
import '../../../core/design/tokens.dart';
import '../../../core/design/widgets/surfaces.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/time/clock.dart';
import '../../../core/time/date_text.dart';
import '../../../core/time/local_date.dart';
import '../../../l10n/app_localizations.dart';
import '../../membership/domain/membership.dart';
import '../domain/visit.dart';

/// One visit: the branch's photo, where and when, and whether the member
/// was let in, with the reason when they weren't.
class VisitCard extends ConsumerWidget {
  const VisitCard({super.key, required this.visit, this.showDay = true});

  final Visit visit;

  /// Off under a day heading, where the day would only repeat it.
  final bool showDay;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final dates = ref.watch(dateTextProvider);
    final time = dates.time(visit.checkedInAt);
    final when = showDay
        ? '${visitDayLabel(l10n, dates, LocalDate.of(visit.checkedInAt.toLocal()), ref.watch(todayProvider))} · $time'
        : time;
    final allowed = visit.result == VisitResult.allowed;
    final statusColor = allowed ? context.brand.primary : AppColors.danger;

    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          BranchPhoto(branch: visit.branch),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(visit.branch.name, style: textTheme.titleMedium),
                const SizedBox(height: 2),
                Text(when, style: textTheme.bodySmall),
                if (!allowed) ...[
                  const SizedBox(height: 2),
                  Text(denialReason(l10n, visit.reasonCode), style: textTheme.bodySmall?.copyWith(color: AppColors.danger)),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          Tooltip(
            message: allowed ? l10n.visitCheckedIn : l10n.visitDenied,
            child: Semantics(
              label: allowed ? l10n.visitCheckedIn : l10n.visitDenied,
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.12), shape: BoxShape.circle),
                child: Icon(allowed ? Icons.check_rounded : Icons.close_rounded, size: 20, color: statusColor),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The branch's own photo when the gym set one, otherwise a gym photo.
class BranchPhoto extends StatelessWidget {
  const BranchPhoto({super.key, required this.branch, this.size = 52});

  final Branch branch;
  final double size;

  @override
  Widget build(BuildContext context) {
    final fallback = Image.asset('assets/photos/branch.jpg', width: size, height: size, fit: BoxFit.cover);
    return ClipOval(
      child: switch (branch.photoUrl) {
        final url? => Image.network(
          url,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stack) => fallback,
        ),
        null => fallback,
      },
    );
  }
}

/// "Today", "Yesterday" or "Mon, Oct 12".
String visitDayLabel(AppLocalizations l10n, DateText dates, LocalDate day, LocalDate today) =>
    switch (day.daysUntil(today)) {
      0 => l10n.today,
      1 => l10n.yesterday,
      _ => dates.weekdayDate(day),
    };

/// Why the front desk turned the member away, from the API's reason code.
String denialReason(AppLocalizations l10n, String? reasonCode) => switch (reasonCode) {
  'MEMBERSHIP_EXPIRED' || 'MEMBERSHIP_NONE' => l10n.reasonMembershipExpired,
  'MEMBERSHIP_FROZEN' => l10n.reasonMembershipFrozen,
  'OUTSIDE_ALLOWED_HOURS' => l10n.reasonOutsideHours,
  'BRANCH_NOT_ALLOWED' => l10n.reasonBranchNotAllowed,
  'NO_VISITS_REMAINING' => l10n.reasonNoVisitsRemaining,
  'ALREADY_CHECKED_IN' => l10n.reasonAlreadyCheckedIn,
  _ => l10n.reasonOther,
};
