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
import '../features/profile/presentation/profile_page.dart';
import '../features/shell/presentation/app_shell.dart';
import '../features/shell/presentation/coming_soon_page.dart';
import 'routes.dart';

export 'routes.dart';

/// Where to send someone, given their session. Guards only spare people
/// screens they can't use; the API authorizes every request on its own.
String? authRedirect({required Session session, required String location}) {
  final signingIn = location.startsWith(AppRoutes.login);
  switch (session) {
    case SignedOut():
      return signingIn ? null : AppRoutes.login;
    case SignedIn(:final profile, :final organization):
      if (profile.organizations.isEmpty) return location == AppRoutes.noGym ? null : AppRoutes.noGym;
      if (organization == null) return location == AppRoutes.selectGym ? null : AppRoutes.selectGym;
      // Signed in with a gym: everything but sign-in is open, including
      // the gym picker for switching.
      return signingIn || location == AppRoutes.noGym ? AppRoutes.home : null;
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final session = ValueNotifier(ref.read(sessionControllerProvider));
  ref.listen(sessionControllerProvider, (_, next) => session.value = next);

  final router = GoRouter(
    initialLocation: AppRoutes.home,
    refreshListenable: session,
    redirect: (context, state) => authRedirect(session: session.value, location: state.matchedLocation),
    routes: [
      GoRoute(path: '/', redirect: (context, state) => AppRoutes.home),
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
                  icon: Icons.card_membership_rounded,
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
                  icon: Icons.qr_code_2_rounded,
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
                  icon: Icons.account_balance_wallet_rounded,
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
    session.dispose();
  });
  return router;
});
