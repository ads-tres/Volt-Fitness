import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../core/auth/session.dart';
import '../core/auth/session_controller.dart';
import '../core/localization/l10n.dart';
import '../features/auth/presentation/otp_page.dart';
import '../features/auth/presentation/phone_page.dart';
import '../features/gyms/presentation/no_gym_page.dart';
import '../features/gyms/presentation/select_gym_page.dart';
import '../features/home/presentation/home_page.dart';
import '../features/onboarding/onboarding_controller.dart';
import '../features/onboarding/presentation/onboarding_page.dart';
import '../features/profile/presentation/profile_page.dart';
import '../features/shell/presentation/app_shell.dart';
import '../features/shell/presentation/coming_soon_page.dart';
import 'routes.dart';

export 'routes.dart';

/// Where to send someone, given their session and whether they have seen
/// the welcome pages. Guards only spare people screens they can't use; the
/// API authorizes every request on its own.
String? authRedirect({required Session session, required bool onboardingDone, required String location}) {
  final signingIn = location.startsWith(AppRoutes.login);
  switch (session) {
    case SignedOut() when !onboardingDone:
      return location == AppRoutes.welcome ? null : AppRoutes.welcome;
    case SignedOut():
      return signingIn ? null : AppRoutes.login;
    case SignedIn(:final profile, :final organization):
      if (profile.organizations.isEmpty) return location == AppRoutes.noGym ? null : AppRoutes.noGym;
      if (organization == null) return location == AppRoutes.selectGym ? null : AppRoutes.selectGym;
      // Signed in with a gym: everything but sign-in is open, including
      // the gym picker for switching.
      return signingIn || location == AppRoutes.noGym || location == AppRoutes.welcome ? AppRoutes.home : null;
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final gate = ValueNotifier((session: ref.read(sessionControllerProvider), onboardingDone: ref.read(onboardingDoneProvider)));
  ref.listen(sessionControllerProvider, (_, next) => gate.value = (session: next, onboardingDone: gate.value.onboardingDone));
  ref.listen(onboardingDoneProvider, (_, next) => gate.value = (session: gate.value.session, onboardingDone: next));

  final router = GoRouter(
    initialLocation: AppRoutes.home,
    refreshListenable: gate,
    redirect: (context, state) => authRedirect(
      session: gate.value.session,
      onboardingDone: gate.value.onboardingDone,
      location: state.matchedLocation,
    ),
    routes: [
      GoRoute(path: '/', redirect: (context, state) => AppRoutes.home),
      GoRoute(path: AppRoutes.welcome, builder: (context, state) => const OnboardingPage()),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const PhonePage(),
        routes: [GoRoute(path: 'verify', builder: (context, state) => const OtpPage())],
      ),
      GoRoute(path: AppRoutes.selectGym, builder: (context, state) => const SelectGymPage()),
      GoRoute(path: AppRoutes.noGym, builder: (context, state) => const NoGymPage()),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [GoRoute(path: AppRoutes.home, builder: (context, state) => const HomePage())],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.membership,
                builder: (context, state) => ComingSoonPage(
                  title: context.l10n.navMembership,
                  photo: 'assets/photos/onboarding_train.jpg',
                  message: context.l10n.comingSoonMembership,
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.qr,
                builder: (context, state) => ComingSoonPage(
                  title: context.l10n.navQr,
                  photo: 'assets/photos/onboarding_check_in.jpg',
                  message: context.l10n.comingSoonQr,
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.payments,
                builder: (context, state) => ComingSoonPage(
                  title: context.l10n.navPayments,
                  photo: 'assets/photos/onboarding_renew.jpg',
                  message: context.l10n.comingSoonPayments,
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: AppRoutes.profile, builder: (context, state) => const ProfilePage())],
          ),
        ],
      ),
    ],
  );
  ref.onDispose(() {
    router.dispose();
    gate.dispose();
  });
  return router;
});
