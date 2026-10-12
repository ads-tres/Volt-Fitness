import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'l10n.dart';
import 'locale_controller.dart';

enum _LanguageChoice { phone, english, amharic }

/// App bar menu for switching between English, Amharic and the phone's
/// language.
class LanguageMenu extends ConsumerWidget {
  const LanguageMenu({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final current = switch (ref.watch(localeControllerProvider)?.languageCode) {
      'en' => _LanguageChoice.english,
      'am' => _LanguageChoice.amharic,
      _ => _LanguageChoice.phone,
    };
    return PopupMenuButton<_LanguageChoice>(
      icon: const Icon(Icons.translate),
      tooltip: l10n.language,
      initialValue: current,
      onSelected: (choice) => ref.read(localeControllerProvider.notifier).select(switch (choice) {
        _LanguageChoice.phone => null,
        _LanguageChoice.english => const Locale('en'),
        _LanguageChoice.amharic => const Locale('am'),
      }),
      itemBuilder: (context) => [
        PopupMenuItem(value: _LanguageChoice.phone, child: Text(l10n.languageSystem)),
        PopupMenuItem(value: _LanguageChoice.english, child: Text(l10n.languageEnglish)),
        PopupMenuItem(value: _LanguageChoice.amharic, child: Text(l10n.languageAmharic)),
      ],
    );
  }
}
