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

  /// No description provided for @notificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsTitle;

  /// No description provided for @markAllRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all as read'**
  String get markAllRead;

  /// No description provided for @unread.
  ///
  /// In en, this message translates to:
  /// **'Unread'**
  String get unread;

  /// No description provided for @noNotifications.
  ///
  /// In en, this message translates to:
  /// **'Nothing here yet'**
  String get noNotifications;

  /// No description provided for @noNotificationsBody.
  ///
  /// In en, this message translates to:
  /// **'We\'ll let you know here when your plan is ending, a payment is due, or your gym has news.'**
  String get noNotificationsBody;

  /// No description provided for @pushPromptTitle.
  ///
  /// In en, this message translates to:
  /// **'Turn on notifications'**
  String get pushPromptTitle;

  /// No description provided for @pushPromptBody.
  ///
  /// In en, this message translates to:
  /// **'Get a reminder before your plan ends, and know when a payment goes through.'**
  String get pushPromptBody;

  /// No description provided for @turnOn.
  ///
  /// In en, this message translates to:
  /// **'Turn on'**
  String get turnOn;

  /// No description provided for @notNow.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get notNow;

  /// No description provided for @pushBlockedTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications are off'**
  String get pushBlockedTitle;

  /// No description provided for @pushBlockedBody.
  ///
  /// In en, this message translates to:
  /// **'To get reminders, allow notifications for Volt in your phone\'s settings.'**
  String get pushBlockedBody;

  /// No description provided for @openSettings.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get openSettings;

  /// No description provided for @pushUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This version of the app can\'t send notifications to your phone yet. You can still read them from the bell on the home screen.'**
  String get pushUnavailable;

  /// No description provided for @notifyMeAbout.
  ///
  /// In en, this message translates to:
  /// **'Notify me about'**
  String get notifyMeAbout;

  /// No description provided for @topicMembership.
  ///
  /// In en, this message translates to:
  /// **'My plan'**
  String get topicMembership;

  /// No description provided for @topicMembershipHint.
  ///
  /// In en, this message translates to:
  /// **'Ending soon, ended or renewed'**
  String get topicMembershipHint;

  /// No description provided for @topicPayments.
  ///
  /// In en, this message translates to:
  /// **'Payments'**
  String get topicPayments;

  /// No description provided for @topicPaymentsHint.
  ///
  /// In en, this message translates to:
  /// **'New invoices, due dates and receipts'**
  String get topicPaymentsHint;

  /// No description provided for @topicVisits.
  ///
  /// In en, this message translates to:
  /// **'Check-ins'**
  String get topicVisits;

  /// No description provided for @topicVisitsHint.
  ///
  /// In en, this message translates to:
  /// **'When a check-in is turned away'**
  String get topicVisitsHint;

  /// No description provided for @topicAnnouncements.
  ///
  /// In en, this message translates to:
  /// **'News from your gym'**
  String get topicAnnouncements;

  /// No description provided for @topicAnnouncementsHint.
  ///
  /// In en, this message translates to:
  /// **'Opening hours, closures and events'**
  String get topicAnnouncementsHint;

  /// No description provided for @inboxKeepsAll.
  ///
  /// In en, this message translates to:
  /// **'Turning a topic off only stops the alerts on your phone. You can still read everything from the bell on the home screen.'**
  String get inboxKeepsAll;

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

  /// The front desk app's name.
  ///
  /// In en, this message translates to:
  /// **'Volt Desk'**
  String get deskTitle;

  /// No description provided for @deskSignInTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to the front desk'**
  String get deskSignInTitle;

  /// No description provided for @deskSignInBody.
  ///
  /// In en, this message translates to:
  /// **'Use the phone number and the password you chose from the gym\'s SMS.'**
  String get deskSignInBody;

  /// No description provided for @deskPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get deskPassword;

  /// No description provided for @deskSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get deskSignIn;

  /// No description provided for @deskNoGym.
  ///
  /// In en, this message translates to:
  /// **'This number isn\'t staff at any gym.'**
  String get deskNoGym;

  /// No description provided for @deskChooseGym.
  ///
  /// In en, this message translates to:
  /// **'Choose the gym'**
  String get deskChooseGym;

  /// No description provided for @deskChooseBranch.
  ///
  /// In en, this message translates to:
  /// **'Which branch is this desk at?'**
  String get deskChooseBranch;

  /// No description provided for @deskNoBranches.
  ///
  /// In en, this message translates to:
  /// **'You don\'t work at any branch of this gym yet. Ask the gym\'s owner.'**
  String get deskNoBranches;

  /// No description provided for @deskChangeBranch.
  ///
  /// In en, this message translates to:
  /// **'Change branch'**
  String get deskChangeBranch;

  /// No description provided for @deskMenu.
  ///
  /// In en, this message translates to:
  /// **'Menu'**
  String get deskMenu;

  /// No description provided for @deskPointCamera.
  ///
  /// In en, this message translates to:
  /// **'Point the camera at the member\'s QR code'**
  String get deskPointCamera;

  /// No description provided for @deskCameraDenied.
  ///
  /// In en, this message translates to:
  /// **'The camera is off for Volt Desk. Allow it in the phone\'s settings to scan.'**
  String get deskCameraDenied;

  /// No description provided for @deskCameraFailed.
  ///
  /// In en, this message translates to:
  /// **'The camera couldn\'t start. Close other apps using it, then try again.'**
  String get deskCameraFailed;

  /// No description provided for @deskLetIn.
  ///
  /// In en, this message translates to:
  /// **'Let in'**
  String get deskLetIn;

  /// No description provided for @deskTurnedAway.
  ///
  /// In en, this message translates to:
  /// **'Turned away'**
  String get deskTurnedAway;

  /// No description provided for @deskPlanUntil.
  ///
  /// In en, this message translates to:
  /// **'{plan} · until {date}'**
  String deskPlanUntil(String plan, String date);

  /// No description provided for @deskOwes.
  ///
  /// In en, this message translates to:
  /// **'Owes {amount}'**
  String deskOwes(String amount);

  /// No description provided for @deskTapToContinue.
  ///
  /// In en, this message translates to:
  /// **'Tap to scan the next member'**
  String get deskTapToContinue;

  /// No description provided for @deskReasonCredentialInvalid.
  ///
  /// In en, this message translates to:
  /// **'Not a member\'s code, or a code for another gym'**
  String get deskReasonCredentialInvalid;

  /// No description provided for @deskReasonCredentialRevoked.
  ///
  /// In en, this message translates to:
  /// **'This phone\'s code was replaced. Ask the member to open the app.'**
  String get deskReasonCredentialRevoked;

  /// No description provided for @deskReasonCodeExpired.
  ///
  /// In en, this message translates to:
  /// **'The code has expired. The member\'s phone clock may be wrong.'**
  String get deskReasonCodeExpired;

  /// No description provided for @deskReasonCodeAlreadyUsed.
  ///
  /// In en, this message translates to:
  /// **'This code was already scanned. Ask for the code the app shows now.'**
  String get deskReasonCodeAlreadyUsed;

  /// No description provided for @deskReasonOutsideHours.
  ///
  /// In en, this message translates to:
  /// **'The branch is closed now'**
  String get deskReasonOutsideHours;

  /// No description provided for @deskReasonMembershipNone.
  ///
  /// In en, this message translates to:
  /// **'No membership for today'**
  String get deskReasonMembershipNone;

  /// No description provided for @deskReasonMembershipExpired.
  ///
  /// In en, this message translates to:
  /// **'The membership has ended'**
  String get deskReasonMembershipExpired;

  /// No description provided for @deskReasonMembershipFrozen.
  ///
  /// In en, this message translates to:
  /// **'The membership is frozen today'**
  String get deskReasonMembershipFrozen;

  /// No description provided for @deskReasonBranchNotAllowed.
  ///
  /// In en, this message translates to:
  /// **'The membership isn\'t valid at this branch'**
  String get deskReasonBranchNotAllowed;

  /// No description provided for @deskReasonVisitsUsedUp.
  ///
  /// In en, this message translates to:
  /// **'Every visit of the pack is used'**
  String get deskReasonVisitsUsedUp;

  /// No description provided for @deskReasonAlreadyCheckedIn.
  ///
  /// In en, this message translates to:
  /// **'Let in less than 5 minutes ago'**
  String get deskReasonAlreadyCheckedIn;

  /// No description provided for @deskReasonOther.
  ///
  /// In en, this message translates to:
  /// **'Not let in'**
  String get deskReasonOther;

  /// No description provided for @deskTabScan.
  ///
  /// In en, this message translates to:
  /// **'Scan'**
  String get deskTabScan;

  /// No description provided for @deskTabDesk.
  ///
  /// In en, this message translates to:
  /// **'Desk'**
  String get deskTabDesk;

  /// No description provided for @deskTabToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get deskTabToday;

  /// No description provided for @deskSearchMembers.
  ///
  /// In en, this message translates to:
  /// **'Name or phone number'**
  String get deskSearchMembers;

  /// No description provided for @deskSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Find a member who came without their phone, then check them in.'**
  String get deskSearchHint;

  /// No description provided for @deskNoMembersFound.
  ///
  /// In en, this message translates to:
  /// **'No member of this gym matches.'**
  String get deskNoMembersFound;

  /// No description provided for @deskCheckIn.
  ///
  /// In en, this message translates to:
  /// **'Check in'**
  String get deskCheckIn;

  /// No description provided for @deskTodayTitle.
  ///
  /// In en, this message translates to:
  /// **'Today at this branch'**
  String get deskTodayTitle;

  /// No description provided for @deskTodayEmpty.
  ///
  /// In en, this message translates to:
  /// **'No one has checked in here yet today.'**
  String get deskTodayEmpty;

  /// No description provided for @deskUnknownMember.
  ///
  /// In en, this message translates to:
  /// **'Unknown code'**
  String get deskUnknownMember;

  /// No description provided for @freezeDays.
  ///
  /// In en, this message translates to:
  /// **'Freeze days'**
  String get freezeDays;

  /// No description provided for @freezeDaysLeftOf.
  ///
  /// In en, this message translates to:
  /// **'{left} of {allowed} left'**
  String freezeDaysLeftOf(int left, int allowed);

  /// No description provided for @freezeMembership.
  ///
  /// In en, this message translates to:
  /// **'Freeze my membership'**
  String get freezeMembership;

  /// No description provided for @freezeSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Freeze your membership'**
  String get freezeSheetTitle;

  /// No description provided for @freezeSheetBody.
  ///
  /// In en, this message translates to:
  /// **'Your plan pauses on these days, and its end date moves later by as many days.'**
  String get freezeSheetBody;

  /// No description provided for @freezeFirstDay.
  ///
  /// In en, this message translates to:
  /// **'First day'**
  String get freezeFirstDay;

  /// No description provided for @freezeLastDay.
  ///
  /// In en, this message translates to:
  /// **'Last day'**
  String get freezeLastDay;

  /// No description provided for @freezeSummary.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =1{1 day} other{{days} days}} · your plan will end on {date}'**
  String freezeSummary(int days, String date);

  /// No description provided for @freezeTooManyDays.
  ///
  /// In en, this message translates to:
  /// **'{left, plural, =1{Only 1 freeze day is left.} other{Only {left} freeze days are left.}}'**
  String freezeTooManyDays(int left);

  /// No description provided for @freezeReason.
  ///
  /// In en, this message translates to:
  /// **'Reason (optional)'**
  String get freezeReason;

  /// No description provided for @freezeReasonHint.
  ///
  /// In en, this message translates to:
  /// **'Travel, illness…'**
  String get freezeReasonHint;

  /// No description provided for @freezeConfirm.
  ///
  /// In en, this message translates to:
  /// **'Freeze'**
  String get freezeConfirm;

  /// No description provided for @freezeDone.
  ///
  /// In en, this message translates to:
  /// **'Frozen from {from} to {to}.'**
  String freezeDone(String from, String to);

  /// No description provided for @freezeCurrent.
  ///
  /// In en, this message translates to:
  /// **'Frozen from {from} to {to}'**
  String freezeCurrent(String from, String to);

  /// No description provided for @freezeComing.
  ///
  /// In en, this message translates to:
  /// **'Freeze from {from} to {to}'**
  String freezeComing(String from, String to);

  /// No description provided for @freezeLength.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =1{1 day} other{{days} days}}'**
  String freezeLength(int days);

  /// No description provided for @freezeBack.
  ///
  /// In en, this message translates to:
  /// **'I\'m back'**
  String get freezeBack;

  /// No description provided for @freezeCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel freeze'**
  String get freezeCancel;

  /// No description provided for @freezeBackTitle.
  ///
  /// In en, this message translates to:
  /// **'End your freeze today?'**
  String get freezeBackTitle;

  /// No description provided for @freezeBackBody.
  ///
  /// In en, this message translates to:
  /// **'You can use the gym again from today. The unused freeze days come back to you, and your plan ends earlier.'**
  String get freezeBackBody;

  /// No description provided for @freezeCancelTitle.
  ///
  /// In en, this message translates to:
  /// **'Cancel this freeze?'**
  String get freezeCancelTitle;

  /// No description provided for @freezeCancelBody.
  ///
  /// In en, this message translates to:
  /// **'The freeze days come back to you, and your plan\'s end date moves back.'**
  String get freezeCancelBody;

  /// No description provided for @freezeKeep.
  ///
  /// In en, this message translates to:
  /// **'Keep it'**
  String get freezeKeep;

  /// No description provided for @freezeEnded.
  ///
  /// In en, this message translates to:
  /// **'Welcome back! Your freeze has ended.'**
  String get freezeEnded;

  /// No description provided for @freezeCancelled.
  ///
  /// In en, this message translates to:
  /// **'Your freeze is cancelled.'**
  String get freezeCancelled;

  /// No description provided for @deskSavedOffline.
  ///
  /// In en, this message translates to:
  /// **'Saved, will check when back online'**
  String get deskSavedOffline;

  /// No description provided for @deskSavedOfflineBody.
  ///
  /// In en, this message translates to:
  /// **'No internet right now. Let them in if you\'re sure; the answer shows in Today once the scan is sent.'**
  String get deskSavedOfflineBody;

  /// No description provided for @deskWaitingBadge.
  ///
  /// In en, this message translates to:
  /// **'{count} waiting'**
  String deskWaitingBadge(int count);

  /// No description provided for @deskWaitingTitle.
  ///
  /// In en, this message translates to:
  /// **'Waiting to send'**
  String get deskWaitingTitle;

  /// No description provided for @deskWaitingBody.
  ///
  /// In en, this message translates to:
  /// **'Scanned without internet. They are sent as soon as the desk is back online.'**
  String get deskWaitingBody;

  /// No description provided for @deskWaitingRow.
  ///
  /// In en, this message translates to:
  /// **'Scanned at {time}'**
  String deskWaitingRow(String time);

  /// No description provided for @deskSendNow.
  ///
  /// In en, this message translates to:
  /// **'Send now'**
  String get deskSendNow;

  /// No description provided for @deskOfflineChip.
  ///
  /// In en, this message translates to:
  /// **'Scanned offline'**
  String get deskOfflineChip;

  /// No description provided for @deskDroppedNotice.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 scan couldn\'t be sent, as it was more than a day old.} other{{count} scans couldn\'t be sent, as they were more than a day old.}}'**
  String deskDroppedNotice(int count);

  /// No description provided for @deskDismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get deskDismiss;

  /// No description provided for @deskInboxTitle.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get deskInboxTitle;

  /// No description provided for @deskMarkAllRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all read'**
  String get deskMarkAllRead;

  /// No description provided for @deskInboxEmpty.
  ///
  /// In en, this message translates to:
  /// **'No messages yet. Online payments, refunds to make, freezes made in the app and the members to call show here.'**
  String get deskInboxEmpty;

  /// No description provided for @deskOpenPanel.
  ///
  /// In en, this message translates to:
  /// **'Open in the staff panel'**
  String get deskOpenPanel;

  /// No description provided for @deskViewMessage.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get deskViewMessage;

  /// No description provided for @deskNotificationSettings.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get deskNotificationSettings;

  /// No description provided for @deskTopicOnlinePayments.
  ///
  /// In en, this message translates to:
  /// **'Online payments'**
  String get deskTopicOnlinePayments;

  /// No description provided for @deskTopicRefunds.
  ///
  /// In en, this message translates to:
  /// **'Refunds to make'**
  String get deskTopicRefunds;

  /// No description provided for @deskTopicAppFreezes.
  ///
  /// In en, this message translates to:
  /// **'Freezes in the app'**
  String get deskTopicAppFreezes;

  /// No description provided for @deskTopicMembersToCall.
  ///
  /// In en, this message translates to:
  /// **'Members to call'**
  String get deskTopicMembersToCall;

  /// No description provided for @deskChannelPush.
  ///
  /// In en, this message translates to:
  /// **'Push'**
  String get deskChannelPush;

  /// No description provided for @deskChannelSms.
  ///
  /// In en, this message translates to:
  /// **'SMS'**
  String get deskChannelSms;

  /// No description provided for @deskQuietHours.
  ///
  /// In en, this message translates to:
  /// **'No SMS goes out between 21:00 and 07:00.'**
  String get deskQuietHours;

  /// No description provided for @promoCodeAsk.
  ///
  /// In en, this message translates to:
  /// **'Have a promo code?'**
  String get promoCodeAsk;

  /// No description provided for @promoCodeHint.
  ///
  /// In en, this message translates to:
  /// **'Promo code'**
  String get promoCodeHint;

  /// No description provided for @promoCodeApply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get promoCodeApply;

  /// No description provided for @promoCodeApplied.
  ///
  /// In en, this message translates to:
  /// **'{code} applied'**
  String promoCodeApplied(String code);

  /// No description provided for @promoCodeRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove the code'**
  String get promoCodeRemove;

  /// No description provided for @branchesTitle.
  ///
  /// In en, this message translates to:
  /// **'Branches and hours'**
  String get branchesTitle;

  /// No description provided for @branchAlwaysOpen.
  ///
  /// In en, this message translates to:
  /// **'Always open'**
  String get branchAlwaysOpen;

  /// No description provided for @branchOpenUntil.
  ///
  /// In en, this message translates to:
  /// **'Open now · until {time}'**
  String branchOpenUntil(String time);

  /// No description provided for @branchClosedOpensAt.
  ///
  /// In en, this message translates to:
  /// **'Closed · opens {time}'**
  String branchClosedOpensAt(String time);

  /// No description provided for @branchClosed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get branchClosed;

  /// No description provided for @branchOnYourPlan.
  ///
  /// In en, this message translates to:
  /// **'Your plan'**
  String get branchOnYourPlan;

  /// No description provided for @yourOtherPlans.
  ///
  /// In en, this message translates to:
  /// **'Your other plans'**
  String get yourOtherPlans;

  /// No description provided for @planDates.
  ///
  /// In en, this message translates to:
  /// **'{from} – {to}'**
  String planDates(String from, String to);

  /// No description provided for @planPaidOf.
  ///
  /// In en, this message translates to:
  /// **'Paid {paid} of {price}'**
  String planPaidOf(String paid, String price);

  /// No description provided for @freezeByYou.
  ///
  /// In en, this message translates to:
  /// **'you froze it in the app'**
  String get freezeByYou;

  /// No description provided for @freezeByGym.
  ///
  /// In en, this message translates to:
  /// **'frozen by the gym'**
  String get freezeByGym;

  /// No description provided for @numbersTitle.
  ///
  /// In en, this message translates to:
  /// **'Numbers'**
  String get numbersTitle;

  /// No description provided for @numbersToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get numbersToday;

  /// No description provided for @numbersWeek.
  ///
  /// In en, this message translates to:
  /// **'7 days'**
  String get numbersWeek;

  /// No description provided for @numbersMonth.
  ///
  /// In en, this message translates to:
  /// **'30 days'**
  String get numbersMonth;

  /// No description provided for @numbersAllBranches.
  ///
  /// In en, this message translates to:
  /// **'All my branches'**
  String get numbersAllBranches;

  /// No description provided for @numbersCheckIns.
  ///
  /// In en, this message translates to:
  /// **'Check-ins'**
  String get numbersCheckIns;

  /// No description provided for @numbersMoney.
  ///
  /// In en, this message translates to:
  /// **'Money'**
  String get numbersMoney;

  /// No description provided for @numbersTaken.
  ///
  /// In en, this message translates to:
  /// **'Taken'**
  String get numbersTaken;

  /// No description provided for @numbersReceived.
  ///
  /// In en, this message translates to:
  /// **'Received'**
  String get numbersReceived;

  /// No description provided for @numbersRefunded.
  ///
  /// In en, this message translates to:
  /// **'Refunded'**
  String get numbersRefunded;

  /// No description provided for @numbersOpenLinks.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 payment link open} other{{count} payment links open}}'**
  String numbersOpenLinks(int count);

  /// No description provided for @numbersRefundsNeeded.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 refund to make} other{{count} refunds to make}}'**
  String numbersRefundsNeeded(int count);

  /// No description provided for @numbersOwed.
  ///
  /// In en, this message translates to:
  /// **'Owed'**
  String get numbersOwed;

  /// No description provided for @numbersOwedMembers.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{by 1 member} other{by {count} members}}'**
  String numbersOwedMembers(int count);

  /// No description provided for @numbersMembers.
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get numbersMembers;

  /// No description provided for @numbersActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get numbersActive;

  /// No description provided for @numbersNew.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get numbersNew;

  /// No description provided for @numbersSoldAtDesk.
  ///
  /// In en, this message translates to:
  /// **'Plans sold at the desk'**
  String get numbersSoldAtDesk;

  /// No description provided for @numbersSoldInApp.
  ///
  /// In en, this message translates to:
  /// **'Plans sold in the app'**
  String get numbersSoldInApp;

  /// No description provided for @numbersBusyHours.
  ///
  /// In en, this message translates to:
  /// **'Busy hours'**
  String get numbersBusyHours;

  /// No description provided for @numbersToCall.
  ///
  /// In en, this message translates to:
  /// **'Members to call'**
  String get numbersToCall;

  /// No description provided for @numbersNoOneToCall.
  ///
  /// In en, this message translates to:
  /// **'No one to call: no plan ends in the next days.'**
  String get numbersNoOneToCall;

  /// No description provided for @numbersEnds.
  ///
  /// In en, this message translates to:
  /// **'ends {date}'**
  String numbersEnds(String date);

  /// No description provided for @numbersCall.
  ///
  /// In en, this message translates to:
  /// **'Call {phone}'**
  String numbersCall(String phone);

  /// No description provided for @deskDecidedOffline.
  ///
  /// In en, this message translates to:
  /// **'Decided offline'**
  String get deskDecidedOffline;

  /// No description provided for @deskReasonNoDoorList.
  ///
  /// In en, this message translates to:
  /// **'No internet, and no door list to check with'**
  String get deskReasonNoDoorList;

  /// No description provided for @deskOfflineRefused.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{The server didn\'t record 1 offline scan.} other{The server didn\'t record {count} offline scans.}}'**
  String deskOfflineRefused(int count);

  /// No description provided for @deskOfflineToReview.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 offline check-in to review in the panel.} other{{count} offline check-ins to review in the panel.}}'**
  String deskOfflineToReview(int count);

  /// No description provided for @deskNoInternetDemo.
  ///
  /// In en, this message translates to:
  /// **'No internet (demo)'**
  String get deskNoInternetDemo;

  /// No description provided for @deskServerDisagrees.
  ///
  /// In en, this message translates to:
  /// **'Server: {reason}, review in the panel'**
  String deskServerDisagrees(String reason);

  /// No description provided for @branchClosedToday.
  ///
  /// In en, this message translates to:
  /// **'Closed today: {reason}'**
  String branchClosedToday(String reason);

  /// No description provided for @branchOtherHoursToday.
  ///
  /// In en, this message translates to:
  /// **'Other hours today: {hours} · {reason}'**
  String branchOtherHoursToday(String hours, String reason);

  /// No description provided for @branchHoursNextDay.
  ///
  /// In en, this message translates to:
  /// **'{hours} (next day)'**
  String branchHoursNextDay(String hours);

  /// No description provided for @branchClosuresComing.
  ///
  /// In en, this message translates to:
  /// **'Closures and other hours'**
  String get branchClosuresComing;

  /// No description provided for @branchEveryYear.
  ///
  /// In en, this message translates to:
  /// **'Every year'**
  String get branchEveryYear;

  /// No description provided for @photoChange.
  ///
  /// In en, this message translates to:
  /// **'Change your photo'**
  String get photoChange;

  /// No description provided for @photoTitle.
  ///
  /// In en, this message translates to:
  /// **'Your photo'**
  String get photoTitle;

  /// No description provided for @photoBody.
  ///
  /// In en, this message translates to:
  /// **'The desk sees it when you check in, at every gym where your number is registered.'**
  String get photoBody;

  /// No description provided for @photoTake.
  ///
  /// In en, this message translates to:
  /// **'Take a photo'**
  String get photoTake;

  /// No description provided for @photoChoose.
  ///
  /// In en, this message translates to:
  /// **'Choose from gallery'**
  String get photoChoose;

  /// No description provided for @photoRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove photo'**
  String get photoRemove;

  /// No description provided for @photoSaved.
  ///
  /// In en, this message translates to:
  /// **'Your photo is saved.'**
  String get photoSaved;

  /// No description provided for @photoRemoved.
  ///
  /// In en, this message translates to:
  /// **'Your photo is removed.'**
  String get photoRemoved;

  /// No description provided for @deskMemberPhoto.
  ///
  /// In en, this message translates to:
  /// **'{name}\'s photo'**
  String deskMemberPhoto(String name);

  /// No description provided for @deskPhotoSaved.
  ///
  /// In en, this message translates to:
  /// **'{name}\'s photo is saved.'**
  String deskPhotoSaved(String name);

  /// No description provided for @deskPhotoRemoved.
  ///
  /// In en, this message translates to:
  /// **'{name}\'s photo is removed.'**
  String deskPhotoRemoved(String name);

  /// No description provided for @deskTakePayment.
  ///
  /// In en, this message translates to:
  /// **'Take payment'**
  String get deskTakePayment;

  /// No description provided for @payTitle.
  ///
  /// In en, this message translates to:
  /// **'Payment from {name}'**
  String payTitle(String name);

  /// No description provided for @payBody.
  ///
  /// In en, this message translates to:
  /// **'Record money the member paid at the desk, or text them a link to pay online.'**
  String get payBody;

  /// No description provided for @payWhichMembership.
  ///
  /// In en, this message translates to:
  /// **'Which membership'**
  String get payWhichMembership;

  /// No description provided for @payAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get payAmountLabel;

  /// No description provided for @payAmountHelp.
  ///
  /// In en, this message translates to:
  /// **'Up to {due} is due'**
  String payAmountHelp(String due);

  /// No description provided for @payAmountInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter an amount like 500 or 500.50.'**
  String get payAmountInvalid;

  /// No description provided for @payMethod.
  ///
  /// In en, this message translates to:
  /// **'How they paid'**
  String get payMethod;

  /// No description provided for @payCash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get payCash;

  /// No description provided for @payTelebirr.
  ///
  /// In en, this message translates to:
  /// **'telebirr'**
  String get payTelebirr;

  /// No description provided for @payCbeBirr.
  ///
  /// In en, this message translates to:
  /// **'CBE Birr'**
  String get payCbeBirr;

  /// No description provided for @payBankTransfer.
  ///
  /// In en, this message translates to:
  /// **'Bank transfer'**
  String get payBankTransfer;

  /// No description provided for @payReference.
  ///
  /// In en, this message translates to:
  /// **'Transaction number'**
  String get payReference;

  /// No description provided for @payReferenceHelp.
  ///
  /// In en, this message translates to:
  /// **'From the payment confirmation'**
  String get payReferenceHelp;

  /// No description provided for @payPaidOn.
  ///
  /// In en, this message translates to:
  /// **'Paid on'**
  String get payPaidOn;

  /// No description provided for @payToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get payToday;

  /// No description provided for @paySummary.
  ///
  /// In en, this message translates to:
  /// **'{amount} by {method} from {name} · {left} left'**
  String paySummary(String amount, String method, String name, String left);

  /// No description provided for @paySummaryPaidOff.
  ///
  /// In en, this message translates to:
  /// **'{amount} by {method} from {name} · paid in full'**
  String paySummaryPaidOff(String amount, String method, String name);

  /// No description provided for @payRecord.
  ///
  /// In en, this message translates to:
  /// **'Record payment'**
  String get payRecord;

  /// No description provided for @payRecorded.
  ///
  /// In en, this message translates to:
  /// **'Receipt {receipt} · {amount}'**
  String payRecorded(String receipt, String amount);

  /// No description provided for @payTextLink.
  ///
  /// In en, this message translates to:
  /// **'Text a pay link instead'**
  String get payTextLink;

  /// No description provided for @payTextAgain.
  ///
  /// In en, this message translates to:
  /// **'Text the pay link again'**
  String get payTextAgain;

  /// No description provided for @payLinkOpen.
  ///
  /// In en, this message translates to:
  /// **'A pay link for this membership is already open.'**
  String get payLinkOpen;

  /// No description provided for @payLinkTexted.
  ///
  /// In en, this message translates to:
  /// **'Pay link texted to {phone}'**
  String payLinkTexted(String phone);

  /// No description provided for @payNothingDue.
  ///
  /// In en, this message translates to:
  /// **'Nothing is due for {name}.'**
  String payNothingDue(String name);

  /// No description provided for @deskSellPlan.
  ///
  /// In en, this message translates to:
  /// **'Sell a plan'**
  String get deskSellPlan;

  /// No description provided for @deskRenew.
  ///
  /// In en, this message translates to:
  /// **'Renew'**
  String get deskRenew;

  /// No description provided for @sellTitle.
  ///
  /// In en, this message translates to:
  /// **'A plan for {name}'**
  String sellTitle(String name);

  /// No description provided for @sellBody.
  ///
  /// In en, this message translates to:
  /// **'Renew the member or sell them another plan. Payment comes next.'**
  String get sellBody;

  /// No description provided for @sellPlan.
  ///
  /// In en, this message translates to:
  /// **'Plan'**
  String get sellPlan;

  /// No description provided for @sellCurrentPlan.
  ///
  /// In en, this message translates to:
  /// **'Current plan'**
  String get sellCurrentPlan;

  /// No description provided for @sellNoPlans.
  ///
  /// In en, this message translates to:
  /// **'This gym has no plans on sale. Add one in the staff panel.'**
  String get sellNoPlans;

  /// No description provided for @sellLengthDays.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day} other{{count} days}}'**
  String sellLengthDays(int count);

  /// No description provided for @sellLengthWeeks.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 week} other{{count} weeks}}'**
  String sellLengthWeeks(int count);

  /// No description provided for @sellLengthMonths.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 month} other{{count} months}}'**
  String sellLengthMonths(int count);

  /// No description provided for @sellLengthYears.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 year} other{{count} years}}'**
  String sellLengthYears(int count);

  /// No description provided for @sellVisits.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 visit} other{{count} visits}}'**
  String sellVisits(int count);

  /// No description provided for @sellStarts.
  ///
  /// In en, this message translates to:
  /// **'Starts'**
  String get sellStarts;

  /// No description provided for @sellFirstFreeDay.
  ///
  /// In en, this message translates to:
  /// **'The first free day'**
  String get sellFirstFreeDay;

  /// No description provided for @sellStartsHelp.
  ///
  /// In en, this message translates to:
  /// **'Today, or the day after their current plan ends.'**
  String get sellStartsHelp;

  /// No description provided for @sellPrice.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get sellPrice;

  /// No description provided for @sellPromoCode.
  ///
  /// In en, this message translates to:
  /// **'Promo code'**
  String get sellPromoCode;

  /// No description provided for @sellPromoCodeHint.
  ///
  /// In en, this message translates to:
  /// **'If they have one'**
  String get sellPromoCodeHint;

  /// No description provided for @sellDiscount.
  ///
  /// In en, this message translates to:
  /// **'Discount'**
  String get sellDiscount;

  /// No description provided for @sellDiscountHint.
  ///
  /// In en, this message translates to:
  /// **'500 or 10%'**
  String get sellDiscountHint;

  /// No description provided for @sellDiscountHelp.
  ///
  /// In en, this message translates to:
  /// **'Instead of a promo code; owners and managers only.'**
  String get sellDiscountHelp;

  /// No description provided for @sellDiscountReason.
  ///
  /// In en, this message translates to:
  /// **'Why the discount'**
  String get sellDiscountReason;

  /// No description provided for @sellSummary.
  ///
  /// In en, this message translates to:
  /// **'{plan} for {name} · {price}, or less with their discount group or promo code'**
  String sellSummary(String plan, String name, String price);

  /// No description provided for @sellSummaryDiscount.
  ///
  /// In en, this message translates to:
  /// **'{plan} for {name} · {price}, less your discount'**
  String sellSummaryDiscount(String plan, String name, String price);

  /// No description provided for @sellConfirm.
  ///
  /// In en, this message translates to:
  /// **'Sell plan'**
  String get sellConfirm;

  /// No description provided for @sellDone.
  ///
  /// In en, this message translates to:
  /// **'{plan} sold to {name} · {from} – {to} · {price}'**
  String sellDone(
    String plan,
    String name,
    String from,
    String to,
    String price,
  );

  /// No description provided for @deskAddMember.
  ///
  /// In en, this message translates to:
  /// **'Add member'**
  String get deskAddMember;

  /// No description provided for @deskNoMembersFoundAdd.
  ///
  /// In en, this message translates to:
  /// **'Not a member yet? Add them.'**
  String get deskNoMembersFoundAdd;

  /// No description provided for @newMemberTitle.
  ///
  /// In en, this message translates to:
  /// **'New member'**
  String get newMemberTitle;

  /// No description provided for @newMemberBody.
  ///
  /// In en, this message translates to:
  /// **'Their home branch will be {branch}. A plan and payment come next.'**
  String newMemberBody(String branch);

  /// No description provided for @newMemberWho.
  ///
  /// In en, this message translates to:
  /// **'Who they are'**
  String get newMemberWho;

  /// No description provided for @newMemberWhoHelp.
  ///
  /// In en, this message translates to:
  /// **'Their name and phone are needed; they sign in to the app with this phone.'**
  String get newMemberWhoHelp;

  /// No description provided for @newMemberName.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get newMemberName;

  /// No description provided for @newMemberPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get newMemberPhone;

  /// No description provided for @newMemberPhoneHelp.
  ///
  /// In en, this message translates to:
  /// **'Like 0911 234 567'**
  String get newMemberPhoneHelp;

  /// No description provided for @newMemberFindThem.
  ///
  /// In en, this message translates to:
  /// **'Find them instead'**
  String get newMemberFindThem;

  /// No description provided for @newMemberFemale.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get newMemberFemale;

  /// No description provided for @newMemberMale.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get newMemberMale;

  /// No description provided for @newMemberBirthday.
  ///
  /// In en, this message translates to:
  /// **'Date of birth'**
  String get newMemberBirthday;

  /// No description provided for @newMemberOptional.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get newMemberOptional;

  /// No description provided for @newMemberMessages.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get newMemberMessages;

  /// No description provided for @newMemberMessagesHelp.
  ///
  /// In en, this message translates to:
  /// **'The language of their texts and app notifications.'**
  String get newMemberMessagesHelp;

  /// No description provided for @newMemberEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get newMemberEmail;

  /// No description provided for @newMemberEmergency.
  ///
  /// In en, this message translates to:
  /// **'Emergency contact'**
  String get newMemberEmergency;

  /// No description provided for @newMemberEmergencyHelp.
  ///
  /// In en, this message translates to:
  /// **'Optional; fill both or neither.'**
  String get newMemberEmergencyHelp;

  /// No description provided for @newMemberContactName.
  ///
  /// In en, this message translates to:
  /// **'Contact\'s name'**
  String get newMemberContactName;

  /// No description provided for @newMemberContactPhone.
  ///
  /// In en, this message translates to:
  /// **'Contact\'s phone'**
  String get newMemberContactPhone;

  /// No description provided for @newMemberAdd.
  ///
  /// In en, this message translates to:
  /// **'Add member'**
  String get newMemberAdd;

  /// No description provided for @newMemberAdded.
  ///
  /// In en, this message translates to:
  /// **'{name} is a member now.'**
  String newMemberAdded(String name);

  /// No description provided for @welcomeBody.
  ///
  /// In en, this message translates to:
  /// **'Next: their photo, so the desk knows them, and a plan to get in.'**
  String get welcomeBody;

  /// No description provided for @welcomePhotoHelp.
  ///
  /// In en, this message translates to:
  /// **'Shown when they check in.'**
  String get welcomePhotoHelp;

  /// No description provided for @welcomePhotoTaken.
  ///
  /// In en, this message translates to:
  /// **'Photo taken'**
  String get welcomePhotoTaken;

  /// No description provided for @welcomePlanHelp.
  ///
  /// In en, this message translates to:
  /// **'Then take the payment.'**
  String get welcomePlanHelp;

  /// No description provided for @welcomeLater.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get welcomeLater;

  /// No description provided for @deskMembershipAction.
  ///
  /// In en, this message translates to:
  /// **'Membership'**
  String get deskMembershipAction;

  /// No description provided for @deskMembershipTitle.
  ///
  /// In en, this message translates to:
  /// **'{name}\'s membership'**
  String deskMembershipTitle(String name);

  /// No description provided for @deskMembershipBody.
  ///
  /// In en, this message translates to:
  /// **'Freeze it while they\'re away, end a freeze, or cancel it.'**
  String get deskMembershipBody;

  /// No description provided for @deskNoRunningMembership.
  ///
  /// In en, this message translates to:
  /// **'No membership running or to come. Sell them a plan.'**
  String get deskNoRunningMembership;

  /// No description provided for @deskStatusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get deskStatusActive;

  /// No description provided for @deskStatusFrozen.
  ///
  /// In en, this message translates to:
  /// **'Frozen'**
  String get deskStatusFrozen;

  /// No description provided for @deskStatusUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Starts later'**
  String get deskStatusUpcoming;

  /// No description provided for @deskFreezeDaysUsed.
  ///
  /// In en, this message translates to:
  /// **'Freeze days: {used} of {allowed} used'**
  String deskFreezeDaysUsed(int used, int allowed);

  /// No description provided for @deskFrozenFrom.
  ///
  /// In en, this message translates to:
  /// **'Frozen {from} – {to}'**
  String deskFrozenFrom(String from, String to);

  /// No description provided for @deskEndFreeze.
  ///
  /// In en, this message translates to:
  /// **'End freeze'**
  String get deskEndFreeze;

  /// No description provided for @deskRemoveFreeze.
  ///
  /// In en, this message translates to:
  /// **'Remove freeze'**
  String get deskRemoveFreeze;

  /// No description provided for @deskKeepFreeze.
  ///
  /// In en, this message translates to:
  /// **'Keep it'**
  String get deskKeepFreeze;

  /// No description provided for @deskEndFreezeTitle.
  ///
  /// In en, this message translates to:
  /// **'End the freeze today?'**
  String get deskEndFreezeTitle;

  /// No description provided for @deskEndFreezeBody.
  ///
  /// In en, this message translates to:
  /// **'They can come in from today, and the plan ends sooner by the days left until {to}.'**
  String deskEndFreezeBody(String to);

  /// No description provided for @deskRemoveFreezeTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove this freeze?'**
  String get deskRemoveFreezeTitle;

  /// No description provided for @deskRemoveFreezeBody.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =1{The plan ends 1 day sooner.} other{The plan ends {days} days sooner.}}'**
  String deskRemoveFreezeBody(int days);

  /// No description provided for @deskFreezeEnded.
  ///
  /// In en, this message translates to:
  /// **'The freeze is ended.'**
  String get deskFreezeEnded;

  /// No description provided for @deskFreezeRemoved.
  ///
  /// In en, this message translates to:
  /// **'The freeze is removed.'**
  String get deskFreezeRemoved;

  /// No description provided for @deskFreezeTitle.
  ///
  /// In en, this message translates to:
  /// **'Freeze {plan}'**
  String deskFreezeTitle(String plan);

  /// No description provided for @deskFreezeBody.
  ///
  /// In en, this message translates to:
  /// **'They can\'t come in on these days, and the plan ends that many days later.'**
  String get deskFreezeBody;

  /// No description provided for @deskFreezeSummary.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =1{1 day} other{{days} days}} · the plan will now end on {date}'**
  String deskFreezeSummary(int days, String date);

  /// No description provided for @deskFreezeDaysLeft.
  ///
  /// In en, this message translates to:
  /// **'{left, plural, =0{No freeze days left on this plan.} =1{1 freeze day left on this plan.} other{{left} freeze days left on this plan.}}'**
  String deskFreezeDaysLeft(int left);

  /// No description provided for @deskFreezeOverAllowanceOwner.
  ///
  /// In en, this message translates to:
  /// **'{left, plural, =1{More than the 1 freeze day left; as an owner or manager you can still freeze it.} other{More than the {left} freeze days left; as an owner or manager you can still freeze it.}}'**
  String deskFreezeOverAllowanceOwner(int left);

  /// No description provided for @deskFreezeReason.
  ///
  /// In en, this message translates to:
  /// **'Why'**
  String get deskFreezeReason;

  /// No description provided for @deskFrozen.
  ///
  /// In en, this message translates to:
  /// **'The membership is frozen.'**
  String get deskFrozen;

  /// No description provided for @deskCancelMembership.
  ///
  /// In en, this message translates to:
  /// **'Cancel membership'**
  String get deskCancelMembership;

  /// No description provided for @deskKeepMembership.
  ///
  /// In en, this message translates to:
  /// **'Keep it'**
  String get deskKeepMembership;

  /// No description provided for @deskCancelTitle.
  ///
  /// In en, this message translates to:
  /// **'Cancel {plan}?'**
  String deskCancelTitle(String plan);

  /// No description provided for @deskCancelBody.
  ///
  /// In en, this message translates to:
  /// **'They won\'t be let in on it any more. Any refund is made in the staff panel.'**
  String get deskCancelBody;

  /// No description provided for @deskCancelReason.
  ///
  /// In en, this message translates to:
  /// **'Why it is cancelled'**
  String get deskCancelReason;

  /// No description provided for @deskCancelled.
  ///
  /// In en, this message translates to:
  /// **'The membership is cancelled.'**
  String get deskCancelled;

  /// No description provided for @deskEndFreezeAction.
  ///
  /// In en, this message translates to:
  /// **'End freeze'**
  String get deskEndFreezeAction;

  /// No description provided for @errorGymPaused.
  ///
  /// In en, this message translates to:
  /// **'This gym is paused for now.'**
  String get errorGymPaused;

  /// No description provided for @gymPausedTag.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get gymPausedTag;

  /// No description provided for @gymPausedMember.
  ///
  /// In en, this message translates to:
  /// **'This gym is paused for now. Ask at the gym.'**
  String get gymPausedMember;

  /// No description provided for @gymPausedStaff.
  ///
  /// In en, this message translates to:
  /// **'This gym is paused. Contact the platform to switch it back on. Scans made now are kept and sent once it is back.'**
  String get gymPausedStaff;

  /// No description provided for @paymentMethodCash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get paymentMethodCash;

  /// No description provided for @paymentMethodTelebirr.
  ///
  /// In en, this message translates to:
  /// **'telebirr'**
  String get paymentMethodTelebirr;

  /// No description provided for @paymentMethodCbeBirr.
  ///
  /// In en, this message translates to:
  /// **'CBE Birr'**
  String get paymentMethodCbeBirr;

  /// No description provided for @paymentMethodBankTransfer.
  ///
  /// In en, this message translates to:
  /// **'Bank transfer'**
  String get paymentMethodBankTransfer;

  /// No description provided for @paymentMethodChapa.
  ///
  /// In en, this message translates to:
  /// **'Chapa'**
  String get paymentMethodChapa;

  /// No description provided for @paymentMethodBroughtIn.
  ///
  /// In en, this message translates to:
  /// **'Paid before'**
  String get paymentMethodBroughtIn;

  /// No description provided for @deskPauseDemo.
  ///
  /// In en, this message translates to:
  /// **'Pause the gym (demo)'**
  String get deskPauseDemo;

  /// No description provided for @memberPageTitle.
  ///
  /// In en, this message translates to:
  /// **'Member'**
  String get memberPageTitle;

  /// No description provided for @memberStatusEnded.
  ///
  /// In en, this message translates to:
  /// **'Ended'**
  String get memberStatusEnded;

  /// No description provided for @memberStatusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get memberStatusCancelled;

  /// No description provided for @memberStatusNoPlan.
  ///
  /// In en, this message translates to:
  /// **'No plan'**
  String get memberStatusNoPlan;

  /// No description provided for @memberSince.
  ///
  /// In en, this message translates to:
  /// **'Member since {date}'**
  String memberSince(String date);

  /// No description provided for @memberMemberships.
  ///
  /// In en, this message translates to:
  /// **'Memberships'**
  String get memberMemberships;

  /// No description provided for @memberNoMemberships.
  ///
  /// In en, this message translates to:
  /// **'No membership yet.'**
  String get memberNoMemberships;

  /// No description provided for @memberPayments.
  ///
  /// In en, this message translates to:
  /// **'Payments'**
  String get memberPayments;

  /// No description provided for @memberNoPayments.
  ///
  /// In en, this message translates to:
  /// **'No payments yet.'**
  String get memberNoPayments;

  /// No description provided for @memberRefund.
  ///
  /// In en, this message translates to:
  /// **'Refund'**
  String get memberRefund;

  /// No description provided for @memberVoided.
  ///
  /// In en, this message translates to:
  /// **'Voided'**
  String get memberVoided;

  /// No description provided for @memberVisits.
  ///
  /// In en, this message translates to:
  /// **'Visits'**
  String get memberVisits;

  /// No description provided for @memberNoVisits.
  ///
  /// In en, this message translates to:
  /// **'No visits yet.'**
  String get memberNoVisits;

  /// No description provided for @memberLoadMore.
  ///
  /// In en, this message translates to:
  /// **'Load more'**
  String get memberLoadMore;

  /// No description provided for @memberDetails.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get memberDetails;

  /// No description provided for @memberGender.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get memberGender;

  /// No description provided for @memberLanguage.
  ///
  /// In en, this message translates to:
  /// **'Messages in'**
  String get memberLanguage;

  /// No description provided for @memberOpenPage.
  ///
  /// In en, this message translates to:
  /// **'Member page'**
  String get memberOpenPage;

  /// No description provided for @editMember.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get editMember;

  /// No description provided for @editMemberTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit {name}'**
  String editMemberTitle(String name);

  /// No description provided for @editMemberBody.
  ///
  /// In en, this message translates to:
  /// **'Fix their details. An empty field is cleared.'**
  String get editMemberBody;

  /// No description provided for @editMemberSave.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get editMemberSave;

  /// No description provided for @editMemberSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved.'**
  String get editMemberSaved;

  /// No description provided for @editMemberPhoneNote.
  ///
  /// In en, this message translates to:
  /// **'They sign in to the app with this number, so it changes for them too.'**
  String get editMemberPhoneNote;

  /// No description provided for @editMemberHomeBranch.
  ///
  /// In en, this message translates to:
  /// **'Home branch'**
  String get editMemberHomeBranch;

  /// No description provided for @editMemberHomeBranchHelp.
  ///
  /// In en, this message translates to:
  /// **'Where they usually come.'**
  String get editMemberHomeBranchHelp;

  /// No description provided for @editMemberPhoneTaken.
  ///
  /// In en, this message translates to:
  /// **'{phone} is another member\'s number. Find them in Desk search.'**
  String editMemberPhoneTaken(String phone);

  /// No description provided for @numbersMonthByMonth.
  ///
  /// In en, this message translates to:
  /// **'Month by month'**
  String get numbersMonthByMonth;

  /// No description provided for @insightsTitle.
  ///
  /// In en, this message translates to:
  /// **'Month by month'**
  String get insightsTitle;

  /// No description provided for @insightsTabMoney.
  ///
  /// In en, this message translates to:
  /// **'Money'**
  String get insightsTabMoney;

  /// No description provided for @insightsTabRenewals.
  ///
  /// In en, this message translates to:
  /// **'Renewals'**
  String get insightsTabRenewals;

  /// No description provided for @insightsTabBusyHours.
  ///
  /// In en, this message translates to:
  /// **'Busy hours'**
  String get insightsTabBusyHours;

  /// No description provided for @insightsTabMembers.
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get insightsTabMembers;

  /// No description provided for @insightsMonths.
  ///
  /// In en, this message translates to:
  /// **'{count} months'**
  String insightsMonths(int count);

  /// No description provided for @insightsMoneyTotal.
  ///
  /// In en, this message translates to:
  /// **'Taken in the last {count} months, net of refunds'**
  String insightsMoneyTotal(int count);

  /// No description provided for @insightsByPlan.
  ///
  /// In en, this message translates to:
  /// **'By plan'**
  String get insightsByPlan;

  /// No description provided for @insightsByMethod.
  ///
  /// In en, this message translates to:
  /// **'By how they paid'**
  String get insightsByMethod;

  /// No description provided for @insightsRenewalRate.
  ///
  /// In en, this message translates to:
  /// **'Renewal rate'**
  String get insightsRenewalRate;

  /// No description provided for @insightsRenewedMeans.
  ///
  /// In en, this message translates to:
  /// **'Renewed: a new plan within 14 days of the old one ending.'**
  String get insightsRenewedMeans;

  /// No description provided for @insightsRenewed.
  ///
  /// In en, this message translates to:
  /// **'Renewed'**
  String get insightsRenewed;

  /// No description provided for @insightsLapsed.
  ///
  /// In en, this message translates to:
  /// **'Didn\'t renew'**
  String get insightsLapsed;

  /// No description provided for @insightsWaiting.
  ///
  /// In en, this message translates to:
  /// **'Not decided yet'**
  String get insightsWaiting;

  /// No description provided for @insightsCheckIns.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 check-in let in} other{{count} check-ins let in}}'**
  String insightsCheckIns(int count);

  /// No description provided for @insightsBusiest.
  ///
  /// In en, this message translates to:
  /// **'Busiest: {day} {hour}'**
  String insightsBusiest(String day, String hour);

  /// No description provided for @insightsActive.
  ///
  /// In en, this message translates to:
  /// **'Members at the month\'s end'**
  String get insightsActive;

  /// No description provided for @insightsNew.
  ///
  /// In en, this message translates to:
  /// **'New members'**
  String get insightsNew;

  /// No description provided for @insightsNewUnder.
  ///
  /// In en, this message translates to:
  /// **'Under each bar: new members that month.'**
  String get insightsNewUnder;

  /// No description provided for @insightsPacks.
  ///
  /// In en, this message translates to:
  /// **'Visit packs that ended'**
  String get insightsPacks;

  /// No description provided for @insightsPacksEnded.
  ///
  /// In en, this message translates to:
  /// **'Packs ended'**
  String get insightsPacksEnded;

  /// No description provided for @insightsVisitsUsed.
  ///
  /// In en, this message translates to:
  /// **'Visits used of those bought'**
  String get insightsVisitsUsed;

  /// No description provided for @insightsPacksLeft.
  ///
  /// In en, this message translates to:
  /// **'Ended with visits left'**
  String get insightsPacksLeft;

  /// No description provided for @insightsNone.
  ///
  /// In en, this message translates to:
  /// **'Nothing in these months yet.'**
  String get insightsNone;

  /// No description provided for @insightsCsvInPanel.
  ///
  /// In en, this message translates to:
  /// **'To download these figures, open Reports › Insights in the staff panel.'**
  String get insightsCsvInPanel;
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
