import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/design/brand.dart';
import '../../../core/design/tokens.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/localization/locale_controller.dart';
import '../../../core/time/clock.dart';
import '../../../core/time/date_text.dart';
import '../../../l10n/app_localizations.dart';

String calendarName(AppLocalizations l10n, CalendarSystem calendar) => switch (calendar) {
  CalendarSystem.gregorian => l10n.calendarGregorian,
  CalendarSystem.ethiopian => l10n.calendarEthiopian,
  CalendarSystem.both => l10n.calendarBoth,
};

/// Picks how dates read, showing today's date in each option.
Future<void> showCalendarSheet(BuildContext context) => showModalBottomSheet<void>(
  context: context,
  showDragHandle: true,
  backgroundColor: AppColors.surface,
  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.card))),
  builder: (context) => const _CalendarSheet(),
);

class _CalendarSheet extends ConsumerWidget {
  const _CalendarSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final chosen = ref.watch(calendarControllerProvider);
    final languageCode = ref.watch(languageCodeProvider);
    final today = ref.watch(todayProvider);

    Widget option(String label, CalendarSystem? value, CalendarSystem shown) {
      final selected = chosen == value;
      return ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 24),
        title: Text(label, style: textTheme.titleSmall),
        subtitle: Text(
          DateText(languageCode: languageCode, calendar: shown).date(today),
          style: textTheme.bodySmall,
        ),
        trailing: Icon(
          selected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
          color: selected ? context.brand.primary : AppColors.textTertiary,
        ),
        onTap: () {
          ref.read(calendarControllerProvider.notifier).select(value);
          Navigator.of(context).pop();
        },
      );
    }

    final automatic = languageCode == 'am' ? CalendarSystem.ethiopian : CalendarSystem.gregorian;
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
            child: Text(l10n.calendar, style: textTheme.titleLarge),
          ),
          option(l10n.calendarAuto, null, automatic),
          option(l10n.calendarGregorian, CalendarSystem.gregorian, CalendarSystem.gregorian),
          option(l10n.calendarEthiopian, CalendarSystem.ethiopian, CalendarSystem.ethiopian),
          option(l10n.calendarBoth, CalendarSystem.both, CalendarSystem.both),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
