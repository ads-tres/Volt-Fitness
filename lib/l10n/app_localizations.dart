import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_am.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('am'),
  ];

  /// App name in the task switcher. A brand name: not translated.
  ///
  /// In en, this message translates to:
  /// **'Volt'**
  String get appTitle;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// Language menu option that follows the phone's language.
  ///
  /// In en, this message translates to:
  /// **'Use phone setting'**
  String get languageSystem;

  /// Always written in English, whatever the current language.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// Always written in Amharic, whatever the current language.
  ///
  /// In en, this message translates to:
  /// **'አማርኛ'**
  String get languageAmharic;

  /// No description provided for @welcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Volt'**
  String get welcomeTitle;

  /// No description provided for @welcomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in with the phone number your gym has on file.'**
  String get welcomeSubtitle;

  /// No description provided for @phoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get phoneLabel;

  /// No description provided for @continueButton.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueButton;

  /// No description provided for @smsNotice.
  ///
  /// In en, this message translates to:
  /// **'We\'ll text you a 6-digit code.'**
  String get smsNotice;

  /// Shown only in development builds that use the built-in fake backend.
  ///
  /// In en, this message translates to:
  /// **'Test mode · code {code}'**
  String testModeNotice(String code);

  /// No description provided for @phoneInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter an Ethiopian mobile number, like 0911 23 45 67.'**
  String get phoneInvalid;

  /// No description provided for @otpTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter the code'**
  String get otpTitle;

  /// No description provided for @otpSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We sent a 6-digit code to {phone}.'**
  String otpSubtitle(String phone);

  /// No description provided for @verifyButton.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get verifyButton;

  /// No description provided for @resendIn.
  ///
  /// In en, this message translates to:
  /// **'Resend code in {time}'**
  String resendIn(String time);

  /// No description provided for @resendCode.
  ///
  /// In en, this message translates to:
  /// **'Resend code'**
  String get resendCode;

  /// No description provided for @codeResent.
  ///
  /// In en, this message translates to:
  /// **'We sent you a new code.'**
  String get codeResent;

  /// No description provided for @otpInvalid.
  ///
  /// In en, this message translates to:
  /// **'That code isn\'t right. Check the SMS and try again.'**
  String get otpInvalid;

  /// No description provided for @otpExpired.
  ///
  /// In en, this message translates to:
  /// **'That code has expired. Ask for a new one.'**
  String get otpExpired;

  /// No description provided for @otpTooManyAttempts.
  ///
  /// In en, this message translates to:
  /// **'Too many wrong codes. Wait a minute, then ask for a new one.'**
  String get otpTooManyAttempts;

  /// No description provided for @selectGymTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose your gym'**
  String get selectGymTitle;

  /// No description provided for @selectGymSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your number is registered at more than one gym. You can switch later in your profile.'**
  String get selectGymSubtitle;

  /// No description provided for @noGymTitle.
  ///
  /// In en, this message translates to:
  /// **'No gym found'**
  String get noGymTitle;

  /// No description provided for @noGymMessage.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t find a membership for {phone}. Ask your gym\'s front desk to register this number.'**
  String noGymMessage(String phone);

  /// No description provided for @useAnotherNumber.
  ///
  /// In en, this message translates to:
  /// **'Use another number'**
  String get useAnotherNumber;

  /// No description provided for @onboardingTrainTitle.
  ///
  /// In en, this message translates to:
  /// **'Your gym,\nin your pocket'**
  String get onboardingTrainTitle;

  /// No description provided for @onboardingTrainBody.
  ///
  /// In en, this message translates to:
  /// **'Your membership, check-ins and payments in one app.'**
  String get onboardingTrainBody;

  /// No description provided for @onboardingCheckInTitle.
  ///
  /// In en, this message translates to:
  /// **'Check in with\none scan'**
  String get onboardingCheckInTitle;

  /// No description provided for @onboardingCheckInBody.
  ///
  /// In en, this message translates to:
  /// **'Show your QR code at the front desk. No card to forget.'**
  String get onboardingCheckInBody;

  /// No description provided for @onboardingRenewTitle.
  ///
  /// In en, this message translates to:
  /// **'Renew without\nthe queue'**
  String get onboardingRenewTitle;

  /// No description provided for @onboardingRenewBody.
  ///
  /// In en, this message translates to:
  /// **'See what you owe, pay from your phone and get a reminder before your plan ends.'**
  String get onboardingRenewBody;

  /// Sample value on a welcome photo, showing what the app tracks.
  ///
  /// In en, this message translates to:
  /// **'18 days left'**
  String get onboardingPinDaysLeft;

  /// No description provided for @onboardingPinCheckedIn.
  ///
  /// In en, this message translates to:
  /// **'Checked in · 06:42'**
  String get onboardingPinCheckedIn;

  /// No description provided for @onboardingPinPaid.
  ///
  /// In en, this message translates to:
  /// **'Paid · 1,500 ETB'**
  String get onboardingPinPaid;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get getStarted;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navMembership.
  ///
  /// In en, this message translates to:
  /// **'Membership'**
  String get navMembership;

  /// No description provided for @navQr.
  ///
  /// In en, this message translates to:
  /// **'My QR'**
  String get navQr;

  /// No description provided for @navPayments.
  ///
  /// In en, this message translates to:
  /// **'Payments'**
  String get navPayments;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @greeting.
  ///
  /// In en, this message translates to:
  /// **'Hello, {name}'**
  String greeting(String name);

  /// No description provided for @greetingNoName.
  ///
  /// In en, this message translates to:
  /// **'Hello'**
  String get greetingNoName;

  /// No description provided for @showQrTitle.
  ///
  /// In en, this message translates to:
  /// **'Show my QR'**
  String get showQrTitle;

  /// No description provided for @showQrSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Scan it at the front desk to check in.'**
  String get showQrSubtitle;

  /// No description provided for @quickAccess.
  ///
  /// In en, this message translates to:
  /// **'Quick access'**
  String get quickAccess;

  /// No description provided for @yourGym.
  ///
  /// In en, this message translates to:
  /// **'Your gym'**
  String get yourGym;

  /// No description provided for @frontDesk.
  ///
  /// In en, this message translates to:
  /// **'Front desk'**
  String get frontDesk;

  /// No description provided for @switchGym.
  ///
  /// In en, this message translates to:
  /// **'Switch'**
  String get switchGym;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @appVersion.
  ///
  /// In en, this message translates to:
  /// **'Volt {version} ({build})'**
  String appVersion(String version, String build);

  /// The big number in the membership gauge: days left in the plan.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day} other{{count} days}}'**
  String gaugeDays(int count);

  /// No description provided for @gaugeEnds.
  ///
  /// In en, this message translates to:
  /// **'Ends {date}'**
  String gaugeEnds(String date);

  /// No description provided for @gaugeEnded.
  ///
  /// In en, this message translates to:
  /// **'Ended {date}'**
  String gaugeEnded(String date);

  /// No description provided for @gaugeStarts.
  ///
  /// In en, this message translates to:
  /// **'Starts {date}'**
  String gaugeStarts(String date);

  /// No description provided for @gaugeUntil.
  ///
  /// In en, this message translates to:
  /// **'Until {date}'**
  String gaugeUntil(String date);

  /// No description provided for @gaugeLastDay.
  ///
  /// In en, this message translates to:
  /// **'Last day'**
  String get gaugeLastDay;

  /// No description provided for @gaugeEndsToday.
  ///
  /// In en, this message translates to:
  /// **'Ends today'**
  String get gaugeEndsToday;

  /// No description provided for @gaugeExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get gaugeExpired;

  /// No description provided for @gaugeFrozen.
  ///
  /// In en, this message translates to:
  /// **'Frozen'**
  String get gaugeFrozen;

  /// No description provided for @gaugeCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get gaugeCancelled;

  /// No description provided for @gaugeStartsSoon.
  ///
  /// In en, this message translates to:
  /// **'Starts soon'**
  String get gaugeStartsSoon;

  /// No description provided for @gaugeNoPlan.
  ///
  /// In en, this message translates to:
  /// **'No plan'**
  String get gaugeNoPlan;

  /// No description provided for @gaugeNoPlanHint.
  ///
  /// In en, this message translates to:
  /// **'Ask your gym to start one'**
  String get gaugeNoPlanHint;

  /// No description provided for @gaugeRenewSoon.
  ///
  /// In en, this message translates to:
  /// **'Renew soon'**
  String get gaugeRenewSoon;

  /// No description provided for @renew.
  ///
  /// In en, this message translates to:
  /// **'Renew'**
  String get renew;

  /// No description provided for @recentVisits.
  ///
  /// In en, this message translates to:
  /// **'Recent visits'**
  String get recentVisits;

  /// No description provided for @seeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get seeAll;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// No description provided for @visitCheckedIn.
  ///
  /// In en, this message translates to:
  /// **'Checked in'**
  String get visitCheckedIn;

  /// No description provided for @visitDenied.
  ///
  /// In en, this message translates to:
  /// **'Not let in'**
  String get visitDenied;

  /// No description provided for @noVisitsYet.
  ///
  /// In en, this message translates to:
  /// **'No visits yet. Your check-ins will show here.'**
  String get noVisitsYet;

  /// No description provided for @offlineNotice.
  ///
  /// In en, this message translates to:
  /// **'You\'re offline. This is what we saw last.'**
  String get offlineNotice;

  /// No description provided for @loadFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t load this.'**
  String get loadFailed;

  /// No description provided for @reasonMembershipExpired.
  ///
  /// In en, this message translates to:
  /// **'Membership expired'**
  String get reasonMembershipExpired;

  /// No description provided for @reasonMembershipFrozen.
  ///
  /// In en, this message translates to:
  /// **'Membership frozen'**
  String get reasonMembershipFrozen;

  /// No description provided for @reasonOutsideHours.
  ///
  /// In en, this message translates to:
  /// **'Outside your plan\'s hours'**
  String get reasonOutsideHours;

  /// No description provided for @reasonBranchNotAllowed.
  ///
  /// In en, this message translates to:
  /// **'This branch isn\'t in your plan'**
  String get reasonBranchNotAllowed;

  /// No description provided for @reasonNoVisitsRemaining.
  ///
  /// In en, this message translates to:
  /// **'No visits left'**
  String get reasonNoVisitsRemaining;

  /// No description provided for @reasonAlreadyCheckedIn.
  ///
  /// In en, this message translates to:
  /// **'Already checked in'**
  String get reasonAlreadyCheckedIn;

  /// No description provided for @reasonOther.
  ///
  /// In en, this message translates to:
  /// **'Not allowed in'**
  String get reasonOther;

  /// No description provided for @visitsTitle.
  ///
  /// In en, this message translates to:
  /// **'Visits'**
  String get visitsTitle;

  /// No description provided for @statusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get statusActive;

  /// No description provided for @statusFrozen.
  ///
  /// In en, this message translates to:
  /// **'Frozen'**
  String get statusFrozen;

  /// No description provided for @statusExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get statusExpired;

  /// No description provided for @statusPending.
  ///
  /// In en, this message translates to:
  /// **'Starts soon'**
  String get statusPending;

  /// No description provided for @statusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get statusCancelled;

  /// No description provided for @statusUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get statusUnknown;

  /// No description provided for @startDate.
  ///
  /// In en, this message translates to:
  /// **'Start date'**
  String get startDate;

  /// No description provided for @endDate.
  ///
  /// In en, this message translates to:
  /// **'End date'**
  String get endDate;

  /// No description provided for @daysLeft.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day left} other{{count} days left}}'**
  String daysLeft(int count);

  /// No description provided for @visitsLeft.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 visit left} other{{count} visits left}}'**
  String visitsLeft(int count);

  /// No description provided for @allowedBranches.
  ///
  /// In en, this message translates to:
  /// **'Branches you can use'**
  String get allowedBranches;

  /// No description provided for @frozenNotice.
  ///
  /// In en, this message translates to:
  /// **'Your membership is frozen until {date}.'**
  String frozenNotice(String date);

  /// No description provided for @graceNotice.
  ///
  /// In en, this message translates to:
  /// **'Your plan has ended, but the gym lets you in until {date}.'**
  String graceNotice(String date);

  /// No description provided for @noPlanTitle.
  ///
  /// In en, this message translates to:
  /// **'No active plan'**
  String get noPlanTitle;

  /// No description provided for @noPlanBody.
  ///
  /// In en, this message translates to:
  /// **'Ask your gym\'s front desk to start a plan for you.'**
  String get noPlanBody;

  /// No description provided for @renewPlan.
  ///
  /// In en, this message translates to:
  /// **'Renew plan'**
  String get renewPlan;

  /// No description provided for @qrMember.
  ///
  /// In en, this message translates to:
  /// **'Member · {name}'**
  String qrMember(String name);

  /// No description provided for @qrNewCodeIn.
  ///
  /// In en, this message translates to:
  /// **'New code in {seconds} s'**
  String qrNewCodeIn(int seconds);

  /// No description provided for @qrHint.
  ///
  /// In en, this message translates to:
  /// **'Show this at the front desk. The code changes every 30 seconds, so a screenshot won\'t work.'**
  String get qrHint;

  /// No description provided for @qrWorksOffline.
  ///
  /// In en, this message translates to:
  /// **'Works without internet'**
  String get qrWorksOffline;

  /// No description provided for @qrImageLabel.
  ///
  /// In en, this message translates to:
  /// **'QR code for check-in'**
  String get qrImageLabel;

  /// No description provided for @qrSetupTitle.
  ///
  /// In en, this message translates to:
  /// **'Connect to set up your QR'**
  String get qrSetupTitle;

  /// No description provided for @qrSetupBody.
  ///
  /// In en, this message translates to:
  /// **'Your QR is created online the first time. After that it works without internet.'**
  String get qrSetupBody;

  /// No description provided for @qrReplacedTitle.
  ///
  /// In en, this message translates to:
  /// **'Your QR is on another phone'**
  String get qrReplacedTitle;

  /// No description provided for @qrReplacedBody.
  ///
  /// In en, this message translates to:
  /// **'You set it up on another phone, so the code here stopped working. Move it back to this phone?'**
  String get qrReplacedBody;

  /// No description provided for @qrUseThisPhone.
  ///
  /// In en, this message translates to:
  /// **'Use this phone'**
  String get qrUseThisPhone;

  /// No description provided for @qrRevokedTitle.
  ///
  /// In en, this message translates to:
  /// **'Your QR was turned off'**
  String get qrRevokedTitle;

  /// No description provided for @qrRevokedBody.
  ///
  /// In en, this message translates to:
  /// **'Ask your gym\'s front desk to turn it back on.'**
  String get qrRevokedBody;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @calendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get calendar;

  /// No description provided for @calendarAuto.
  ///
  /// In en, this message translates to:
  /// **'Same as language'**
  String get calendarAuto;

  /// No description provided for @calendarGregorian.
  ///
  /// In en, this message translates to:
  /// **'Gregorian'**
  String get calendarGregorian;

  /// No description provided for @calendarEthiopian.
  ///
  /// In en, this message translates to:
  /// **'Ethiopian'**
  String get calendarEthiopian;

  /// No description provided for @calendarBoth.
  ///
  /// In en, this message translates to:
  /// **'Both'**
  String get calendarBoth;

  /// No description provided for @devices.
  ///
  /// In en, this message translates to:
  /// **'Signed-in devices'**
  String get devices;

  /// No description provided for @thisPhone.
  ///
  /// In en, this message translates to:
  /// **'This phone'**
  String get thisPhone;

  /// No description provided for @lastActive.
  ///
  /// In en, this message translates to:
  /// **'Last active {date}'**
  String lastActive(String date);

  /// No description provided for @signOutDeviceTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign out {device}?'**
  String signOutDeviceTitle(String device);

  /// No description provided for @signOutDeviceBody.
  ///
  /// In en, this message translates to:
  /// **'It will need a new SMS code to sign in, and its QR code stops working.'**
  String get signOutDeviceBody;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @amountDue.
  ///
  /// In en, this message translates to:
  /// **'Amount due'**
  String get amountDue;

  /// No description provided for @dueOn.
  ///
  /// In en, this message translates to:
  /// **'Due {date}'**
  String dueOn(String date);

  /// No description provided for @dueDate.
  ///
  /// In en, this message translates to:
  /// **'Due date'**
  String get dueDate;

  /// No description provided for @paymentDue.
  ///
  /// In en, this message translates to:
  /// **'Payment due'**
  String get paymentDue;

  /// No description provided for @payNow.
  ///
  /// In en, this message translates to:
  /// **'Pay now'**
  String get payNow;

  /// No description provided for @pay.
  ///
  /// In en, this message translates to:
  /// **'Pay'**
  String get pay;

  /// No description provided for @payAmount.
  ///
  /// In en, this message translates to:
  /// **'Pay {amount}'**
  String payAmount(String amount);

  /// No description provided for @plansTitle.
  ///
  /// In en, this message translates to:
  /// **'Renew or change your plan'**
  String get plansTitle;

  /// No description provided for @choosePlan.
  ///
  /// In en, this message translates to:
  /// **'Choose'**
  String get choosePlan;

  /// No description provided for @historyTitle.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get historyTitle;

  /// No description provided for @noInvoices.
  ///
  /// In en, this message translates to:
  /// **'No payments yet.'**
  String get noInvoices;

  /// No description provided for @invoiceStatusOpen.
  ///
  /// In en, this message translates to:
  /// **'Unpaid'**
  String get invoiceStatusOpen;

  /// No description provided for @invoiceStatusPaid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get invoiceStatusPaid;

  /// No description provided for @invoiceStatusVoid.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get invoiceStatusVoid;

  /// No description provided for @invoiceTitle.
  ///
  /// In en, this message translates to:
  /// **'Invoice {number}'**
  String invoiceTitle(String number);

  /// No description provided for @issuedOn.
  ///
  /// In en, this message translates to:
  /// **'Issued'**
  String get issuedOn;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @receiptTitle.
  ///
  /// In en, this message translates to:
  /// **'Receipt'**
  String get receiptTitle;

  /// No description provided for @paidOn.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get paidOn;

  /// No description provided for @paymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Method'**
  String get paymentMethod;

  /// No description provided for @paymentReference.
  ///
  /// In en, this message translates to:
  /// **'Reference'**
  String get paymentReference;

  /// No description provided for @openReceipt.
  ///
  /// In en, this message translates to:
  /// **'Open receipt'**
  String get openReceipt;

  /// No description provided for @confirmPlanBody.
  ///
  /// In en, this message translates to:
  /// **'Your membership is extended as soon as Chapa confirms the payment.'**
  String get confirmPlanBody;

  /// No description provided for @securedByChapa.
  ///
  /// In en, this message translates to:
  /// **'Secure checkout by Chapa: telebirr, CBE Birr and cards'**
  String get securedByChapa;

  /// No description provided for @checkoutTitle.
  ///
  /// In en, this message translates to:
  /// **'Pay with Chapa'**
  String get checkoutTitle;

  /// No description provided for @leaveCheckoutTitle.
  ///
  /// In en, this message translates to:
  /// **'Leave the payment?'**
  String get leaveCheckoutTitle;

  /// No description provided for @leaveCheckoutBody.
  ///
  /// In en, this message translates to:
  /// **'If you already paid, we\'ll still confirm it.'**
  String get leaveCheckoutBody;

  /// No description provided for @leave.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get leave;

  /// No description provided for @stay.
  ///
  /// In en, this message translates to:
  /// **'Stay'**
  String get stay;

  /// No description provided for @resultConfirming.
  ///
  /// In en, this message translates to:
  /// **'Confirming your payment'**
  String get resultConfirming;

  /// No description provided for @resultConfirmingBody.
  ///
  /// In en, this message translates to:
  /// **'This usually takes a few seconds.'**
  String get resultConfirmingBody;

  /// No description provided for @resultSucceeded.
  ///
  /// In en, this message translates to:
  /// **'Payment received'**
  String get resultSucceeded;

  /// No description provided for @resultSucceededUntil.
  ///
  /// In en, this message translates to:
  /// **'Your membership is active until {date}.'**
  String resultSucceededUntil(String date);

  /// No description provided for @resultSucceededBody.
  ///
  /// In en, this message translates to:
  /// **'Thank you. Your receipt is ready.'**
  String get resultSucceededBody;

  /// No description provided for @resultFailed.
  ///
  /// In en, this message translates to:
  /// **'Payment didn\'t go through'**
  String get resultFailed;

  /// No description provided for @resultFailedBody.
  ///
  /// In en, this message translates to:
  /// **'Chapa couldn\'t complete the payment. You can try again.'**
  String get resultFailedBody;

  /// No description provided for @resultNotFinished.
  ///
  /// In en, this message translates to:
  /// **'Payment not finished'**
  String get resultNotFinished;

  /// No description provided for @resultNotFinishedBody.
  ///
  /// In en, this message translates to:
  /// **'You left before paying, so your plan hasn\'t changed.'**
  String get resultNotFinishedBody;

  /// No description provided for @resultStillConfirming.
  ///
  /// In en, this message translates to:
  /// **'Still confirming'**
  String get resultStillConfirming;

  /// No description provided for @resultStillConfirmingBody.
  ///
  /// In en, this message translates to:
  /// **'Chapa hasn\'t confirmed the payment yet. You can leave this screen: your membership updates as soon as it does.'**
  String get resultStillConfirmingBody;

  /// No description provided for @viewReceipt.
  ///
  /// In en, this message translates to:
  /// **'View receipt'**
  String get viewReceipt;

  /// No description provided for @backToPayments.
  ///
  /// In en, this message translates to:
  /// **'Back to payments'**
  String get backToPayments;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get retry;

  /// No description provided for @errorNetwork.
  ///
  /// In en, this message translates to:
  /// **'No internet connection. Check your connection and try again.'**
  String get errorNetwork;

  /// No description provided for @errorSessionExpired.
  ///
  /// In en, this message translates to:
  /// **'Your session has ended. Please sign in again.'**
  String get errorSessionExpired;

  /// No description provided for @errorForbidden.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have access to this.'**
  String get errorForbidden;

  /// No description provided for @errorNotFound.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t find what you were looking for.'**
  String get errorNotFound;

  /// No description provided for @errorConflict.
  ///
  /// In en, this message translates to:
  /// **'This changed in the meantime. Refresh and try again.'**
  String get errorConflict;

  /// No description provided for @errorValidation.
  ///
  /// In en, this message translates to:
  /// **'Some details need fixing. Check them and try again.'**
  String get errorValidation;

  /// No description provided for @errorRateLimited.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Please wait a moment and try again.'**
  String get errorRateLimited;

  /// No description provided for @errorUpdateRequired.
  ///
  /// In en, this message translates to:
  /// **'This version of the app is no longer supported. Please update to continue.'**
  String get errorUpdateRequired;

  /// No description provided for @errorServer.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong on our side. Please try again later.'**
  String get errorServer;

  /// No description provided for @errorUnexpected.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get errorUnexpected;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['am', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'am':
      return AppLocalizationsAm();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
