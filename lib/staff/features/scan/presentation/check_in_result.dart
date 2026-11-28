import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/design/widgets/member_photo.dart';
import '../../../../core/localization/l10n.dart';
import '../../../../core/localization/locale_controller.dart';
import '../../../../core/time/date_text.dart';
import '../../../../l10n/app_localizations.dart';
import '../domain/desk_check_in.dart';

/// The reason shown when the desk has no internet and no door list good
/// now, so it can't decide.
const noDoorList = 'NO_DOOR_LIST';

/// Amber, for scans waiting for the internet.
const offlineColor = Color(0xFFB54708);

/// The answer at the door, big enough to read from the desk: green and
/// who it is when let in, red and why when turned away. What the member
/// owes shows either way, for the desk to ask for. Tapping it, or waiting,
/// goes back to scanning.
class CheckInResultView extends ConsumerWidget {
  const CheckInResultView({
    super.key,
    required this.checkIn,
    required this.onDone,
    this.onTakePayment,
    this.onRenew,
    this.onEndFreeze,
    this.onOpenMember,
  });

  /// The reasons a new plan would let the member in.
  static const renewable = {'MEMBERSHIP_EXPIRED', 'MEMBERSHIP_NONE', 'VISITS_USED_UP'};

  static const letInColor = Color(0xFF12805C);
  static const turnedAwayColor = Color(0xFFC0262D);

  final DeskCheckIn checkIn;
  final VoidCallback onDone;

  /// Opens the payment sheet for what the member owes; only online, when
  /// the API named the member.
  final VoidCallback? onTakePayment;

  /// Opens the sheet to sell a plan, for a member turned away for having
  /// none that lets them in; only online, when the API named the member.
  final VoidCallback? onRenew;

  /// Opens the member's memberships to end the freeze that turned them away;
  /// only online, when the API named the member.
  final VoidCallback? onEndFreeze;

  /// Opens the member's page; only online, when the API named the member.
  final VoidCallback? onOpenMember;

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
                if (checkIn.offline) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.cloud_off_rounded, color: Colors.white, size: 18),
                      const SizedBox(width: 6),
                      Text(l10n.deskDecidedOffline, style: textTheme.labelLarge),
                    ],
                  ),
                ],
                if (!checkIn.letIn) ...[
                  const SizedBox(height: 8),
                  Text(deskReason(l10n, checkIn.reasonCode), style: textTheme.titleMedium),
                  if (onRenew case final renew?
                      when !checkIn.offline && checkIn.memberId != null && renewable.contains(checkIn.reasonCode)) ...[
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      key: const Key('result-renew'),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: turnedAwayColor,
                        minimumSize: const Size(0, 44),
                      ),
                      onPressed: renew,
                      icon: const Icon(Icons.autorenew_rounded),
                      label: Text(l10n.deskRenew),
                    ),
                  ],
                  if (onEndFreeze case final endFreeze?
                      when !checkIn.offline && checkIn.memberId != null && checkIn.reasonCode == 'MEMBERSHIP_FROZEN') ...[
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      key: const Key('result-end-freeze'),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: turnedAwayColor,
                        minimumSize: const Size(0, 44),
                      ),
                      onPressed: endFreeze,
                      icon: const Icon(Icons.wb_sunny_outlined),
                      label: Text(l10n.deskEndFreezeAction),
                    ),
                  ],
                ],
                if (checkIn.memberName case final name?) ...[
                  // Large, so the desk sees the person is the member.
                  if (checkIn.memberPhotoUrl case final photo?) ...[
                    const SizedBox(height: 20),
                    MemberPhoto(url: photo, size: 128, fallback: const SizedBox.shrink()),
                  ],
                  const SizedBox(height: 20),
                  Text(name, style: textTheme.headlineSmall),
                  if (checkIn.memberPhone case final phone?) Text(phone, style: textTheme.bodyMedium),
                  if (onOpenMember case final open? when !checkIn.offline && checkIn.memberId != null)
                    TextButton.icon(
                      key: const Key('result-open-member'),
                      style: TextButton.styleFrom(foregroundColor: Colors.white, padding: EdgeInsets.zero),
                      onPressed: open,
                      icon: const Icon(Icons.person_rounded, size: 18),
                      label: Text(l10n.memberOpenPage),
                    ),
                ],
                if ((checkIn.planName, checkIn.endsOn) case (final plan?, final endsOn?)) ...[
                  const SizedBox(height: 8),
                  Text(l10n.deskPlanUntil(plan, dates.date(endsOn)), style: textTheme.bodyLarge),
                ],
                if ((checkIn.planName, checkIn.endsOn) case (final plan?, null)) ...[
                  const SizedBox(height: 8),
                  Text(plan, style: textTheme.bodyLarge),
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
                  if (onTakePayment case final takePayment? when !checkIn.offline && checkIn.memberId != null) ...[
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      key: const Key('result-take-payment'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white),
                        minimumSize: const Size(0, 44),
                      ),
                      onPressed: takePayment,
                      icon: const Icon(Icons.payments_rounded),
                      label: Text(l10n.deskTakePayment),
                    ),
                  ],
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
  noDoorList => l10n.deskReasonNoDoorList,
  'MEMBERSHIP_NONE' => l10n.deskReasonMembershipNone,
  'MEMBERSHIP_EXPIRED' => l10n.deskReasonMembershipExpired,
  'MEMBERSHIP_FROZEN' => l10n.deskReasonMembershipFrozen,
  'BRANCH_NOT_ALLOWED' => l10n.deskReasonBranchNotAllowed,
  'VISITS_USED_UP' => l10n.deskReasonVisitsUsedUp,
  'ALREADY_CHECKED_IN' => l10n.deskReasonAlreadyCheckedIn,
  _ => l10n.deskReasonOther,
};
