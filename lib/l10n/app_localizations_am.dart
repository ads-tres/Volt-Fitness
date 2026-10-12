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
  String get signIn => 'ግባ';

  @override
  String get signOut => 'ውጣ';

  @override
  String get home => 'መነሻ';

  @override
  String get language => 'ቋንቋ';

  @override
  String get languageSystem => 'የስልኩን ቋንቋ ተጠቀም';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageAmharic => 'አማርኛ';

  @override
  String get placeholderNotice => 'ዲዛይኑ እስኪዘጋጅ ድረስ ይህ ጊዜያዊ ገጽ ነው።';

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
