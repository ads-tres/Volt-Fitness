import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/localization/l10n.dart';
import '../../../../core/localization/locale_controller.dart';
import '../../../../core/time/date_text.dart';
import '../../../../l10n/app_localizations.dart';
import '../domain/desk_check_in.dart';

/// The answer at the door, big enough to read from the desk: green and
/// who it is when let in, red and why when turned away. What the member
/// owes shows either way, for the desk to ask for. Tapping it, or waiting,
/// goes back to scanning.
class CheckInResultView extends ConsumerWidget {
  const CheckInResultView({super.key, required this.checkIn, required this.onDone});

  static const letInColor = Color(0xFF12805C);
  static const turnedAwayColor = Color(0xFFC0262D);

  final DeskCheckIn checkIn;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme.apply(bodyColor: Colors.white, displayColor: Colors.white);
    final languageCode = ref.watch(languageCodeProvider);
    final dates = ref.watch(dateTextProvider);
    return GestureDetector(
      key: const Key('check-in-result'),
      onTap: onDone,
      child: ColoredBox(
        color: checkIn.letIn ? letInColor : turnedAwayColor,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Spacer(),
                Icon(checkIn.letIn ? Icons.check_circle_rounded : Icons.block_rounded, color: Colors.white, size: 72),
                const SizedBox(height: 16),
                Text(checkIn.letIn ? l10n.deskLetIn : l10n.deskTurnedAway, style: textTheme.headlineMedium),
                if (!checkIn.letIn) ...[
                  const SizedBox(height: 8),
                  Text(deskReason(l10n, checkIn.reasonCode), style: textTheme.titleMedium),
                ],
                if (checkIn.memberName case final name?) ...[
                  const SizedBox(height: 28),
                  Text(name, style: textTheme.headlineSmall),
                  if (checkIn.memberPhone case final phone?) Text(phone, style: textTheme.bodyMedium),
                ],
                if ((checkIn.planName, checkIn.endsOn) case (final plan?, final endsOn?)) ...[
                  const SizedBox(height: 8),
                  Text(l10n.deskPlanUntil(plan, dates.date(endsOn)), style: textTheme.bodyLarge),
                ],
                if (checkIn.owes) ...[
                  const SizedBox(height: 16),
                  DecoratedBox(
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      child: Text(
                        l10n.deskOwes(checkIn.balanceDue!.format(languageCode)),
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                Text(l10n.deskTapToContinue, style: textTheme.bodySmall),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Why the door turned a member away, for the desk, by the API's reason
/// code (the members-app contract lists them).
String deskReason(AppLocalizations l10n, String? reasonCode) => switch (reasonCode) {
  'CREDENTIAL_INVALID' => l10n.deskReasonCredentialInvalid,
  'CREDENTIAL_REVOKED' => l10n.deskReasonCredentialRevoked,
  'CODE_EXPIRED' => l10n.deskReasonCodeExpired,
  'CODE_ALREADY_USED' => l10n.deskReasonCodeAlreadyUsed,
  'OUTSIDE_HOURS' => l10n.deskReasonOutsideHours,
  'MEMBERSHIP_NONE' => l10n.deskReasonMembershipNone,
  'MEMBERSHIP_EXPIRED' => l10n.deskReasonMembershipExpired,
  'MEMBERSHIP_FROZEN' => l10n.deskReasonMembershipFrozen,
  'BRANCH_NOT_ALLOWED' => l10n.deskReasonBranchNotAllowed,
  'VISITS_USED_UP' => l10n.deskReasonVisitsUsedUp,
  'ALREADY_CHECKED_IN' => l10n.deskReasonAlreadyCheckedIn,
  _ => l10n.deskReasonOther,
};
