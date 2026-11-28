import '../../l10n/app_localizations.dart';
import 'failure.dart';

/// The code every route of a gym the platform paused answers with, in a
/// `403`.
const gymPausedCode = 'GYM_PAUSED';

/// Whether [failure] says the gym is paused.
bool isGymPaused(Object failure) => failure is ForbiddenFailure && failure.code == gymPausedCode;

/// The text to show for [failure] in the current language. Features add
/// specific codes (`OTP_EXPIRED`, `MEMBERSHIP_FROZEN`) on top of this.
String failureMessage(AppLocalizations l10n, Failure failure) => switch (failure) {
  NetworkFailure() => l10n.errorNetwork,
  UnauthenticatedFailure() => l10n.errorSessionExpired,
  // A gym the platform paused (the API's ADR 0043): its own words, already
  // in the request's language.
  ForbiddenFailure(code: gymPausedCode, :final message) => message ?? l10n.errorGymPaused,
  ForbiddenFailure() => l10n.errorForbidden,
  NotFoundFailure() => l10n.errorNotFound,
  ConflictFailure() => l10n.errorConflict,
  ValidationFailure() => l10n.errorValidation,
  UpdateRequiredFailure() => l10n.errorUpdateRequired,
  RateLimitedFailure() => l10n.errorRateLimited,
  ServerFailure() => l10n.errorServer,
  CancelledFailure() || UnexpectedFailure() => l10n.errorUnexpected,
};
