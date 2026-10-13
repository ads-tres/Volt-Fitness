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
  String welcomeBack(String gym) {
    return 'ወደ $gym እንኳን በደህና ተመለሱ።';
  }

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
  String get comingSoonTitle => 'በሚቀጥለው ዝማኔ ይመጣል';

  @override
  String get comingSoonMembership => 'ዕቅድዎ፣ ቀናቱ እና እድሳቱ እዚህ ይታያሉ።';

  @override
  String get comingSoonQr => 'የመግቢያ QR ኮድዎ እዚህ ይታያል።';

  @override
  String get comingSoonPayments => 'ደረሰኞችዎ፣ ክፍያዎችዎ እና ማስረጃዎችዎ እዚህ ይታያሉ።';

  @override
  String get switchGym => 'ቀይር';

  @override
  String get signOut => 'ውጣ';

  @override
  String appVersion(String version, String build) {
    return 'Volt $version ($build)';
  }

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
