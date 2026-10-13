import 'package:flutter_test/flutter_test.dart';
import 'package:gym_mobile/app/router.dart';
import 'package:gym_mobile/core/auth/session.dart';

import '../support/test_doubles.dart';

void main() {
  test('a signed-out member can only be in the sign-in flow', () {
    const session = SignedOut();
    expect(authRedirect(session: session, location: AppRoutes.home), AppRoutes.login);
    expect(authRedirect(session: session, location: AppRoutes.login), isNull);
    expect(authRedirect(session: session, location: AppRoutes.verify), isNull);
  });

  test('a member with no gym is held on the no-gym screen', () {
    final session = SignedIn(profile: memberOf([]));
    expect(authRedirect(session: session, location: AppRoutes.home), AppRoutes.noGym);
    expect(authRedirect(session: session, location: AppRoutes.noGym), isNull);
  });

  test('a member of several gyms picks one first', () {
    final session = SignedIn(profile: memberOf([boleGym, kazanchisGym]));
    expect(authRedirect(session: session, location: AppRoutes.verify), AppRoutes.selectGym);
    expect(authRedirect(session: session, location: AppRoutes.selectGym), isNull);
  });

  test('a member in a gym leaves sign-in for home, and may switch gyms', () {
    final session = SignedIn(profile: memberOf([boleGym, kazanchisGym]), organizationId: boleGym.id);
    expect(authRedirect(session: session, location: AppRoutes.verify), AppRoutes.home);
    expect(authRedirect(session: session, location: AppRoutes.profile), isNull);
    expect(authRedirect(session: session, location: AppRoutes.selectGym), isNull);
  });
}
