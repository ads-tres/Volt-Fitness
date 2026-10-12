import '../../l10n/app_localizations.dart';
import 'failure.dart';

/// The text to show for [failure] in the current language. Features add
/// specific codes (`OTP_EXPIRED`, `MEMBERSHIP_FROZEN`) on top of this.
String failureMessage(AppLocalizations l10n, Failure failure) => switch (failure) {
  NetworkFailure() => l10n.errorNetwork,
  UnauthenticatedFailure() => l10n.errorSessionExpired,
  ForbiddenFailure() => l10n.errorForbidden,
  NotFoundFailure() => l10n.errorNotFound,
  ConflictFailure() => l10n.errorConflict,
  ValidationFailure() => l10n.errorValidation,
  UpdateRequiredFailure() => l10n.errorUpdateRequired,
  RateLimitedFailure() => l10n.errorRateLimited,
  ServerFailure() => l10n.errorServer,
  CancelledFailure() || UnexpectedFailure() => l10n.errorUnexpected,
};
