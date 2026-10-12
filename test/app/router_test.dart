import 'package:flutter_test/flutter_test.dart';
import 'package:gym_mobile/app/router.dart';
import 'package:gym_mobile/core/auth/session_controller.dart';

void main() {
  test('a signed-out member is sent to sign-in from anywhere else', () {
    expect(authRedirect(status: SessionStatus.signedOut, location: AppRoutes.home), AppRoutes.login);
    expect(authRedirect(status: SessionStatus.signedOut, location: AppRoutes.login), isNull);
  });

  test('a signed-in member is kept out of sign-in', () {
    expect(authRedirect(status: SessionStatus.signedIn, location: AppRoutes.login), AppRoutes.home);
    expect(authRedirect(status: SessionStatus.signedIn, location: AppRoutes.home), isNull);
  });
}
