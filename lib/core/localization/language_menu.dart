import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../design/tokens.dart';
import '../design/widgets/surfaces.dart';
import 'l10n.dart';
import 'locale_controller.dart';

/// A round header button showing the current language. It opens a menu of
/// English, Amharic and the phone's language.
class LanguageMenu extends ConsumerWidget {
  const LanguageMenu({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final chosen = ref.watch(localeControllerProvider);
    final shown = ref.watch(languageCodeProvider);
    final controller = ref.read(localeControllerProvider.notifier);

    MenuItemButton option(String label, Locale? locale) => MenuItemButton(
      onPressed: () => controller.select(locale),
      trailingIcon: chosen?.languageCode == locale?.languageCode
          ? const Icon(Icons.check_rounded, size: 18, color: AppColors.ink)
          : null,
      child: Text(label),
    );

    return MenuAnchor(
      alignmentOffset: const Offset(-144, 8),
      menuChildren: [
        option(l10n.languageSystem, null),
        option(l10n.languageEnglish, const Locale('en')),
        option(l10n.languageAmharic, const Locale('am')),
      ],
      builder: (context, menu, child) => CircleButton(
        tooltip: l10n.language,
        onPressed: () => menu.isOpen ? menu.close() : menu.open(),
        child: Text(
          shown == 'am' ? 'አማ' : 'EN',
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.ink),
        ),
      ),
    );
  }
}
