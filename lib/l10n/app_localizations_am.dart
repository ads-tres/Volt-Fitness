// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Amharic (`am`).
class AppLocalizationsAm extends AppLocalizations {
  AppLocalizationsAm([String locale = 'am']) : super(locale);

  @override
  String get appTitle => 'Volt';

  @override
  String get back => 'ተመለስ';

  @override
  String get language => 'ቋንቋ';

  @override
  String get languageSystem => 'የስልኩን ቋንቋ ተጠቀም';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageAmharic => 'አማርኛ';

  @override
  String get welcomeTitle => 'እንኳን ወደ Volt በደህና መጡ';

  @override
  String get welcomeSubtitle => 'ጂምዎ በመዘገበው ስልክ ቁጥር ይግቡ።';

  @override
  String get phoneLabel => 'ስልክ ቁጥር';

  @override
  String get continueButton => 'ቀጥል';

  @override
  String get smsNotice => 'ባለ 6 አሃዝ ኮድ በአጭር መልዕክት እንልክልዎታለን።';

  @override
  String testModeNotice(String code) {
    return 'የሙከራ ሁነታ · ኮድ $code';
  }

  @override
  String get phoneInvalid => 'እንደ 0911 23 45 67 ያለ የኢትዮጵያ ሞባይል ቁጥር ያስገቡ።';

  @override
  String get otpTitle => 'ኮዱን ያስገቡ';

  @override
  String otpSubtitle(String phone) {
    return 'ባለ 6 አሃዝ ኮድ ወደ $phone ልከናል።';
  }

  @override
  String get verifyButton => 'አረጋግጥ';

  @override
  String resendIn(String time) {
    return 'ኮዱን በ$time ውስጥ እንደገና መላክ ይችላሉ';
  }

  @override
  String get resendCode => 'ኮዱን እንደገና ላክ';

  @override
  String get codeResent => 'አዲስ ኮድ ልከንልዎታል።';

  @override
  String get otpInvalid => 'ኮዱ ትክክል አይደለም። መልዕክቱን አረጋግጠው እንደገና ይሞክሩ።';

  @override
  String get otpExpired => 'ኮዱ ጊዜው አልፎበታል። አዲስ ኮድ ይጠይቁ።';

  @override
  String get otpTooManyAttempts =>
      'ብዙ የተሳሳቱ ኮዶች ገብተዋል። ለአንድ ደቂቃ ቆይተው አዲስ ኮድ ይጠይቁ።';

  @override
  String get selectGymTitle => 'ጂምዎን ይምረጡ';

  @override
  String get selectGymSubtitle =>
      'ቁጥርዎ ከአንድ በላይ ጂም ተመዝግቧል። በኋላ ከመገለጫዎ መቀየር ይችላሉ።';

  @override
  String get noGymTitle => 'ጂም አልተገኘም';

  @override
  String noGymMessage(String phone) {
    return 'ለ$phone የተመዘገበ አባልነት አላገኘንም። ይህን ቁጥር እንዲመዘግቡ የጂምዎን እንግዳ መቀበያ ይጠይቁ።';
  }

  @override
  String get useAnotherNumber => 'ሌላ ቁጥር ተጠቀም';

  @override
  String get onboardingTrainTitle => 'ጂምዎ\nበኪስዎ ውስጥ';

  @override
  String get onboardingTrainBody => 'አባልነትዎ፣ መግቢያዎችዎ እና ክፍያዎችዎ በአንድ መተግበሪያ።';

  @override
  String get onboardingCheckInTitle => 'በአንድ ስካን\nይግቡ';

  @override
  String get onboardingCheckInBody => 'QR ኮድዎን በእንግዳ መቀበያው ያሳዩ። የሚረሳ ካርድ የለም።';

  @override
  String get onboardingRenewTitle => 'ያለ ሰልፍ\nያድሱ';

  @override
  String get onboardingRenewBody =>
      'ያለብዎትን ይመልከቱ፣ በስልክዎ ይክፈሉ እና ዕቅድዎ ከማለቁ በፊት ማስታወሻ ያግኙ።';

  @override
  String get onboardingPinDaysLeft => '18 ቀናት ቀርተዋል';

  @override
  String get onboardingPinCheckedIn => 'ገብተዋል · 06:42';

  @override
  String get onboardingPinPaid => 'ተከፍሏል · 1,500 ብር';

  @override
  String get next => 'ቀጣይ';

  @override
  String get getStarted => 'እንጀምር';

  @override
  String get skip => 'ዝለል';

  @override
  String get navHome => 'መነሻ';

  @override
  String get navMembership => 'አባልነት';

