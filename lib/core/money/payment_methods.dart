import '../../l10n/app_localizations.dart';

/// How a receipt names the way the member paid: at the desk, online
/// through Chapa, or before the gym joined the platform (`brought_in`, from
/// its import of members).
String paymentMethodName(AppLocalizations l10n, String method) => switch (method) {
  'cash' => l10n.paymentMethodCash,
  'telebirr' => l10n.paymentMethodTelebirr,
  'cbe_birr' => l10n.paymentMethodCbeBirr,
  'bank_transfer' => l10n.paymentMethodBankTransfer,
  'chapa' => l10n.paymentMethodChapa,
  'brought_in' => l10n.paymentMethodBroughtIn,
  _ => method,
};
