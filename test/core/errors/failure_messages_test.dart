import 'package:flutter_test/flutter_test.dart';
import 'package:gym_mobile/core/errors/failure.dart';
import 'package:gym_mobile/core/errors/failure_messages.dart';
import 'package:gym_mobile/l10n/app_localizations_en.dart';

void main() {
  final l10n = AppLocalizationsEn();

  test('a paused gym shows the API\'s own words, or ours when it sent none', () {
    const paused = ForbiddenFailure(code: 'GYM_PAUSED', message: 'Demo Gym is paused. Ask at the gym.');
    expect(failureMessage(l10n, paused), 'Demo Gym is paused. Ask at the gym.');
    expect(failureMessage(l10n, const ForbiddenFailure(code: 'GYM_PAUSED')), 'This gym is paused for now.');
    expect(isGymPaused(paused), isTrue);
  });

  test('any other 403 is still "no access"', () {
    expect(failureMessage(l10n, const ForbiddenFailure(message: 'This action is unauthorized.')), "You don't have access to this.");
    expect(isGymPaused(const ForbiddenFailure()), isFalse);
    expect(isGymPaused(const NetworkFailure()), isFalse);
  });
}
