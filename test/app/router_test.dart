import 'package:flutter_test/flutter_test.dart';
import 'package:gym_mobile/app/router.dart';
import 'package:gym_mobile/core/auth/session.dart';

import '../support/test_doubles.dart';

String? redirect(Session session, String location, {bool onboardingDone = true}) =>
    authRedirect(session: session, onboardingDone: onboardingDone, location: location);

void main() {
  test('a first launch shows the welcome pages before anything else', () {
    expect(redirect(const SignedOut(), AppRoutes.home, onboardingDone: false), AppRoutes.welcome);
    expect(redirect(const SignedOut(), AppRoutes.login, onboardingDone: false), AppRoutes.welcome);
    expect(redirect(const SignedOut(), AppRoutes.welcome, onboardingDone: false), isNull);
  });

  test('a signed-out member can only be in the sign-in flow', () {
    const session = SignedOut();
    expect(redirect(session, AppRoutes.home), AppRoutes.login);
    expect(redirect(session, AppRoutes.welcome), AppRoutes.login);
    expect(redirect(session, AppRoutes.login), isNull);
    expect(redirect(session, AppRoutes.verify), isNull);
  });

  test('a member with no gym is held on the no-gym screen', () {
    final session = SignedIn(profile: memberOf([]));
    expect(redirect(session, AppRoutes.home), AppRoutes.noGym);
    expect(redirect(session, AppRoutes.noGym), isNull);
  });

  test('a member of several gyms picks one first', () {
    final session = SignedIn(profile: memberOf([boleGym, kazanchisGym]));
    expect(redirect(session, AppRoutes.verify), AppRoutes.selectGym);
    expect(redirect(session, AppRoutes.selectGym), isNull);
  });

  test('a member in a gym leaves sign-in for home, and may switch gyms', () {
    final session = SignedIn(profile: memberOf([boleGym, kazanchisGym]), organizationId: boleGym.id);
    expect(redirect(session, AppRoutes.verify), AppRoutes.home);
    expect(redirect(session, AppRoutes.welcome), AppRoutes.home);
    expect(redirect(session, AppRoutes.profile), isNull);
    expect(redirect(session, AppRoutes.selectGym), isNull);
  });
}
