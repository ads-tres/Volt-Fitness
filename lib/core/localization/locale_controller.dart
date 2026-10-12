import 'dart:ui' show Locale, PlatformDispatcher;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../storage/preferences_store.dart';

/// The language the member chose, or null to follow the phone.
///
/// Language and calendar are separate settings: someone can read English
/// with Ethiopian dates. The calendar preference arrives with dates (Phase 3).
final class LocaleController extends Notifier<Locale?> {
  static const _key = 'settings.language';

  @override
  Locale? build() {
    final languageCode = ref.watch(preferencesStoreProvider).getString(_key);
    return languageCode == null ? null : Locale(languageCode);
  }

  Future<void> select(Locale? locale) async {
    final preferences = ref.read(preferencesStoreProvider);
    if (locale == null) {
      await preferences.remove(_key);
    } else {
      await preferences.setString(_key, locale.languageCode);
    }
    state = locale;
  }
}

final localeControllerProvider = NotifierProvider<LocaleController, Locale?>(
  LocaleController.new,
);

/// The language the UI shows, sent to the API as `Accept-Language`. When
/// following the phone, it is the phone's first supported language, the way
/// MaterialApp picks it.
final languageCodeProvider = Provider<String>((ref) {
  final chosen = ref.watch(localeControllerProvider);
  if (chosen != null) return chosen.languageCode;
  final supported = AppLocalizations.supportedLocales.map((locale) => locale.languageCode);
  for (final locale in PlatformDispatcher.instance.locales) {
    if (supported.contains(locale.languageCode)) return locale.languageCode;
  }
  return 'en';
});
