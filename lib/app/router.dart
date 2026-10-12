import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/auth/session_controller.dart';
import '../features/auth/presentation/login_page.dart';
import '../features/home/presentation/home_page.dart';

abstract final class AppRoutes {
  static const login = '/login';
  static const home = '/home';
}

/// Where to send someone, given their session. Guards only spare people
/// screens they can't use; the API authorizes every request on its own.
String? authRedirect({required SessionStatus status, required String location}) {
  final isPublic = location == AppRoutes.login;
  return switch (status) {
    SessionStatus.signedOut when !isPublic => AppRoutes.login,
    SessionStatus.signedIn when isPublic => AppRoutes.home,
    _ => null,
  };
}

final routerProvider = Provider<GoRouter>((ref) {
  final session = ValueNotifier(ref.read(sessionControllerProvider));
  ref.listen(sessionControllerProvider, (_, status) => session.value = status);

  final router = GoRouter(
    initialLocation: AppRoutes.home,
    refreshListenable: session,
    redirect: (context, state) => authRedirect(status: session.value, location: state.matchedLocation),
    routes: [
      GoRoute(path: '/', redirect: (context, state) => AppRoutes.home),
      GoRoute(path: AppRoutes.login, builder: (context, state) => const LoginPage()),
      GoRoute(path: AppRoutes.home, builder: (context, state) => const HomePage()),
    ],
  );
  ref.onDispose(() {
    router.dispose();
    session.dispose();
  });
  return router;
});
