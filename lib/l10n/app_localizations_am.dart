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
  String get notificationsTitle => 'ማሳወቂያዎች';

  @override
  String get markAllRead => 'ሁሉንም እንደተነበቡ ምልክት አድርግ';

  @override
  String get unread => 'ያልተነበበ';

  @override
  String get noNotifications => 'እስካሁን ምንም የለም';

  @override
  String get noNotificationsBody =>
      'ዕቅድዎ ሊያበቃ ሲቃረብ፣ ክፍያ ሲደርስ ወይም ጂምዎ ዜና ሲኖረው እዚህ እናሳውቅዎታለን።';

  @override
  String get pushPromptTitle => 'ማሳወቂያዎችን ያብሩ';

  @override
  String get pushPromptBody => 'ዕቅድዎ ከማለቁ በፊት ማስታወሻ ያግኙ፤ ክፍያዎ ሲፈጸምም ይወቁ።';

  @override
  String get turnOn => 'አብራ';

  @override
  String get notNow => 'አሁን አይደለም';

  @override
  String get pushBlockedTitle => 'ማሳወቂያዎች ጠፍተዋል';

  @override
  String get pushBlockedBody =>
      'ማስታወሻዎችን ለማግኘት በስልክዎ ቅንብሮች ውስጥ ለVolt ማሳወቂያዎችን ይፍቀዱ።';

  @override
  String get openSettings => 'ቅንብሮችን ክፈት';

  @override
  String get pushUnavailable =>
      'ይህ የመተግበሪያው ስሪት እስካሁን ወደ ስልክዎ ማሳወቂያ መላክ አይችልም። ሆኖም በመነሻ ገጹ ላይ ካለው ደወል ማንበብ ይችላሉ።';

  @override
  String get notifyMeAbout => 'ስለሚከተሉት አሳውቀኝ';

  @override
  String get topicMembership => 'ዕቅዴ';

  @override
  String get topicMembershipHint => 'ሊያበቃ ሲል፣ ሲያበቃ ወይም ሲታደስ';

  @override
  String get topicPayments => 'ክፍያዎች';

  @override
  String get topicPaymentsHint => 'አዲስ የክፍያ መጠየቂያዎች፣ የመክፈያ ቀኖች እና ደረሰኞች';

  @override
  String get topicVisits => 'መግቢያዎች';

  @override
  String get topicVisitsHint => 'መግቢያ ተቀባይነት ሳያገኝ ሲቀር';

  @override
  String get topicAnnouncements => 'የጂምዎ ዜናዎች';

  @override
  String get topicAnnouncementsHint => 'የስራ ሰዓት፣ የመዘጋት ቀኖች እና ዝግጅቶች';

  @override
  String get inboxKeepsAll =>
      'አንድን ርዕስ ማጥፋት በስልክዎ ላይ የሚመጡ ማሳወቂያዎችን ብቻ ያቆማል። ሁሉንም አሁንም በመነሻ ገጹ ላይ ካለው ደወል ማንበብ ይችላሉ።';

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

  @override
  String get deskTitle => 'ቮልት ዴስክ';

  @override
  String get deskSignInTitle => 'ወደ መቀበያ ዴስክ ይግቡ';

  @override
  String get deskSignInBody => 'ከጂሙ በመጣው ኤስኤምኤስ ያዘጋጁትን ስልክ ቁጥርና የይለፍ ቃል ይጠቀሙ።';

  @override
  String get deskPassword => 'የይለፍ ቃል';

  @override
  String get deskSignIn => 'ግባ';

  @override
  String get deskNoGym => 'ይህ ቁጥር በየትኛውም ጂም ሠራተኛ አይደለም።';

  @override
  String get deskChooseGym => 'ጂሙን ይምረጡ';

  @override
  String get deskChooseBranch => 'ይህ ዴስክ በየትኛው ቅርንጫፍ ነው?';

  @override
  String get deskNoBranches =>
      'በዚህ ጂም በየትኛውም ቅርንጫፍ ገና አልተመደቡም። የጂሙን ባለቤት ይጠይቁ።';

  @override
  String get deskChangeBranch => 'ቅርንጫፍ ቀይር';

  @override
  String get deskMenu => 'ምናሌ';

  @override
  String get deskPointCamera => 'ካሜራውን ወደ አባሉ QR ኮድ ያዙሩ';

  @override
  String get deskCameraDenied =>
      'ለቮልት ዴስክ ካሜራ ጠፍቷል። ለመቃኘት በስልኩ ቅንብሮች ውስጥ ይፍቀዱ።';

  @override
  String get deskCameraFailed =>
      'ካሜራው መጀመር አልቻለም። ካሜራውን የሚጠቀሙ ሌሎች መተግበሪያዎችን ዝግተው እንደገና ይሞክሩ።';

  @override
  String get deskLetIn => 'ገብቷል';

  @override
  String get deskTurnedAway => 'አልገባም';

  @override
  String deskPlanUntil(String plan, String date) {
    return '$plan · እስከ $date';
  }

  @override
  String deskOwes(String amount) {
    return 'ዕዳ $amount';
  }

  @override
  String get deskTapToContinue => 'ቀጣዩን አባል ለመቃኘት ይንኩ';

  @override
  String get deskReasonCredentialInvalid => 'የአባል ኮድ አይደለም፣ ወይም የሌላ ጂም ኮድ ነው';

  @override
  String get deskReasonCredentialRevoked =>
      'የዚህ ስልክ ኮድ ተተክቷል። አባሉ መተግበሪያውን እንዲከፍት ይጠይቁ።';

  @override
  String get deskReasonCodeExpired =>
      'ኮዱ ጊዜው አልፎበታል። የአባሉ ስልክ ሰዓት ትክክል ላይሆን ይችላል።';

  @override
  String get deskReasonCodeAlreadyUsed =>
      'ይህ ኮድ ቀድሞ ተቃኝቷል። መተግበሪያው አሁን የሚያሳየውን ኮድ ይጠይቁ።';

  @override
  String get deskReasonOutsideHours => 'ቅርንጫፉ አሁን ዝግ ነው';

  @override
  String get deskReasonMembershipNone => 'ለዛሬ አባልነት የለም';

  @override
  String get deskReasonMembershipExpired => 'አባልነቱ አልቋል';

  @override
  String get deskReasonMembershipFrozen => 'አባልነቱ ዛሬ ታግዷል';

  @override
  String get deskReasonBranchNotAllowed => 'አባልነቱ በዚህ ቅርንጫፍ አይሰራም';

  @override
  String get deskReasonVisitsUsedUp => 'የጥቅሉ ጉብኝቶች በሙሉ ተጠቅመዋል';

  @override
  String get deskReasonAlreadyCheckedIn => 'ከ5 ደቂቃ በፊት ገብቷል';

  @override
  String get deskReasonOther => 'አልገባም';

  @override
  String get deskTabScan => 'ቃኝ';

  @override
  String get deskTabDesk => 'ዴስክ';

  @override
  String get deskTabToday => 'ዛሬ';

  @override
  String get deskSearchMembers => 'ስም ወይም ስልክ ቁጥር';

  @override
  String get deskSearchHint => 'ያለ ስልካቸው የመጡ አባልን ይፈልጉና ያስገቡ።';

  @override
  String get deskNoMembersFound => 'የሚመሳሰል የዚህ ጂም አባል የለም።';

  @override
  String get deskCheckIn => 'አስገባ';

  @override
  String get deskTodayTitle => 'ዛሬ በዚህ ቅርንጫፍ';

  @override
  String get deskTodayEmpty => 'ዛሬ እዚህ እስካሁን የገባ የለም።';

  @override
  String get deskUnknownMember => 'ያልታወቀ ኮድ';

  @override
  String get freezeDays => 'የማቆሚያ ቀናት';

  @override
  String freezeDaysLeftOf(int left, int allowed) {
    return 'ከ$allowed $left ቀርቷል';
  }

  @override
  String get freezeMembership => 'አባልነቴን ለጊዜው አቁም';

  @override
  String get freezeSheetTitle => 'አባልነትዎን ለጊዜው ያቁሙ';

  @override
  String get freezeSheetBody =>
      'ዕቅድዎ በእነዚህ ቀናት ይቆማል፤ የሚያልቅበት ቀንም በዚያው ልክ ይራዘማል።';

  @override
  String get freezeFirstDay => 'የመጀመሪያ ቀን';

  @override
  String get freezeLastDay => 'የመጨረሻ ቀን';

  @override
  String freezeSummary(int days, String date) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days ቀናት',
      one: '1 ቀን',
    );
    return '$_temp0 · ዕቅድዎ $date ላይ ያልቃል';
  }

  @override
  String freezeTooManyDays(int left) {
    String _temp0 = intl.Intl.pluralLogic(
      left,
      locale: localeName,
      other: 'የቀሩት $left የማቆሚያ ቀናት ብቻ ናቸው።',
      one: 'የቀረው 1 የማቆሚያ ቀን ብቻ ነው።',
    );
    return '$_temp0';
  }

  @override
  String get freezeReason => 'ምክንያት (አማራጭ)';

  @override
  String get freezeReasonHint => 'ጉዞ፣ ሕመም…';

  @override
  String get freezeConfirm => 'አቁም';

  @override
  String freezeDone(String from, String to) {
    return 'ከ$from እስከ $to ቆሟል።';
  }

  @override
  String freezeCurrent(String from, String to) {
    return 'ከ$from እስከ $to ቆሟል';
  }

  @override
  String freezeComing(String from, String to) {
    return 'ከ$from እስከ $to ይቆማል';
  }

  @override
  String freezeLength(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days ቀናት',
      one: '1 ቀን',
    );
    return '$_temp0';
  }

  @override
  String get freezeBack => 'ተመልሻለሁ';

  @override
  String get freezeCancel => 'ማቆሙን ሰርዝ';

  @override
  String get freezeBackTitle => 'ማቆሙን ዛሬ ይጨርሱ?';

  @override
  String get freezeBackBody =>
      'ከዛሬ ጀምሮ ጂሙን መጠቀም ይችላሉ። ያልተጠቀሙባቸው የማቆሚያ ቀናት ይመለሱልዎታል፤ ዕቅድዎም ቀድሞ ያልቃል።';

  @override
  String get freezeCancelTitle => 'ይህን ማቆም ይሰርዙ?';

  @override
  String get freezeCancelBody =>
      'የማቆሚያ ቀናቱ ይመለሱልዎታል፤ ዕቅድዎ የሚያልቅበት ቀንም ወደ ቀድሞው ይመለሳል።';

  @override
  String get freezeKeep => 'ይቆይ';

  @override
  String get freezeEnded => 'እንኳን ደህና መጡ! ማቆሙ አብቅቷል።';

  @override
  String get freezeCancelled => 'ማቆሙ ተሰርዟል።';

  @override
  String get deskSavedOffline => 'ተቀምጧል፤ ኢንተርኔት ሲመለስ ይረጋገጣል';

  @override
  String get deskSavedOfflineBody =>
      'አሁን ኢንተርኔት የለም። እርግጠኛ ከሆኑ ያስገቡ፤ ስካኑ ሲላክ ውጤቱ በዛሬ ገጽ ላይ ይታያል።';

  @override
  String deskWaitingBadge(int count) {
    return '$count በመጠባበቅ ላይ';
  }

  @override
  String get deskWaitingTitle => 'ለመላክ በመጠባበቅ ላይ';

  @override
  String get deskWaitingBody => 'ያለ ኢንተርኔት የተስካኑ። ዴስኩ ኢንተርኔት እንዳገኘ ይላካሉ።';

  @override
  String deskWaitingRow(String time) {
    return '$time ላይ የተስካነ';
  }

  @override
  String get deskSendNow => 'አሁን ላክ';

  @override
  String get deskOfflineChip => 'ያለ ኢንተርኔት የተስካነ';

  @override
  String deskDroppedNotice(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ስካኖች ከአንድ ቀን በላይ ስለቆዩ መላክ አልተቻለም።',
      one: '1 ስካን ከአንድ ቀን በላይ ስለቆየ መላክ አልተቻለም።',
    );
    return '$_temp0';
  }

  @override
  String get deskDismiss => 'ዝጋ';

  @override
  String get deskInboxTitle => 'መልዕክቶች';

  @override
  String get deskMarkAllRead => 'ሁሉንም እንደተነበበ ምልክት አድርግ';

  @override
  String get deskInboxEmpty =>
      'እስካሁን መልዕክት የለም። የኦንላይን ክፍያዎች፣ የሚመለሱ ገንዘቦች፣ በመተግበሪያው የቆሙ አባልነቶች እና የሚደወልላቸው አባላት እዚህ ይታያሉ።';

  @override
  String get deskOpenPanel => 'በሰራተኞች ፓነል ክፈት';

  @override
  String get deskViewMessage => 'ይመልከቱ';

  @override
  String get deskNotificationSettings => 'ማሳወቂያዎች';

  @override
  String get deskTopicOnlinePayments => 'የኦንላይን ክፍያዎች';

  @override
  String get deskTopicRefunds => 'የሚመለሱ ገንዘቦች';

  @override
  String get deskTopicAppFreezes => 'በመተግበሪያው የቆሙ አባልነቶች';

  @override
  String get deskTopicMembersToCall => 'የሚደወልላቸው አባላት';

  @override
  String get deskChannelPush => 'ፑሽ';

  @override
  String get deskChannelSms => 'ኤስኤምኤስ';

  @override
  String get deskQuietHours => 'ከምሽቱ 3:00 እስከ ጠዋቱ 1:00 ኤስኤምኤስ አይላክም።';

  @override
  String get promoCodeAsk => 'የቅናሽ ኮድ አለዎት?';

  @override
  String get promoCodeHint => 'የቅናሽ ኮድ';

  @override
  String get promoCodeApply => 'ተግብር';

  @override
  String promoCodeApplied(String code) {
    return '$code ተተግብሯል';
  }

  @override
  String get promoCodeRemove => 'ኮዱን አስወግድ';

  @override
  String get branchesTitle => 'ቅርንጫፎች እና የስራ ሰዓታት';

  @override
  String get branchAlwaysOpen => 'ሁልጊዜ ክፍት';

  @override
  String branchOpenUntil(String time) {
    return 'አሁን ክፍት · እስከ $time';
  }

  @override
  String branchClosedOpensAt(String time) {
    return 'ዝግ · $time ይከፈታል';
  }

  @override
  String get branchClosed => 'ዝግ';

  @override
  String get branchOnYourPlan => 'የእርስዎ ዕቅድ';

  @override
  String get yourOtherPlans => 'ሌሎች እቅዶችዎ';

  @override
  String planDates(String from, String to) {
    return '$from – $to';
  }

  @override
  String planPaidOf(String paid, String price) {
    return 'ከ$price $paid ተከፍሏል';
  }

  @override
  String get freezeByYou => 'በመተግበሪያው እርስዎ ያቆሙት';

  @override
  String get freezeByGym => 'ጂሙ ያቆመው';

  @override
  String get numbersTitle => 'ቁጥሮች';

  @override
  String get numbersToday => 'ዛሬ';

  @override
  String get numbersWeek => '7 ቀናት';

  @override
  String get numbersMonth => '30 ቀናት';

  @override
  String get numbersAllBranches => 'ሁሉም ቅርንጫፎቼ';

  @override
  String get numbersCheckIns => 'መግቢያዎች';

  @override
  String get numbersMoney => 'ገንዘብ';

  @override
  String get numbersTaken => 'የተሰበሰበ';

  @override
  String get numbersReceived => 'የተቀበልነው';

  @override
  String get numbersRefunded => 'የተመለሰ';

  @override
  String numbersOpenLinks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ክፍት የክፍያ ሊንኮች',
      one: '1 ክፍት የክፍያ ሊንክ',
    );
    return '$_temp0';
  }

  @override
  String numbersRefundsNeeded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count የሚመለሱ ገንዘቦች',
      one: '1 የሚመለስ ገንዘብ',
    );
    return '$_temp0';
  }

  @override
  String get numbersOwed => 'ዕዳ';

  @override
  String numbersOwedMembers(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'በ$count አባላት',
      one: 'በ1 አባል',
    );
    return '$_temp0';
  }

  @override
  String get numbersMembers => 'አባላት';

  @override
  String get numbersActive => 'ንቁ';

  @override
  String get numbersNew => 'አዲስ';

  @override
  String get numbersSoldAtDesk => 'በዴስክ የተሸጡ እቅዶች';

  @override
  String get numbersSoldInApp => 'በመተግበሪያው የተሸጡ እቅዶች';

  @override
  String get numbersBusyHours => 'የተጨናነቁ ሰዓታት';

  @override
  String get numbersToCall => 'የሚደወልላቸው አባላት';

  @override
  String get numbersNoOneToCall => 'የሚደወልለት የለም፤ በሚቀጥሉት ቀናት የሚያልቅ ዕቅድ የለም።';

  @override
  String numbersEnds(String date) {
    return '$date ያልቃል';
  }

  @override
  String numbersCall(String phone) {
    return 'ወደ $phone ይደውሉ';
  }

  @override
  String get deskDecidedOffline => 'ያለ ኢንተርኔት የተወሰነ';

  @override
  String get deskReasonNoDoorList => 'ኢንተርኔት የለም፤ ለማረጋገጥ የበር ዝርዝርም የለም';

  @override
  String deskOfflineRefused(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ሰርቨሩ $count ያለ ኢንተርኔት የተስካኑ አልመዘገበም።',
      one: 'ሰርቨሩ 1 ያለ ኢንተርኔት የተስካነ አልመዘገበም።',
    );
    return '$_temp0';
  }

  @override
  String deskOfflineToReview(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'በፓነሉ የሚታዩ $count ያለ ኢንተርኔት የገቡ።',
      one: 'በፓነሉ የሚታይ 1 ያለ ኢንተርኔት የገባ።',
    );
    return '$_temp0';
  }

  @override
  String get deskNoInternetDemo => 'ኢንተርኔት የለም (ሙከራ)';

  @override
  String deskServerDisagrees(String reason) {
    return 'ሰርቨር፦ $reason፤ በፓነሉ ይመልከቱ';
  }

  @override
  String branchClosedToday(String reason) {
    return 'ዛሬ ዝግ ነው፦ $reason';
  }

  @override
  String branchOtherHoursToday(String hours, String reason) {
    return 'ዛሬ ሌላ ሰዓት፦ $hours · $reason';
  }

  @override
  String branchHoursNextDay(String hours) {
    return '$hours (በማግስቱ)';
  }

  @override
  String get branchClosuresComing => 'የሚዘጋባቸው ቀናት እና ሌላ ሰዓት';

  @override
  String get branchEveryYear => 'በየዓመቱ';

  @override
  String get photoChange => 'ፎቶዎን ይቀይሩ';

  @override
  String get photoTitle => 'የእርስዎ ፎቶ';

  @override
  String get photoBody => 'ሲገቡ ዴስኩ ያየዋል፤ ቁጥርዎ በተመዘገበባቸው ጂሞች ሁሉ።';

  @override
  String get photoTake => 'ፎቶ አንሳ';

  @override
  String get photoChoose => 'ከጋለሪ ምረጥ';

  @override
  String get photoRemove => 'ፎቶውን አስወግድ';

  @override
  String get photoSaved => 'ፎቶዎ ተቀምጧል።';

  @override
  String get photoRemoved => 'ፎቶዎ ተወግዷል።';

  @override
  String deskMemberPhoto(String name) {
    return 'የ$name ፎቶ';
  }

  @override
  String deskPhotoSaved(String name) {
    return 'የ$name ፎቶ ተቀምጧል።';
  }

  @override
  String deskPhotoRemoved(String name) {
    return 'የ$name ፎቶ ተወግዷል።';
  }

  @override
  String get deskTakePayment => 'ክፍያ ተቀበል';

  @override
  String payTitle(String name) {
    return 'ከ$name ክፍያ';
  }

  @override
  String get payBody =>
      'አባሉ በዴስኩ የከፈለውን ገንዘብ ይመዝግቡ፣ ወይም በመስመር ላይ እንዲከፍሉ ሊንክ በኤስኤምኤስ ይላኩ።';

  @override
  String get payWhichMembership => 'የትኛው አባልነት';

  @override
  String get payAmountLabel => 'መጠን';

  @override
  String payAmountHelp(String due) {
    return 'እስከ $due ይቀራል';
  }

  @override
  String get payAmountInvalid => 'እንደ 500 ወይም 500.50 ያለ መጠን ያስገቡ።';

  @override
  String get payMethod => 'እንዴት ከፈሉ';

  @override
  String get payCash => 'ጥሬ ገንዘብ';

  @override
  String get payTelebirr => 'ቴሌብር';

  @override
  String get payCbeBirr => 'ሲቢኢ ብር';

  @override
  String get payBankTransfer => 'የባንክ ዝውውር';

  @override
  String get payReference => 'የግብይት ቁጥር';

  @override
  String get payReferenceHelp => 'ከክፍያ ማረጋገጫው';

  @override
  String get payPaidOn => 'የተከፈለበት ቀን';

  @override
  String get payToday => 'ዛሬ';

  @override
  String paySummary(String amount, String method, String name, String left) {
    return '$amount በ$method ከ$name · $left ይቀራል';
  }

  @override
  String paySummaryPaidOff(String amount, String method, String name) {
    return '$amount በ$method ከ$name · ሙሉ በሙሉ ተከፍሏል';
  }

  @override
  String get payRecord => 'ክፍያውን መዝግብ';

  @override
  String payRecorded(String receipt, String amount) {
    return 'ደረሰኝ $receipt · $amount';
  }

  @override
  String get payTextLink => 'በምትኩ የክፍያ ሊንክ ላክ';

  @override
  String get payTextAgain => 'የክፍያ ሊንኩን እንደገና ላክ';

  @override
  String get payLinkOpen => 'ለዚህ አባልነት የተከፈተ የክፍያ ሊንክ አለ።';

  @override
  String payLinkTexted(String phone) {
    return 'የክፍያ ሊንክ ወደ $phone ተልኳል';
  }

  @override
  String payNothingDue(String name) {
    return '$name የሚከፍሉት ነገር የለም።';
  }

  @override
  String get deskSellPlan => 'ዕቅድ ሽጥ';

  @override
  String get deskRenew => 'አድስ';

  @override
  String sellTitle(String name) {
    return 'ዕቅድ ለ$name';
  }

  @override
  String get sellBody => 'አባሉን ያድሱ ወይም ሌላ ዕቅድ ይሽጡላቸው። ክፍያው ቀጥሎ ይመጣል።';

  @override
  String get sellPlan => 'ዕቅድ';

  @override
  String get sellCurrentPlan => 'የአሁኑ ዕቅድ';

  @override
  String get sellNoPlans => 'ይህ ጂም የሚሸጥ ዕቅድ የለውም። በሰራተኞች ፓነል ላይ ይጨምሩ።';

  @override
  String sellLengthDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ቀናት',
      one: '1 ቀን',
    );
    return '$_temp0';
  }

  @override
  String sellLengthWeeks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ሳምንታት',
      one: '1 ሳምንት',
    );
    return '$_temp0';
  }

  @override
  String sellLengthMonths(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ወራት',
      one: '1 ወር',
    );
    return '$_temp0';
  }

  @override
  String sellLengthYears(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ዓመታት',
      one: '1 ዓመት',
    );
    return '$_temp0';
  }

  @override
  String sellVisits(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ጉብኝቶች',
      one: '1 ጉብኝት',
    );
    return '$_temp0';
  }

  @override
  String get sellStarts => 'የሚጀምርበት';

  @override
  String get sellFirstFreeDay => 'የመጀመሪያው ክፍት ቀን';

  @override
  String get sellStartsHelp => 'ዛሬ፣ ወይም የአሁኑ ዕቅዳቸው ካለቀ በኋላ ባለው ቀን።';

  @override
  String get sellPrice => 'ዋጋ';

  @override
  String get sellPromoCode => 'የፕሮሞ ኮድ';

  @override
  String get sellPromoCodeHint => 'ካላቸው';

  @override
  String get sellDiscount => 'ቅናሽ';

  @override
  String get sellDiscountHint => '500 ወይም 10%';

  @override
  String get sellDiscountHelp => 'በፕሮሞ ኮድ ምትክ፤ ለባለቤቶችና ለአስተዳዳሪዎች ብቻ።';

  @override
  String get sellDiscountReason => 'የቅናሹ ምክንያት';

  @override
  String sellSummary(String plan, String name, String price) {
    return '$plan ለ$name · $price፣ ወይም በቅናሽ ቡድናቸው ወይም በፕሮሞ ኮድ ያነሰ';
  }

  @override
  String sellSummaryDiscount(String plan, String name, String price) {
    return '$plan ለ$name · $price፣ ቅናሽዎ ተቀንሶ';
  }

  @override
  String get sellConfirm => 'ዕቅዱን ሽጥ';

  @override
  String sellDone(
    String plan,
    String name,
    String from,
    String to,
    String price,
  ) {
    return '$plan ለ$name ተሽጧል · $from – $to · $price';
  }

  @override
  String get deskAddMember => 'አባል ጨምር';

  @override
  String get deskNoMembersFoundAdd => 'ገና አባል አይደሉም? ይጨምሯቸው።';

  @override
  String get newMemberTitle => 'አዲስ አባል';

  @override
  String newMemberBody(String branch) {
    return 'ዋና ቅርንጫፋቸው $branch ይሆናል። ዕቅድና ክፍያ ቀጥሎ ይመጣሉ።';
  }

  @override
  String get newMemberWho => 'ማን ናቸው';

  @override
  String get newMemberWhoHelp => 'ስማቸውና ስልካቸው ያስፈልጋል፤ በዚህ ስልክ ወደ መተግበሪያው ይገባሉ።';

  @override
  String get newMemberName => 'ሙሉ ስም';

  @override
  String get newMemberPhone => 'ስልክ';

  @override
  String get newMemberPhoneHelp => 'እንደ 0911 234 567';

  @override
  String get newMemberFindThem => 'በምትኩ ፈልጋቸው';

  @override
  String get newMemberFemale => 'ሴት';

  @override
  String get newMemberMale => 'ወንድ';

  @override
  String get newMemberBirthday => 'የትውልድ ቀን';

  @override
  String get newMemberOptional => 'አማራጭ';

  @override
  String get newMemberMessages => 'መልዕክቶች';

  @override
  String get newMemberMessagesHelp => 'የኤስኤምኤስና የመተግበሪያ ማሳወቂያዎቻቸው ቋንቋ።';

  @override
  String get newMemberEmail => 'ኢሜይል';

  @override
  String get newMemberEmergency => 'የአደጋ ጊዜ ተጠሪ';

  @override
  String get newMemberEmergencyHelp => 'አማራጭ፤ ሁለቱንም ይሙሉ ወይም አንዱንም አይሙሉ።';

  @override
  String get newMemberContactName => 'የተጠሪው ስም';

  @override
  String get newMemberContactPhone => 'የተጠሪው ስልክ';

  @override
  String get newMemberAdd => 'አባል ጨምር';

  @override
  String newMemberAdded(String name) {
    return '$name አሁን አባል ናቸው።';
  }

  @override
  String get welcomeBody => 'ቀጥሎ፦ ዴስኩ እንዲያውቃቸው ፎቶአቸው፣ እና ለመግባት ዕቅድ።';

  @override
  String get welcomePhotoHelp => 'ሲገቡ ይታያል።';

  @override
  String get welcomePhotoTaken => 'ፎቶ ተነስቷል';

  @override
  String get welcomePlanHelp => 'ከዚያ ክፍያውን ይቀበሉ።';

  @override
  String get welcomeLater => 'በኋላ';

  @override
  String get deskMembershipAction => 'አባልነት';

  @override
  String deskMembershipTitle(String name) {
    return 'የ$name አባልነት';
  }

  @override
  String get deskMembershipBody => 'በሌሉበት ጊዜ ያቁሙት፣ ማቆሙን ያንሱ፣ ወይም ይሰርዙት።';

  @override
  String get deskNoRunningMembership =>
      'እየሄደ ያለ ወይም የሚመጣ አባልነት የለም። ዕቅድ ይሽጡላቸው።';

  @override
  String get deskStatusActive => 'ንቁ';

  @override
  String get deskStatusFrozen => 'የቆመ';

  @override
  String get deskStatusUpcoming => 'በኋላ ይጀምራል';

  @override
  String deskFreezeDaysUsed(int used, int allowed) {
    return 'የማቆሚያ ቀናት፦ ከ$allowed $used ጥቅም ላይ ውለዋል';
  }

  @override
  String deskFrozenFrom(String from, String to) {
    return 'የቆመ $from – $to';
  }

  @override
  String get deskEndFreeze => 'ማቆሙን አንሳ';

  @override
  String get deskRemoveFreeze => 'ማቆሙን ሰርዝ';

  @override
  String get deskKeepFreeze => 'ይቆይ';

  @override
  String get deskEndFreezeTitle => 'ማቆሙ ዛሬ ይነሳ?';

  @override
  String deskEndFreezeBody(String to) {
    return 'ከዛሬ ጀምሮ መግባት ይችላሉ፣ ዕቅዱም እስከ $to በቀሩት ቀናት ቀድሞ ያልቃል።';
  }

  @override
  String get deskRemoveFreezeTitle => 'ይህ ማቆሚያ ይሰረዝ?';

  @override
  String deskRemoveFreezeBody(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'ዕቅዱ $days ቀናት ቀድሞ ያልቃል።',
      one: 'ዕቅዱ 1 ቀን ቀድሞ ያልቃል።',
    );
    return '$_temp0';
  }

  @override
  String get deskFreezeEnded => 'ማቆሙ ተነስቷል።';

  @override
  String get deskFreezeRemoved => 'ማቆሙ ተሰርዟል።';

  @override
  String deskFreezeTitle(String plan) {
    return '$plan አቁም';
  }

  @override
  String get deskFreezeBody =>
      'በእነዚህ ቀናት መግባት አይችሉም፣ ዕቅዱም በዚያው ቁጥር ቀናት ዘግይቶ ያልቃል።';

  @override
  String deskFreezeSummary(int days, String date) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days ቀናት',
      one: '1 ቀን',
    );
    return '$_temp0 · ዕቅዱ አሁን $date ያልቃል';
  }

  @override
  String deskFreezeDaysLeft(int left) {
    String _temp0 = intl.Intl.pluralLogic(
      left,
      locale: localeName,
      other: 'በዚህ ዕቅድ $left የማቆሚያ ቀናት ቀርተዋል።',
      one: 'በዚህ ዕቅድ 1 የማቆሚያ ቀን ቀርቷል።',
      zero: 'በዚህ ዕቅድ የቀረ የማቆሚያ ቀን የለም።',
    );
    return '$_temp0';
  }

  @override
  String deskFreezeOverAllowanceOwner(int left) {
    String _temp0 = intl.Intl.pluralLogic(
      left,
      locale: localeName,
      other: 'ከቀሩት $left የማቆሚያ ቀናት ይበልጣል፤ እንደ ባለቤት ወይም አስተዳዳሪ አሁንም ማቆም ይችላሉ።',
      one: 'ከቀረው 1 የማቆሚያ ቀን ይበልጣል፤ እንደ ባለቤት ወይም አስተዳዳሪ አሁንም ማቆም ይችላሉ።',
    );
    return '$_temp0';
  }

  @override
  String get deskFreezeReason => 'ለምን';

  @override
  String get deskFrozen => 'አባልነቱ ቆሟል።';

  @override
  String get deskCancelMembership => 'አባልነቱን ሰርዝ';

  @override
  String get deskKeepMembership => 'ይቆይ';

  @override
  String deskCancelTitle(String plan) {
    return '$plan ይሰረዝ?';
  }

  @override
  String get deskCancelBody =>
      'ከእንግዲህ በዚህ አይገቡም። ተመላሽ ገንዘብ ካለ በሰራተኞች ፓነል ይሰጣል።';

  @override
  String get deskCancelReason => 'የተሰረዘበት ምክንያት';

  @override
  String get deskCancelled => 'አባልነቱ ተሰርዟል።';

  @override
  String get deskEndFreezeAction => 'ማቆሙን አንሳ';

  @override
  String get errorGymPaused => 'ይህ ጂም ለጊዜው ቆሟል።';

  @override
  String get gymPausedTag => 'የቆመ';

  @override
  String get gymPausedMember => 'ይህ ጂም ለጊዜው ቆሟል። ጂሙን ይጠይቁ።';

  @override
  String get gymPausedStaff =>
      'ይህ ጂም ቆሟል። እንደገና እንዲከፈት መድረኩን ያነጋግሩ። አሁን የሚደረጉ ስካኖች ተቀምጠው ሲመለስ ይላካሉ።';

  @override
  String get paymentMethodCash => 'ጥሬ ገንዘብ';

  @override
  String get paymentMethodTelebirr => 'ቴሌብር';

  @override
  String get paymentMethodCbeBirr => 'ሲቢኢ ብር';

  @override
  String get paymentMethodBankTransfer => 'የባንክ ዝውውር';

  @override
  String get paymentMethodChapa => 'ቻፓ';

  @override
  String get paymentMethodBroughtIn => 'ከዚህ በፊት የተከፈለ';

  @override
  String get deskPauseDemo => 'ጂሙን አቁም (ሙከራ)';

  @override
  String get memberPageTitle => 'አባል';

  @override
  String get memberStatusEnded => 'ያለቀ';

  @override
  String get memberStatusCancelled => 'የተሰረዘ';

  @override
  String get memberStatusNoPlan => 'ዕቅድ የለም';

  @override
  String memberSince(String date) {
    return 'ከ$date ጀምሮ አባል';
  }

  @override
  String get memberMemberships => 'አባልነቶች';

  @override
  String get memberNoMemberships => 'ገና አባልነት የለም።';

  @override
  String get memberPayments => 'ክፍያዎች';

  @override
  String get memberNoPayments => 'ገና ክፍያ የለም።';

  @override
  String get memberRefund => 'ተመላሽ';

  @override
  String get memberVoided => 'የተሰረዘ';

  @override
  String get memberVisits => 'ጉብኝቶች';

  @override
  String get memberNoVisits => 'ገና ጉብኝት የለም።';

  @override
  String get memberLoadMore => 'ተጨማሪ አሳይ';

  @override
  String get memberDetails => 'ዝርዝሮች';

  @override
  String get memberGender => 'ጾታ';

  @override
  String get memberLanguage => 'የመልዕክት ቋንቋ';

  @override
  String get memberOpenPage => 'የአባሉ ገጽ';

  @override
  String get editMember => 'አስተካክል';

  @override
  String editMemberTitle(String name) {
    return '$nameን አስተካክል';
  }

  @override
  String get editMemberBody => 'ዝርዝሮቻቸውን ያስተካክሉ። ባዶ የሆነ መስክ ይሰረዛል።';

  @override
  String get editMemberSave => 'ለውጦቹን አስቀምጥ';

  @override
  String get editMemberSaved => 'ተቀምጧል።';

  @override
  String get editMemberPhoneNote =>
      'በዚህ ቁጥር ወደ መተግበሪያው ይገባሉ፣ ስለዚህ ለእነሱም ይቀየራል።';

  @override
  String get editMemberHomeBranch => 'ዋና ቅርንጫፍ';

  @override
  String get editMemberHomeBranchHelp => 'ብዙውን ጊዜ የሚመጡበት።';

  @override
  String editMemberPhoneTaken(String phone) {
    return '$phone የሌላ አባል ቁጥር ነው። በዴስክ ፍለጋ ያግኟቸው።';
  }
}
