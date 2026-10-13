import '../../../core/errors/failure_messages.dart';
import '../../../l10n/app_localizations.dart';
import 'sign_in_controller.dart';

String signInProblemText(AppLocalizations l10n, SignInProblem problem) => switch (problem) {
  InvalidPhone() => l10n.phoneInvalid,
  RequestFailed(:final failure) => switch (failure.code) {
    'OTP_INVALID' => l10n.otpInvalid,
    'OTP_EXPIRED' => l10n.otpExpired,
    'OTP_TOO_MANY_ATTEMPTS' => l10n.otpTooManyAttempts,
    _ => failureMessage(l10n, failure),
  },
};
