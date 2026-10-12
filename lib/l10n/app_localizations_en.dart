// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Volt';

  @override
  String get signIn => 'Sign in';

  @override
  String get signOut => 'Sign out';

  @override
  String get home => 'Home';

  @override
  String get language => 'Language';

  @override
  String get languageSystem => 'Use phone setting';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageAmharic => 'አማርኛ';

  @override
  String get placeholderNotice =>
      'This screen is a placeholder until the design is ready.';

  @override
  String get retry => 'Try again';

  @override
  String get errorNetwork =>
      'No internet connection. Check your connection and try again.';

  @override
  String get errorSessionExpired =>
      'Your session has ended. Please sign in again.';

  @override
  String get errorForbidden => 'You don\'t have access to this.';

  @override
  String get errorNotFound => 'We couldn\'t find what you were looking for.';

  @override
  String get errorConflict =>
      'This changed in the meantime. Refresh and try again.';

  @override
  String get errorValidation =>
      'Some details need fixing. Check them and try again.';

  @override
  String get errorRateLimited =>
      'Too many attempts. Please wait a moment and try again.';

  @override
  String get errorUpdateRequired =>
      'This version of the app is no longer supported. Please update to continue.';

  @override
  String get errorServer =>
      'Something went wrong on our side. Please try again later.';

  @override
  String get errorUnexpected => 'Something went wrong. Please try again.';
}
