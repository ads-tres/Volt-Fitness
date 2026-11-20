import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/design/tokens.dart';
import '../../../../core/localization/l10n.dart';
import '../../../../core/localization/locale_controller.dart';
import '../../../../core/time/date_text.dart';
import '../../../../core/utils/ethiopian_phone.dart';
import '../domain/desk_numbers.dart';

/// The members to call: plans ending soon and visit packs nearly used,
/// with what each owes for those who see money. Tapping one dials them.
class MembersToCall extends ConsumerWidget {
  const MembersToCall({super.key, required this.members});

  final List<MemberToCall> members;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final dates = ref.watch(dateTextProvider);
    final languageCode = ref.watch(languageCodeProvider);
    return Card(
      margin: const EdgeInsets.only(top: 12),
      color: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.control),
        side: const BorderSide(color: AppColors.line),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(l10n.numbersToCall, style: textTheme.titleSmall?.copyWith(color: AppColors.textSecondary)),
            ),
            if (members.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Text(l10n.numbersNoOneToCall, style: textTheme.bodyMedium),
              ),
            for (final member in members)
              ListTile(
                title: Text(member.name),
                subtitle: Text(
                  [
                    member.planName,
                    l10n.numbersEnds(dates.date(member.endsOn)),
                    if (member.visitsLeft case final visits?) l10n.visitsLeft(visits),
                    if (member.balanceDue case final owed? when owed.amountMinor > 0)
                      l10n.deskOwes(owed.format(languageCode)),
                  ].join(' · '),
                ),
                trailing: member.phone.isEmpty
                    ? null
                    : IconButton(
                        tooltip: l10n.numbersCall(EthiopianPhone.format(member.phone)),
                        icon: const Icon(Icons.call_rounded),
                        onPressed: () => unawaited(launchUrl(Uri(scheme: 'tel', path: member.phone))),
                      ),
              ),
          ],
        ),
      ),
    );
  }
}
