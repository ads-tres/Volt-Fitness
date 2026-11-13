import '../../../core/errors/failure.dart';
import '../../../core/errors/failure_messages.dart';
import '../../../l10n/app_localizations.dart';
import 'sign_in_controller.dart';

String signInProblemText(AppLocalizations l10n, SignInProblem problem) => switch (problem) {
  InvalidPhone() => l10n.phoneInvalid,
  // The API answers a wrong or expired code alike, on the `code` field, and
  // too many tries with 429.
  RequestFailed(:final failure) => switch (failure) {
    ValidationFailure(:final fieldErrors) when fieldErrors.containsKey('code') => l10n.otpInvalid,
    RateLimitedFailure() => l10n.otpTooManyAttempts,
    _ => failureMessage(l10n, failure),
  },
};
