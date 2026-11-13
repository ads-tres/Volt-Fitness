import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../core/desk_session.dart';
import '../features/auth/presentation/desk_sign_in_page.dart';
import '../features/gym/presentation/choose_branch_page.dart';
import '../features/gym/presentation/choose_gym_page.dart';
import '../features/scan/presentation/scan_page.dart';
import 'staff_routes.dart';

export 'staff_routes.dart';

/// Where the desk belongs, given its session: signed in, then a gym, then a
/// branch, then the scanner. The API authorizes every request on its own.
String? deskRedirect(DeskSession session, String location) {
  final target = switch (session) {
    DeskSignedOut() => StaffRoutes.signIn,
    DeskSignedIn(gym: null) => StaffRoutes.chooseGym,
    DeskSignedIn(branch: null) => StaffRoutes.chooseBranch,
    DeskSignedIn() => null,
  };
  if (target != null) return location == target ? null : target;
  const setUp = [StaffRoutes.signIn, StaffRoutes.chooseGym, StaffRoutes.chooseBranch];
  return setUp.contains(location) ? StaffRoutes.scan : null;
}

final staffRouterProvider = Provider<GoRouter>((ref) {
  final gate = ValueNotifier(ref.read(deskSessionProvider));
  ref.listen(deskSessionProvider, (_, next) => gate.value = next);

  final router = GoRouter(
    initialLocation: StaffRoutes.scan,
    refreshListenable: gate,
    redirect: (context, state) => deskRedirect(gate.value, state.matchedLocation),
    routes: [
      GoRoute(path: '/', redirect: (context, state) => StaffRoutes.scan),
      GoRoute(path: StaffRoutes.signIn, builder: (context, state) => const DeskSignInPage()),
      GoRoute(path: StaffRoutes.chooseGym, builder: (context, state) => const ChooseGymPage()),
      GoRoute(path: StaffRoutes.chooseBranch, builder: (context, state) => const ChooseBranchPage()),
      GoRoute(path: StaffRoutes.scan, builder: (context, state) => const ScanPage()),
    ],
  );
  ref.onDispose(() {
    router.dispose();
    gate.dispose();
  });
  return router;
});