  @override
  String get navQr => 'የእኔ QR';

  @override
  String get navPayments => 'ክፍያዎች';

  @override
  String get navProfile => 'መገለጫ';

  @override
  String greeting(String name) {
    return 'ሰላም፣ $name';
  }

  @override
  String get greetingNoName => 'ሰላም';

  @override
  String get showQrTitle => 'QR ኮዴን አሳይ';

  @override
  String get showQrSubtitle => 'ለመግባት በእንግዳ መቀበያው ያስቃኙት።';

  @override
  String get quickAccess => 'ፈጣን መዳረሻ';

  @override
  String get yourGym => 'ጂምዎ';

  @override
  String get frontDesk => 'እንግዳ መቀበያ';

  @override
  String get switchGym => 'ቀይር';

  @override
  String get signOut => 'ውጣ';

  @override
  String appVersion(String version, String build) {
    return 'Volt $version ($build)';
  }

  @override
  String gaugeDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ቀናት',
      one: '1 ቀን',
    );
    return '$_temp0';
  }

  @override
  String gaugeEnds(String date) {
    return '$date ያበቃል';
  }

  @override
  String gaugeEnded(String date) {
    return '$date አብቅቷል';
  }

  @override
  String gaugeStarts(String date) {
    return '$date ይጀምራል';
  }

  @override
  String gaugeUntil(String date) {
    return 'እስከ $date';
  }

  @override
  String get gaugeLastDay => 'የመጨረሻ ቀን';

  @override
  String get gaugeEndsToday => 'ዛሬ ያበቃል';

  @override
  String get gaugeExpired => 'አብቅቷል';

  @override
  String get gaugeFrozen => 'ለጊዜው ቆሟል';

  @override
  String get gaugeCancelled => 'ተሰርዟል';

  @override
  String get gaugeStartsSoon => 'በቅርቡ ይጀምራል';

  @override
  String get gaugeNoPlan => 'ዕቅድ የለም';

  @override
  String get gaugeNoPlanHint => 'ጂምዎ ዕቅድ እንዲጀምርልዎ ይጠይቁ';

  @override
  String get gaugeRenewSoon => 'በቅርቡ ያድሱ';

  @override
  String get renew => 'አድስ';

  @override
  String get recentVisits => 'የቅርብ ጊዜ ጉብኝቶች';

  @override
  String get seeAll => 'ሁሉንም ይመልከቱ';

  @override
  String get today => 'ዛሬ';

  @override
  String get yesterday => 'ትናንት';

  @override
  String get visitCheckedIn => 'ገብተዋል';

  @override
  String get visitDenied => 'አልገቡም';

  @override
  String get noVisitsYet => 'እስካሁን ጉብኝት የለም። መግቢያዎችዎ እዚህ ይታያሉ።';

  @override
  String get offlineNotice => 'ከኢንተርኔት ውጭ ነዎት። ይህ ለመጨረሻ ጊዜ ያየነው ነው።';

  @override
  String get loadFailed => 'ይህንን መጫን አልቻልንም።';

  @override
  String get reasonMembershipExpired => 'አባልነቱ አብቅቷል';

  @override
  String get reasonMembershipFrozen => 'አባልነቱ ለጊዜው ቆሟል';

  @override
  String get reasonOutsideHours => 'ከዕቅድዎ ሰዓት ውጭ';

  @override
  String get reasonBranchNotAllowed => 'ይህ ቅርንጫፍ በዕቅድዎ ውስጥ የለም';

  @override
  String get reasonNoVisitsRemaining => 'የቀረ ጉብኝት የለም';

  @override
  String get reasonAlreadyCheckedIn => 'ቀድመው ገብተዋል';

  @override
  String get reasonOther => 'መግባት አልተፈቀደም';

  @override
  String get visitsTitle => 'ጉብኝቶች';

  @override
  String get statusActive => 'ንቁ';

  @override
  String get statusFrozen => 'ለጊዜው የቆመ';

  @override
  String get statusExpired => 'ያበቃ';

  @override
  String get statusPending => 'በቅርቡ የሚጀምር';

  @override
  String get statusCancelled => 'የተሰረዘ';

  @override
  String get statusUnknown => 'ያልታወቀ';

  @override
  String get startDate => 'የሚጀምርበት ቀን';

  @override
  String get endDate => 'የሚያበቃበት ቀን';

  @override
  String daysLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ቀናት ቀርተዋል',
      one: '1 ቀን ቀርቷል',
    );
    return '$_temp0';
  }

  @override
  String visitsLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ጉብኝቶች ቀርተዋል',
      one: '1 ጉብኝት ቀርቷል',
    );
    return '$_temp0';
  }

  @override
  String get allowedBranches => 'መጠቀም የሚችሏቸው ቅርንጫፎች';

  @override
  String frozenNotice(String date) {
    return 'አባልነትዎ እስከ $date ድረስ ለጊዜው ቆሟል።';
  }

  @override
  String graceNotice(String date) {
    return 'ዕቅድዎ አብቅቷል፤ ሆኖም ጂሙ እስከ $date ድረስ ያስገባዎታል።';
  }

  @override
  String get noPlanTitle => 'ንቁ ዕቅድ የለም';

  @override
  String get noPlanBody => 'ዕቅድ እንዲጀምሩልዎ የጂምዎን እንግዳ መቀበያ ይጠይቁ።';

  @override
  String get renewPlan => 'ዕቅድ አድስ';

  @override
  String qrMember(String name) {
    return 'አባል · $name';
  }

  @override
  String qrNewCodeIn(int seconds) {
    return 'አዲስ ኮድ በ$seconds ሰከንድ';
  }

  @override
  String get qrHint =>
      'ይህንን በእንግዳ መቀበያው ያሳዩ። ኮዱ በየ30 ሰከንዱ ስለሚቀየር ስክሪንሾት አይሰራም።';

  @override
  String get qrWorksOffline => 'ያለ ኢንተርኔት ይሰራል';

  @override
  String get qrImageLabel => 'ለመግቢያ የሚሆን QR ኮድ';

  @override
  String get qrSetupTitle => 'QR ኮድዎን ለማዘጋጀት ከኢንተርኔት ጋር ይገናኙ';

  @override
  String get qrSetupBody =>
      'QR ኮድዎ ለመጀመሪያ ጊዜ የሚዘጋጀው በኢንተርኔት ነው። ከዚያ በኋላ ያለ ኢንተርኔት ይሰራል።';

  @override
  String get qrReplacedTitle => 'QR ኮድዎ በሌላ ስልክ ላይ ነው';

  @override
  String get qrReplacedBody =>
      'በሌላ ስልክ ስላዘጋጁት እዚህ ያለው ኮድ መስራት አቁሟል። ወደዚህ ስልክ ይመልሱት?';

  @override
  String get qrUseThisPhone => 'ይህን ስልክ ተጠቀም';

  @override
  String get qrRevokedTitle => 'QR ኮድዎ ጠፍቷል';

  @override
  String get qrRevokedBody => 'እንደገና እንዲያበሩት የጂምዎን እንግዳ መቀበያ ይጠይቁ።';

  @override
  String get settings => 'ቅንብሮች';

  @override
  String get calendar => 'የቀን አቆጣጠር';

  @override
  String get calendarAuto => 'እንደ ቋንቋው';

  @override
  String get calendarGregorian => 'ጎርጎርዮሳዊ';

  @override
  String get calendarEthiopian => 'ኢትዮጵያዊ';

  @override
  String get calendarBoth => 'ሁለቱም';

  @override
  String get devices => 'የገቡባቸው መሣሪያዎች';

  @override
  String get thisPhone => 'ይህ ስልክ';

  @override
  String lastActive(String date) {
    return 'ለመጨረሻ ጊዜ የታየው $date';
  }

  @override
  String signOutDeviceTitle(String device) {
    return 'ከ$device ይውጡ?';
  }

  @override
  String get signOutDeviceBody =>
      'እንደገና ለመግባት አዲስ የኤስኤምኤስ ኮድ ያስፈልገዋል፤ የሱ QR ኮድም መስራት ያቆማል።';

  @override
  String get cancel => 'ይቅር';

  @override
  String get amountDue => 'የሚከፈል መጠን';

  @override
  String dueOn(String date) {
    return 'እስከ $date';
  }

  @override
  String get dueDate => 'የመክፈያ ቀን';

  @override
  String get paymentDue => 'ያልተከፈለ ክፍያ';

  @override
  String get payNow => 'አሁን ክፈል';

  @override
  String get pay => 'ክፈል';

  @override
  String payAmount(String amount) {
    return '$amount ክፈል';
  }

  @override
  String get plansTitle => 'ዕቅድዎን ያድሱ ወይም ይቀይሩ';

  @override
  String get choosePlan => 'ምረጥ';

  @override
  String get historyTitle => 'ታሪክ';

  @override
  String get noInvoices => 'እስካሁን ክፍያ የለም።';

  @override
  String get invoiceStatusOpen => 'ያልተከፈለ';

  @override
  String get invoiceStatusPaid => 'የተከፈለ';

  @override
  String get invoiceStatusVoid => 'የተሰረዘ';

  @override
  String invoiceTitle(String number) {
    return 'የክፍያ መጠየቂያ $number';
  }

  @override
  String get issuedOn => 'የወጣበት';

  @override
  String get total => 'ጠቅላላ';

  @override
  String get receiptTitle => 'ደረሰኝ';

  @override
  String get paidOn => 'የተከፈለበት';

  @override
  String get paymentMethod => 'የክፍያ መንገድ';

  @override
  String get paymentReference => 'መለያ ቁጥር';

  @override
  String get openReceipt => 'ደረሰኙን ክፈት';

  @override
  String get confirmPlanBody => 'ቻፓ ክፍያውን እንዳረጋገጠ አባልነትዎ ይራዘማል።';

  @override
  String get securedByChapa => 'ደህንነቱ የተጠበቀ ክፍያ በቻፓ፦ ቴሌብር፣ ሲቢኢ ብር እና ካርዶች';

  @override
  String get checkoutTitle => 'በቻፓ ይክፈሉ';

  @override
  String get leaveCheckoutTitle => 'ክፍያውን ትተው ይወጣሉ?';

  @override
  String get leaveCheckoutBody => 'ቀድመው ከፍለው ከሆነ አሁንም እናረጋግጠዋለን።';

  @override
  String get leave => 'ውጣ';

  @override
  String get stay => 'ቆይ';

  @override
  String get resultConfirming => 'ክፍያዎን እያረጋገጥን ነው';

  @override
  String get resultConfirmingBody => 'ብዙውን ጊዜ ጥቂት ሰከንዶች ይወስዳል።';

  @override
  String get resultSucceeded => 'ክፍያው ደርሷል';

  @override
  String resultSucceededUntil(String date) {
    return 'አባልነትዎ እስከ $date ድረስ ንቁ ነው።';
  }

  @override
  String get resultSucceededBody => 'እናመሰግናለን። ደረሰኝዎ ዝግጁ ነው።';

  @override
  String get resultFailed => 'ክፍያው አልተሳካም';

  @override
  String get resultFailedBody => 'ቻፓ ክፍያውን ማጠናቀቅ አልቻለም። እንደገና መሞከር ይችላሉ።';

  @override
  String get resultNotFinished => 'ክፍያው አልተጠናቀቀም';

  @override
  String get resultNotFinishedBody => 'ከመክፈልዎ በፊት ስለወጡ ዕቅድዎ አልተቀየረም።';

  @override
  String get resultStillConfirming => 'አሁንም እያረጋገጥን ነው';

  @override
  String get resultStillConfirmingBody =>
      'ቻፓ ክፍያውን እስካሁን አላረጋገጠም። ይህን ገጽ መተው ይችላሉ፤ እንዳረጋገጠ አባልነትዎ ይዘመናል።';

  @override
  String get viewReceipt => 'ደረሰኝ ይመልከቱ';

  @override
  String get backToPayments => 'ወደ ክፍያዎች ተመለስ';

  @override
  String get done => 'ጨርስ';

  @override
  String get retry => 'እንደገና ሞክር';

  @override
  String get errorNetwork => 'የኢንተርኔት ግንኙነት የለም። ግንኙነትዎን አረጋግጠው እንደገና ይሞክሩ።';

  @override
  String get errorSessionExpired => 'ክፍለ ጊዜዎ አብቅቷል። እባክዎ እንደገና ይግቡ።';

  @override
  String get errorForbidden => 'ይህንን ለማግኘት ፈቃድ የለዎትም።';

  @override
  String get errorNotFound => 'የፈለጉትን ማግኘት አልቻልንም።';

  @override
  String get errorConflict => 'ይህ በመሃል ተቀይሯል። አድሰው እንደገና ይሞክሩ።';

  @override
  String get errorValidation => 'አንዳንድ መረጃዎች መስተካከል አለባቸው። አረጋግጠው እንደገና ይሞክሩ።';

  @override
  String get errorRateLimited =>
      'በጣም ብዙ ሙከራዎች ተደርገዋል። እባክዎ ትንሽ ቆይተው እንደገና ይሞክሩ።';

  @override
  String get errorUpdateRequired =>
      'ይህ የመተግበሪያው ስሪት ከአሁን በኋላ አይደገፍም። ለመቀጠል እባክዎ ያዘምኑ።';

  @override
  String get errorServer => 'በእኛ በኩል ችግር ተፈጥሯል። እባክዎ ቆይተው እንደገና ይሞክሩ።';

  @override
  String get errorUnexpected => 'የሆነ ችግር ተፈጥሯል። እባክዎ እንደገና ይሞክሩ።';
}
