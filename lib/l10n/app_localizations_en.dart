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
  String get switchGym => 'Switch';

  @override
  String get signOut => 'Sign out';

  @override
  String appVersion(String version, String build) {
    return 'Volt $version ($build)';
  }

  @override
  String gaugeDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String gaugeEnds(String date) {
    return 'Ends $date';
  }

  @override
  String gaugeEnded(String date) {
    return 'Ended $date';
  }

  @override
  String gaugeStarts(String date) {
    return 'Starts $date';
  }

  @override
  String gaugeUntil(String date) {
    return 'Until $date';
  }

  @override
  String get gaugeLastDay => 'Last day';

  @override
  String get gaugeEndsToday => 'Ends today';

  @override
  String get gaugeExpired => 'Expired';

  @override
  String get gaugeFrozen => 'Frozen';

  @override
  String get gaugeCancelled => 'Cancelled';

  @override
  String get gaugeStartsSoon => 'Starts soon';

  @override
  String get gaugeNoPlan => 'No plan';

  @override
  String get gaugeNoPlanHint => 'Ask your gym to start one';

  @override
  String get gaugeRenewSoon => 'Renew soon';

  @override
  String get renew => 'Renew';

  @override
  String get recentVisits => 'Recent visits';

  @override
  String get seeAll => 'See all';

  @override
  String get today => 'Today';

  @override
  String get yesterday => 'Yesterday';

  @override
  String get visitCheckedIn => 'Checked in';

  @override
  String get visitDenied => 'Not let in';

  @override
  String get noVisitsYet => 'No visits yet. Your check-ins will show here.';

  @override
  String get offlineNotice => 'You\'re offline. This is what we saw last.';

  @override
  String get loadFailed => 'We couldn\'t load this.';

  @override
  String get reasonMembershipExpired => 'Membership expired';

  @override
  String get reasonMembershipFrozen => 'Membership frozen';

  @override
  String get reasonOutsideHours => 'Outside your plan\'s hours';

  @override
  String get reasonBranchNotAllowed => 'This branch isn\'t in your plan';

  @override
  String get reasonNoVisitsRemaining => 'No visits left';

  @override
  String get reasonAlreadyCheckedIn => 'Already checked in';

  @override
  String get reasonOther => 'Not allowed in';

  @override
  String get visitsTitle => 'Visits';

  @override
  String get statusActive => 'Active';

  @override
  String get statusFrozen => 'Frozen';

  @override
  String get statusExpired => 'Expired';

  @override
  String get statusPending => 'Starts soon';

  @override
  String get statusCancelled => 'Cancelled';

  @override
  String get statusUnknown => 'Unknown';

  @override
  String get startDate => 'Start date';

  @override
  String get endDate => 'End date';

  @override
  String daysLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days left',
      one: '1 day left',
    );
    return '$_temp0';
  }

  @override
  String visitsLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count visits left',
      one: '1 visit left',
    );
    return '$_temp0';
  }

  @override
  String get allowedBranches => 'Branches you can use';

  @override
  String frozenNotice(String date) {
    return 'Your membership is frozen until $date.';
  }

  @override
  String graceNotice(String date) {
    return 'Your plan has ended, but the gym lets you in until $date.';
  }

  @override
  String get noPlanTitle => 'No active plan';

  @override
  String get noPlanBody =>
      'Ask your gym\'s front desk to start a plan for you.';

  @override
  String get renewPlan => 'Renew plan';

  @override
  String qrMember(String name) {
    return 'Member · $name';
  }

  @override
  String qrNewCodeIn(int seconds) {
    return 'New code in $seconds s';
  }

  @override
  String get qrHint =>
      'Show this at the front desk. The code changes every 30 seconds, so a screenshot won\'t work.';

  @override
  String get qrWorksOffline => 'Works without internet';

  @override
  String get qrImageLabel => 'QR code for check-in';

  @override
  String get qrSetupTitle => 'Connect to set up your QR';

  @override
  String get qrSetupBody =>
      'Your QR is created online the first time. After that it works without internet.';

  @override
  String get qrReplacedTitle => 'Your QR is on another phone';

  @override
  String get qrReplacedBody =>
      'You set it up on another phone, so the code here stopped working. Move it back to this phone?';

  @override
  String get qrUseThisPhone => 'Use this phone';

  @override
  String get qrRevokedTitle => 'Your QR was turned off';

  @override
  String get qrRevokedBody => 'Ask your gym\'s front desk to turn it back on.';

  @override
  String get settings => 'Settings';

  @override
  String get calendar => 'Calendar';

  @override
  String get calendarAuto => 'Same as language';

  @override
  String get calendarGregorian => 'Gregorian';

  @override
  String get calendarEthiopian => 'Ethiopian';

  @override
  String get calendarBoth => 'Both';

  @override
  String get devices => 'Signed-in devices';

  @override
  String get thisPhone => 'This phone';

  @override
  String lastActive(String date) {
    return 'Last active $date';
  }

  @override
  String signOutDeviceTitle(String device) {
    return 'Sign out $device?';
  }

  @override
  String get signOutDeviceBody =>
      'It will need a new SMS code to sign in, and its QR code stops working.';

  @override
  String get cancel => 'Cancel';

  @override
  String get amountDue => 'Amount due';

  @override
  String dueOn(String date) {
    return 'Due $date';
  }

  @override
  String get dueDate => 'Due date';

  @override
  String get paymentDue => 'Payment due';

  @override
  String get payNow => 'Pay now';

  @override
  String get pay => 'Pay';

  @override
  String payAmount(String amount) {
    return 'Pay $amount';
  }

  @override
  String get plansTitle => 'Renew or change your plan';

  @override
  String get choosePlan => 'Choose';

  @override
  String get historyTitle => 'History';

  @override
  String get noInvoices => 'No payments yet.';

  @override
  String get invoiceStatusOpen => 'Unpaid';

  @override
  String get invoiceStatusPaid => 'Paid';

  @override
  String get invoiceStatusVoid => 'Cancelled';

  @override
  String invoiceTitle(String number) {
    return 'Invoice $number';
  }

  @override
  String get issuedOn => 'Issued';

  @override
  String get total => 'Total';

  @override
  String get receiptTitle => 'Receipt';

  @override
  String get paidOn => 'Paid';

  @override
  String get paymentMethod => 'Method';

  @override
  String get paymentReference => 'Reference';

  @override
  String get openReceipt => 'Open receipt';

  @override
  String get confirmPlanBody =>
      'Your membership is extended as soon as Chapa confirms the payment.';

  @override
  String get securedByChapa =>
      'Secure checkout by Chapa: telebirr, CBE Birr and cards';

  @override
  String get checkoutTitle => 'Pay with Chapa';

  @override
  String get leaveCheckoutTitle => 'Leave the payment?';

  @override
  String get leaveCheckoutBody =>
      'If you already paid, we\'ll still confirm it.';

  @override
  String get leave => 'Leave';

  @override
  String get stay => 'Stay';

  @override
  String get resultConfirming => 'Confirming your payment';

  @override
  String get resultConfirmingBody => 'This usually takes a few seconds.';

  @override
  String get resultSucceeded => 'Payment received';

  @override
  String resultSucceededUntil(String date) {
    return 'Your membership is active until $date.';
  }

  @override
  String get resultSucceededBody => 'Thank you. Your receipt is ready.';

  @override
  String get resultFailed => 'Payment didn\'t go through';

  @override
  String get resultFailedBody =>
      'Chapa couldn\'t complete the payment. You can try again.';

  @override
  String get resultNotFinished => 'Payment not finished';

  @override
  String get resultNotFinishedBody =>
      'You left before paying, so your plan hasn\'t changed.';

  @override
  String get resultStillConfirming => 'Still confirming';

  @override
  String get resultStillConfirmingBody =>
      'Chapa hasn\'t confirmed the payment yet. You can leave this screen: your membership updates as soon as it does.';

  @override
  String get viewReceipt => 'View receipt';

  @override
  String get backToPayments => 'Back to payments';

  @override
  String get done => 'Done';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get markAllRead => 'Mark all as read';

  @override
  String get unread => 'Unread';

  @override
  String get noNotifications => 'Nothing here yet';

  @override
  String get noNotificationsBody =>
      'We\'ll let you know here when your plan is ending, a payment is due, or your gym has news.';

  @override
  String get pushPromptTitle => 'Turn on notifications';

  @override
  String get pushPromptBody =>
      'Get a reminder before your plan ends, and know when a payment goes through.';

  @override
  String get turnOn => 'Turn on';

  @override
  String get notNow => 'Not now';

  @override
  String get pushBlockedTitle => 'Notifications are off';

  @override
  String get pushBlockedBody =>
      'To get reminders, allow notifications for Volt in your phone\'s settings.';

  @override
  String get openSettings => 'Open settings';

  @override
  String get pushUnavailable =>
      'This version of the app can\'t send notifications to your phone yet. You can still read them from the bell on the home screen.';

  @override
  String get notifyMeAbout => 'Notify me about';

  @override
  String get topicMembership => 'My plan';

  @override
  String get topicMembershipHint => 'Ending soon, ended or renewed';

  @override
  String get topicPayments => 'Payments';

  @override
  String get topicPaymentsHint => 'New invoices, due dates and receipts';

  @override
  String get topicVisits => 'Check-ins';

  @override
  String get topicVisitsHint => 'When a check-in is turned away';

  @override
  String get topicAnnouncements => 'News from your gym';

  @override
  String get topicAnnouncementsHint => 'Opening hours, closures and events';

  @override
  String get inboxKeepsAll =>
      'Turning a topic off only stops the alerts on your phone. You can still read everything from the bell on the home screen.';

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
