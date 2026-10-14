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
  String get back => 'Back';

  @override
  String get language => 'Language';

  @override
  String get languageSystem => 'Use phone setting';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageAmharic => 'አማርኛ';

  @override
  String get welcomeTitle => 'Welcome to Volt';

  @override
  String get welcomeSubtitle =>
      'Sign in with the phone number your gym has on file.';

  @override
  String get phoneLabel => 'Phone number';

  @override
  String get continueButton => 'Continue';

  @override
  String get smsNotice => 'We\'ll text you a 6-digit code.';

  @override
  String testModeNotice(String code) {
    return 'Test mode · code $code';
  }

  @override
  String get phoneInvalid =>
      'Enter an Ethiopian mobile number, like 0911 23 45 67.';

  @override
  String get otpTitle => 'Enter the code';

  @override
  String otpSubtitle(String phone) {
    return 'We sent a 6-digit code to $phone.';
  }

  @override
  String get verifyButton => 'Verify';

  @override
  String resendIn(String time) {
    return 'Resend code in $time';
  }

  @override
  String get resendCode => 'Resend code';

  @override
  String get codeResent => 'We sent you a new code.';

  @override
  String get otpInvalid =>
      'That code isn\'t right. Check the SMS and try again.';

  @override
  String get otpExpired => 'That code has expired. Ask for a new one.';

  @override
  String get otpTooManyAttempts =>
      'Too many wrong codes. Wait a minute, then ask for a new one.';

  @override
  String get selectGymTitle => 'Choose your gym';

  @override
  String get selectGymSubtitle =>
      'Your number is registered at more than one gym. You can switch later in your profile.';

  @override
  String get noGymTitle => 'No gym found';

  @override
  String noGymMessage(String phone) {
    return 'We couldn\'t find a membership for $phone. Ask your gym\'s front desk to register this number.';
  }

  @override
  String get useAnotherNumber => 'Use another number';

  @override
  String get onboardingTrainTitle => 'Your gym,\nin your pocket';

  @override
  String get onboardingTrainBody =>
      'Your membership, check-ins and payments in one app.';

  @override
  String get onboardingCheckInTitle => 'Check in with\none scan';

  @override
  String get onboardingCheckInBody =>
      'Show your QR code at the front desk. No card to forget.';

  @override
  String get onboardingRenewTitle => 'Renew without\nthe queue';

  @override
  String get onboardingRenewBody =>
      'See what you owe, pay from your phone and get a reminder before your plan ends.';

  @override
  String get onboardingPinDaysLeft => '18 days left';

  @override
  String get onboardingPinCheckedIn => 'Checked in · 06:42';

  @override
  String get onboardingPinPaid => 'Paid · 1,500 ETB';

  @override
  String get next => 'Next';

  @override
  String get getStarted => 'Get started';

  @override
  String get skip => 'Skip';

  @override
  String get navHome => 'Home';

  @override
  String get navMembership => 'Membership';

  @override
  String get navQr => 'My QR';

  @override
  String get navPayments => 'Payments';

  @override
  String get navProfile => 'Profile';

  @override
  String greeting(String name) {
    return 'Hello, $name';
  }

  @override
  String get greetingNoName => 'Hello';

  @override
  String welcomeBack(String gym) {
    return 'Welcome back to $gym.';
  }

  @override
  String get showQrTitle => 'Show my QR';

  @override
  String get showQrSubtitle => 'Scan it at the front desk to check in.';

  @override
  String get quickAccess => 'Quick access';

  @override
  String get yourGym => 'Your gym';

  @override
  String get frontDesk => 'Front desk';

  @override
  String get comingSoonTitle => 'Coming in the next update';

  @override
  String get comingSoonMembership =>
      'Your plan, its dates and renewal will show here.';

  @override
  String get comingSoonQr => 'Your check-in QR code will show here.';

  @override
  String get comingSoonPayments =>
      'Your invoices, payments and receipts will show here.';

  @override
  String get switchGym => 'Switch';

  @override
  String get signOut => 'Sign out';

  @override
  String appVersion(String version, String build) {
    return 'Volt $version ($build)';
  }

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
